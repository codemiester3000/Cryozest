import SwiftUI
import HealthKit

// MARK: - Strain Categories (matches WHOOP green/yellow/red zones)

enum StrainCategory: String {
    case rest     = "Rest"       // 0–4.9
    case light    = "Light"      // 5–9.9
    case moderate = "Moderate"   // 10–13.9
    case hard     = "Hard"       // 14–17.9
    case allOut   = "All Out"    // 18–21

    var color: Color {
        switch self {
        case .rest:     return .blue
        case .light:    return .green
        case .moderate: return .yellow
        case .hard:     return .orange
        case .allOut:   return .red
        }
    }
}

// MARK: - View Model

class StrainScoreModel: ObservableObject {
    @Published var dailyStrain: Double = 0
    @Published var workoutStrains: [WorkoutStrain] = []
    @Published var totalWorkoutMinutes: Double = 0
    @Published var peakHR: Double = 0
    @Published var strainCategory: StrainCategory = .rest
    @Published var isLoading: Bool = false

    // 7-day history for chart display
    @Published var last7DaysStrain: [(date: Date, strain: Double)] = []

    private let engine = StrainScoreEngine.shared
    private let healthStore = HKHealthStore()

    // MARK: - Compute Today's Strain

    func computeStrain(for date: Date) {
        isLoading = true

        let group = DispatchGroup()
        var maxHR: Double = 180
        var restingHR: Double = 60
        var activeCalories: Double?
        var workouts: [WorkoutData] = []

        // 1. Fetch user age → max HR
        group.enter()
        HealthKitManager.shared.fetchUserAge { age, _ in
            if let age = age {
                maxHR = 207 - (0.7 * Double(age))
            }
            group.leave()
        }

        // 2. Fetch 30-day average resting HR
        group.enter()
        HealthKitManager.shared.fetchAvgRestingHeartRate(numDays: 30) { rhr in
            if let rhr = rhr {
                restingHR = rhr
            }
            group.leave()
        }

        // 3. Fetch active calories for the day
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        group.enter()
        HealthKitManager.shared.fetchActiveEnergy(from: startOfDay, to: endOfDay) { samples, _ in
            if let samples = samples {
                activeCalories = samples.reduce(0.0) {
                    $0 + $1.quantity.doubleValue(for: .kilocalorie())
                }
            }
            group.leave()
        }

        // 4. Fetch HKWorkouts + their HR samples
        group.enter()
        fetchWorkoutsWithHR(for: date) { result in
            workouts = result
            group.leave()
        }

        // 5. Combine everything
        group.notify(queue: .main) { [weak self] in
            guard let self = self else { return }

            let result = self.engine.computeDailyStrain(
                workouts: workouts,
                maxHR: maxHR,
                restingHR: restingHR,
                activeCalories: activeCalories
            )

            self.dailyStrain = (result.strain * 10).rounded() / 10
            self.workoutStrains = result.workouts
            self.totalWorkoutMinutes = result.totalWorkoutMinutes
            self.peakHR = result.peakHR
            self.strainCategory = Self.categoryFor(result.strain)
            self.isLoading = false

            // Compute 7-day history in background
            self.computeLast7Days(currentDate: date, maxHR: maxHR, restingHR: restingHR)
        }
    }

    // MARK: - 7-Day History

    private func computeLast7Days(currentDate: Date, maxHR: Double, restingHR: Double) {
        let calendar = Calendar.current
        let group = DispatchGroup()
        var strainByDate: [(date: Date, strain: Double)] = []
        let lock = NSLock()

        for i in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: calendar.startOfDay(for: currentDate)) else { continue }

            group.enter()

            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

            // Fetch workouts + active calories for each day
            let innerGroup = DispatchGroup()
            var dayWorkouts: [WorkoutData] = []
            var dayCal: Double?

            innerGroup.enter()
            fetchWorkoutsWithHR(for: date) { result in
                dayWorkouts = result
                innerGroup.leave()
            }

            innerGroup.enter()
            HealthKitManager.shared.fetchActiveEnergy(from: startOfDay, to: endOfDay) { samples, _ in
                if let samples = samples {
                    dayCal = samples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: .kilocalorie()) }
                }
                innerGroup.leave()
            }

            innerGroup.notify(queue: .global()) { [weak self] in
                guard let self = self else {
                    group.leave()
                    return
                }
                let result = self.engine.computeDailyStrain(
                    workouts: dayWorkouts,
                    maxHR: maxHR,
                    restingHR: restingHR,
                    activeCalories: dayCal
                )
                let rounded = (result.strain * 10).rounded() / 10
                lock.lock()
                strainByDate.append((date: date, strain: rounded))
                lock.unlock()
                group.leave()
            }
        }

        group.notify(queue: .main) { [weak self] in
            self?.last7DaysStrain = strainByDate.sorted { $0.date < $1.date }
        }
    }

    // MARK: - HealthKit Queries

    private func fetchWorkoutsWithHR(for date: Date, completion: @escaping ([WorkoutData]) -> Void) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            completion([])
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        let query = HKSampleQuery(
            sampleType: .workoutType(),
            predicate: predicate,
            limit: HKObjectQueryNoLimit,
            sortDescriptors: nil
        ) { [weak self] _, samples, _ in
            guard let self = self,
                  let hkWorkouts = samples as? [HKWorkout],
                  !hkWorkouts.isEmpty else {
                DispatchQueue.main.async { completion([]) }
                return
            }

            let group = DispatchGroup()
            var workoutDataArray: [WorkoutData] = []
            let lock = NSLock()

            for workout in hkWorkouts {
                group.enter()
                self.fetchHRSamples(from: workout.startDate, to: workout.endDate) { hrSamples in
                    let therapyType = StrainScoreEngine.therapyType(for: workout.workoutActivityType)
                    let data = WorkoutData(
                        startDate: workout.startDate,
                        endDate: workout.endDate,
                        activityType: therapyType,
                        heartRateSamples: hrSamples
                    )
                    lock.lock()
                    workoutDataArray.append(data)
                    lock.unlock()
                    group.leave()
                }
            }

            group.notify(queue: .main) {
                completion(workoutDataArray)
            }
        }
        healthStore.execute(query)
    }

    private func fetchHRSamples(from start: Date, to end: Date, completion: @escaping ([(timestamp: Date, bpm: Double)]) -> Void) {
        HealthKitManager.shared.fetchHeartRateData(from: start, to: end) { samples, _ in
            guard let samples = samples else {
                completion([])
                return
            }
            let hrUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            let result = samples.map {
                (timestamp: $0.startDate, bpm: $0.quantity.doubleValue(for: hrUnit))
            }
            completion(result)
        }
    }

    // MARK: - Helpers

    static func categoryFor(_ strain: Double) -> StrainCategory {
        switch strain {
        case ..<5:   return .rest
        case ..<10:  return .light
        case ..<14:  return .moderate
        case ..<18:  return .hard
        default:     return .allOut
        }
    }
}
