//
//  InsightsViewModel.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//
//  Enhanced with robust statistical analysis:
//  - Pearson correlation with p-values
//  - Lag analysis (next-day effects)
//  - Outlier detection
//  - Multi-habit regression
//  - Confidence indicators
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
    let lastSessionDate: Date?

    // Enhanced statistical properties
    let correlation: CorrelationResult?
    let optimalLag: LaggedCorrelation?

    var changeDescription: String {
        let pct = abs(Int(percentageChange))
        return isPositive ? "+\(pct)%" : "-\(pct)%"
    }

    var impactScore: Double {
        // Weight by effect size, statistical confidence, AND recency
        let baseScore = abs(percentageChange)
        let confidenceMultiplier: Double
        switch confidenceLevel {
        case .high: confidenceMultiplier = 1.0
        case .moderate: confidenceMultiplier = 0.8
        case .earlySignal: confidenceMultiplier = 0.6
        case .low: confidenceMultiplier = 0.5
        case .insufficient: confidenceMultiplier = 0.2
        }

        // Recency boost: strongly favor habits done recently
        let recencyMultiplier: Double
        if let lastDate = lastSessionDate {
            let daysAgo = Calendar.current.dateComponents([.day], from: lastDate, to: Date()).day ?? 60
            if daysAgo <= 3 { recencyMultiplier = 3.0 }
            else if daysAgo <= 7 { recencyMultiplier = 2.5 }
            else if daysAgo <= 14 { recencyMultiplier = 1.5 }
            else if daysAgo <= 21 { recencyMultiplier = 0.8 }
            else { recencyMultiplier = 0.3 }
        } else {
            recencyMultiplier = 0.2
        }

        return baseScore * confidenceMultiplier * recencyMultiplier
    }

    var confidenceLevel: ConfidenceLevel {
        correlation?.confidenceLevel ?? .insufficient
    }

    var isStatisticallySignificant: Bool {
        correlation?.isSignificant ?? false
    }

    var pValue: Double? {
        correlation?.pValue
    }

    var lagDescription: String? {
        guard let lag = optimalLag, lag.lagDays > 0 else { return nil }
        return lag.description
    }

    // Convenience initializer for backward compatibility
    init(habitType: TherapyType, metricName: String, baselineValue: Double, habitValue: Double,
         percentageChange: Double, isPositive: Bool, sampleSize: Int,
         correlation: CorrelationResult? = nil, optimalLag: LaggedCorrelation? = nil,
         lastSessionDate: Date? = nil) {
        self.habitType = habitType
        self.metricName = metricName
        self.baselineValue = baselineValue
        self.habitValue = habitValue
        self.percentageChange = percentageChange
        self.isPositive = isPositive
        self.sampleSize = sampleSize
        self.correlation = correlation
        self.optimalLag = optimalLag
        self.lastSessionDate = lastSessionDate
    }
}

struct DataCollectionProgress: Identifiable {
    let id = UUID()
    let habitType: TherapyType
    let therapyDayCount: Int
    let nonTherapyDayCount: Int
    let minimumRequired: Int

    var therapyProgress: Double {
        min(Double(therapyDayCount) / Double(minimumRequired), 1.0)
    }

    var nonTherapyProgress: Double {
        min(Double(nonTherapyDayCount) / Double(minimumRequired), 1.0)
    }

    var overallProgress: Double {
        min((therapyProgress + nonTherapyProgress) / 2.0, 1.0)
    }

    var hasEnoughData: Bool {
        therapyDayCount >= minimumRequired && nonTherapyDayCount >= minimumRequired
    }

    var sessionsNeeded: Int {
        max(0, minimumRequired - therapyDayCount)
    }

    var progressDescription: String {
        if hasEnoughData { return "Insights available" }
        let needed = sessionsNeeded
        if needed > 0 {
            return "\(therapyDayCount)/\(minimumRequired) sessions \u{2014} track \(needed) more to unlock insights"
        }
        return "Collecting baseline data..."
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

// Multi-habit attribution result
struct HabitAttribution: Identifiable {
    let id = UUID()
    let metricName: String
    let habitContributions: [(habitType: TherapyType, contribution: Double, isSignificant: Bool)]
    let rSquared: Double
    let isModelSignificant: Bool
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
        let pct = abs(Int(changePercentage))
        return isPositive ? "+\(pct)%" : "-\(pct)%"
    }
}

class InsightsViewModel: ObservableObject {
    @Published var topHabitImpacts: [HabitImpact] = []
    @Published var sleepImpacts: [HabitImpact] = []
    @Published var hrvImpacts: [HabitImpact] = []
    @Published var rhrImpacts: [HabitImpact] = []
    @Published var painImpacts: [HabitImpact] = []
    @Published var waterImpacts: [HabitImpact] = []
    @Published var healthTrends: [HealthTrend] = []
    @Published var habitAttributions: [HabitAttribution] = []
    @Published var habitImpactsByType: [TherapyType: [HabitImpact]] = [:]
    @Published var dataCollectionProgress: [TherapyType: DataCollectionProgress] = [:]
    @Published var isLoading: Bool = true

    // Statistical configuration
    static let minimumSampleSize = StatisticsUtility.minimumSampleSize // 5 days for early signals
    /// Only analyze data from the last N days — older data is stale
    @Published var analysisWindowDays: Int = 30

    func refetch() {
        DispatchQueue.main.async {
            self.fetchAllImpacts()
        }
    }

    /// Exercise types that naturally suppress same-day HRV (acute stress response).
    /// For these, we compare next-day HRV instead of same-day.
    private static let exerciseTypes: Set<TherapyType> = [
        .running, .walking, .stairClimbing, .weightTraining, .cycling,
        .swimming, .boxing, .pilates, .crossfit, .dance, .rockClimbing,
        .hiking, .rowing, .surfing, .pickleball, .basketball, .elliptical, .barre
    ]

    /// Returns the top insight for a habit the user has actually done in the last 7 days.
    /// Only surfaces core health metrics (Sleep, HRV, RHR) — not pain or water.
    var recentInsight: HabitImpact? {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()

        let recentHabitTypes = Set(
            sessions
                .filter { session in
                    guard let date = session.date else { return false }
                    return date >= sevenDaysAgo
                }
                .compactMap { $0.therapyType }
        )

        let coreMetrics: Set<String> = ["Sleep Duration", "HRV", "RHR"]

        return topHabitImpacts.first { impact in
            recentHabitTypes.contains(impact.habitType.rawValue)
            && coreMetrics.contains(impact.metricName)
        }
    }

    private let healthKitManager = HealthKitManager.shared
    private let statsUtility = StatisticsUtility.shared
    private(set) var sessions: FetchedResults<TherapySessionEntity>
    private(set) var selectedTherapyTypes: [TherapyType]
    private var viewContext: NSManagedObjectContext?

    init(sessions: FetchedResults<TherapySessionEntity>, selectedTherapyTypes: [TherapyType], viewContext: NSManagedObjectContext? = nil) {
        self.sessions = sessions
        self.selectedTherapyTypes = selectedTherapyTypes
        self.viewContext = viewContext

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
        if DemoDataManager.shared.isDemoMode {
            DemoDataManager.shared.populateInsightsViewModel(self)
            return
        }
        isLoading = true

        // Combine manually selected types with recorded workout types
        let recordedWorkouts = getRecordedWorkoutTypes()
        let candidateTypes = Array(Set(selectedTherapyTypes + recordedWorkouts))

        // Only analyze habits with sessions in the analysis window (last 60 days)
        let calendar = Calendar.current
        let windowStart = calendar.date(byAdding: .day, value: -self.analysisWindowDays, to: Date()) ?? Date()
        let recentHabitTypes = Set(
            sessions
                .filter { ($0.date ?? .distantPast) >= windowStart }
                .compactMap { $0.therapyType }
        )
        let allTherapyTypes = candidateTypes.filter { recentHabitTypes.contains($0.rawValue) }

        // Compute data collection progress for all habits
        computeDataCollectionProgress(for: allTherapyTypes)

        print("🔍 InsightsViewModel: Starting to fetch impacts for \(allTherapyTypes.count) therapy types (filtered from \(candidateTypes.count) candidates)")
        print("🔍 InsightsViewModel: Excluded stale habits: \(candidateTypes.filter { !recentHabitTypes.contains($0.rawValue) }.map { $0.rawValue })")

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

            // Fetch Pain impact (if we have pain data)
            if self.viewContext != nil {
                group.enter()
                self.fetchPainImpact(for: therapyType) { impact in
                    if let impact = impact {
                        allImpacts.append(impact)
                    }
                    group.leave()
                }

                // Fetch Water intake impact
                group.enter()
                self.fetchWaterImpact(for: therapyType) { impact in
                    if let impact = impact {
                        allImpacts.append(impact)
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            print("🔍 InsightsViewModel: Fetching complete. Found \(allImpacts.count) impacts and \(trends.count) trends")

            // Sort by impact score
            allImpacts.sort { $0.impactScore > $1.impactScore }

            self.healthTrends = trends
            self.sleepImpacts = allImpacts.filter { $0.metricName == "Sleep Duration" }
            self.hrvImpacts = allImpacts.filter { $0.metricName == "HRV" }
            self.rhrImpacts = allImpacts.filter { $0.metricName == "RHR" }
            self.painImpacts = allImpacts.filter { $0.metricName == "Pain Level" }
            self.waterImpacts = allImpacts.filter { $0.metricName == "Hydration" }

            // Group impacts by habit type for the My Habits tab
            var byType: [TherapyType: [HabitImpact]] = [:]
            for impact in allImpacts {
                byType[impact.habitType, default: []].append(impact)
            }
            self.habitImpactsByType = byType

            // Use Gemini to validate and rank top correlations
            let candidateImpacts = Array(allImpacts.prefix(10))
            if InsightsSynthesizer.shared.isConfigured && !candidateImpacts.isEmpty {
                Task {
                    let validIndices = await InsightsSynthesizer.shared.validateCorrelations(candidateImpacts)
                    let validated = validIndices.prefix(5).compactMap { idx -> HabitImpact? in
                        guard idx < candidateImpacts.count else { return nil }
                        return candidateImpacts[idx]
                    }
                    await MainActor.run {
                        self.topHabitImpacts = validated.isEmpty ? Array(candidateImpacts.prefix(5)) : validated
                        self.isLoading = false
                        print("🔍 InsightsViewModel: Gemini validated \(validated.count) correlations")
                    }
                }
            } else {
                self.topHabitImpacts = Array(candidateImpacts.prefix(5))
                self.isLoading = false
            }
        }
    }

    /// Returns (therapyDates, nonTherapyDates) both within the analysis window.
    /// Both are sets of startOfDay dates, using the SAME window for fair comparison.
    private func datesInWindow(for therapyType: TherapyType) -> (therapy: [Date], nonTherapy: [Date]) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let windowStart = calendar.date(byAdding: .day, value: -self.analysisWindowDays, to: today) ?? today

        // All dates in the window
        let allWindowDates = (0..<self.analysisWindowDays).compactMap {
            calendar.date(byAdding: .day, value: -$0, to: today)
        }

        // Therapy dates within window (deduplicated to unique days)
        let therapyDaySet = Set(
            sessions
                .filter { $0.therapyType == therapyType.rawValue && ($0.date ?? .distantPast) >= windowStart }
                .compactMap { session -> Date? in
                    guard let d = session.date else { return nil }
                    return calendar.startOfDay(for: d)
                }
        )

        let therapyDates = Array(therapyDaySet).sorted()
        let nonTherapyDates = allWindowDates.filter { !therapyDaySet.contains($0) }

        return (therapyDates, nonTherapyDates)
    }

    private func computeDataCollectionProgress(for therapyTypes: [TherapyType]) {
        var progress: [TherapyType: DataCollectionProgress] = [:]
        let minRequired = 5

        for therapyType in therapyTypes {
            let (therapyDates, nonTherapyDates) = datesInWindow(for: therapyType)

            progress[therapyType] = DataCollectionProgress(
                habitType: therapyType,
                therapyDayCount: therapyDates.count,
                nonTherapyDayCount: nonTherapyDates.count,
                minimumRequired: minRequired
            )
        }

        self.dataCollectionProgress = progress
    }

    private func fetchHealthTrends(completion: @escaping ([HealthTrend]) -> Void) {
        let group = DispatchGroup()
        let trendsQueue = DispatchQueue(label: "com.cryozest.trends", attributes: .concurrent)
        var trends: [HealthTrend] = []

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

        // Pain Trend (from Core Data)
        if let context = viewContext {
            group.enter()
            DispatchQueue.main.async {
                let recentAvg = self.getPainAverage(days: 7, context: context)
                let last14Avg = self.getPainAverage(days: 14, context: context)

                defer { group.leave() }

                guard let recent = recentAvg, let last14 = last14Avg else {
                    print("⚠️ InsightsViewModel: No Pain data available")
                    return
                }

                // Approximate previous 7 days pain
                let previous = last14 * 2 - recent
                guard previous >= 0 else {
                    print("⚠️ InsightsViewModel: Invalid previous Pain calculation")
                    return
                }

                let change = previous > 0 ? ((recent - previous) / previous) * 100 : 0
                let trend = HealthTrend(
                    title: "Pain Level",
                    metric: "Pain",
                    currentValue: recent,
                    previousValue: previous,
                    changePercentage: change,
                    isPositive: recent < previous, // Lower pain is better
                    icon: "bolt.heart.fill",
                    color: abs(change) > 10 ? (recent < previous ? .green : .red) : .orange,
                    description: abs(change) > 10
                        ? (recent < previous ? "Pain levels improving" : "Pain levels increased")
                        : "Pain levels stable"
                )
                trendsQueue.async(flags: .barrier) {
                    trends.append(trend)
                }
                print("✅ InsightsViewModel: Added Pain trend")
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
        let (therapyDates, nonTherapyDates) = datesInWindow(for: therapyType)

        let totalDays = therapyDates.count + nonTherapyDates.count
        let frequency = totalDays > 0 ? Double(therapyDates.count) / Double(totalDays) : 0
        guard therapyDates.count >= 5 && nonTherapyDates.count >= 5 && frequency <= 0.85 else {
            completion(nil)
            return
        }

        let group = DispatchGroup()
        var baselineValues: [Double] = []
        var habitValues: [Double] = []
        var allMetricData: [(date: Date, value: Double)] = []

        for date in nonTherapyDates {
            group.enter()
            healthKitManager.fetchSleepDurationForDay(date: date) { duration in
                if let duration = duration {
                    let hours = duration / 3600
                    baselineValues.append(hours)
                    allMetricData.append((date: date, value: hours))
                }
                group.leave()
            }
        }

        for date in therapyDates {
            group.enter()
            healthKitManager.fetchSleepDurationForDay(date: date) { duration in
                if let duration = duration {
                    let hours = duration / 3600
                    habitValues.append(hours)
                    allMetricData.append((date: date, value: hours))
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            let cleanBaseline = self.statsUtility.removeOutliers(baselineValues)
            let cleanHabit = self.statsUtility.removeOutliers(habitValues)

            guard !cleanBaseline.isEmpty && !cleanHabit.isEmpty else {
                completion(nil)
                return
            }

            let baselineValue = self.statsUtility.mean(cleanBaseline)
            let habitValue = self.statsUtility.mean(cleanHabit)

            guard baselineValue > 0 else {
                completion(nil)
                return
            }

            let x = therapyDates.map { _ in 1.0 } + nonTherapyDates.map { _ in 0.0 }
            let y = habitValues + baselineValues
            let correlation = self.statsUtility.pearsonCorrelation(x, y)

            let laggedResults = self.statsUtility.laggedCorrelations(
                habitDates: therapyDates,
                metricData: allMetricData,
                maxLag: 1
            )
            let optimalLag = self.statsUtility.optimalLag(from: laggedResults)

            let change = self.statsUtility.percentageChange(baseline: baselineValue, new: habitValue)
            let impact = HabitImpact(
                habitType: therapyType,
                metricName: "Sleep Duration",
                baselineValue: baselineValue,
                habitValue: habitValue,
                percentageChange: change,
                isPositive: habitValue > baselineValue,
                sampleSize: therapyDates.count,
                correlation: correlation,
                optimalLag: optimalLag,
                lastSessionDate: therapyDates.max()
            )
            completion(impact)
        }
    }

    private func fetchHRVImpact(for therapyType: TherapyType, completion: @escaping (HabitImpact?) -> Void) {
        let (therapyDates, nonTherapyDates) = datesInWindow(for: therapyType)
        let isExercise = Self.exerciseTypes.contains(therapyType)
        let calendar = Calendar.current

        let totalDays = therapyDates.count + nonTherapyDates.count
        let frequency = totalDays > 0 ? Double(therapyDates.count) / Double(totalDays) : 0
        guard therapyDates.count >= 5 && nonTherapyDates.count >= 5 && frequency <= 0.85 else {
            completion(nil)
            return
        }

        // For exercise types, measure NEXT-DAY HRV (recovery effect).
        // For non-exercise (meditation, supplements, etc.), measure same-day HRV.
        let therapyMeasureDates: [Date] = isExercise
            ? therapyDates.compactMap { calendar.date(byAdding: .day, value: 1, to: $0) }
            : therapyDates

        let group = DispatchGroup()
        var baselineValues: [Double] = []
        var habitValues: [Double] = []
        var allMetricData: [(date: Date, value: Double)] = []

        for date in nonTherapyDates {
            group.enter()
            healthKitManager.fetchAvgHRVForDay(date: date) { hrv in
                if let hrv = hrv {
                    baselineValues.append(hrv)
                    allMetricData.append((date: date, value: hrv))
                }
                group.leave()
            }
        }

        for date in therapyMeasureDates {
            group.enter()
            healthKitManager.fetchAvgHRVForDay(date: date) { hrv in
                if let hrv = hrv {
                    habitValues.append(hrv)
                    allMetricData.append((date: date, value: hrv))
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            let cleanBaseline = self.statsUtility.removeOutliers(baselineValues)
            let cleanHabit = self.statsUtility.removeOutliers(habitValues)

            guard !cleanBaseline.isEmpty && !cleanHabit.isEmpty else {
                completion(nil)
                return
            }

            let baselineValue = self.statsUtility.mean(cleanBaseline)
            let habitValue = self.statsUtility.mean(cleanHabit)

            guard baselineValue > 0 else {
                completion(nil)
                return
            }

            let x = therapyDates.map { _ in 1.0 } + nonTherapyDates.map { _ in 0.0 }
            let y = habitValues + baselineValues
            let correlation = self.statsUtility.pearsonCorrelation(x, y)

            let laggedResults = self.statsUtility.laggedCorrelations(
                habitDates: therapyDates,
                metricData: allMetricData,
                maxLag: 2
            )
            let optimalLag = self.statsUtility.optimalLag(from: laggedResults)

            let change = self.statsUtility.percentageChange(baseline: baselineValue, new: habitValue)
            // For exercise, always show "Next day" lag since we measured next-day HRV
            let lagNote: LaggedCorrelation?
            if isExercise, let corr = correlation {
                lagNote = LaggedCorrelation(lagDays: 1, result: corr)
            } else {
                lagNote = optimalLag
            }
            let impact = HabitImpact(
                habitType: therapyType,
                metricName: "HRV",
                baselineValue: baselineValue,
                habitValue: habitValue,
                percentageChange: change,
                isPositive: habitValue > baselineValue,
                sampleSize: therapyDates.count,
                correlation: correlation,
                optimalLag: lagNote,
                lastSessionDate: therapyDates.max()
            )
            completion(impact)
        }
    }

    private func fetchRHRImpact(for therapyType: TherapyType, completion: @escaping (HabitImpact?) -> Void) {
        let (therapyDates, nonTherapyDates) = datesInWindow(for: therapyType)

        let totalDays = therapyDates.count + nonTherapyDates.count
        let frequency = totalDays > 0 ? Double(therapyDates.count) / Double(totalDays) : 0
        guard therapyDates.count >= 5 && nonTherapyDates.count >= 5 && frequency <= 0.85 else {
            completion(nil)
            return
        }

        let group = DispatchGroup()
        var baselineValues: [Double] = []
        var habitValues: [Double] = []
        var allMetricData: [(date: Date, value: Double)] = []

        // Fetch RHR for each non-therapy day
        for date in nonTherapyDates {
            group.enter()
            healthKitManager.fetchMostRecentRestingHeartRate(for: date) { rhr, _ in
                if let rhr = rhr {
                    baselineValues.append(Double(rhr))
                    allMetricData.append((date: date, value: Double(rhr)))
                }
                group.leave()
            }
        }

        // Fetch RHR for each therapy day
        for date in therapyDates {
            group.enter()
            healthKitManager.fetchMostRecentRestingHeartRate(for: date) { rhr, _ in
                if let rhr = rhr {
                    habitValues.append(Double(rhr))
                    allMetricData.append((date: date, value: Double(rhr)))
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            // Remove outliers
            let cleanBaseline = self.statsUtility.removeOutliers(baselineValues)
            let cleanHabit = self.statsUtility.removeOutliers(habitValues)

            guard !cleanBaseline.isEmpty && !cleanHabit.isEmpty else {
                completion(nil)
                return
            }

            let baselineValue = self.statsUtility.mean(cleanBaseline)
            let habitValue = self.statsUtility.mean(cleanHabit)

            guard baselineValue > 0 else {
                completion(nil)
                return
            }

            // Calculate correlation (note: for RHR, negative correlation is good)
            let x = therapyDates.map { _ in 1.0 } + nonTherapyDates.map { _ in 0.0 }
            let y = habitValues + baselineValues
            let correlation = self.statsUtility.pearsonCorrelation(x, y)

            // Calculate lagged correlations
            let laggedResults = self.statsUtility.laggedCorrelations(
                habitDates: therapyDates,
                metricData: allMetricData,
                maxLag: 2
            )
            let optimalLag = self.statsUtility.optimalLag(from: laggedResults)

            let change = self.statsUtility.percentageChange(baseline: baselineValue, new: habitValue)
            let impact = HabitImpact(
                habitType: therapyType,
                metricName: "RHR",
                baselineValue: baselineValue,
                habitValue: habitValue,
                percentageChange: change,
                isPositive: habitValue < baselineValue, // Lower is better for RHR
                sampleSize: therapyDates.count,
                correlation: correlation,
                optimalLag: optimalLag,
                lastSessionDate: therapyDates.max()
            )
            completion(impact)
        }
    }

    private func fetchPainImpact(for therapyType: TherapyType, completion: @escaping (HabitImpact?) -> Void) {
        guard let context = viewContext else {
            completion(nil)
            return
        }

        let (therapyDates, nonTherapyDates) = datesInWindow(for: therapyType)

        let totalDays = therapyDates.count + nonTherapyDates.count
        let frequency = totalDays > 0 ? Double(therapyDates.count) / Double(totalDays) : 0
        guard therapyDates.count >= 5 && nonTherapyDates.count >= 5 && frequency <= 0.85 else {
            completion(nil)
            return
        }

        var baselineValues: [Double] = []
        var habitValues: [Double] = []
        var allMetricData: [(date: Date, value: Double)] = []

        // Fetch pain ratings for non-therapy days (using daily averages)
        for date in nonTherapyDates {
            if let avgPain = PainRating.getAverageRatingForDay(date: date, context: context) {
                baselineValues.append(avgPain)
                allMetricData.append((date: date, value: avgPain))
            }
        }

        // Fetch pain ratings for therapy days (using daily averages)
        for date in therapyDates {
            if let avgPain = PainRating.getAverageRatingForDay(date: date, context: context) {
                habitValues.append(avgPain)
                allMetricData.append((date: date, value: avgPain))
            }
        }

        // Remove outliers
        let cleanBaseline = statsUtility.removeOutliers(baselineValues)
        let cleanHabit = statsUtility.removeOutliers(habitValues)

        guard !cleanBaseline.isEmpty && !cleanHabit.isEmpty else {
            completion(nil)
            return
        }

        let baselineValue = statsUtility.mean(cleanBaseline)
        let habitValue = statsUtility.mean(cleanHabit)

        // Calculate correlation (note: for pain, negative correlation is good - less pain is better)
        let x = therapyDates.prefix(habitValues.count).map { _ in 1.0 } + nonTherapyDates.prefix(baselineValues.count).map { _ in 0.0 }
        let y = habitValues + baselineValues

        guard x.count == y.count && !y.isEmpty else {
            completion(nil)
            return
        }

        let correlation = statsUtility.pearsonCorrelation(x, y)

        // Calculate lagged correlations (does habit today affect pain tomorrow?)
        let laggedResults = statsUtility.laggedCorrelations(
            habitDates: therapyDates,
            metricData: allMetricData,
            maxLag: 2  // Check up to 2 days later
        )
        let optimalLag = statsUtility.optimalLag(from: laggedResults)

        let change = statsUtility.percentageChange(baseline: baselineValue, new: habitValue)
        let impact = HabitImpact(
            habitType: therapyType,
            metricName: "Pain Level",
            baselineValue: baselineValue,
            habitValue: habitValue,
            percentageChange: change,
            isPositive: habitValue < baselineValue, // Lower pain is better
            sampleSize: habitValues.count,
            correlation: correlation,
            optimalLag: optimalLag,
            lastSessionDate: therapyDates.max()
        )
        completion(impact)
    }

    private func fetchWaterImpact(for therapyType: TherapyType, completion: @escaping (HabitImpact?) -> Void) {
        guard let context = viewContext else {
            completion(nil)
            return
        }

        let (therapyDates, nonTherapyDates) = datesInWindow(for: therapyType)

        let totalDays = therapyDates.count + nonTherapyDates.count
        let frequency = totalDays > 0 ? Double(therapyDates.count) / Double(totalDays) : 0
        guard therapyDates.count >= 5 && nonTherapyDates.count >= 5 && frequency <= 0.85 else {
            completion(nil)
            return
        }

        var baselineValues: [Double] = []
        var habitValues: [Double] = []
        var allMetricData: [(date: Date, value: Double)] = []

        // Fetch water intake for non-therapy days
        for date in nonTherapyDates {
            let cups = WaterIntake.getTotalCups(for: date, context: context)
            if cups > 0 {
                let value = Double(cups)
                baselineValues.append(value)
                allMetricData.append((date: date, value: value))
            }
        }

        // Fetch water intake for therapy days
        for date in therapyDates {
            let cups = WaterIntake.getTotalCups(for: date, context: context)
            if cups > 0 {
                let value = Double(cups)
                habitValues.append(value)
                allMetricData.append((date: date, value: value))
            }
        }

        // Remove outliers
        let cleanBaseline = statsUtility.removeOutliers(baselineValues)
        let cleanHabit = statsUtility.removeOutliers(habitValues)

        guard !cleanBaseline.isEmpty && !cleanHabit.isEmpty else {
            completion(nil)
            return
        }

        let baselineValue = statsUtility.mean(cleanBaseline)
        let habitValue = statsUtility.mean(cleanHabit)

        // Calculate correlation (for water, positive correlation is good - more hydration is better)
        let x = therapyDates.prefix(habitValues.count).map { _ in 1.0 } + nonTherapyDates.prefix(baselineValues.count).map { _ in 0.0 }
        let y = habitValues + baselineValues

        guard x.count == y.count && !y.isEmpty else {
            completion(nil)
            return
        }

        let correlation = statsUtility.pearsonCorrelation(x, y)

        // Calculate lagged correlations
        let laggedResults = statsUtility.laggedCorrelations(
            habitDates: therapyDates,
            metricData: allMetricData,
            maxLag: 2
        )
        let optimalLag = statsUtility.optimalLag(from: laggedResults)

        let change = statsUtility.percentageChange(baseline: baselineValue, new: habitValue)
        let impact = HabitImpact(
            habitType: therapyType,
            metricName: "Hydration",
            baselineValue: baselineValue,
            habitValue: habitValue,
            percentageChange: change,
            isPositive: habitValue > baselineValue, // Higher hydration is better
            sampleSize: habitValues.count,
            correlation: correlation,
            optimalLag: optimalLag,
            lastSessionDate: therapyDates.max()
        )
        completion(impact)
    }

    // MARK: - Multi-Habit Regression Analysis

    /// Analyze multiple habits' combined effect on a metric
    func fetchMultiHabitAttribution(for metricName: String, completion: @escaping (HabitAttribution?) -> Void) {
        let allTherapyTypes = Array(Set(selectedTherapyTypes + getRecordedWorkoutTypes()))

        guard allTherapyTypes.count >= 2 else {
            completion(nil)
            return
        }

        // Get all dates in the analysis period
        let allDates = DateUtils.shared.getBaselineDatesForTimeFrame(timeFrame: .allTime, fromStartDate: Date())

        let group = DispatchGroup()
        var metricData: [Date: Double] = [:]

        // Fetch metric data for all dates
        for date in allDates {
            group.enter()

            switch metricName {
            case "HRV":
                healthKitManager.fetchAvgHRVForDay(date: date) { value in
                    if let value = value { metricData[date] = value }
                    group.leave()
                }
            case "Sleep Duration":
                healthKitManager.fetchSleepDurationForDay(date: date) { value in
                    if let value = value { metricData[date] = value / 3600 }
                    group.leave()
                }
            case "RHR":
                healthKitManager.fetchMostRecentRestingHeartRate(for: date) { rhr, _ in
                    if let rhr = rhr { metricData[date] = Double(rhr) }
                    group.leave()
                }
            case "Pain Level":
                if let context = self.viewContext,
                   let avgPain = PainRating.getAverageRatingForDay(date: date, context: context) {
                    metricData[date] = avgPain
                }
                group.leave()
            default:
                group.leave()
            }
        }

        group.notify(queue: .main) {
            // Build habit presence matrix
            var habitPresence: [[Double]] = []
            var outcomes: [Double] = []
            let habitNames = allTherapyTypes.map { $0.rawValue }

            for date in allDates {
                guard let metric = metricData[date] else { continue }

                var dayHabits: [Double] = []
                for therapyType in allTherapyTypes {
                    let didHabit = self.sessions.contains { session in
                        guard let sessionDate = session.date,
                              session.therapyType == therapyType.rawValue else { return false }
                        return Calendar.current.isDate(sessionDate, inSameDayAs: date)
                    }
                    dayHabits.append(didHabit ? 1.0 : 0.0)
                }

                habitPresence.append(dayHabits)
                outcomes.append(metric)
            }

            // Run regression
            guard let result = self.statsUtility.multipleRegression(
                habitPresence: habitPresence,
                outcome: outcomes,
                habitNames: habitNames
            ) else {
                completion(nil)
                return
            }

            // Build contributions list
            var contributions: [(habitType: TherapyType, contribution: Double, isSignificant: Bool)] = []
            for therapyType in allTherapyTypes {
                if let coef = result.coefficients[therapyType.rawValue] {
                    contributions.append((
                        habitType: therapyType,
                        contribution: coef,
                        isSignificant: result.isSignificant
                    ))
                }
            }

            // Sort by absolute contribution
            contributions.sort { abs($0.contribution) > abs($1.contribution) }

            let attribution = HabitAttribution(
                metricName: metricName,
                habitContributions: contributions,
                rSquared: result.rSquared,
                isModelSignificant: result.isSignificant
            )
            completion(attribution)
        }
    }

    // MARK: - Pain Data Helpers

    /// Calculate average pain level over the past N days
    private func getPainAverage(days: Int, context: NSManagedObjectContext) -> Double? {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else {
            return nil
        }

        let ratings = PainRating.getRatings(from: startDate, to: endDate, context: context)

        guard !ratings.isEmpty else {
            return nil
        }

        let total = ratings.reduce(0.0) { $0 + Double($1.rating) }
        return total / Double(ratings.count)
    }
}
