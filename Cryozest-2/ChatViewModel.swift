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
        stressModel: StressScoreModel? = nil,
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
            stressModel: stressModel,
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
        stressModel: StressScoreModel? = nil,
        sessions: [TherapySessionEntity],
        selectedTherapyTypes: [TherapyType],
        viewContext: NSManagedObjectContext
    ) {
        healthContext = HealthContextBuilder.buildContext(
            recoveryModel: recoveryModel,
            insightsViewModel: insightsViewModel,
            sleepModel: sleepModel,
            exertionModel: exertionModel,
            stressModel: stressModel,
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

    /// Whether the AI is currently streaming its response (text still arriving)
    @Published var isStreaming = false

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
                let history = Array(messages.dropLast()) // exclude the just-added user msg

                // Create a placeholder AI message for streaming
                var streamingMessage = ChatMessage(role: .model, content: "")
                messages.append(streamingMessage)
                let streamingIndex = messages.count - 1

                isLoading = false
                isStreaming = true

                // Accumulate streamed text and update the displayed message progressively
                var accumulatedText = ""
                var displayedCharCount = 0
                // Timer for typewriter effect — reveals characters gradually
                var typewriterTask: Task<Void, Never>?

                let fullResponse = try await chatService.streamMessage(
                    userMessage: trimmed,
                    conversationHistory: history,
                    healthContext: healthContext,
                    onChunk: { [weak self] chunk in
                        Task { @MainActor [weak self] in
                            guard let self = self else { return }
                            accumulatedText += chunk

                            // Cancel previous typewriter and start a new one with updated text
                            typewriterTask?.cancel()
                            typewriterTask = Task { @MainActor [weak self] in
                                guard let self = self else { return }
                                while displayedCharCount < accumulatedText.count {
                                    guard !Task.isCancelled else { return }
                                    // Reveal characters in small bursts for smooth typewriter feel
                                    let charsToReveal = min(3, accumulatedText.count - displayedCharCount)
                                    displayedCharCount += charsToReveal
                                    let displayText = String(accumulatedText.prefix(displayedCharCount))

                                    // Update the streaming message with text blocks only during streaming
                                    self.messages[streamingIndex].content = displayText
                                    self.messages[streamingIndex].blocks = [CoachResponseBlock(content: .text(displayText))]

                                    try? await Task.sleep(nanoseconds: 12_000_000) // ~12ms per burst
                                }
                            }
                        }
                    }
                )

                // Wait for typewriter to finish revealing all text
                typewriterTask?.cancel()
                // Small delay to let any pending UI updates land
                try? await Task.sleep(nanoseconds: 50_000_000)

                // Now parse the full response into proper blocks + widgets
                let (cleaned, followUps) = CoachResponseParser.extractFollowUps(fullResponse)
                let blocks = CoachResponseParser.parse(cleaned, snapshot: healthSnapshot)
                let plainText = CoachResponseParser.extractPlainText(from: blocks)

                messages[streamingIndex].content = plainText
                messages[streamingIndex].blocks = blocks
                messages[streamingIndex].followUpSuggestions = followUps

                isStreaming = false
            } catch {
                // Remove the placeholder message if streaming failed
                if isStreaming, !messages.isEmpty, messages.last?.role == .model, messages.last?.content.isEmpty == true {
                    messages.removeLast()
                }
                errorMessage = (error as? ChatServiceError)?.errorDescription ?? error.localizedDescription
                isLoading = false
                isStreaming = false
            }
        }
    }

    func sendInitialQuestionIfNeeded(_ question: String?) {
        if DemoDataManager.shared.isDemoMode && messages.isEmpty {
            DemoDataManager.shared.populateChatViewModel(self)
            return
        }
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
            snap.recoveryScore = r.recoveryScores.last.flatMap { $0 }
            snap.recoveryScores = r.recoveryScores.compactMap { $0 }
            snap.weeklyAverage = r.weeklyAverage

            if let hrv = r.avgHrvDuringSleep, HealthDataValidator.isValidHRV(hrv) {
                snap.hrv = hrv
            }
            snap.hrvBaseline = r.avgHrvDuringSleep60Days

            if let rhr = r.mostRecentRestingHeartRate, HealthDataValidator.isValidRestingHR(rhr) {
                snap.rhr = rhr
            }
            snap.rhrBaseline = r.avgRestingHeartRate60Days

            snap.spo2 = r.mostRecentSPO2
            snap.vo2Max = r.mostRecentVO2Max
            snap.respiratoryRate = r.mostRecentRespiratoryRate

            if let steps = r.mostRecentSteps { snap.steps = Int(steps) }
            if let cal = r.mostRecentActiveCalories { snap.activeCalories = Int(cal) }
        }

        if let s = sleepModel {
            snap.sleepDuration = HealthDataValidator.isValidDisplayString(s.totalTimeAsleep) ? s.totalTimeAsleep : nil
            snap.sleepScore = s.sleepScore > 0 ? Int(s.sleepScore) : nil
            snap.deepSleep = HealthDataValidator.isValidDisplayString(s.totalDeepSleep) ? s.totalDeepSleep : nil
            snap.remSleep = HealthDataValidator.isValidDisplayString(s.totalRemSleep) ? s.totalRemSleep : nil
            snap.coreSleep = HealthDataValidator.isValidDisplayString(s.totalCoreSleep) ? s.totalCoreSleep : nil
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
