//
//  InsightsViewModel.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//

import SwiftUI
import CoreData

struct HabitImpact: Identifiable {
    let id = UUID()
    let habitType: TherapyType
    let metricName: String
    let baselineValue: Double
    let habitValue: Double
    let percentageChange: Double
    let isPositive: Bool
    let sampleSize: Int

    var changeDescription: String {
        let sign = percentageChange >= 0 ? "+" : ""
        return "\(sign)\(Int(percentageChange))%"
    }

    var impactScore: Double {
        abs(percentageChange)
    }
}

struct MetricCorrelation: Identifiable {
    let id = UUID()
    let habitType: TherapyType
    let metricName: String
    let correlationStrength: Double // 0-1
    let direction: CorrelationDirection

    enum CorrelationDirection {
        case positive, negative, neutral
    }
}

struct HealthTrend: Identifiable {
    let id = UUID()
    let title: String
    let metric: String
    let currentValue: Double
    let previousValue: Double
    let changePercentage: Double
    let isPositive: Bool
    let icon: String
    let color: Color
    let description: String

    var changeDescription: String {
        let sign = changePercentage >= 0 ? "+" : ""
        return "\(sign)\(Int(changePercentage))%"
    }
}

class InsightsViewModel: ObservableObject {
    @Published var topHabitImpacts: [HabitImpact] = []
    @Published var sleepImpacts: [HabitImpact] = []
    @Published var hrvImpacts: [HabitImpact] = []
    @Published var rhrImpacts: [HabitImpact] = []
    @Published var healthTrends: [HealthTrend] = []
    @Published var isLoading: Bool = true

    private let healthKitManager = HealthKitManager.shared
    private var sessions: FetchedResults<TherapySessionEntity>
    private var selectedTherapyTypes: [TherapyType]

    init(sessions: FetchedResults<TherapySessionEntity>, selectedTherapyTypes: [TherapyType]) {
        self.sessions = sessions
        self.selectedTherapyTypes = selectedTherapyTypes

        // Fetch impacts asynchronously to ensure we're on the main thread
        DispatchQueue.main.async {
            self.fetchAllImpacts()
        }
    }

    // Get all workout therapy types from recorded sessions
    private func getRecordedWorkoutTypes() -> [TherapyType] {
        let workoutCategory = TherapyType.therapies(forCategory: .category0) // Workouts category
        var recordedWorkouts: Set<TherapyType> = []

        for session in sessions {
            if let therapyTypeString = session.therapyType,
               let therapyType = TherapyType(rawValue: therapyTypeString),
               workoutCategory.contains(therapyType) {
                recordedWorkouts.insert(therapyType)
            }
        }

        return Array(recordedWorkouts)
    }

    func fetchAllImpacts() {
        isLoading = true

        // Combine manually selected types with recorded workout types
        let recordedWorkouts = getRecordedWorkoutTypes()
        let allTherapyTypes = Array(Set(selectedTherapyTypes + recordedWorkouts))

        print("🔍 InsightsViewModel: Starting to fetch impacts for \(allTherapyTypes.count) therapy types")
        print("🔍 InsightsViewModel: Selected types: \(selectedTherapyTypes.map { $0.rawValue })")
        print("🔍 InsightsViewModel: Recorded workouts: \(recordedWorkouts.map { $0.rawValue })")

        let group = DispatchGroup()
        var allImpacts: [HabitImpact] = []
        var trends: [HealthTrend] = []

        // Fetch general health trends (always runs)
        group.enter()
        fetchHealthTrends { fetchedTrends in
            trends = fetchedTrends
            group.leave()
        }

        // Fetch habit impacts (includes both selected types and recorded workouts)
        for therapyType in allTherapyTypes {
            // Fetch sleep impact
            group.enter()
            fetchSleepImpact(for: therapyType) { impact in
                if let impact = impact {
                    allImpacts.append(impact)
                }
                group.leave()
            }

            // Fetch HRV impact
            group.enter()
            fetchHRVImpact(for: therapyType) { impact in
                if let impact = impact {
                    allImpacts.append(impact)
                }
                group.leave()
            }

            // Fetch RHR impact
            group.enter()
            fetchRHRImpact(for: therapyType) { impact in
                if let impact = impact {
                    allImpacts.append(impact)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            print("🔍 InsightsViewModel: Fetching complete. Found \(allImpacts.count) impacts and \(trends.count) trends")

            // Sort by impact score
            allImpacts.sort { $0.impactScore > $1.impactScore }

            self.healthTrends = trends
            self.topHabitImpacts = Array(allImpacts.prefix(5))
            self.sleepImpacts = allImpacts.filter { $0.metricName == "Sleep Duration" }
            self.hrvImpacts = allImpacts.filter { $0.metricName == "HRV" }
            self.rhrImpacts = allImpacts.filter { $0.metricName == "RHR" }

            print("🔍 InsightsViewModel: Setting isLoading = false")
            self.isLoading = false
        }
    }

    private func fetchHealthTrends(completion: @escaping ([HealthTrend]) -> Void) {
        let group = DispatchGroup()
        let trendsQueue = DispatchQueue(label: "com.cryozest.trends", attributes: .concurrent)
        var trends: [HealthTrend] = []

        // Compare last 7 days to previous 7 days
        let calendar = Calendar.current
        let today = Date()

        // RHR Trend
        group.enter()
        healthKitManager.fetchAvgRestingHeartRate(numDays: 7) { recentRHR in
            self.healthKitManager.fetchAvgRestingHeartRate(numDays: 14) { last14DaysRHR in
                defer { group.leave() }

                guard let recent = recentRHR, let last14 = last14DaysRHR, recent > 0, last14 > 0 else {
                    print("⚠️ InsightsViewModel: No RHR data available")
                    return
                }

                // Approximate previous 7 days RHR
                let previous = last14 * 2 - recent
                guard previous > 0 else {
                    print("⚠️ InsightsViewModel: Invalid previous RHR calculation")
                    return
                }

                let change = ((recent - previous) / previous) * 100
                let trend = HealthTrend(
                    title: "Resting Heart Rate",
                    metric: "RHR",
                    currentValue: recent,
                    previousValue: previous,
                    changePercentage: change,
                    isPositive: recent < previous, // Lower RHR is better
                    icon: "heart.fill",
                    color: abs(change) > 3 ? (recent < previous ? .green : .red) : .orange,
                    description: abs(change) > 3
                        ? (recent < previous ? "Improving recovery capacity" : "May indicate increased stress")
                        : "Maintaining steady baseline"
                )
                trendsQueue.async(flags: .barrier) {
                    trends.append(trend)
                }
                print("✅ InsightsViewModel: Added RHR trend")
            }
        }

        // HRV Trend
        group.enter()
        healthKitManager.fetchAvgHRVForLastDays(numberOfDays: 7) { recentHRV in
            self.healthKitManager.fetchAvgHRVForLastDays(numberOfDays: 14) { last14Days in
                defer { group.leave() }

                guard let recent = recentHRV, let last14 = last14Days, recent > 0, last14 > 0 else {
                    print("⚠️ InsightsViewModel: No HRV data available")
                    return
                }

                // Approximate previous 7 days HRV
                let previous = last14 * 2 - recent
                guard previous > 0 else {
                    print("⚠️ InsightsViewModel: Invalid previous HRV calculation")
                    return
                }

                let change = ((recent - previous) / previous) * 100
                let trend = HealthTrend(
                    title: "Heart Rate Variability",
                    metric: "HRV",
                    currentValue: recent,
                    previousValue: previous,
                    changePercentage: change,
                    isPositive: recent > previous, // Higher HRV is better
                    icon: "waveform.path.ecg",
                    color: abs(change) > 5 ? (recent > previous ? .green : .red) : .orange,
                    description: abs(change) > 5
                        ? (recent > previous ? "Better stress resilience" : "May indicate fatigue or stress")
                        : "Consistent stress response"
                )
                trendsQueue.async(flags: .barrier) {
                    trends.append(trend)
                }
                print("✅ InsightsViewModel: Added HRV trend")
            }
        }

        // Sleep Trend
        group.enter()
        healthKitManager.fetchAvgSleepDurationForLastNDays(numDays: 7) { recentSleep in
            self.healthKitManager.fetchAvgSleepDurationForLastNDays(numDays: 14) { last14Days in
                defer { group.leave() }

                guard let recent = recentSleep, let last14 = last14Days, recent > 0, last14 > 0 else {
                    print("⚠️ InsightsViewModel: No Sleep data available")
                    return
                }

                // Approximate previous 7 days sleep
                let previous = last14 * 2 - recent
                guard previous > 0 else {
                    print("⚠️ InsightsViewModel: Invalid previous Sleep calculation")
                    return
                }

                let change = ((recent - previous) / previous) * 100
                let recentHours = recent / 3600
                let previousHours = previous / 3600

                let trend = HealthTrend(
                    title: "Sleep Duration",
                    metric: "Sleep",
                    currentValue: recentHours,
                    previousValue: previousHours,
                    changePercentage: change,
                    isPositive: recent > previous,
                    icon: "bed.double.fill",
                    color: abs(change) > 10 ? (recent > previous ? .green : .red) : .purple,
                    description: abs(change) > 10
                        ? (recent > previous ? "Getting more restorative sleep" : "Sleep time has decreased")
                        : "Maintaining sleep routine"
                )
                trendsQueue.async(flags: .barrier) {
                    trends.append(trend)
                }
                print("✅ InsightsViewModel: Added Sleep trend")
            }
        }

        // Steps Trend (works with iPhone motion sensors)
        group.enter()
        healthKitManager.fetchAvgStepsForLastNDays(numDays: 7) { recentSteps in
            self.healthKitManager.fetchAvgStepsForLastNDays(numDays: 14) { last14Days in
                defer { group.leave() }

                guard let recent = recentSteps, let last14 = last14Days, recent > 0, last14 > 0 else {
                    print("⚠️ InsightsViewModel: No Steps data available")
                    return
                }

                // Approximate previous 7 days steps
                let previous = last14 * 2 - recent
                guard previous > 0 else {
                    print("⚠️ InsightsViewModel: Invalid previous Steps calculation")
                    return
                }

                let change = ((recent - previous) / previous) * 100
                let trend = HealthTrend(
                    title: "Daily Steps",
                    metric: "Steps",
                    currentValue: recent,
                    previousValue: previous,
                    changePercentage: change,
                    isPositive: recent > previous,
                    icon: "figure.walk",
                    color: abs(change) > 10 ? (recent > previous ? .green : .red) : .cyan,
                    description: abs(change) > 10
                        ? (recent > previous ? "More daily movement" : "Less daily activity")
                        : "Steady activity level"
                )
                trendsQueue.async(flags: .barrier) {
                    trends.append(trend)
                }
                print("✅ InsightsViewModel: Added Steps trend")
            }
        }

        // Active Calories Trend (works with iPhone motion sensors)
        group.enter()
        healthKitManager.fetchAvgActiveEnergyForLastNDays(numDays: 7) { recentCalories in
            self.healthKitManager.fetchAvgActiveEnergyForLastNDays(numDays: 14) { last14Days in
                defer { group.leave() }

                guard let recent = recentCalories, let last14 = last14Days, recent > 0, last14 > 0 else {
                    print("⚠️ InsightsViewModel: No Active Calories data available")
                    return
                }

                // Approximate previous 7 days calories
                let previous = last14 * 2 - recent
                guard previous > 0 else {
                    print("⚠️ InsightsViewModel: Invalid previous Calories calculation")
                    return
                }

                let change = ((recent - previous) / previous) * 100
                let trend = HealthTrend(
                    title: "Active Calories",
                    metric: "Calories",
                    currentValue: recent,
                    previousValue: previous,
                    changePercentage: change,
                    isPositive: recent > previous,
                    icon: "flame.fill",
                    color: abs(change) > 10 ? (recent > previous ? .green : .red) : .orange,
                    description: abs(change) > 10
                        ? (recent > previous ? "Increased energy expenditure" : "Reduced activity intensity")
                        : "Stable calorie burn"
                )
                trendsQueue.async(flags: .barrier) {
                    trends.append(trend)
                }
                print("✅ InsightsViewModel: Added Calories trend")
            }
        }

        group.notify(queue: .main) {
            trendsQueue.sync {
                print("📊 InsightsViewModel: Health trends fetched - \(trends.count) trends available")
                if trends.isEmpty {
                    print("⚠️ InsightsViewModel: No health trends available. Please ensure:")
                    print("   - Motion & Fitness tracking is enabled for Steps/Calories")
                    print("   - Apple Watch is connected for RHR and HRV data")
                    print("   - Sleep tracking is enabled in Health app for Sleep data")
                }
                completion(trends)
            }
        }
    }

    private func fetchSleepImpact(for therapyType: TherapyType, completion: @escaping (HabitImpact?) -> Void) {
        let therapyDates = DateUtils.shared.completedSessionDates(sessions: sessions, therapyType: therapyType)
        let nonTherapyDates = DateUtils.shared.datesWithoutTherapySessions(sessions: sessions, therapyType: therapyType, timeFrame: .month)

        guard therapyDates.count >= 3 && nonTherapyDates.count >= 3 else {
            completion(nil)
            return
        }

        let group = DispatchGroup()
        var baselineValue: Double = 0
        var habitValue: Double = 0

        group.enter()
        healthKitManager.fetchAvgSleepDurationForDays(days: nonTherapyDates) { duration in
            if let duration = duration {
                baselineValue = duration / 3600 // Convert to hours
            }
            group.leave()
        }

        group.enter()
        healthKitManager.fetchAvgSleepDurationForDays(days: therapyDates) { duration in
            if let duration = duration {
                habitValue = duration / 3600 // Convert to hours
            }
            group.leave()
        }

        group.notify(queue: .main) {
            guard baselineValue > 0 else {
                completion(nil)
                return
            }

            let change = ((habitValue - baselineValue) / baselineValue) * 100
            let impact = HabitImpact(
                habitType: therapyType,
                metricName: "Sleep Duration",
                baselineValue: baselineValue,
                habitValue: habitValue,
                percentageChange: change,
                isPositive: habitValue > baselineValue,
                sampleSize: therapyDates.count
            )
            completion(impact)
        }
    }

    private func fetchHRVImpact(for therapyType: TherapyType, completion: @escaping (HabitImpact?) -> Void) {
        let therapyDates = DateUtils.shared.completedSessionDates(sessions: sessions, therapyType: therapyType)
        let nonTherapyDates = DateUtils.shared.datesWithoutTherapySessions(sessions: sessions, therapyType: therapyType, timeFrame: .month)

        guard therapyDates.count >= 3 && nonTherapyDates.count >= 3 else {
            completion(nil)
            return
        }

        let group = DispatchGroup()
        var baselineValues: [Double] = []
        var habitValues: [Double] = []

        // Fetch HRV for each non-therapy day
        for date in nonTherapyDates {
            group.enter()
            healthKitManager.fetchAvgHRVForDay(date: date) { hrv in
                if let hrv = hrv {
                    baselineValues.append(hrv)
                }
                group.leave()
            }
        }

        // Fetch HRV for each therapy day
        for date in therapyDates {
            group.enter()
            healthKitManager.fetchAvgHRVForDay(date: date) { hrv in
                if let hrv = hrv {
                    habitValues.append(hrv)
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            guard !baselineValues.isEmpty && !habitValues.isEmpty else {
                completion(nil)
                return
            }

            let baselineValue = baselineValues.reduce(0, +) / Double(baselineValues.count)
            let habitValue = habitValues.reduce(0, +) / Double(habitValues.count)

            guard baselineValue > 0 else {
                completion(nil)
                return
            }

            let change = ((habitValue - baselineValue) / baselineValue) * 100
            let impact = HabitImpact(
                habitType: therapyType,
                metricName: "HRV",
                baselineValue: baselineValue,
                habitValue: habitValue,
                percentageChange: change,
                isPositive: habitValue > baselineValue,
                sampleSize: therapyDates.count
            )
            completion(impact)
        }
    }

    private func fetchRHRImpact(for therapyType: TherapyType, completion: @escaping (HabitImpact?) -> Void) {
        let therapyDates = DateUtils.shared.completedSessionDates(sessions: sessions, therapyType: therapyType)
        let nonTherapyDates = DateUtils.shared.datesWithoutTherapySessions(sessions: sessions, therapyType: therapyType, timeFrame: .month)

        guard therapyDates.count >= 3 && nonTherapyDates.count >= 3 else {
            completion(nil)
            return
        }

        let group = DispatchGroup()
        var baselineValue: Double = 0
        var habitValue: Double = 0

        group.enter()
        healthKitManager.fetchWakingStatisticsForDays(days: nonTherapyDates) { rhr, _, _ in
            baselineValue = rhr
            group.leave()
        }

        group.enter()
        healthKitManager.fetchWakingStatisticsForDays(days: therapyDates) { rhr, _, _ in
            habitValue = rhr
            group.leave()
        }

        group.notify(queue: .main) {
            guard baselineValue > 0 else {
                completion(nil)
                return
            }

            let change = ((habitValue - baselineValue) / baselineValue) * 100
            let impact = HabitImpact(
                habitType: therapyType,
                metricName: "RHR",
                baselineValue: baselineValue,
                habitValue: habitValue,
                percentageChange: change,
                isPositive: habitValue < baselineValue, // Lower is better for RHR
                sampleSize: therapyDates.count
            )
            completion(impact)
        }
    }
}
