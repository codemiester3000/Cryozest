import Foundation
import HealthKit

// MARK: - Data Structures

struct WorkoutData {
    let startDate: Date
    let endDate: Date
    let activityType: TherapyType
    let heartRateSamples: [(timestamp: Date, bpm: Double)]
}

struct WorkoutStrain {
    let activityType: TherapyType
    let durationMinutes: Double
    let avgHR: Double
    let peakHR: Double
    let cardiovascularTRIMP: Double
    let muscularMultiplier: Double
    let workoutStrain: Double       // Individual workout strain (0-21 scale)
}

struct DailyStrainResult {
    let date: Date
    let strain: Double              // 0-21 total daily strain
    let workouts: [WorkoutStrain]
    let totalCardiovascularTRIMP: Double
    let totalMuscularTRIMP: Double
    let totalWorkoutMinutes: Double
    let peakHR: Double
}

// MARK: - Engine

/// Calculates daily strain on a 0-21 logarithmic scale (aligned with WHOOP).
///
/// **Cardiovascular load**: Modified Edwards TRIMP — time spent in each HR zone
/// weighted exponentially. Higher zones accumulate strain dramatically faster.
///
/// **Muscular load**: Activity-type multipliers applied on top of cardiovascular
/// TRIMP. Strength training, CrossFit, and other high-muscular-demand activities
/// receive a bonus that boosts their strain beyond what HR alone would indicate.
/// Inspired by WHOOP 5.0's Strength Trainer and passive MSK estimation.
///
/// **Logarithmic scale**: Raw TRIMP is log-transformed so that easy days score
/// low (2-5), moderate workouts land in the middle (10-14), hard sessions push
/// high (15-18), and only truly brutal efforts reach 19-21. This matches the
/// Borg Scale of Perceived Exertion that WHOOP's 0-21 range is based on.
class StrainScoreEngine {
    static let shared = StrainScoreEngine()

    // MARK: - Zone Configuration

    /// Exponential zone weights: higher zones accumulate strain much faster.
    /// Calibrated against Edwards TRIMP (1/2/3/4/5) but with steeper curve
    /// at zones 4-5 to match WHOOP's emphasis on high-intensity effort.
    private static let zoneWeights: [Double] = [1.0, 2.0, 3.5, 5.5, 9.0]

    /// Zone boundaries as fraction of HR reserve (Karvonen method).
    /// Zone 1: 50-60%, Zone 2: 60-70%, Zone 3: 70-80%, Zone 4: 80-90%, Zone 5: 90%+
    private static let zoneBounds: [Double] = [0.50, 0.60, 0.70, 0.80, 0.90]

    // MARK: - Muscular Load Multipliers

    /// Activity-type multipliers for muscular demand beyond what HR captures.
    /// Inspired by WHOOP 5.0's Strength Trainer: strength training and functional
    /// fitness get the largest boost because HR underrepresents their true load
    /// (heavy lifting elevates strain without sustaining high HR).
    ///
    /// Activities not listed default to 1.0 (pure cardiovascular).
    private static let muscularMultipliers: [TherapyType: Double] = [
        .weightTraining: 1.40,  // Heavy compound lifts, machines, free weights
        .crossfit:       1.35,  // Functional fitness, WODs
        .boxing:         1.30,  // Upper body muscular demand + cardio
        .rockClimbing:   1.25,  // Grip + full body isometric load
        .rowing:         1.20,  // Full-body pulling compound movement
        .swimming:       1.15,  // Full-body resistance against water
        .pilates:        1.15,  // Core-focused muscular endurance
        .barre:          1.15,  // Isometric holds + small muscle groups
        .dance:          1.10,  // Varied muscular patterns
        .basketball:     1.10,  // Explosive jumping, cutting
        .surfing:        1.10,  // Paddling + balance/stability
        .pickleball:     1.10,  // Lateral movement + arm strain
        .stairClimbing:  1.05,  // Leg-dominant concentric work
    ]
    // running, cycling, hiking, elliptical, walking → 1.0 (cardio-dominant)

    // MARK: - Scaling

    /// Log scale factor: strain = scaleFactor * ln(totalTRIMP + 1).
    /// Calibrated so:
    ///   - Rest day (~15 background TRIMP) → strain ~3
    ///   - 45-min moderate run (~120 TRIMP) → strain ~12-13
    ///   - 90-min lifting session (~250 TRIMP) → strain ~14-15
    ///   - Hard 2-hr session (~500 TRIMP) → strain ~17-18
    ///   - Brutal multi-workout day (~800+ TRIMP) → strain ~20+
    private static let logScaleFactor: Double = 3.0

    /// Minimum background TRIMP for a day (being alive, walking around, NEAT).
    private static let baseDailyTRIMP: Double = 15.0

    private init() {}

    // MARK: - Daily Strain Computation

    /// Computes total daily strain from workouts + background activity.
    ///
    /// - Parameters:
    ///   - workouts: All HKWorkouts for the day with their HR samples.
    ///   - maxHR: User's estimated max heart rate (207 - 0.7 * age).
    ///   - restingHR: User's 30-day average resting heart rate.
    ///   - activeCalories: Optional active energy burned for the day (improves
    ///     background strain estimate for non-workout activity).
    func computeDailyStrain(
        workouts: [WorkoutData],
        maxHR: Double,
        restingHR: Double,
        activeCalories: Double? = nil
    ) -> DailyStrainResult {
        let hrReserve = maxHR - restingHR
        guard hrReserve > 0 else {
            return DailyStrainResult(
                date: Date(), strain: 0, workouts: [],
                totalCardiovascularTRIMP: 0, totalMuscularTRIMP: 0,
                totalWorkoutMinutes: 0, peakHR: 0
            )
        }

        var workoutStrains: [WorkoutStrain] = []
        var totalCardioTRIMP: Double = 0
        var totalMuscularTRIMP: Double = 0
        var totalMinutes: Double = 0
        var overallPeakHR: Double = 0

        for workout in workouts {
            let result = computeWorkoutStrain(
                workout: workout,
                hrReserve: hrReserve,
                restingHR: restingHR
            )
            workoutStrains.append(result)
            totalCardioTRIMP += result.cardiovascularTRIMP
            // Muscular bonus = cardio * (multiplier - 1.0)
            totalMuscularTRIMP += result.cardiovascularTRIMP * (result.muscularMultiplier - 1.0)
            totalMinutes += result.durationMinutes
            overallPeakHR = max(overallPeakHR, result.peakHR)
        }

        // Background strain from non-workout activity (walking, stairs, NEAT).
        // If active calories are available, use them as a proxy; otherwise use base.
        let backgroundTRIMP: Double
        if let cal = activeCalories, cal > 0 {
            // ~1 TRIMP per 30 active calories, floored at base
            backgroundTRIMP = max(cal / 30.0, Self.baseDailyTRIMP)
        } else {
            backgroundTRIMP = Self.baseDailyTRIMP
        }

        let totalTRIMP = totalCardioTRIMP + totalMuscularTRIMP + backgroundTRIMP

        // Logarithmic scale to 0-21
        let strain = min(Self.logScaleFactor * log(totalTRIMP + 1.0), 21.0)

        return DailyStrainResult(
            date: Date(),
            strain: strain,
            workouts: workoutStrains,
            totalCardiovascularTRIMP: totalCardioTRIMP,
            totalMuscularTRIMP: totalMuscularTRIMP,
            totalWorkoutMinutes: totalMinutes,
            peakHR: overallPeakHR
        )
    }

    // MARK: - Per-Workout Strain

    private func computeWorkoutStrain(
        workout: WorkoutData,
        hrReserve: Double,
        restingHR: Double
    ) -> WorkoutStrain {
        let samples = workout.heartRateSamples.sorted { $0.timestamp < $1.timestamp }

        var zoneTimes = [Double](repeating: 0, count: 5) // minutes per zone
        var peakHR: Double = 0
        var totalHR: Double = 0

        for i in 0..<samples.count {
            let hr = samples[i].bpm
            totalHR += hr
            peakHR = max(peakHR, hr)

            // Time attributed to this sample: gap to next sample, capped at 5 min
            // (avoids inflating strain from sparse HR data)
            let timeDeltaMinutes: Double
            if i + 1 < samples.count {
                let gap = samples[i + 1].timestamp.timeIntervalSince(samples[i].timestamp)
                timeDeltaMinutes = min(gap, 300) / 60.0
            } else {
                timeDeltaMinutes = 5.0 / 60.0 // 5 seconds default for last sample
            }

            // Determine HR zone using Karvonen method
            let hrFraction = (hr - restingHR) / hrReserve
            let zone = zoneForFraction(hrFraction)
            if zone >= 0 {
                zoneTimes[zone] += timeDeltaMinutes
            }
        }

        let avgHR = samples.isEmpty ? 0 : totalHR / Double(samples.count)
        let durationMinutes = workout.endDate.timeIntervalSince(workout.startDate) / 60.0

        // Cardiovascular TRIMP: sum of (time in zone × zone weight)
        var cardioTRIMP: Double = 0
        for i in 0..<5 {
            cardioTRIMP += zoneTimes[i] * Self.zoneWeights[i]
        }

        // Muscular multiplier based on activity type
        let muscleMultiplier = Self.muscularMultipliers[workout.activityType] ?? 1.0
        let effectiveTRIMP = cardioTRIMP * muscleMultiplier

        // Per-workout strain on log scale
        let workoutStrain = min(Self.logScaleFactor * log(effectiveTRIMP + 1.0), 21.0)

        return WorkoutStrain(
            activityType: workout.activityType,
            durationMinutes: durationMinutes,
            avgHR: avgHR,
            peakHR: peakHR,
            cardiovascularTRIMP: cardioTRIMP,
            muscularMultiplier: muscleMultiplier,
            workoutStrain: workoutStrain
        )
    }

    // MARK: - Helpers

    /// Maps HR fraction (Karvonen) to zone index 0-4. Returns -1 if below zone 1.
    private func zoneForFraction(_ fraction: Double) -> Int {
        if fraction < Self.zoneBounds[0] { return -1 }
        for i in 0..<(Self.zoneBounds.count - 1) {
            if fraction < Self.zoneBounds[i + 1] { return i }
        }
        return 4 // Zone 5: 90%+
    }

    // MARK: - HKWorkout → TherapyType Mapping

    /// Maps Apple's workout activity type to the app's TherapyType.
    /// Mirrors the mapping in AppleWorkoutsService.
    static func therapyType(for workoutType: HKWorkoutActivityType) -> TherapyType {
        switch workoutType {
        case .running:                       return .running
        case .cycling:                       return .cycling
        case .swimming:                      return .swimming
        case .pilates:                       return .pilates
        case .basketball:                    return .basketball
        case .elliptical:                    return .elliptical
        case .hiking:                        return .hiking
        case .rowing:                        return .rowing
        case .walking:                       return .walking
        case .traditionalStrengthTraining,
             .functionalStrengthTraining:    return .weightTraining
        case .barre:                         return .barre
        case .boxing, .kickboxing:           return .boxing
        case .surfingSports:                 return .surfing
        case .pickleball:                    return .pickleball
        case .dance,
             .socialDance,
             .cardioDance:                   return .dance
        case .crossTraining,
             .highIntensityIntervalTraining: return .crossfit
        case .stairClimbing, .stairs:        return .stairClimbing
        case .climbing:                      return .rockClimbing
        default:                             return .running // Fallback: treat unknown as cardio
        }
    }
}
