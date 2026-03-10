import SwiftUI
import CoreData
import Combine

struct InsightsTabView: View {
    @Environment(\.managedObjectContext) private var viewContext

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

    @FetchRequest(
        entity: WellnessRating.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \WellnessRating.date, ascending: false)]
    )
    private var wellnessRatings: FetchedResults<WellnessRating>

    var insightsViewModel: InsightsViewModel?
    @StateObject private var viewModelWrapper = LocalInsightsViewModelWrapper()

    @State private var expandedHabit: TherapyType? = nil
    @State private var showHabitSelection = false
    @State private var showInfoSheet = false
    @State private var showCoachSheet = false
    @State private var coachQuestion: String? = nil
    @State private var showInsightsHub = false
    @State private var hubHighlightMessage: String = "Tap to see your weekly summary"
    @State private var topProjections: [HealthProjection] = []

    // Logging state
    @State private var animatingHabit: TherapyType? = nil
    @State private var showCheckmark = false
    @State private var logButtonScale: CGFloat = 1.0
    @State private var showUndoToast = false
    @State private var lastCompletedSession: TherapySessionEntity?
    @State private var completedHabitType: TherapyType? = nil
    @State private var undoCountdown: Int = 5
    @State private var undoTimer: Timer? = nil

    private var selectedTherapyTypes: [TherapyType] {
        let types: [TherapyType]
        if selectedTherapies.isEmpty {
            types = [.running, .weightTraining, .cycling, .meditation]
        } else {
            types = selectedTherapies.compactMap { TherapyType(rawValue: $0.therapyType ?? "") }
        }
        // Stack rank by most recent session
        return types.sorted { a, b in
            let aDate = sessions.first(where: { $0.therapyType == a.rawValue })?.date ?? .distantPast
            let bDate = sessions.first(where: { $0.therapyType == b.rawValue })?.date ?? .distantPast
            return aDate > bDate
        }
    }

    private var activeViewModel: InsightsViewModel? {
        insightsViewModel ?? viewModelWrapper.viewModel
    }

    var body: some View {
        ZStack {
            Color(red: 0.06, green: 0.10, blue: 0.18)
                .ignoresSafeArea()

            if let viewModel = activeViewModel {
                if viewModel.isLoading {
                    loadingView
                } else {
                    mainContent(viewModel: viewModel)
                        .onAppear { loadProjections(viewModel: viewModel) }
                }
            } else {
                loadingView
            }

            // Undo toast
            if showUndoToast {
                VStack {
                    Spacer()
                    undoToast
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear {
            if insightsViewModel == nil && viewModelWrapper.viewModel == nil {
                viewModelWrapper.viewModel = InsightsViewModel(
                    sessions: sessions,
                    selectedTherapyTypes: selectedTherapyTypes,
                    viewContext: viewContext
                )
            }
        }
        .sheet(isPresented: $showHabitSelection) {
            TherapyTypeSelectionView()
                .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showInfoSheet) {
            InsightsInfoSheet()
        }
        .sheet(isPresented: $showCoachSheet) {
            CoachSheetView(
                insightsViewModel: activeViewModel,
                initialQuestion: coachQuestion
            )
            .environment(\.managedObjectContext, viewContext)
        }
        .sheet(isPresented: $showInsightsHub) {
            InsightsHubView(insightsViewModel: activeViewModel)
                .environment(\.managedObjectContext, viewContext)
        }
    }

    // MARK: - Main Content

    private func mainContent(viewModel: InsightsViewModel) -> some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 0) {
                // Header
                HStack(alignment: .center) {
                    Text("Insights")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Spacer()

                    Button(action: { showHabitSelection = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Button(action: { showInfoSheet = true }) {
                        Image(systemName: "info.circle")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 40, height: 40)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 16)

                // What's Working section
                WhatsWorkingSection(
                    insightsViewModel: viewModel,
                    sessions: sessions
                )
                .padding(.horizontal, 20)
                .padding(.bottom, 12)

                // Insights Hub entry card
                InsightsHubEntryCard(highlightMessage: hubHighlightMessage)
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
                    .onTapGesture { showInsightsHub = true }
                    .onAppear { loadHubHighlight() }

                // 1. Data Collection Progress (only if any habit has < 100% progress)
                if hasIncompleteProgress(viewModel: viewModel) {
                    dataCollectionSection(viewModel: viewModel)
                    InsightsDivider()
                        .padding(.horizontal, 20)
                }

                // 2. Top Correlations
                topCorrelationsSection(viewModel: viewModel)

                InsightsDivider()
                    .padding(.horizontal, 20)

                // 3. Per-Habit Cards
                perHabitSection(viewModel: viewModel)

                InsightsDivider()
                    .padding(.horizontal, 20)

                // 4. Health Trends
                if !viewModel.healthTrends.isEmpty {
                    healthTrendsSection(viewModel: viewModel)

                    InsightsDivider()
                        .padding(.horizontal, 20)
                }

                // 5. Projections
                if !topProjections.isEmpty {
                    projectionsSection

                    InsightsDivider()
                        .padding(.horizontal, 20)
                }

                // 6. Wellness Trends
                WellnessInsightsSection(
                    ratings: Array(wellnessRatings),
                    sessions: Array(sessions),
                    therapyTypes: selectedTherapyTypes
                )

                // Bottom spacer
                Color.clear
                    .frame(height: 120)
            }
        }
    }

    // MARK: - Sections

    private func hasIncompleteProgress(viewModel: InsightsViewModel) -> Bool {
        selectedTherapyTypes.contains { type in
            guard let progress = viewModel.dataCollectionProgress[type] else { return true }
            return progress.overallProgress < 1.0
        }
    }

    private func dataCollectionSection(viewModel: InsightsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            InsightsSectionHeader(
                title: "Data Collection",
                icon: "chart.bar.doc.horizontal",
                color: .cyan
            )
            .padding(.horizontal, 20)

            VStack(spacing: 8) {
                ForEach(selectedTherapyTypes.filter { type in
                    guard let progress = viewModel.dataCollectionProgress[type] else { return true }
                    return progress.overallProgress < 1.0
                }, id: \.self) { type in
                    if let progress = viewModel.dataCollectionProgress[type] {
                        HStack(spacing: 10) {
                            Image(systemName: type.icon)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(type.color)
                                .frame(width: 24, height: 24)

                            VStack(alignment: .leading, spacing: 4) {
                                Text(type.displayName(viewContext))
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))

                                DataCollectionProgressView(
                                    progress: progress,
                                    habitColor: type.color
                                )
                            }
                        }
                        .padding(.horizontal, 20)
                    }
                }
            }
        }
        .padding(.bottom, 8)
    }

    private func topCorrelationsSection(viewModel: InsightsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "chart.bar.xaxis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.orange)

                Text("Top Correlations")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .textCase(.uppercase)
                    .tracking(0.5)

                Spacer()

                if !viewModel.topHabitImpacts.isEmpty {
                    Button(action: {
                        coachQuestion = "What should I know about my top health correlations?"
                        showCoachSheet = true
                    }) {
                        HStack(spacing: 3) {
                            Image(systemName: "sparkles")
                                .font(.system(size: 8, weight: .bold))
                            Text("Ask Coach")
                                .font(.system(size: 9, weight: .semibold))
                        }
                        .foregroundColor(.cyan.opacity(0.6))
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.cyan.opacity(0.08))
                        )
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 8)

            if viewModel.topHabitImpacts.isEmpty {
                InsightsEmptyStateCard(
                    title: "More Data Needed",
                    message: "Track habits for at least 5 days to see correlations.",
                    icon: "chart.bar.fill"
                )
                .padding(.horizontal, 20)
            } else {
                VStack(spacing: 6) {
                    ForEach(Array(viewModel.topHabitImpacts.enumerated()), id: \.element.id) { index, impact in
                        TopImpactCard(impact: impact, rank: index + 1)
                            .padding(.horizontal, 20)
                    }
                }
            }
        }
        .padding(.bottom, 8)
    }

    private func perHabitSection(viewModel: InsightsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                InsightsSectionHeader(
                    title: "My Habits",
                    icon: "list.bullet.rectangle.portrait",
                    color: .green
                )

                Spacer()

                // Today summary
                let completedToday = habitsCompletedToday
                if !selectedTherapyTypes.isEmpty {
                    Text("\(completedToday)/\(selectedTherapyTypes.count)")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.cyan)
                }
            }
            .padding(.horizontal, 20)

            LazyVStack(spacing: 10) {
                ForEach(selectedTherapyTypes, id: \.self) { habitType in
                    HabitDashboardCard(
                        habitType: habitType,
                        sessions: sessions,
                        impacts: viewModel.habitImpactsByType[habitType] ?? [],
                        progress: viewModel.dataCollectionProgress[habitType],
                        isExpanded: expandedHabit == habitType,
                        onTap: { toggleExpanded(habitType) },
                        onLog: { logSession(for: habitType) },
                        onDelete: { session in deleteSession(session) },
                        showCheckmark: animatingHabit == habitType && showCheckmark,
                        logButtonScale: animatingHabit == habitType ? logButtonScale : 1.0
                    )
                }
            }
            .padding(.horizontal, 20)

            if selectedTherapyTypes.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 36, weight: .light))
                        .foregroundColor(.white.opacity(0.2))

                    Text("No habits selected")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))

                    Button(action: { showHabitSelection = true }) {
                        Text("Add Habits")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.cyan)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 30)
            }
        }
    }

    private func healthTrendsSection(viewModel: InsightsViewModel) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            InsightsSectionHeader(
                title: "Health This Week",
                icon: "chart.line.uptrend.xyaxis",
                color: .cyan
            )
            .padding(.horizontal, 20)

            VStack(spacing: 16) {
                ForEach(viewModel.healthTrends) { trend in
                    HealthTrendCard(trend: trend)
                        .padding(.horizontal, 20)
                }
            }
        }
        .padding(.bottom, 8)
    }

    // MARK: - Loading View

    private var loadingView: some View {
        VStack(spacing: 20) {
            Text("Insights")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal)
                .padding(.top, 16)

            InsightsLoadingSkeleton()
                .padding(.horizontal)

            Spacer()
        }
    }

    // MARK: - Computed Properties

    private var habitsCompletedToday: Int {
        let calendar = Calendar.current
        return selectedTherapyTypes.filter { type in
            sessions.contains { session in
                guard let date = session.date else { return false }
                return calendar.isDateInToday(date) && session.therapyType == type.rawValue
            }
        }.count
    }

    // MARK: - Actions

    private func toggleExpanded(_ habitType: TherapyType) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            expandedHabit = expandedHabit == habitType ? nil : habitType
        }
    }

    private func logSession(for habitType: TherapyType) {
        let newSession = TherapySessionEntity(context: viewContext)
        newSession.date = Date()
        newSession.therapyType = habitType.rawValue

        do {
            try viewContext.save()
            lastCompletedSession = newSession
            completedHabitType = habitType
            triggerAnimation(for: habitType)
            startUndoTimer()
        } catch {
            print("Error saving session: \(error)")
        }
    }

    private func deleteSession(_ session: TherapySessionEntity) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            viewContext.delete(session)
            do {
                try viewContext.save()
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            } catch {
                print("Error deleting session: \(error)")
            }
        }
    }

    private func triggerAnimation(for habitType: TherapyType) {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
        animatingHabit = habitType

        withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
            logButtonScale = 1.3
            showCheckmark = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.25, dampingFraction: 0.7)) {
                logButtonScale = 1.0
            }
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

    private func startUndoTimer() {
        undoTimer?.invalidate()
        undoCountdown = 5
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { showUndoToast = true }

        undoTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if undoCountdown > 1 {
                undoCountdown -= 1
            } else {
                timer.invalidate()
                undoTimer = nil
                withAnimation(.easeOut(duration: 0.25)) { showUndoToast = false }
            }
        }
    }

    private func undoCompletion() {
        guard let session = lastCompletedSession else { return }
        undoTimer?.invalidate()
        undoTimer = nil

        viewContext.delete(session)
        do {
            try viewContext.save()
            lastCompletedSession = nil
            completedHabitType = nil
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { showUndoToast = false }
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        } catch {
            print("Error undoing session: \(error)")
        }
    }

    private func loadProjections(viewModel: InsightsViewModel) {
        let engine = HealthProjectionEngine()
        var all: [HealthProjection] = []

        for (habitType, impacts) in viewModel.habitImpactsByType {
            let projections = engine.generateProjections(
                for: habitType,
                impacts: impacts,
                sessions: Array(sessions)
            )
            all.append(contentsOf: projections)
        }

        // Sort by confidence (high first), take top 3
        let confidenceOrder: [ConfidenceLevel: Int] = [.high: 0, .moderate: 1, .earlySignal: 2, .low: 3, .insufficient: 4]
        all.sort { (confidenceOrder[$0.confidence] ?? 4) < (confidenceOrder[$1.confidence] ?? 4) }
        topProjections = Array(all.prefix(3))
    }

    private var projectionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 10) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.cyan)

                Text("30-Day Projections")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.6))
                    .textCase(.uppercase)
                    .tracking(0.5)

                Spacer()

                Button(action: { showInsightsHub = true }) {
                    HStack(spacing: 3) {
                        Text("See all")
                            .font(.system(size: 11, weight: .semibold))
                        Image(systemName: "chevron.right")
                            .font(.system(size: 8, weight: .bold))
                    }
                    .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 4)

            VStack(spacing: 8) {
                ForEach(topProjections) { projection in
                    inlineProjectionCard(projection)
                        .padding(.horizontal, 20)
                }
            }
        }
        .padding(.bottom, 8)
    }

    private func inlineProjectionCard(_ projection: HealthProjection) -> some View {
        HStack(spacing: 12) {
            // Metric icon
            VStack(spacing: 2) {
                Image(systemName: projectionIcon(projection.metric))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(projectionColor(projection.metric))
            }
            .frame(width: 32, height: 32)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(projectionColor(projection.metric).opacity(0.12))
            )

            // Metric name
            VStack(alignment: .leading, spacing: 2) {
                Text(projection.metric)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))

                Text("via \(projection.basedOnHabit)")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.35))
            }

            Spacer()

            // Current → Projected
            HStack(spacing: 6) {
                Text(formatProjectionValue(projection.currentValue, metric: projection.metric))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))

                Image(systemName: "arrow.right")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(.white.opacity(0.3))

                Text(formatProjectionValue(projection.projectedValue, metric: projection.metric))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(projection.isPositiveDirection ? .green : .red)
            }

            // Change badge
            let sign = projection.projectedChange >= 0 ? "+" : ""
            Text("\(sign)\(Int(projection.projectedChange))%")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(projection.isPositiveDirection ? .green : .red)
                .padding(.horizontal, 6)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill((projection.isPositiveDirection ? Color.green : Color.red).opacity(0.12))
                )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    private func projectionIcon(_ metric: String) -> String {
        switch metric {
        case "HRV": return "waveform.path.ecg"
        case "RHR", "Resting Heart Rate": return "heart.fill"
        case "Sleep Duration": return "bed.double.fill"
        case "Mood": return "face.smiling"
        case "Pain Level": return "bolt.heart.fill"
        default: return "chart.line.uptrend.xyaxis"
        }
    }

    private func projectionColor(_ metric: String) -> Color {
        switch metric {
        case "HRV": return .purple
        case "RHR", "Resting Heart Rate": return .red
        case "Sleep Duration": return .indigo
        case "Mood": return .pink
        case "Pain Level": return .orange
        default: return .cyan
        }
    }

    private func formatProjectionValue(_ value: Double, metric: String) -> String {
        switch metric {
        case "HRV": return "\(Int(value))ms"
        case "RHR", "Resting Heart Rate": return "\(Int(value))bpm"
        case "Sleep Duration": return String(format: "%.1fh", value)
        case "Mood": return String(format: "%.1f★", value)
        default: return String(format: "%.1f", value)
        }
    }

    private func loadHubHighlight() {
        if DemoDataManager.shared.isDemoMode {
            hubHighlightMessage = WeeklyReviewGenerator.demoReview().highlightMessage
            return
        }
        let generator = WeeklyReviewGenerator()
        generator.generate(
            sessions: Array(sessions),
            recoveryScores: [],
            context: viewContext
        ) { review in
            hubHighlightMessage = review.highlightMessage
        }
    }

    // MARK: - Undo Toast

    private var undoToast: some View {
        Button(action: undoCompletion) {
            HStack(spacing: 12) {
                if let habit = completedHabitType {
                    ZStack {
                        Circle()
                            .fill(habit.color.opacity(0.2))
                            .frame(width: 32, height: 32)
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(habit.color)
                    }
                }

                VStack(alignment: .leading, spacing: 2) {
                    if let habit = completedHabitType {
                        Text("\(habit.displayName(viewContext)) logged")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white)
                    }
                    Text("Tap to undo")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                Text("\(undoCountdown)s")
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.4))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color(red: 0.12, green: 0.16, blue: 0.24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .shadow(color: Color.black.opacity(0.3), radius: 12, x: 0, y: 4)
            )
        }
    }
}

// Local wrapper for when no shared viewModel is provided
private class LocalInsightsViewModelWrapper: ObservableObject {
    @Published var viewModel: InsightsViewModel? {
        didSet {
            cancellable?.cancel()
            cancellable = viewModel?.objectWillChange.sink { [weak self] _ in
                self?.objectWillChange.send()
            }
        }
    }
    private var cancellable: AnyCancellable?
}
