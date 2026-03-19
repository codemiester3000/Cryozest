import Foundation
import CoreData

struct HealthContextBuilder {

    static func buildContext(
        recoveryModel: RecoveryGraphModel?,
        insightsViewModel: InsightsViewModel?,
        sleepModel: DailySleepViewModel?,
        exertionModel: ExertionModel?,
        stressModel: StressScoreModel? = nil,
        sessions: [TherapySessionEntity],
        selectedTherapyTypes: [TherapyType],
        viewContext: NSManagedObjectContext
    ) -> String {
        var sections: [String] = []

        // Persona + strict data rules
        sections.append("""
        You are an AI health coach inside a personal health tracking app called Cryozest. \
        The user wears an Apple Watch and tracks daily habits.

        CRITICAL RULES:
        1. ONLY reference data explicitly provided below. NEVER invent or fabricate numbers.
        2. If a habit shows "0x this week" it means the user has NOT done that activity this week. Do not say they did it.
        3. If asked about a metric that is not listed at all, say you don't have that data.
        4. Be specific with the exact numbers from the data below.
        5. Be direct and conversational — like a knowledgeable friend, not a doctor.
        6. Never diagnose medical conditions. For serious symptoms, suggest a healthcare provider.
        7. Keep responses concise (3-5 sentences unless they ask for detail).

        ANALYZING CORRELATIONS:
        When the user asks how an activity impacts a metric (e.g. "how does swimming affect my mood"), \
        you SHOULD analyze the data below to find patterns. You have session dates/times AND metric history — \
        use them together. Compare metrics on days with that activity vs days without. \
        If you have both activity data and metric data, provide your best analysis with specific numbers. \
        If data is limited (fewer than 3 sessions), say so and suggest they keep tracking. \
        If the STATISTICAL CORRELATIONS section has a relevant entry, cite it. \
        Never say "I don't have that data" when you actually have sessions AND metrics — analyze what you have.

        WIDGET DISPLAY:
        When your response would benefit from a visual widget, include a tag on its own line: \
        [SHOW:widget_type]. Only include widgets directly relevant to the user's question. \
        Do NOT include widgets for topics you merely mention in passing. \
        Available widgets: sessions, sessions:type (e.g. sessions:running), mood, pain, water, \
        zones, recovery, hrv, rhr, heart_rate, sleep, steps, calories, spo2, vo2, respiratory, \
        exertion, trends, overview. \
        Example: If asked "how is running affecting my HRV", use [SHOW:sessions:running] and [SHOW:hrv]. \
        If asked about mood trends, use [SHOW:mood]. Do NOT show a recovery chart if the question is about sleep.

        FOLLOW-UP SUGGESTIONS:
        At the end of every response, suggest 2-3 follow-up questions the user might want to ask, \
        specific to the data you just discussed. Format each as [FOLLOWUP:question text] on its own line. \
        Make them specific and actionable based on the conversation, not generic.

        Respond in natural, conversational language. Use specific numbers from the data. When comparing metrics, mention both current and baseline values. End with actionable advice when relevant.
        """)

        // Time context
        let now = Date()
        let hour = Calendar.current.component(.hour, from: now)
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEEE"
        let dayOfWeek = dayFormatter.string(from: now)
        let timeLabel: String
        switch hour {
        case 5..<12: timeLabel = "morning"
        case 12..<17: timeLabel = "afternoon"
        case 17..<21: timeLabel = "evening"
        default: timeLabel = "night"
        }
        sections.append("""
        TIME CONTEXT:
        Current time: \(hour):00, \(dayOfWeek), \(timeLabel).
        Adjust your tone and recommendations to the time of day. For example, \
        evening advice might focus on wind-down and sleep prep, while morning advice \
        might focus on readiness and the day ahead.
        """)

        // Today's health metrics
        if let recovery = recoveryModel {
            var metricsLines: [String] = []

            if let sleep = recovery.previousNightSleepDuration, !sleep.isEmpty {
                metricsLines.append("Sleep last night: \(sleep) hrs")
            }
            if let hrv = recovery.avgHrvDuringSleep {
                var line = "HRV (during sleep): \(hrv) ms"
                if let hrv60 = recovery.avgHrvDuringSleep60Days {
                    line += " (60-day avg: \(hrv60) ms"
                    if let pct = recovery.hrvSleepPercentage {
                        let sign = pct >= 0 ? "+" : ""
                        line += ", \(sign)\(pct)% vs baseline"
                    }
                    line += ")"
                }
                metricsLines.append(line)
            }
            if let rhr = recovery.dailyAvgRestingHeartRate ?? recovery.mostRecentRestingHeartRate {
                var line = "Resting heart rate: \(rhr) bpm (daily avg)"
                if let rhr60 = recovery.avgRestingHeartRate60Days {
                    line += " (60-day avg: \(rhr60) bpm"
                    if let pct = recovery.restingHeartRatePercentage {
                        let sign = pct >= 0 ? "+" : ""
                        line += ", \(sign)\(pct)% vs baseline"
                    }
                    line += ")"
                }
                metricsLines.append(line)
            }
            if let spo2 = recovery.mostRecentSPO2 {
                metricsLines.append("SpO2: \(String(format: "%.1f", spo2))%")
            }
            if let vo2 = recovery.mostRecentVO2Max {
                metricsLines.append("VO2 Max: \(String(format: "%.1f", vo2)) mL/kg/min")
            }
            if let respRate = recovery.mostRecentRespiratoryRate {
                metricsLines.append("Respiratory rate: \(String(format: "%.1f", respRate)) breaths/min")
            }
            if let steps = recovery.mostRecentSteps {
                metricsLines.append("Steps today: \(Int(steps))")
            }
            if let activeCal = recovery.mostRecentActiveCalories {
                var line = "Active calories: \(Int(activeCal)) kcal"
                if let restCal = recovery.mostRecentRestingCalories {
                    line += " (resting: \(Int(restCal)) kcal, total: \(Int(activeCal + restCal)) kcal)"
                }
                metricsLines.append(line)
            }

            // Recovery scores — daily array for charts
            if !recovery.recoveryScores.isEmpty {
                // recoveryScores is [Int?] — unwrap both the array .last (Int??) and the inner optional
                if let latestOpt = recovery.recoveryScores.last, let latest = latestOpt {
                    metricsLines.append("Recovery score today: \(latest)/100 (weekly avg: \(recovery.weeklyAverage))")
                } else if recovery.weeklyAverage > 0 {
                    metricsLines.append("Recovery score today: not available (weekly avg: \(recovery.weeklyAverage))")
                }

                let dayLabels = lastNDayLabels(7)
                let scoreStrings = zip(dayLabels, recovery.recoveryScores).map { label, score -> String in
                    if let score = score {
                        return "\(label): \(score)%"
                    } else {
                        return "\(label): no data"
                    }
                }
                metricsLines.append("Recovery scores (last 7 days): \(scoreStrings.joined(separator: ", "))")
            }

            if !metricsLines.isEmpty {
                sections.append("TODAY'S HEALTH METRICS:\n" + metricsLines.joined(separator: "\n"))
            }
        }

        // Stress & Recovery scores (new 5-metric Z-score system)
        if let stress = stressModel {
            var stressLines: [String] = []

            if let stressScore = stress.todayStressScore {
                stressLines.append("Stress score today: \(stressScore)/100 (\(StressScoreModel.stressStatusLabel(stressScore)))")
            }
            if let recoveryScore = stress.todayRecoveryScore {
                stressLines.append("Recovery score (Z-score formula): \(recoveryScore)/100")
            }

            if let z = stress.zScores {
                var drivers: [String] = []
                if let zHRV = z.hrv { drivers.append("HRV z=\(String(format: "%.1f", zHRV))") }
                if let zRHR = z.rhr { drivers.append("RHR z=\(String(format: "%.1f", zRHR))") }
                if let zResp = z.respRate { drivers.append("Resp z=\(String(format: "%.1f", zResp))") }
                if let zTemp = z.wristTemp { drivers.append("Temp z=\(String(format: "%.1f", zTemp))") }
                if !drivers.isEmpty {
                    stressLines.append("Z-score drivers: " + drivers.joined(separator: ", "))
                }
            }

            if let deficit = stress.sleepDeficit, deficit > 0 {
                stressLines.append("Sleep deficit: \(Int((deficit * 100).rounded()))%")
            }

            if stress.baselineDayCount < 14 {
                stressLines.append("Note: baseline still building (day \(stress.baselineDayCount)/14, using blended population priors)")
            }

            if let avgStress = stress.weeklyAvgStress, let avgRecovery = stress.weeklyAvgRecovery {
                stressLines.append("Weekly avg stress: \(avgStress), weekly avg recovery: \(avgRecovery)")
            }

            if !stressLines.isEmpty {
                sections.append("STRESS & RECOVERY ANALYSIS:\n" + stressLines.joined(separator: "\n"))
            }
        }

        // Sleep details
        if let sleep = sleepModel {
            var sleepLines: [String] = []
            if sleep.totalTimeAsleep != "--" {
                sleepLines.append("Time asleep: \(sleep.totalTimeAsleep)")
            }
            if sleep.totalTimeInBed != "--" {
                sleepLines.append("Time in bed: \(sleep.totalTimeInBed)")
            }
            if sleep.totalTimeAwake != "--" {
                sleepLines.append("Time awake (during sleep period): \(sleep.totalTimeAwake)")
            }
            if sleep.totalDeepSleep != "--" {
                sleepLines.append("Deep sleep: \(sleep.totalDeepSleep)")
            }
            if sleep.totalRemSleep != "--" {
                sleepLines.append("REM sleep: \(sleep.totalRemSleep)")
            }
            if sleep.totalCoreSleep != "--" {
                sleepLines.append("Core sleep: \(sleep.totalCoreSleep)")
            }
            if sleep.sleepScore > 0 {
                sleepLines.append("Sleep score: \(Int(sleep.sleepScore))/100")
            }
            if sleep.restorativeSleepPercentage > 0 {
                sleepLines.append("Restorative sleep: \(Int(sleep.restorativeSleepPercentage))%")
            }
            if sleep.averageHeartRateDuringSleep > 0 {
                sleepLines.append("Avg heart rate during sleep: \(Int(sleep.averageHeartRateDuringSleep)) bpm")
            }
            if sleep.averageWakingHeartRate > 0 {
                sleepLines.append("Avg waking heart rate: \(Int(sleep.averageWakingHeartRate)) bpm")
                if sleep.averageHeartRateDuringSleep > 0 {
                    let diff = Int(sleep.averageWakingHeartRate - sleep.averageHeartRateDuringSleep)
                    sleepLines.append("Heart rate recovery (sleep→wake difference): \(diff) bpm")
                }
            }
            if !sleepLines.isEmpty {
                sections.append("SLEEP BREAKDOWN:\n" + sleepLines.joined(separator: "\n"))
            }
        }

        // Exertion
        if let exertion = exertionModel, exertion.exertionScore > 0 {
            var exertionLines: [String] = []
            exertionLines.append("Exertion score: \(String(format: "%.0f", exertion.exertionScore))")
            if exertion.recoveryMinutes > 0 {
                exertionLines.append("Recovery zone: \(Int(exertion.recoveryMinutes)) min")
            }
            if exertion.conditioningMinutes > 0 {
                exertionLines.append("Conditioning zone: \(Int(exertion.conditioningMinutes)) min")
            }
            if exertion.overloadMinutes > 0 {
                exertionLines.append("Overload zone: \(Int(exertion.overloadMinutes)) min")
            }
            // Include zone boundaries if available
            if !exertion.heartRateZoneRanges.isEmpty {
                let zoneDescriptions = exertion.heartRateZoneRanges.enumerated().map { i, range in
                    "Zone \(i): \(Int(range.lowerBound))-\(Int(range.upperBound)) bpm"
                }
                exertionLines.append("HR zone ranges: " + zoneDescriptions.joined(separator: ", "))
            }
            sections.append("EXERTION TODAY:\n" + exertionLines.joined(separator: "\n"))
        }

        // Recent session details (last 7 days, with per-session data)
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentSessions = sessions.filter { ($0.date ?? .distantPast) >= weekAgo }

        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MMM d"

        if !recentSessions.isEmpty {
            let sorted = recentSessions
                .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }
                .prefix(5)

            var sessionLines: [String] = []
            for s in sorted {
                let typeName = TherapyType(rawValue: s.therapyType ?? "")?.displayName(viewContext) ?? (s.therapyType ?? "Unknown")
                let dateStr = dateFormatter.string(from: s.date ?? Date())
                let mins = Int(s.duration / 60)
                var line = "- \(typeName): \(dateStr), \(mins) min"
                if s.averageHeartRate > 0 {
                    line += ", avg HR \(Int(s.averageHeartRate)) bpm"
                }
                line += s.isAppleWatch ? " (Apple Watch)" : " (manual log)"
                sessionLines.append(line)
            }
            sections.append("RECENT SESSIONS (last 7 days):\n" + sessionLines.joined(separator: "\n"))

            // Per-type weekly volume
            var volumeLines: [String] = []
            let grouped = Dictionary(grouping: recentSessions) { $0.therapyType ?? "" }
            for (typeRaw, typeSessions) in grouped.sorted(by: { $0.value.count > $1.value.count }) {
                let typeName = TherapyType(rawValue: typeRaw)?.displayName(viewContext) ?? typeRaw
                let totalMins = typeSessions.reduce(0) { $0 + Int($1.duration / 60) }
                let hrs = totalMins / 60
                let remainMins = totalMins % 60
                let durationStr = hrs > 0 ? "\(hrs)h \(remainMins)min" : "\(remainMins)min"
                let hrSessions = typeSessions.filter { $0.averageHeartRate > 0 }
                var line = "- \(typeName): \(typeSessions.count) sessions, \(durationStr) total"
                if !hrSessions.isEmpty {
                    let avgHR = Int(hrSessions.reduce(0.0) { $0 + $1.averageHeartRate } / Double(hrSessions.count))
                    line += ", avg HR \(avgHR) bpm"
                }
                volumeLines.append(line)
            }
            if !volumeLines.isEmpty {
                sections.append("WEEKLY TRAINING VOLUME:\n" + volumeLines.joined(separator: "\n"))
            }
        }

        // Recent habits — explicit about active AND inactive

        if !selectedTherapyTypes.isEmpty {
            var activeLines: [String] = []
            var inactiveNames: [String] = []

            for type in selectedTherapyTypes {
                let count = recentSessions.filter { $0.therapyType == type.rawValue }.count
                let name = type.displayName(viewContext)
                if count > 0 {
                    let streak = calculateStreak(for: type, sessions: sessions)
                    var line = "- \(name): \(count)x this week"
                    if streak > 1 { line += " (\(streak)-day streak)" }
                    activeLines.append(line)
                } else {
                    inactiveNames.append(name)
                }
            }

            var habitSection = "HABITS THIS WEEK:\n"
            if activeLines.isEmpty {
                habitSection += "No habits logged this week."
            } else {
                habitSection += activeLines.joined(separator: "\n")
            }
            if !inactiveNames.isEmpty {
                habitSection += "\nNOT done this week (0 sessions): \(inactiveNames.joined(separator: ", "))"
            }
            sections.append(habitSection)
        }

        // Last 30 days session summary for longer-term context
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        let monthlySessions = sessions.filter { ($0.date ?? .distantPast) >= thirtyDaysAgo }
        if !monthlySessions.isEmpty {
            var monthLines: [String] = []
            for type in selectedTherapyTypes {
                let typeSessions = monthlySessions.filter { $0.therapyType == type.rawValue }
                let count = typeSessions.count
                if count > 0 {
                    let name = type.displayName(viewContext)
                    monthLines.append("- \(name): \(count)x in last 30 days")

                    // Include dates for correlation analysis
                    let dates = typeSessions
                        .compactMap { $0.date }
                        .sorted()
                        .map { dateFormatter.string(from: $0) }
                    if !dates.isEmpty {
                        monthLines.append("  Dates: \(dates.joined(separator: ", "))")
                    }
                }
            }
            if !monthLines.isEmpty {
                sections.append("LAST 30 DAYS ACTIVITY (with dates for correlation analysis):\n" + monthLines.joined(separator: "\n"))
            }
        }

        // Statistical correlations
        if let vm = insightsViewModel, !vm.topHabitImpacts.isEmpty {
            let impactLines = vm.topHabitImpacts.prefix(8).map { impact in
                let direction = impact.isPositive ? "improved" : "worsened"
                let confidence = impact.confidenceLevel.rawValue
                return "- \(impact.habitType.rawValue) → \(impact.metricName) \(direction) by \(abs(Int(impact.percentageChange)))% (confidence: \(confidence), n=\(impact.sampleSize))"
            }
            sections.append("STATISTICAL CORRELATIONS (from user's data):\n" + impactLines.joined(separator: "\n"))
        }

        // Health trends
        if let vm = insightsViewModel, !vm.healthTrends.isEmpty {
            let trendLines = vm.healthTrends.prefix(6).map { trend in
                let dir = trend.changePercentage >= 0 ? "up" : "down"
                return "- \(trend.metric): \(dir) \(abs(Int(trend.changePercentage)))% vs last week"
            }
            sections.append("WEEK-OVER-WEEK TRENDS:\n" + trendLines.joined(separator: "\n"))
        }

        // Wellness data
        let today = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today
        let thirtyDaysAgoWellness = calendar.date(byAdding: .day, value: -30, to: today) ?? today
        var wellnessLines: [String] = []

        let wellnessDateFormatter = DateFormatter()
        wellnessDateFormatter.dateFormat = "MMM d"

        // Mood
        if let moodAvg = WellnessRating.getAverageRatingForDay(date: today, context: viewContext) {
            let moodInt = Int(moodAvg.rounded())
            let label = WellnessRating.moodLabel(for: moodInt)
            var line = "Mood today: \(label) (\(moodInt)/5)"
            let dailyAvgs = WellnessRating.getDailyAverages(from: sevenDaysAgo, to: today, context: viewContext)
            if dailyAvgs.count >= 2 {
                let avg7d = dailyAvgs.reduce(0.0) { $0 + $1.average } / Double(dailyAvgs.count)
                line += " — 7-day avg: \(String(format: "%.1f", avg7d))/5"
            }
            wellnessLines.append(line)
        }

        // Mood history (30 days) for correlation analysis
        let moodDailyAvgs30 = WellnessRating.getDailyAverages(from: thirtyDaysAgoWellness, to: today, context: viewContext)
        if moodDailyAvgs30.count >= 3 {
            let moodHistoryEntries = moodDailyAvgs30.map { entry in
                "\(wellnessDateFormatter.string(from: entry.date)): \(String(format: "%.1f", entry.average))"
            }
            wellnessLines.append("Mood history (last 30 days, daily avg): " + moodHistoryEntries.joined(separator: ", "))
        }

        // Pain
        if let painAvg = PainRating.getAverageRatingForDay(date: today, context: viewContext) {
            let painInt = Int(painAvg.rounded())
            let label = PainRating.painLabel(for: painInt)
            var line = "Pain today: \(label) (\(painInt)/5)"
            let todayPainRatings = PainRating.getAllRatingsForDay(date: today, context: viewContext)
            if let latestLocation = todayPainRatings.first?.bodyLocation, !latestLocation.isEmpty {
                line += ", location: \(latestLocation)"
            }
            let painAvgs = PainRating.getDailyAverages(from: sevenDaysAgo, to: today, context: viewContext)
            if painAvgs.count >= 2 {
                let avg7d = painAvgs.reduce(0.0) { $0 + $1.average } / Double(painAvgs.count)
                line += " — 7-day avg: \(String(format: "%.1f", avg7d))/5"
            }
            wellnessLines.append(line)
        }

        // Pain history (30 days) for correlation analysis
        let painDailyAvgs30 = PainRating.getDailyAverages(from: thirtyDaysAgoWellness, to: today, context: viewContext)
        if painDailyAvgs30.count >= 3 {
            let painHistoryEntries = painDailyAvgs30.map { entry in
                "\(wellnessDateFormatter.string(from: entry.date)): \(String(format: "%.1f", entry.average))"
            }
            wellnessLines.append("Pain history (last 30 days, daily avg): " + painHistoryEntries.joined(separator: ", "))
        }

        // Water
        let waterCups = WaterIntake.getTotalCups(for: today, context: viewContext)
        if waterCups > 0 {
            let goal = WaterIntake.defaultDailyGoal
            let pct = Int(Double(waterCups) / Double(goal) * 100)
            wellnessLines.append("Water: \(waterCups)/\(goal) cups (\(pct)%)")
        }

        // Medications
        let activeMeds = Medication.getActiveMedications(context: viewContext)
        if !activeMeds.isEmpty {
            var medParts: [String] = []
            for med in activeMeds {
                let taken = MedicationIntake.wasTaken(medicationId: med.id ?? UUID(), on: today, context: viewContext)
                let adherence = MedicationIntake.getAdherencePercentage(medicationId: med.id ?? UUID(), days: 30, context: viewContext)
                let name = med.name ?? "Unknown"
                medParts.append("\(name) (\(taken ? "taken today" : "not taken")) — 30-day adherence: \(Int(adherence))%")
            }
            wellnessLines.append("Medications: " + medParts.joined(separator: ", "))
        }

        if !wellnessLines.isEmpty {
            var section = "WELLNESS TODAY:\n" + wellnessLines.joined(separator: "\n")
            section += "\n\nScale reference — Mood: 1=Rough, 2=Low, 3=Okay, 4=Good, 5=Great | Pain: 0=None, 1=Minimal, 2=Mild, 3=Moderate, 4=Severe, 5=Extreme"
            sections.append(section)
        }

        return sections.joined(separator: "\n\n")
    }

    // MARK: - Helpers

    private static func lastNDayLabels(_ n: Int) -> [String] {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        let calendar = Calendar.current
        return (0..<n).reversed().compactMap { offset in
            guard let date = calendar.date(byAdding: .day, value: -offset, to: Date()) else { return nil }
            return formatter.string(from: date)
        }
    }

    private static func calculateStreak(for type: TherapyType, sessions: [TherapySessionEntity]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var checkDate = today

        while true {
            let hasSession = sessions.contains { session in
                guard let date = session.date else { return false }
                return calendar.isDate(date, inSameDayAs: checkDate) && session.therapyType == type.rawValue
            }
            if hasSession {
                streak += 1
                guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prevDay
            } else {
                break
            }
        }

        return streak
    }
}
