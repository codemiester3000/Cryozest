import SwiftUI
import CoreData

struct DailyView: View {
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.managedObjectContext) private var viewContext
    @EnvironmentObject var appState: AppState

    @ObservedObject var recoveryModel: RecoveryGraphModel
    @ObservedObject var exertionModel: ExertionModel
    @ObservedObject var sleepModel: DailySleepViewModel
    @ObservedObject var stressModel: StressScoreModel

    var appleWorkoutsService: AppleWorkoutsService
    var insightsViewModel: InsightsViewModel?

    @FetchRequest(
        entity: TherapySessionEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TherapySessionEntity.date, ascending: false)]
    )
    private var sessions: FetchedResults<TherapySessionEntity>

    @FetchRequest(
        entity: SelectedTherapy.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \SelectedTherapy.therapyType, ascending: true)]
    )
    private var selectedTherapies: FetchedResults<SelectedTherapy>

    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var showOnboarding = false
    @State private var showSettings = false
    @State private var showHabitSelection = false

    // Quick-log state
    @State private var animatingHabit: TherapyType? = nil
    @State private var showCheckmark = false
    @State private var confirmingUndo: TherapyType? = nil

    // LLM insight
    @State private var llmInsight: String?
    @State private var llmInsightFailed = false

    // Coach sheet
    @State private var showCoachSheet = false
    @State private var coachQuestion: String? = nil

    // First-log celebration
    @State private var showFirstLogCelebration = false
    @State private var firstLogHabitType: TherapyType?

    // Quick-log pulse for new users
    @State private var pulseQuickLog = false

    init(
        recoveryModel: RecoveryGraphModel,
        exertionModel: ExertionModel,
        sleepModel: DailySleepViewModel,
        stressModel: StressScoreModel,
        context: NSManagedObjectContext,
        insightsViewModel: InsightsViewModel? = nil
    ) {
        self.recoveryModel = recoveryModel
        self.exertionModel = exertionModel
        self.sleepModel = sleepModel
        self.stressModel = stressModel
        self.appleWorkoutsService = AppleWorkoutsService(context: context)
        self.insightsViewModel = insightsViewModel
    }

    private var selectedTherapyTypes: [TherapyType] {
        if selectedTherapies.isEmpty {
            return [.running, .weightTraining, .cycling, .meditation]
        } else {
            return selectedTherapies.compactMap { TherapyType(rawValue: $0.therapyType ?? "") }
        }
    }

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.10, blue: 0.18)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Header
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 12)

                    // 1. Wellness Check-In
                    WellnessCheckInCard(selectedDate: $selectedDate)
                        .padding(.horizontal, 20)

                    // 2. Quick-Log Habit Grid
                    quickLogGrid
                        .padding(.horizontal, 20)

                    // 3. Today's Insight (AI-powered)
                    if let insight = llmInsight {
                        LLMInsightCard(text: insight)
                            .padding(.horizontal, 20)
                            .onTapGesture {
                                coachQuestion = "Tell me more about this: \(insight)"
                                showCoachSheet = true
                            }
                    } else if InsightsSynthesizer.shared.isConfigured && !llmInsightFailed {
                        LLMInsightCard(text: "Analyzing your data...")
                            .padding(.horizontal, 20)
                            .redacted(reason: .placeholder)
                    } else if let recentInsight = insightsViewModel?.recentInsight {
                        TodayInsightCard(
                            impact: recentInsight,
                            recentSessionCount: recentSessionCount(for: recentInsight.habitType),
                            streak: currentStreak(for: recentInsight.habitType)
                        )
                        .padding(.horizontal, 20)
                        .onTapGesture {
                            let habitName = recentInsight.habitType.displayName(viewContext)
                            let direction = recentInsight.isPositive ? "improves" : "worsens"
                            let pct = abs(Int(recentInsight.percentageChange))
                            coachQuestion = "Explain why \(habitName) \(direction) my \(recentInsight.metricName) by \(pct)%"
                            showCoachSheet = true
                        }
                    } else {
                        // Fallback — always show insight card with tip
                        DailyTipCard(sessions: Array(sessions))
                            .padding(.horizontal, 20)
                            .onTapGesture {
                                coachQuestion = "Give me a full health breakdown"
                                showCoachSheet = true
                            }
                    }

                    // 4. Health Snapshot
                    HealthSnapshotGrid(
                        recoveryModel: recoveryModel,
                        sleepModel: sleepModel,
                        rhrImpacts: insightsViewModel?.rhrImpacts ?? []
                    )
                    .padding(.horizontal, 20)

                    // 5. Recovery Score
                    RecoveryScoreCard(recoveryModel: recoveryModel)
                        .padding(.horizontal, 20)

                    // 5b. Stress Score
                    StressScoreCard(stressModel: stressModel)
                        .padding(.horizontal, 20)

                    // 6. More tracking
                    PainTrackingCard(selectedDate: $selectedDate)
                        .padding(.horizontal, 20)
                    MedicationsCard(selectedDate: $selectedDate)
                        .padding(.horizontal, 20)

                    // Bottom spacer for tab bar
                    Color.clear
                        .frame(height: 100)
                }
            }
            // First-log celebration overlay
            .overlay(
                Group {
                    if showFirstLogCelebration {
                        FirstLogCelebrationOverlay(habitType: firstLogHabitType)
                            .transition(.opacity)
                            .onAppear {
                                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                                    withAnimation(.easeOut(duration: 0.4)) {
                                        showFirstLogCelebration = false
                                    }
                                }
                            }
                    }
                }
            )
            .refreshable {
                // Force refresh — bypass cooldown
                stressModel.invalidateCache()
                recoveryModel.lastDataRefresh = nil
                recoveryModel.pullAllRecoveryData(forDate: selectedDate)
                exertionModel.fetchExertionScoreAndTimes(forDate: selectedDate)
                sleepModel.fetchSleepData(forDate: selectedDate)
                stressModel.computeScores(forDate: selectedDate)
            }
        }
        .fullScreenCover(isPresented: $showOnboarding) {
            OnboardingFlowView(onComplete: {
                OnboardingManager.shared.markDailyTabSeen()
                showOnboarding = false
                loadHealthData()
            })
            .environmentObject(appState)
        }
        .sheet(isPresented: $showHabitSelection) {
            TherapyTypeSelectionView()
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showCoachSheet) {
            CoachSheetView(
                insightsViewModel: insightsViewModel,
                initialQuestion: coachQuestion
            )
            .environment(\.managedObjectContext, viewContext)
        }
        .onAppear {
            // Pulse quick-log grid for new users
            if !OnboardingManager.shared.hasCompletedFirstSession {
                pulseQuickLog = true
            }

            if OnboardingManager.shared.shouldShowDailyEmptyState {
                showOnboarding = true
            } else {
                HealthKitManager.shared.areHealthMetricsAuthorized { isAuthorized in
                    if isAuthorized {
                        loadHealthData()
                        appleWorkoutsService.fetchAndSaveWorkouts()
                    }
                }
            }

            // Catch case where impacts are already loaded before .onChange registers
            if let count = insightsViewModel?.topHabitImpacts.count, count > 0, llmInsight == nil {
                fetchLLMInsight()
            }
        }
        .onChange(of: insightsViewModel?.topHabitImpacts.count) { count in
            // Trigger LLM insight once correlations finish loading
            if let count = count, count > 0, llmInsight == nil {
                fetchLLMInsight()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                let calendar = Calendar.current
                let now = Date()
                let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now
                if calendar.isDate(selectedDate, inSameDayAs: yesterday) {
                    selectedDate = calendar.startOfDay(for: now)
                }
                loadHealthData()
                scheduleStreakProtection()
            }
        }
    }

    // MARK: - Header

    private var isToday: Bool {
        Calendar.current.isDateInToday(selectedDate)
    }

    private var header: some View {
        HStack(alignment: .center) {
            // Back arrow
            Button(action: { navigateDay(by: -1) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 32, height: 32)
            }

            VStack(spacing: 2) {
                Text(isToday ? "Today" : dayLabel)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.white)

                Text(dateString)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .onTapGesture {
                // Tap date label to jump back to today
                let today = Calendar.current.startOfDay(for: Date())
                guard selectedDate != today else { return }
                selectedDate = today
                loadHealthData()
            }

            // Forward arrow (hidden if already on today)
            Button(action: { navigateDay(by: 1) }) {
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(isToday ? .clear : .white.opacity(0.5))
                    .frame(width: 32, height: 32)
            }
            .disabled(isToday)

            Spacer()

            Button(action: { showSettings = true }) {
                Image(systemName: "gearshape.fill")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(width: 40, height: 40)
            }
        }
    }

    private var dayLabel: String {
        let calendar = Calendar.current
        if calendar.isDateInYesterday(selectedDate) { return "Yesterday" }
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE"
        return formatter.string(from: selectedDate)
    }

    private var dateString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = isToday ? "EEEE, MMM d" : "MMM d, yyyy"
        return formatter.string(from: selectedDate)
    }

    private func navigateDay(by offset: Int) {
        let calendar = Calendar.current
        guard let newDate = calendar.date(byAdding: .day, value: offset, to: selectedDate) else { return }
        let today = calendar.startOfDay(for: Date())
        guard newDate <= today else { return }
        selectedDate = newDate
        loadHealthData()
    }

    // MARK: - Quick-Log Habit Grid

    private var completedCount: Int {
        selectedTherapyTypes.filter { isCompletedToday($0) }.count
    }

    private var completionFraction: Double {
        guard !selectedTherapyTypes.isEmpty else { return 0 }
        return Double(completedCount) / Double(selectedTherapyTypes.count)
    }

    private var quickLogGrid: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Header with progress ring
            HStack(spacing: 8) {
                // Mini completion ring
                if !selectedTherapyTypes.isEmpty {
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.08), lineWidth: 2.5)
                            .frame(width: 26, height: 26)
                        Circle()
                            .trim(from: 0, to: completionFraction)
                            .stroke(
                                completedCount == selectedTherapyTypes.count ? Color.green : Color.cyan,
                                style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                            )
                            .rotationEffect(.degrees(-90))
                            .frame(width: 26, height: 26)
                            .animation(.easeInOut(duration: 0.4), value: completionFraction)

                        Text("\(completedCount)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(completedCount == selectedTherapyTypes.count ? .green : .white)
                    }
                }

                VStack(alignment: .leading, spacing: 1) {
                    Text("Today's Habits")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white.opacity(0.9))

                    if !selectedTherapyTypes.isEmpty {
                        Text(completedCount == selectedTherapyTypes.count
                             ? "All done — great work!"
                             : "\(selectedTherapyTypes.count - completedCount) remaining")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(completedCount == selectedTherapyTypes.count ? .green.opacity(0.7) : .white.opacity(0.3))
                    }
                }

                Spacer()

                Button(action: { showHabitSelection = true }) {
                    Image(systemName: "plus")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(width: 24, height: 24)
                        .background(
                            Circle()
                                .fill(Color.white.opacity(0.1))
                        )
                }
            }

            if selectedTherapyTypes.isEmpty {
                Text("Tap + to add habits to track")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.vertical, 16)
            } else {
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: 6),
                    GridItem(.flexible(), spacing: 6),
                    GridItem(.flexible(), spacing: 6)
                ], spacing: 6) {
                    ForEach(selectedTherapyTypes, id: \.self) { habit in
                        QuickLogButton(
                            habitType: habit,
                            isCompleted: isCompletedToday(habit),
                            streak: currentStreak(for: habit),
                            showCheckmark: animatingHabit == habit && showCheckmark,
                            confirmingUndo: confirmingUndo == habit,
                            onTap: { toggleHabit(habit) }
                        )
                    }
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .overlay(
            Group {
                if pulseQuickLog {
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.cyan.opacity(0.4), lineWidth: 1.5)
                        .scaleEffect(pulseQuickLog ? 1.02 : 1.0)
                        .opacity(pulseQuickLog ? 0.6 : 0)
                        .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: pulseQuickLog)
                }
            }
        )
    }

    // MARK: - Helpers

    private func isCompletedToday(_ habit: TherapyType) -> Bool {
        let calendar = Calendar.current
        return sessions.contains { session in
            guard let date = session.date else { return false }
            return calendar.isDateInToday(date) && session.therapyType == habit.rawValue
        }
    }

    private func currentStreak(for habit: TherapyType) -> Int {
        let dates = sessions
            .filter { $0.therapyType == habit.rawValue }
            .compactMap { $0.date }
            .sorted(by: >)
        guard !dates.isEmpty else { return 0 }
        let calendar = Calendar.current
        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())
        let todayCount = dates.filter { calendar.isDateInToday($0) }.count
        if todayCount == 0 {
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }
        for date in dates {
            let sessionDay = calendar.startOfDay(for: date)
            if calendar.isDate(sessionDay, inSameDayAs: checkDate) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if sessionDay < checkDate {
                break
            }
        }
        return streak
    }

    private func toggleHabit(_ habit: TherapyType) {
        if isCompletedToday(habit) {
            // Already completed — first tap shows confirm state, second tap undoes
            if confirmingUndo == habit {
                undoSession(for: habit)
                confirmingUndo = nil
            } else {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                withAnimation(.easeInOut(duration: 0.2)) {
                    confirmingUndo = habit
                }
                // Auto-dismiss confirm state after 3 seconds
                DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                    withAnimation(.easeOut(duration: 0.2)) {
                        if confirmingUndo == habit {
                            confirmingUndo = nil
                        }
                    }
                }
            }
        } else {
            confirmingUndo = nil
            logSession(for: habit)
        }
    }

    private func logSession(for habitType: TherapyType) {
        let newSession = TherapySessionEntity(context: viewContext)
        newSession.date = Date()
        newSession.therapyType = habitType.rawValue

        do {
            try viewContext.save()

            // First-log celebration
            if !OnboardingManager.shared.hasCompletedFirstSession {
                OnboardingManager.shared.markFirstSessionCompleted()
                firstLogHabitType = habitType
                pulseQuickLog = false
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) {
                    showFirstLogCelebration = true
                }
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            }

            triggerAnimation(for: habitType)
        } catch {
            print("Error saving session: \(error)")
        }
    }

    private func undoSession(for habitType: TherapyType) {
        // Find the most recent quick-log session for this habit today
        // (only remove manual logs with 0 duration — don't remove Apple Watch workouts)
        let calendar = Calendar.current
        let todaySession = sessions.first { session in
            guard let date = session.date else { return false }
            return calendar.isDateInToday(date)
                && session.therapyType == habitType.rawValue
                && session.duration == 0
        }

        // If no zero-duration session, fall back to removing the most recent today session
        let sessionToRemove = todaySession ?? sessions.first { session in
            guard let date = session.date else { return false }
            return calendar.isDateInToday(date) && session.therapyType == habitType.rawValue
        }

        guard let session = sessionToRemove else { return }

        viewContext.delete(session)
        do {
            try viewContext.save()
            UINotificationFeedbackGenerator().notificationOccurred(.warning)
        } catch {
            print("Error deleting session: \(error)")
        }
    }

    private func triggerAnimation(for habitType: TherapyType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        animatingHabit = habitType
        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            showCheckmark = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            withAnimation(.easeOut(duration: 0.2)) {
                showCheckmark = false
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                animatingHabit = nil
            }
        }
    }

    private func recentSessionCount(for habit: TherapyType) -> Int {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sessions.filter { session in
            guard let date = session.date else { return false }
            return date >= sevenDaysAgo && session.therapyType == habit.rawValue
        }.count
    }

    private func loadHealthData() {
        if DemoDataManager.shared.isDemoMode {
            DemoDataManager.shared.populateRecoveryModel(recoveryModel)
            DemoDataManager.shared.populateExertionModel(exertionModel)
            DemoDataManager.shared.populateSleepModel(sleepModel)
            DemoDataManager.shared.populateStressModel(stressModel)
            DemoDataManager.shared.populateCoreDataIfNeeded(context: viewContext)
            return
        }
        recoveryModel.pullAllRecoveryData(forDate: selectedDate)
        exertionModel.fetchExertionScoreAndTimes(forDate: selectedDate)
        sleepModel.fetchSleepData(forDate: selectedDate)
        stressModel.computeScores(forDate: selectedDate)
    }

    private func scheduleStreakProtection() {
        let habitNames = selectedTherapyTypes.map { $0.rawValue }
        NotificationManager.shared.checkAndScheduleStreakProtection(
            sessions: Array(sessions),
            selectedHabitNames: habitNames
        )
    }

    private func fetchLLMInsight() {
        guard InsightsSynthesizer.shared.isConfigured else {
            print("LLM Insight: Not configured (no API key)")
            return
        }
        guard let vm = insightsViewModel, !vm.topHabitImpacts.isEmpty else {
            print("LLM Insight: No impacts available yet")
            return
        }

        let recentHabits: [(name: String, count: Int, streak: Int)] = selectedTherapyTypes.map { habit in
            (name: habit.rawValue, count: recentSessionCount(for: habit), streak: currentStreak(for: habit))
        }.filter { $0.count > 0 }

        let impacts = vm.topHabitImpacts
        let trends = vm.healthTrends

        let sleep = recoveryModel.previousNightSleepDuration.flatMap { Double($0) }.map { String(format: "%.1f", $0) }
        let hrv = recoveryModel.avgHrvDuringSleep.map { "\($0)" }
        let rhr = recoveryModel.mostRecentRestingHeartRate.map { "\($0)" }
        let steps = recoveryModel.mostRecentSteps.map { v -> String in
            let val = Int(v)
            return val >= 1000 ? String(format: "%.1fk", Double(val) / 1000.0) : "\(val)"
        }

        Task {
            let result = await InsightsSynthesizer.shared.generateInsight(
                impacts: impacts,
                healthTrends: trends,
                recentHabits: recentHabits,
                sleepHours: sleep,
                hrv: hrv,
                rhr: rhr,
                steps: steps
            )
            await MainActor.run {
                if let result = result {
                    withAnimation(.easeIn(duration: 0.3)) {
                        llmInsight = result
                    }
                } else {
                    withAnimation(.easeIn(duration: 0.3)) {
                        llmInsightFailed = true
                    }
                }
            }
        }
    }
}

// MARK: - Quick Log Button

struct QuickLogButton: View {
    let habitType: TherapyType
    let isCompleted: Bool
    let streak: Int
    let showCheckmark: Bool
    let confirmingUndo: Bool
    let onTap: () -> Void

    @Environment(\.managedObjectContext) private var viewContext

    var body: some View {
        Button(action: onTap) {
            VStack(spacing: 4) {
                ZStack {
                    // Outer glow when completed
                    if isCompleted && !confirmingUndo {
                        Circle()
                            .fill(habitType.color.opacity(0.1))
                            .frame(width: 40, height: 40)
                    }

                    Circle()
                        .fill(circleColor)
                        .frame(width: 34, height: 34)

                    // Completed ring
                    if isCompleted && !confirmingUndo && !showCheckmark {
                        Circle()
                            .stroke(habitType.color.opacity(0.4), lineWidth: 1.5)
                            .frame(width: 34, height: 34)
                    }

                    if confirmingUndo {
                        Image(systemName: "xmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.red.opacity(0.9))
                    } else if showCheckmark {
                        Image(systemName: "checkmark")
                            .font(.system(size: 15, weight: .bold))
                            .foregroundColor(.green)
                    } else if isCompleted {
                        Image(systemName: habitType.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(habitType.color)
                    } else {
                        Image(systemName: habitType.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.35))
                    }
                }
                .frame(height: 40)

                if confirmingUndo {
                    Text("Tap to undo")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.red.opacity(0.7))
                        .lineLimit(1)
                } else {
                    Text(habitType.displayName(viewContext))
                        .font(.system(size: 9, weight: isCompleted ? .bold : .medium))
                        .foregroundColor(isCompleted ? .white.opacity(0.9) : .white.opacity(0.5))
                        .lineLimit(1)
                }

                if confirmingUndo {
                    Spacer().frame(height: 0)
                } else if streak > 1 {
                    HStack(spacing: 2) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 6, weight: .bold))
                            .foregroundColor(.orange)
                        Text("\(streak)d")
                            .font(.system(size: 8, weight: .bold, design: .rounded))
                            .foregroundColor(.orange)
                    }
                    .padding(.horizontal, 5)
                    .padding(.vertical, 1.5)
                    .background(Capsule().fill(Color.orange.opacity(0.12)))
                } else {
                    Spacer().frame(height: 10)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(backgroundFill)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(borderColor, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .animation(.easeInOut(duration: 0.2), value: confirmingUndo)
        .animation(.easeInOut(duration: 0.3), value: isCompleted)
    }

    private var circleColor: Color {
        if confirmingUndo { return Color.red.opacity(0.2) }
        if isCompleted { return habitType.color.opacity(0.2) }
        return Color.white.opacity(0.06)
    }

    private var backgroundFill: Color {
        if confirmingUndo { return Color.red.opacity(0.06) }
        if isCompleted { return habitType.color.opacity(0.06) }
        return Color.white.opacity(0.02)
    }

    private var borderColor: Color {
        if confirmingUndo { return Color.red.opacity(0.25) }
        if isCompleted { return habitType.color.opacity(0.2) }
        return Color.white.opacity(0.05)
    }
}

// MARK: - Today's Insight Card

struct TodayInsightCard: View {
    let impact: HabitImpact
    let recentSessionCount: Int
    let streak: Int

    @Environment(\.managedObjectContext) private var viewContext

    private var habitName: String {
        impact.habitType.displayName(viewContext)
    }

    /// Clear, human-readable description of what happened
    private var insightMessage: String {
        let pct = abs(Int(impact.percentageChange))

        // Metric-specific language that's actually useful
        switch impact.metricName {
        case "Sleep Duration":
            if impact.isPositive {
                return streak > 3
                    ? "\(streak)-day \(habitName) streak \u{2192} you're sleeping \(pct)% longer"
                    : "\(habitName) \(recentSessionCount)x this week \u{2192} \(pct)% more sleep"
            } else {
                return "\(habitName) days correlate with \(pct)% less sleep"
            }
        case "HRV":
            if impact.isPositive {
                return streak > 3
                    ? "\(streak)-day \(habitName) streak \u{2192} HRV up \(pct)% (better recovery)"
                    : "\(habitName) \(recentSessionCount)x this week \u{2192} HRV up \(pct)%"
            } else {
                return "\(habitName) days show \(pct)% lower HRV (more stress)"
            }
        case "RHR":
            // Lower RHR = better
            if impact.isPositive {
                return streak > 3
                    ? "\(streak)-day \(habitName) streak \u{2192} resting HR down \(pct)% (fitter)"
                    : "\(habitName) \(recentSessionCount)x this week \u{2192} resting HR down \(pct)%"
            } else {
                return "\(habitName) days show \(pct)% higher resting HR"
            }
        default:
            return "\(habitName) \(recentSessionCount)x this week \u{2192} \(impact.metricName.lowercased()) \(impact.isPositive ? "improved" : "changed") \(pct)%"
        }
    }

    private var isGoodNews: Bool {
        impact.isPositive
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(impact.habitType.color.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: impact.habitType.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(impact.habitType.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: isGoodNews ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 9, weight: .bold))
                    Text(isGoodNews ? "Working for you" : "Worth watching")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.3)
                }
                .foregroundColor(isGoodNews ? .green.opacity(0.9) : .orange.opacity(0.9))

                Text(insightMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(2)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [
                            (isGoodNews ? Color.green : Color.orange).opacity(0.08),
                            Color.white.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke((isGoodNews ? Color.green : Color.orange).opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - LLM-Powered Insight Card

struct LLMInsightCard: View {
    let text: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: "sparkles")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.cyan)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 9, weight: .bold))
                    Text("AI Insight")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.3)

                    Spacer()

                    HStack(spacing: 4) {
                        Text("Ask Coach")
                            .font(.system(size: 9, weight: .medium))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 7, weight: .semibold))
                    }
                    .foregroundColor(.white.opacity(0.25))
                }
                .foregroundColor(.cyan.opacity(0.9))

                Text(text)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.cyan.opacity(0.08),
                            Color.white.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.cyan.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Daily Tip Fallback Card

struct DailyTipCard: View {
    let sessions: [TherapySessionEntity]

    private var todayCount: Int {
        let start = Calendar.current.startOfDay(for: Date())
        return sessions.filter { ($0.date ?? .distantPast) >= start }.count
    }

    private var weekCount: Int {
        let sevenDaysAgo = Calendar.current.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        return sessions.filter { ($0.date ?? .distantPast) >= sevenDaysAgo }.count
    }

    private var tipMessage: String {
        if todayCount == 0 && weekCount == 0 {
            return "Log your first habit to start seeing personalized insights about what works for your body."
        } else if todayCount == 0 {
            return "You logged \(weekCount) session\(weekCount == 1 ? "" : "s") this week. Log today's activity to keep your streaks alive."
        } else {
            return "\(todayCount) session\(todayCount == 1 ? "" : "s") logged today, \(weekCount) this week. Keep it up \u{2014} correlations unlock after 5+ sessions."
        }
    }

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(Color.blue.opacity(0.2))
                    .frame(width: 44, height: 44)

                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.blue)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 9, weight: .bold))
                    Text("Daily Insight")
                        .font(.system(size: 11, weight: .bold))
                        .tracking(0.3)
                }
                .foregroundColor(.blue.opacity(0.9))

                Text(tipMessage)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.9))
                    .lineLimit(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Spacer(minLength: 0)

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.2))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [
                            Color.blue.opacity(0.08),
                            Color.white.opacity(0.03)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - First Log Celebration Overlay

struct FirstLogCelebrationOverlay: View {
    let habitType: TherapyType?

    @State private var showText = false
    @State private var particles: [(id: Int, x: CGFloat, y: CGFloat, color: Color, opacity: Double)] = []

    var body: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()

            // Confetti particles
            ForEach(particles, id: \.id) { particle in
                Circle()
                    .fill(particle.color)
                    .frame(width: CGFloat.random(in: 4...8), height: CGFloat.random(in: 4...8))
                    .position(x: particle.x, y: particle.y)
                    .opacity(particle.opacity)
            }

            // Celebration card
            VStack(spacing: 20) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 80, height: 80)

                    if let habit = habitType {
                        Image(systemName: habit.icon)
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(habit.color)
                    } else {
                        Image(systemName: "checkmark")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.green)
                    }
                }
                .scaleEffect(showText ? 1 : 0.5)

                VStack(spacing: 8) {
                    Text("First habit logged!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    Text("Keep going — insights unlock after a few days.")
                        .font(.system(size: 15))
                        .foregroundColor(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                }
                .opacity(showText ? 1 : 0)
                .offset(y: showText ? 0 : 10)
            }
            .padding(32)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
                showText = true
            }
            createParticles()
        }
    }

    private func createParticles() {
        let colors: [Color] = [.cyan, .green, .yellow, .orange, .pink, .purple]
        let screenWidth = UIScreen.main.bounds.width
        let screenHeight = UIScreen.main.bounds.height
        let centerX = screenWidth / 2
        let centerY = screenHeight / 2.5

        for i in 0..<25 {
            particles.append((id: i, x: centerX, y: centerY, color: colors.randomElement()!, opacity: 1.0))

            withAnimation(.easeOut(duration: Double.random(in: 1.0...2.0)).delay(Double(i) * 0.02)) {
                particles[i].x = CGFloat.random(in: 20...(screenWidth - 20))
                particles[i].y = CGFloat.random(in: (centerY - 100)...(screenHeight - 200))
                particles[i].opacity = 0
            }
        }
    }
}
