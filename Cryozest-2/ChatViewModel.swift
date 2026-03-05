import SwiftUI
import CoreData

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [ChatMessage] = []
    @Published var isLoading = false
    @Published var inputText = ""
    @Published var errorMessage: String?

    private let chatService = GeminiChatService()
    private var healthContext: String = ""
    private var healthSnapshot = HealthSnapshot()

    var isConfigured: Bool { chatService.isConfigured }

    func configure(
        insightsViewModel: InsightsViewModel?,
        recoveryModel: RecoveryGraphModel?,
        sleepModel: DailySleepViewModel?,
        exertionModel: ExertionModel?,
        sessions: [TherapySessionEntity],
        selectedTherapyTypes: [TherapyType],
        viewContext: NSManagedObjectContext
    ) {
        // Only build context once per session (or on clear)
        guard healthContext.isEmpty else { return }
        refreshHealthContext(
            insightsViewModel: insightsViewModel,
            recoveryModel: recoveryModel,
            sleepModel: sleepModel,
            exertionModel: exertionModel,
            sessions: sessions,
            selectedTherapyTypes: selectedTherapyTypes,
            viewContext: viewContext
        )
    }

    func refreshHealthContext(
        insightsViewModel: InsightsViewModel?,
        recoveryModel: RecoveryGraphModel?,
        sleepModel: DailySleepViewModel?,
        exertionModel: ExertionModel?,
        sessions: [TherapySessionEntity],
        selectedTherapyTypes: [TherapyType],
        viewContext: NSManagedObjectContext
    ) {
        healthContext = HealthContextBuilder.buildContext(
            recoveryModel: recoveryModel,
            insightsViewModel: insightsViewModel,
            sleepModel: sleepModel,
            exertionModel: exertionModel,
            sessions: sessions,
            selectedTherapyTypes: selectedTherapyTypes,
            viewContext: viewContext
        )
        healthSnapshot = Self.buildSnapshot(
            recoveryModel: recoveryModel,
            sleepModel: sleepModel,
            exertionModel: exertionModel,
            insightsViewModel: insightsViewModel,
            sessions: sessions,
            selectedTherapyTypes: selectedTherapyTypes,
            viewContext: viewContext
        )
    }

    func sendMessage(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        errorMessage = nil
        let userMessage = ChatMessage(role: .user, content: trimmed)
        messages.append(userMessage)
        inputText = ""
        isLoading = true

        Task {
            do {
                let response = try await chatService.sendMessage(
                    userMessage: trimmed,
                    conversationHistory: messages.dropLast().map { $0 }, // exclude the just-added user msg
                    healthContext: healthContext
                )
                let blocks = CoachResponseParser.parse(response, snapshot: healthSnapshot)
                // Store plain text for conversation history so Gemini doesn't see widget markup
                let plainText = CoachResponseParser.extractPlainText(from: blocks)
                let aiMessage = ChatMessage(role: .model, content: plainText, blocks: blocks)
                messages.append(aiMessage)
            } catch {
                errorMessage = (error as? ChatServiceError)?.errorDescription ?? error.localizedDescription
            }
            isLoading = false
        }
    }

    func sendInitialQuestionIfNeeded(_ question: String?) {
        guard let question = question,
              !question.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              messages.isEmpty else { return }
        sendMessage(question)
    }

    func clearConversation(
        insightsViewModel: InsightsViewModel?,
        recoveryModel: RecoveryGraphModel?,
        sleepModel: DailySleepViewModel?,
        exertionModel: ExertionModel?,
        sessions: [TherapySessionEntity],
        selectedTherapyTypes: [TherapyType],
        viewContext: NSManagedObjectContext
    ) {
        messages.removeAll()
        errorMessage = nil
        healthContext = "" // force rebuild
        refreshHealthContext(
            insightsViewModel: insightsViewModel,
            recoveryModel: recoveryModel,
            sleepModel: sleepModel,
            exertionModel: exertionModel,
            sessions: sessions,
            selectedTherapyTypes: selectedTherapyTypes,
            viewContext: viewContext
        )
    }

    // MARK: - Build HealthSnapshot from models

    private static func buildSnapshot(
        recoveryModel: RecoveryGraphModel?,
        sleepModel: DailySleepViewModel?,
        exertionModel: ExertionModel?,
        insightsViewModel: InsightsViewModel?,
        sessions: [TherapySessionEntity],
        selectedTherapyTypes: [TherapyType],
        viewContext: NSManagedObjectContext
    ) -> HealthSnapshot {
        var snap = HealthSnapshot()

        if let r = recoveryModel {
            snap.recoveryScore = r.recoveryScores.last
            snap.recoveryScores = r.recoveryScores
            snap.weeklyAverage = r.weeklyAverage

            snap.hrv = r.avgHrvDuringSleep
            snap.hrvBaseline = r.avgHrvDuringSleep60Days

            snap.rhr = r.mostRecentRestingHeartRate
            snap.rhrBaseline = r.avgRestingHeartRate60Days

            snap.spo2 = r.mostRecentSPO2
            snap.vo2Max = r.mostRecentVO2Max
            snap.respiratoryRate = r.mostRecentRespiratoryRate

            if let steps = r.mostRecentSteps { snap.steps = Int(steps) }
            if let cal = r.mostRecentActiveCalories { snap.activeCalories = Int(cal) }
        }

        if let s = sleepModel {
            snap.sleepDuration = s.totalTimeAsleep != "--" ? s.totalTimeAsleep : nil
            snap.sleepScore = s.sleepScore > 0 ? Int(s.sleepScore) : nil
            snap.deepSleep = s.totalDeepSleep != "--" ? s.totalDeepSleep : nil
            snap.remSleep = s.totalRemSleep != "--" ? s.totalRemSleep : nil
            snap.coreSleep = s.totalCoreSleep != "--" ? s.totalCoreSleep : nil
            snap.restorativePercent = s.restorativeSleepPercentage > 0 ? Int(s.restorativeSleepPercentage) : nil
            if s.averageHeartRateDuringSleep > 0 { snap.sleepHeartRate = Int(s.averageHeartRateDuringSleep) }
            if s.averageWakingHeartRate > 0 { snap.wakingHeartRate = Int(s.averageWakingHeartRate) }
        }

        if let e = exertionModel, e.exertionScore > 0 {
            snap.exertionScore = Int(e.exertionScore)
        }

        // Exertion zones
        if let e = exertionModel {
            if e.recoveryMinutes > 0 || e.conditioningMinutes > 0 || e.overloadMinutes > 0 {
                snap.recoveryMinutes = Int(e.recoveryMinutes)
                snap.conditioningMinutes = Int(e.conditioningMinutes)
                snap.overloadMinutes = Int(e.overloadMinutes)
            }
        }

        if let vm = insightsViewModel {
            snap.healthTrends = vm.healthTrends.prefix(6).map { trend in
                (metric: trend.metric, change: Int(trend.changePercentage), isPositive: trend.isPositive)
            }
        }

        // Recent sessions (last 7 days)
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let recentSessions = sessions
            .filter { ($0.date ?? .distantPast) >= weekAgo }
            .sorted { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) }

        snap.recentSessions = recentSessions.map { s in
            let typeName = TherapyType(rawValue: s.therapyType ?? "")?.displayName(viewContext) ?? (s.therapyType ?? "Unknown")
            return SessionSnapshot(
                type: typeName,
                date: s.date ?? Date(),
                durationMinutes: Int(s.duration / 60),
                avgHeartRate: s.averageHeartRate > 0 ? Int(s.averageHeartRate) : nil,
                isAppleWatch: s.isAppleWatch
            )
        }

        // Weekly volume by type
        let grouped = Dictionary(grouping: recentSessions) { $0.therapyType ?? "" }
        snap.weeklyVolume = grouped.compactMap { (typeRaw, typeSessions) in
            let typeName = TherapyType(rawValue: typeRaw)?.displayName(viewContext) ?? typeRaw
            let totalMins = typeSessions.reduce(0) { $0 + Int($1.duration / 60) }
            let hrSessions = typeSessions.filter { $0.averageHeartRate > 0 }
            let avgHR = hrSessions.isEmpty ? nil : Int(hrSessions.reduce(0.0) { $0 + $1.averageHeartRate } / Double(hrSessions.count))
            return WorkoutVolume(
                type: typeName,
                sessionCount: typeSessions.count,
                totalMinutes: totalMins,
                avgHeartRate: avgHR
            )
        }.sorted { $0.sessionCount > $1.sessionCount }

        // Wellness data
        let today = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: today) ?? today

        // Mood
        if let moodAvg = WellnessRating.getAverageRatingForDay(date: today, context: viewContext) {
            snap.mood = Int(moodAvg.rounded())
        }
        let moodDailyAvgs = WellnessRating.getDailyAverages(from: sevenDaysAgo, to: today, context: viewContext)
        snap.moodHistory = moodDailyAvgs.map { Int($0.average.rounded()) }

        // Pain
        if let painAvg = PainRating.getAverageRatingForDay(date: today, context: viewContext) {
            snap.pain = Int(painAvg.rounded())
        }
        let todayPain = PainRating.getAllRatingsForDay(date: today, context: viewContext)
        if let location = todayPain.first?.bodyLocation, !location.isEmpty {
            snap.painLocation = location
        }
        let painDailyAvgs = PainRating.getDailyAverages(from: sevenDaysAgo, to: today, context: viewContext)
        snap.painHistory = painDailyAvgs.map { Int($0.average.rounded()) }

        // Water
        let cups = WaterIntake.getTotalCups(for: today, context: viewContext)
        if cups > 0 {
            snap.waterCups = cups
        }
        snap.waterGoal = WaterIntake.defaultDailyGoal

        // Tracked habit names for dynamic sport matching
        snap.trackedHabitNames = selectedTherapyTypes.map { $0.displayName(viewContext) }

        return snap
    }
}
