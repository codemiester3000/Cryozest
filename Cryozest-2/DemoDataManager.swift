import SwiftUI
import CoreData

class DemoDataManager: ObservableObject {
    static let shared = DemoDataManager()

    @Published var isDemoMode: Bool {
        didSet { UserDefaults.standard.set(isDemoMode, forKey: "isDemoMode") }
    }

    private init() {
        self.isDemoMode = UserDefaults.standard.bool(forKey: "isDemoMode")
    }

    // MARK: - Recovery Model

    func populateRecoveryModel(_ model: RecoveryGraphModel) {
        DispatchQueue.main.async {
            model.recoveryScores = [62, 71, 58, 75, 82, 68, 78]
            // weeklyAverage is set automatically by didSet

            model.avgHrvDuringSleep = 48
            model.avgHrvDuringSleep60Days = 42
            // hrvSleepPercentage computed by didSet

            model.mostRecentRestingHeartRate = 56
            model.dailyAvgRestingHeartRate = 57 // Daily avg (used by Z-score engine)
            model.avgRestingHeartRate60Days = 61
            // restingHeartRatePercentage computed by didSet

            model.previousNightSleepDuration = "7.3"
            // sleepScorePercentage computed by didSet

            model.lastKnownHRV = 52
            model.mostRecentSPO2 = 97.5
            model.mostRecentRespiratoryRate = 14.2
            model.mostRecentActiveCalories = 485
            model.mostRecentRestingCalories = 1680
            model.mostRecentSteps = 9247
            model.mostRecentVO2Max = 42.5
            model.averageDailyRHR = 59
        }
    }

    // MARK: - Exertion Model

    func populateExertionModel(_ model: ExertionModel) {
        DispatchQueue.main.async {
            model.exertionScore = 64.0
            model.zoneTimes = [28, 18, 14, 6, 2]
            model.recoveryMinutes = 28
            model.conditioningMinutes = 32
            model.overloadMinutes = 8
            model.avgRestingHeartRate = 58
            model.heartRateZoneRanges = [
                (lowerBound: 96, upperBound: 115),
                (lowerBound: 115, upperBound: 134),
                (lowerBound: 134, upperBound: 153),
                (lowerBound: 153, upperBound: 172),
                (lowerBound: 172, upperBound: 191)
            ]
        }
    }

    // MARK: - Sleep Model

    func populateSleepModel(_ model: DailySleepViewModel) {
        DispatchQueue.main.async {
            model.totalTimeInBed = "7h 52m"
            model.totalTimeAsleep = "7h 18m"
            model.totalDeepSleep = "1h 24m"
            model.totalCoreSleep = "3h 38m"
            model.totalRemSleep = "2h 16m"
            model.totalTimeAwake = "34m"
            model.sleepScore = 82.0
            model.restorativeSleepPercentage = 49.0
            model.averageWakingHeartRate = 74.0
            model.averageHeartRateDuringSleep = 54.0
        }
    }

    // MARK: - Stress Score Model

    func populateStressModel(_ model: StressScoreModel) {
        DispatchQueue.main.async {
            model.todayStressScore = 42
            model.todayRecoveryScore = 72
            // nil entries represent days the watch wasn't worn to sleep
            model.last7DaysStress = [38, nil, 47, 61, nil, 50, 42]
            model.last7DaysRecovery = [75, nil, 66, 52, nil, 63, 72]
            model.weeklyAvgStress = 48
            model.weeklyAvgRecovery = 65
            model.zScores = MetricZScores(hrv: 0.6, rhr: -0.3, respRate: 0.1, wristTemp: nil)
            model.sleepDeficit = 0.08
            model.hasTemperatureData = false
            // Weights with resp present but no temp: base 35/25/15/15 = 0.90, scale = 1/0.90
            model.computedWeights = ComputedWeights(hrv: 0.389, rhr: 0.278, resp: 0.167, temp: 0.0, sleep: 0.167)
            model.baselineDayCount = 10
            model.dataQuality = .noTemp
            model.insufficientDataReason = nil
        }
    }

    // MARK: - Insights View Model

    func populateInsightsViewModel(_ vm: InsightsViewModel) {
        vm.isLoading = false

        vm.healthTrends = [
            HealthTrend(title: "Sleep Duration", metric: "Sleep", currentValue: 7.3, previousValue: 6.8, changePercentage: 7.4, isPositive: true, icon: "bed.double.fill", color: .indigo, description: "Up from last week"),
            HealthTrend(title: "HRV", metric: "HRV", currentValue: 48, previousValue: 44, changePercentage: 9.1, isPositive: true, icon: "waveform.path.ecg", color: .purple, description: "Improving trend"),
            HealthTrend(title: "Resting Heart Rate", metric: "RHR", currentValue: 56, previousValue: 59, changePercentage: -5.1, isPositive: true, icon: "heart.fill", color: .red, description: "Lower is better"),
            HealthTrend(title: "Steps", metric: "Steps", currentValue: 9247, previousValue: 8100, changePercentage: 14.2, isPositive: true, icon: "figure.walk", color: .green, description: "More active this week"),
        ]

        let runningCorrelation = CorrelationResult(coefficient: 0.62, pValue: 0.008, sampleSize: 18, confidenceInterval: (lower: 0.45, upper: 0.79))
        let runningImpact = HabitImpact(
            habitType: .running,
            metricName: "HRV",
            baselineValue: 42,
            habitValue: 48,
            percentageChange: 14.3,
            isPositive: true,
            sampleSize: 18,
            correlation: runningCorrelation,
            optimalLag: LaggedCorrelation(lagDays: 1, result: runningCorrelation),
            lastSessionDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())
        )

        let meditationImpact = HabitImpact(
            habitType: .meditation,
            metricName: "Sleep Duration",
            baselineValue: 6.6,
            habitValue: 7.4,
            percentageChange: 12.1,
            isPositive: true,
            sampleSize: 22,
            correlation: CorrelationResult(coefficient: 0.55, pValue: 0.012, sampleSize: 22, confidenceInterval: (lower: 0.35, upper: 0.75)),
            lastSessionDate: Date()
        )

        let weightTrainingImpact = HabitImpact(
            habitType: .weightTraining,
            metricName: "RHR",
            baselineValue: 62,
            habitValue: 56,
            percentageChange: -9.7,
            isPositive: true,
            sampleSize: 15,
            correlation: CorrelationResult(coefficient: -0.48, pValue: 0.03, sampleSize: 15, confidenceInterval: (lower: -0.68, upper: -0.28)),
            lastSessionDate: Calendar.current.date(byAdding: .day, value: -2, to: Date())
        )

        let cyclingImpact = HabitImpact(
            habitType: .cycling,
            metricName: "Sleep Duration",
            baselineValue: 6.8,
            habitValue: 7.2,
            percentageChange: 5.9,
            isPositive: true,
            sampleSize: 8,
            correlation: CorrelationResult(coefficient: 0.38, pValue: 0.09, sampleSize: 8, confidenceInterval: (lower: 0.10, upper: 0.66)),
            lastSessionDate: Calendar.current.date(byAdding: .day, value: -3, to: Date())
        )

        // Negative correlation for "Watch Out" section
        let lateNightScreenImpact = HabitImpact(
            habitType: .weightTraining,
            metricName: "Sleep Duration",
            baselineValue: 7.2,
            habitValue: 6.5,
            percentageChange: -9.7,
            isPositive: false,
            sampleSize: 12,
            correlation: CorrelationResult(coefficient: -0.42, pValue: 0.04, sampleSize: 12, confidenceInterval: (lower: -0.65, upper: -0.19)),
            lastSessionDate: Calendar.current.date(byAdding: .day, value: -1, to: Date())
        )

        // Additional positive: meditation also helps HRV
        let meditationHRVImpact = HabitImpact(
            habitType: .meditation,
            metricName: "HRV",
            baselineValue: 40,
            habitValue: 45,
            percentageChange: 12.5,
            isPositive: true,
            sampleSize: 20,
            correlation: CorrelationResult(coefficient: 0.50, pValue: 0.015, sampleSize: 20, confidenceInterval: (lower: 0.30, upper: 0.70)),
            lastSessionDate: Date()
        )

        vm.topHabitImpacts = [runningImpact, meditationImpact, meditationHRVImpact, weightTrainingImpact, cyclingImpact, lateNightScreenImpact]
        vm.sleepImpacts = [meditationImpact, cyclingImpact, lateNightScreenImpact]
        vm.hrvImpacts = [runningImpact, meditationHRVImpact]
        vm.rhrImpacts = [weightTrainingImpact]

        vm.habitImpactsByType = [
            .running: [runningImpact],
            .meditation: [meditationImpact, meditationHRVImpact],
            .weightTraining: [weightTrainingImpact, lateNightScreenImpact],
            .cycling: [cyclingImpact]
        ]
    }

    // MARK: - Chat Demo Conversation

    @MainActor
    func populateChatViewModel(_ vm: ChatViewModel) {
        let userMsg1 = ChatMessage(role: .user, content: "How's my recovery looking today?")

        let aiBlocks1: [CoachResponseBlock] = [
            CoachResponseBlock(content: .metric(
                MetricData(label: "Recovery", value: "78%", unit: "", trend: .up, change: "+10% vs yesterday")
            )),
            CoachResponseBlock(content: .text("Your recovery is looking solid today. Your HRV was 48ms during sleep, which is 14% above your 60-day average \u{2014} that's the main driver. Your resting heart rate also came in at 56 bpm, nicely below your baseline of 61.")),
            CoachResponseBlock(content: .tip(TipData(text: "Today is a great day for a harder workout. Your body is primed for it.", icon: "flame.fill")))
        ]
        let aiMsg1 = ChatMessage(role: .model, content: "Your recovery is looking solid today.", blocks: aiBlocks1)

        let userMsg2 = ChatMessage(role: .user, content: "What about my sleep last night?")

        let aiBlocks2: [CoachResponseBlock] = [
            CoachResponseBlock(content: .metricsRow([
                MetricData(label: "Sleep", value: "7.3", unit: "hrs", trend: .up, change: nil),
                MetricData(label: "Deep", value: "1h 24m", unit: "", trend: .up, change: nil),
                MetricData(label: "REM", value: "2h 16m", unit: "", trend: .stable, change: nil)
            ])),
            CoachResponseBlock(content: .text("You got 7.3 hours of sleep with a solid 49% restorative sleep (deep + REM). Your deep sleep of 1h 24m is particularly good \u{2014} that's when your body does most of its physical repair. Your heart rate dropped to 54 bpm during sleep, a healthy 27% dip from your waking rate.")),
        ]
        let aiMsg2 = ChatMessage(role: .model, content: "You got 7.3 hours of sleep with solid restorative sleep.", blocks: aiBlocks2)

        let userMsg3 = ChatMessage(role: .user, content: "How does running affect my health?")

        let aiBlocks3: [CoachResponseBlock] = [
            CoachResponseBlock(content: .text("Running is your strongest habit for recovery. Based on your data from the last 30 days:")),
            CoachResponseBlock(content: .metric(
                MetricData(label: "HRV Impact", value: "+14%", unit: "next day", trend: .up, change: "high confidence")
            )),
            CoachResponseBlock(content: .heartZones(HeartZoneData(recovery: 28, conditioning: 32, overload: 8))),
            CoachResponseBlock(content: .text("On days after you run, your HRV averages 48ms compared to 42ms on rest days. This is a statistically significant next-day effect (p = 0.008). Your zone distribution looks healthy too \u{2014} most of your time is in conditioning zones with a good recovery base."))
        ]
        let aiMsg3 = ChatMessage(role: .model, content: "Running is your strongest habit for recovery.", blocks: aiBlocks3)

        vm.messages = [userMsg1, aiMsg1, userMsg2, aiMsg2, userMsg3, aiMsg3]
    }

    // MARK: - CoreData Demo Records

    func populateCoreDataIfNeeded(context: NSManagedObjectContext) {
        // Check if we already have demo data
        let fetchRequest: NSFetchRequest<TherapySessionEntity> = TherapySessionEntity.fetchRequest()
        let count = (try? context.count(for: fetchRequest)) ?? 0
        if count > 10 { return } // Already has data

        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Therapy sessions over last 14 days
        let sessionData: [(type: String, daysAgo: Int, duration: Double)] = [
            ("Running", 0, 2520),         // 42 min today
            ("Meditation", 0, 900),        // 15 min today
            ("Weight Training", 1, 3600),  // 60 min yesterday
            ("Running", 1, 1800),          // 30 min yesterday
            ("Cycling", 2, 2700),          // 45 min
            ("Meditation", 2, 600),        // 10 min
            ("Weight Training", 3, 3300),  // 55 min
            ("Running", 3, 2400),          // 40 min
            ("Meditation", 4, 900),
            ("Cycling", 5, 3000),          // 50 min
            ("Running", 5, 2100),          // 35 min
            ("Weight Training", 6, 3600),
            ("Meditation", 6, 1200),       // 20 min
            ("Running", 7, 2700),
            ("Cycling", 8, 2400),
            ("Weight Training", 9, 3300),
            ("Running", 10, 1800),
            ("Meditation", 11, 900),
            ("Weight Training", 12, 3600),
            ("Running", 13, 2400),
        ]

        for entry in sessionData {
            let session = TherapySessionEntity(context: context)
            session.therapyType = entry.type
            session.date = calendar.date(byAdding: .day, value: -entry.daysAgo, to: today)
            session.duration = entry.duration
        }

        // Wellness ratings (last 3 days)
        for daysAgo in 0..<3 {
            if let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) {
                let ratings = daysAgo == 0 ? [4] : (daysAgo == 1 ? [4, 5] : [3, 4])
                for rating in ratings {
                    WellnessRating.addRating(rating: rating, for: date, context: context)
                }
            }
        }

        // Pain ratings
        if let today = calendar.date(byAdding: .day, value: 0, to: today) {
            PainRating.addRating(rating: 1, for: today, context: context)
        }

        // Water intake
        for _ in 0..<6 {
            WaterIntake.addOneCup(for: today, context: context)
        }

        // Selected therapies (if none exist)
        let therapyFetch: NSFetchRequest<SelectedTherapy> = SelectedTherapy.fetchRequest()
        let therapyCount = (try? context.count(for: therapyFetch)) ?? 0
        if therapyCount == 0 {
            for type in [TherapyType.running, .weightTraining, .cycling, .meditation] {
                let selected = SelectedTherapy(context: context)
                selected.therapyType = type.rawValue
            }
        }

        try? context.save()
    }
}
