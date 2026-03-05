import SwiftUI
import CoreData

struct InsightsHubView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        entity: TherapySessionEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TherapySessionEntity.date, ascending: false)]
    )
    private var sessions: FetchedResults<TherapySessionEntity>

    var insightsViewModel: InsightsViewModel?

    @State private var selectedSection: HubSection = .weekReview
    @State private var weeklyReview: WeeklyReview?
    @State private var projectionsByHabit: [TherapyType: [HealthProjection]] = [:]
    @State private var lookbackDays: Int = 30

    @StateObject private var recoveryModel = RecoveryGraphModel(
        selectedDate: Calendar.current.startOfDay(for: Date())
    )

    enum HubSection: String, CaseIterable {
        case weekReview = "Week"
        case trends = "Trends"
        case projections = "Projections"
    }

    private let darkBg = Color(red: 0.06, green: 0.10, blue: 0.18)

    var body: some View {
        ZStack {
            darkBg.ignoresSafeArea()

            VStack(spacing: 0) {
                header
                sectionPicker
                content
            }
        }
        .onAppear { loadData() }
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Insights Hub")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer()

            Button(action: { dismiss() }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 16)
        .padding(.bottom, 12)
    }

    // MARK: - Section Picker

    private var sectionPicker: some View {
        HStack(spacing: 0) {
            ForEach(HubSection.allCases, id: \.self) { section in
                Button(action: {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedSection = section
                    }
                }) {
                    Text(section.rawValue)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(selectedSection == section ? .white : .white.opacity(0.4))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(
                            selectedSection == section
                                ? Capsule().fill(Color.cyan.opacity(0.2))
                                : Capsule().fill(Color.clear)
                        )
                }
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.06))
        )
        .padding(.horizontal, 20)
        .padding(.bottom, 12)
    }

    // MARK: - Content

    @ViewBuilder
    private var content: some View {
        switch selectedSection {
        case .weekReview:
            if let review = weeklyReview {
                WeeklyReviewView(review: review)
            } else {
                loadingPlaceholder
            }

        case .trends:
            trendsContent

        case .projections:
            ProjectionsView(projectionsByHabit: projectionsByHabit)
                .environment(\.managedObjectContext, viewContext)
        }
    }

    // MARK: - Trends Content

    private var trendsContent: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                lookbackPicker

                if let vm = insightsViewModel {
                    // Health Dashboard — 2-column grid
                    if !vm.healthTrends.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("HEALTH DASHBOARD")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.4))
                                .tracking(0.5)

                            LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                                ForEach(vm.healthTrends) { trend in
                                    HealthTrendTile(trend: trend)
                                }
                            }
                        }
                    }

                    // Insight Spotlight
                    if let topImpact = vm.topHabitImpacts.first {
                        insightSpotlight(topImpact)
                    }

                    // All Correlations
                    if !vm.topHabitImpacts.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("ALL CORRELATIONS")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.4))
                                .tracking(0.5)

                            ForEach(Array(vm.topHabitImpacts.enumerated()), id: \.element.id) { index, impact in
                                TopImpactCard(impact: impact, rank: index + 1)
                            }
                        }
                    } else {
                        InsightsEmptyStateCard(
                            title: "More Data Needed",
                            message: "Track habits for at least 5 days to see correlations.",
                            icon: "chart.bar.fill"
                        )
                    }
                }

                Color.clear.frame(height: 40)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
        }
    }

    private func insightSpotlight(_ impact: HabitImpact) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.yellow)
                Text("TOP INSIGHT")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.yellow.opacity(0.8))
                    .tracking(0.5)
            }

            HStack(spacing: 12) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(impact.habitType.color.opacity(0.2))
                        .frame(width: 48, height: 48)
                    Image(systemName: impact.habitType.icon)
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(impact.habitType.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(impact.habitType.displayName(viewContext))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    HStack(spacing: 4) {
                        Image(systemName: impact.isPositive ? "arrow.up.right" : "arrow.down.right")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(impact.isPositive ? .green : .red)
                        Text("\(impact.changeDescription) \(impact.metricName)")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(impact.isPositive ? .green : .red)
                    }
                }

                Spacer()

                ConfidenceIndicator(level: impact.confidenceLevel)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.yellow.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.yellow.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private var lookbackPicker: some View {
        HStack(spacing: 0) {
            ForEach([30, 60, 90], id: \.self) { days in
                Button(action: {
                    lookbackDays = days
                    insightsViewModel?.analysisWindowDays = days
                    insightsViewModel?.refetch()
                }) {
                    Text("\(days) days")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(lookbackDays == days ? .white : .white.opacity(0.4))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 8)
                        .background(
                            lookbackDays == days
                                ? Capsule().fill(Color.cyan.opacity(0.2))
                                : Capsule().fill(Color.clear)
                        )
                }
            }
        }
        .padding(3)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.06))
        )
    }

    // MARK: - Loading

    private var loadingPlaceholder: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.cyan)
            Text("Loading your week...")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    // MARK: - Data Loading

    private func loadData() {
        if DemoDataManager.shared.isDemoMode {
            weeklyReview = WeeklyReviewGenerator.demoReview()
            projectionsByHabit = [.running: HealthProjectionEngine.demoProjections()]
            return
        }

        let generator = WeeklyReviewGenerator()
        generator.generate(
            sessions: Array(sessions),
            recoveryScores: recoveryModel.recoveryScores,
            context: viewContext
        ) { review in
            self.weeklyReview = review
        }

        // Generate projections for each habit that has impacts
        if let vm = insightsViewModel {
            let engine = HealthProjectionEngine()
            var results: [TherapyType: [HealthProjection]] = [:]
            for (habitType, impacts) in vm.habitImpactsByType {
                let projections = engine.generateProjections(
                    for: habitType,
                    impacts: impacts,
                    sessions: Array(sessions)
                )
                if !projections.isEmpty {
                    results[habitType] = projections
                }
            }
            projectionsByHabit = results
        }
    }
}

// MARK: - Entry Card

struct InsightsHubEntryCard: View {
    let highlightMessage: String

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.cyan.opacity(0.15))
                    .frame(width: 38, height: 38)

                Image(systemName: "calendar.badge.clock")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.cyan)
            }

            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 5) {
                    Text("Week in Review")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)

                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.cyan)
                }

                Text(highlightMessage)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.3))
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color(red: 0.10, green: 0.14, blue: 0.22))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.cyan.opacity(0.1), lineWidth: 1)
                )
        )
    }
}
