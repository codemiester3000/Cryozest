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
        verdicts.filter { v in
            // Include habits that are promising or better,
            // OR mixed verdicts that still have at least one positive impact
            v.verdict <= .promising
                || (v.verdict == .mixed && v.impacts.contains { $0.isPositive })
        }
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

    /// Build a list of one benefit card per positive habit.
    /// Prefers showing a different metric per habit for variety, but never
    /// drops a habit just because its best metric was already shown.
    /// Filters out impacts with insufficient/low confidence — those are noise.
    private var benefitCards: [BenefitCard] {
        var claimed: Set<String> = []
        var cards: [BenefitCard] = []

        for v in positiveVerdicts {
            let positiveImpacts = v.impacts
                .filter { $0.isPositive && ($0.confidenceLevel != .insufficient || abs($0.percentageChange) >= 3) }
                .sorted { $0.impactScore > $1.impactScore }

            guard !positiveImpacts.isEmpty else { continue }

            // Prefer an unclaimed metric for variety, but always fall back
            // to the best one — never skip a habit entirely
            let best = positiveImpacts.first(where: { !claimed.contains($0.metricName) })
                ?? positiveImpacts.first!
            claimed.insert(best.metricName)

            let credibleCount = positiveImpacts.count - 1

            cards.append(BenefitCard(
                habitType: v.habitType,
                impact: best,
                streak: v.currentStreak,
                frequency: v.weeklyFrequency,
                secondaryCount: credibleCount
            ))
        }
        return cards
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

            if benefitCards.isEmpty {
                earlySignalEmptyState
            } else {
                ForEach(benefitCards.prefix(3), id: \.habitType) { card in
                    BenefitRow(card: card)
                }
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    // MARK: - Full Experience (14+ days)

    private var fullView: some View {
        VStack(alignment: .leading, spacing: 14) {
            sectionHeader

            if verdicts.isEmpty {
                noDataState
            } else if allNegative {
                attentionHeader

                ForEach(verdicts.prefix(4)) { v in
                    WatchListRow(verdict: v)
                }
            } else {
                // Benefit rows — one per habit, each showing its best metric
                let visible = showAllHabits ? benefitCards : Array(benefitCards.prefix(4))
                ForEach(visible, id: \.habitType) { card in
                    BenefitRow(card: card)
                }

                if benefitCards.count > 4 && !showAllHabits {
                    Button(action: { withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { showAllHabits = true } }) {
                        HStack(spacing: 4) {
                            Text("Show \(benefitCards.count - 4) more")
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

            Text("How your habits are improving your health")
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
                ForEach(Array(watchListVerdicts.enumerated()), id: \.element.id) { index, v in
                    WatchListRow(verdict: v)
                        .modifier(StaggeredAppearance(index: index))
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

// MARK: - Benefit Card Model

struct BenefitCard {
    let habitType: TherapyType
    let impact: HabitImpact
    let streak: Int
    let frequency: Int
    let secondaryCount: Int
}

// MARK: - Benefit Row

struct BenefitRow: View {
    let card: BenefitCard

    @Environment(\.managedObjectContext) private var viewContext

    private var metricColor: Color {
        switch card.impact.metricName {
        case "HRV": return .purple
        case "Sleep Duration": return .indigo
        case "RHR", "Resting Heart Rate": return .red
        case "Pain Level": return .orange
        case "Mood": return .pink
        default: return .cyan
        }
    }

    private var metricLabel: String {
        switch card.impact.metricName {
        case "Sleep Duration": return "Sleep"
        case "Resting Heart Rate": return "RHR"
        case "Pain Level": return "Pain"
        default: return card.impact.metricName
        }
    }

    private var changeText: String {
        let pct = abs(Int(card.impact.percentageChange))
        let name = card.impact.metricName
        if name == "RHR" || name == "Resting Heart Rate" || name == "Pain Level" {
            return card.impact.isPositive ? "\u{2193}\(pct)%" : "\u{2191}\(pct)%"
        }
        return card.impact.isPositive ? "+\(pct)%" : "-\(pct)%"
    }

    private var confidence: ConfidenceLevel {
        card.impact.confidenceLevel
    }

    private var isEarlySignal: Bool {
        confidence == .earlySignal || confidence == .low || confidence == .insufficient
    }

    private var benefitPhrase: String {
        let metric = metricLabel.lowercased()
        let qualifier = isEarlySignal ? "may be " : ""
        switch card.impact.metricName {
        case "Sleep Duration":
            return "\(qualifier)improving your sleep"
        case "HRV":
            return "\(qualifier)boosting your HRV"
        case "Resting Heart Rate", "RHR":
            return "\(qualifier)lowering your RHR"
        case "Pain Level":
            return "\(qualifier)reducing your pain"
        case "Mood":
            return "\(qualifier)lifting your mood"
        default:
            return "\(qualifier)improving your \(metric)"
        }
    }

    private var confidenceLabel: String {
        switch confidence {
        case .high: return "High confidence"
        case .moderate: return "Moderate confidence"
        case .earlySignal: return "Early signal"
        case .low: return "Low confidence"
        case .insufficient: return "Preliminary"
        }
    }

    private var confidenceColor: Color {
        switch confidence {
        case .high: return .green
        case .moderate: return .cyan
        case .earlySignal: return .cyan.opacity(0.7)
        case .low: return .orange
        case .insufficient: return .gray
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            // Habit icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(card.habitType.color.opacity(0.12))
                    .frame(width: 40, height: 40)
                Image(systemName: card.habitType.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(card.habitType.color)
            }

            // Center: habit name + benefit phrase
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(card.habitType.displayName(viewContext))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.white)

                    if card.streak >= 3 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 7, weight: .bold))
                            Text("\(card.streak)d")
                                .font(.system(size: 9, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.orange)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 2)
                        .background(Capsule().fill(Color.orange.opacity(0.12)))
                    }
                }

                Text(benefitPhrase)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.45))

                HStack(spacing: 4) {
                    Circle()
                        .fill(confidenceColor)
                        .frame(width: 5, height: 5)
                    Text("\(confidenceLabel) \u{00B7} \(card.impact.sampleSize) sessions")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                }

                if card.secondaryCount > 0 {
                    Text("+ \(card.secondaryCount) more metric\(card.secondaryCount == 1 ? "" : "s")")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.25))
                }
            }

            Spacer()

            // Right: metric badge with change
            VStack(spacing: 3) {
                Text(changeText)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(card.impact.isPositive ? .green : .orange)

                Text(metricLabel)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(metricColor)
                    .textCase(.uppercase)
                    .tracking(0.3)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(metricColor.opacity(0.08))
            )
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(card.habitType.color.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Watch List Row

struct WatchListRow: View {
    let verdict: HabitVerdict

    @Environment(\.managedObjectContext) private var viewContext

    private var worstImpact: HabitImpact? {
        verdict.impacts.filter { !$0.isPositive }.max { abs($0.percentageChange) < abs($1.percentageChange) }
    }

    private func watchConfidenceColor(_ level: ConfidenceLevel) -> Color {
        switch level {
        case .high: return .green
        case .moderate: return .cyan
        case .earlySignal: return .cyan.opacity(0.7)
        case .low: return .orange
        case .insufficient: return .gray
        }
    }

    private var specificExplanation: String {
        guard let worst = worstImpact else { return verdict.headline }
        let habitName = verdict.habitType.displayName(viewContext)
        switch worst.metricName {
        case "Resting Heart Rate", "RHR":
            return "RHR tends to rise on \(habitName) days"
        case "Sleep Duration":
            return "Sleep duration drops after \(habitName)"
        case "HRV":
            return "HRV dips on \(habitName) days"
        case "Pain Level":
            return "Pain tends to increase after \(habitName)"
        case "Mood":
            return "Mood dips on \(habitName) days"
        default:
            return "\(worst.metricName) worsens after \(habitName)"
        }
    }

    var body: some View {
        HStack(spacing: 10) {
            ZStack {
                RoundedRectangle(cornerRadius: 6)
                    .fill(verdict.habitType.color.opacity(0.1))
                    .frame(width: 28, height: 28)
                Image(systemName: verdict.habitType.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(verdict.habitType.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(verdict.habitType.displayName(viewContext))
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.8))

                Text(specificExplanation)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.orange.opacity(0.7))

                if let worst = worstImpact {
                    HStack(spacing: 4) {
                        Circle()
                            .fill(watchConfidenceColor(worst.confidenceLevel))
                            .frame(width: 5, height: 5)
                        Text("\(worst.confidenceLevel.rawValue) \u{00B7} \(worst.sampleSize) sessions")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }

                if verdict.weeklyFrequency > 0 {
                    Text("Done \(verdict.weeklyFrequency)x this week")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                }
            }

            Spacer()

            if let worst = worstImpact {
                let pct = abs(Int(worst.percentageChange))
                Text(worst.isPositive ? "+\(pct)%" : "-\(pct)%")
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundColor(.orange)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.orange.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.orange.opacity(0.1), lineWidth: 1)
                )
        )
    }
}
