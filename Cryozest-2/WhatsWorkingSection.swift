import SwiftUI
import CoreData

struct WhatsWorkingSection: View {
    let insightsViewModel: InsightsViewModel?
    let sessions: FetchedResults<TherapySessionEntity>

    @Environment(\.managedObjectContext) private var viewContext
    @State private var showWatchList = false
    @State private var showAllHabits = false

    // MARK: - Computed Data

    private var verdicts: [HabitVerdict] {
        guard let vm = insightsViewModel else { return [] }
        return HabitVerdict.buildVerdicts(
            from: vm.habitImpactsByType,
            sessions: Array(sessions)
        )
    }

    private var positiveVerdicts: [HabitVerdict] {
        verdicts.filter { $0.verdict <= .promising }
    }

    private var watchListVerdicts: [HabitVerdict] {
        verdicts.filter { $0.verdict >= .mixed && $0.verdict != .insufficient }
    }

    private var allNegative: Bool {
        !verdicts.isEmpty && positiveVerdicts.isEmpty
    }

    private var totalDaysTracked: Int {
        let allDates = sessions.compactMap { $0.date }
        guard let earliest = allDates.min() else { return 0 }
        return max(1, Calendar.current.dateComponents([.day], from: earliest, to: Date()).day ?? 0)
    }

    private var coldStartTier: ColdStartTier {
        if totalDaysTracked < 5 { return .brewing }
        if totalDaysTracked < 14 { return .earlySignals }
        return .full
    }

    // MARK: - Body

    var body: some View {
        switch coldStartTier {
        case .brewing:
            brewingView
        case .earlySignals:
            earlySignalsView
        case .full:
            fullView
        }
    }

    // MARK: - Cold Start: Brewing (0-4 days)

    private var brewingView: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader

            VStack(spacing: 10) {
                HStack(spacing: 10) {
                    Image(systemName: "flask.fill")
                        .font(.system(size: 20))
                        .foregroundColor(.cyan.opacity(0.7))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Your insights are brewing")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))

                        Text("Keep tracking \u{2014} first signals appear around day 5")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }

                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                LinearGradient(
                                    colors: [.cyan.opacity(0.6), .cyan],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geo.size.width * min(Double(totalDaysTracked) / 5.0, 1.0), height: 6)
                    }
                }
                .frame(height: 6)

                Text("Day \(totalDaysTracked) of 5")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
                    .frame(maxWidth: .infinity, alignment: .trailing)
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    // MARK: - Early Signals (5-13 days)

    private var earlySignalsView: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader

            if verdicts.isEmpty {
                earlySignalEmptyState
            } else {
                // Show verdict cards with "Early" badge
                ForEach(verdicts.prefix(3)) { v in
                    HabitVerdictCard(verdict: v, mode: .compact)
                }
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    // MARK: - Full Experience (14+ days)

    private var fullView: some View {
        VStack(alignment: .leading, spacing: 12) {
            sectionHeader

            if verdicts.isEmpty {
                noDataState
            } else if allNegative {
                // No hero — all habits are watch-list
                attentionHeader

                ForEach(verdicts) { v in
                    HabitVerdictCard(verdict: v, mode: .compact)
                }
            } else {
                // Hero card for rank #1
                if let hero = positiveVerdicts.first {
                    HabitVerdictCard(verdict: hero, mode: .hero)
                }

                // Compact cards for ranks #2-5
                let remaining = Array(positiveVerdicts.dropFirst())
                let visibleCount = showAllHabits ? remaining.count : min(remaining.count, 4)

                ForEach(remaining.prefix(visibleCount)) { v in
                    HabitVerdictCard(verdict: v, mode: .compact)
                }

                // "Show N more" button
                if remaining.count > 4 && !showAllHabits {
                    Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { showAllHabits = true } }) {
                        HStack(spacing: 4) {
                            Text("Show \(remaining.count - 4) more")
                                .font(.system(size: 12, weight: .semibold))
                            Image(systemName: "chevron.down")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(.white.opacity(0.4))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 6)
                    }
                    .buttonStyle(PlainButtonStyle())
                }

                // Watch List
                if !watchListVerdicts.isEmpty {
                    watchListSection
                }
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.seal.fill")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.green)

                Text("What\u{2019}s Working")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))

                Spacer()

                if coldStartTier == .earlySignals {
                    HStack(spacing: 3) {
                        Image(systemName: "sparkle")
                            .font(.system(size: 7, weight: .bold))
                        Text("Early Data")
                            .font(.system(size: 9, weight: .bold))
                            .textCase(.uppercase)
                            .tracking(0.3)
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background(Capsule().fill(Color.cyan.opacity(0.15)))
                }
            }

            Text("Your habits, ranked by health impact")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.35))
        }
    }

    // MARK: - Watch List

    private var watchListSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { showWatchList.toggle() } }) {
                HStack(spacing: 5) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.orange)

                    Text("Watch List (\(watchListVerdicts.count))")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.orange)

                    Spacer()

                    Image(systemName: showWatchList ? "chevron.down" : "chevron.right")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .buttonStyle(PlainButtonStyle())

            if showWatchList {
                ForEach(watchListVerdicts) { v in
                    HabitVerdictCard(verdict: v, mode: .compact)
                }
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Attention Header (all negative)

    private var attentionHeader: some View {
        HStack(spacing: 8) {
            Image(systemName: "exclamationmark.triangle.fill")
                .font(.system(size: 14))
                .foregroundColor(.orange)

            Text("Your habits need attention")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.orange)
        }
    }

    // MARK: - Empty / No Data States

    private var earlySignalEmptyState: some View {
        HStack(spacing: 10) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 18))
                .foregroundColor(.cyan.opacity(0.5))

            VStack(alignment: .leading, spacing: 2) {
                Text("Collecting enough data to find patterns")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))

                Text("Day \(totalDaysTracked) \u{2014} correlations need ~14 days for reliable signals")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
    }

    private var noDataState: some View {
        HStack(spacing: 10) {
            Image(systemName: "chart.bar.fill")
                .font(.system(size: 18))
                .foregroundColor(.white.opacity(0.3))

            Text("No habit data yet \u{2014} start tracking to see what works")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
    }

    // MARK: - Styling

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }

    private enum ColdStartTier {
        case brewing
        case earlySignals
        case full
    }
}
