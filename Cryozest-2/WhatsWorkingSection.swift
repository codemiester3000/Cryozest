import SwiftUI
import CoreData

struct WhatsWorkingSection: View {
    let insightsViewModel: InsightsViewModel?
    let sessions: FetchedResults<TherapySessionEntity>

    @Environment(\.managedObjectContext) private var viewContext

    // MARK: - Computed Data

    private var allImpacts: [HabitImpact] {
        insightsViewModel?.topHabitImpacts ?? []
    }

    private var positiveImpacts: [HabitImpact] {
        allImpacts.filter { $0.isPositive }
    }

    private var negativeImpacts: [HabitImpact] {
        allImpacts.filter { !$0.isPositive }
    }

    /// Group positive impacts by metric: "what helps your HRV", "what helps your sleep", etc.
    private var positiveByMetric: [(metric: String, icon: String, color: Color, impacts: [HabitImpact])] {
        let metricOrder = ["HRV", "Sleep Duration", "RHR", "Pain Level", "Hydration"]
        let metricMeta: [String: (icon: String, color: Color)] = [
            "HRV": ("waveform.path.ecg", .purple),
            "Sleep Duration": ("bed.double.fill", .indigo),
            "RHR": ("heart.fill", .red),
            "Pain Level": ("figure.walk", .orange),
            "Hydration": ("drop.fill", .cyan),
        ]

        var grouped: [String: [HabitImpact]] = [:]
        for impact in positiveImpacts {
            grouped[impact.metricName, default: []].append(impact)
        }

        return metricOrder.compactMap { metric in
            guard let impacts = grouped[metric], !impacts.isEmpty else { return nil }
            let meta = metricMeta[metric] ?? (icon: "chart.bar.fill", color: .green)
            return (metric: metric, icon: meta.icon, color: meta.color, impacts: impacts.sorted { $0.impactScore > $1.impactScore })
        }
    }

    /// Habits the user hasn't done today but that have positive correlations
    private var tryTodaySuggestions: [HabitImpact] {
        let calendar = Calendar.current
        let todayHabits = Set(
            sessions
                .filter { session in
                    guard let date = session.date else { return false }
                    return calendar.isDateInToday(date)
                }
                .compactMap { $0.therapyType }
        )

        var seen = Set<String>()
        return positiveImpacts.filter { impact in
            let key = impact.habitType.rawValue
            guard !todayHabits.contains(key), !seen.contains(key) else { return false }
            seen.insert(key)
            return true
        }
    }

    /// Number of days since the user's first tracked session
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

    private var healthTrends: [HealthTrend] {
        insightsViewModel?.healthTrends ?? []
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

                        Text("Keep tracking — first signals appear around day 5")
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

            if positiveImpacts.isEmpty && negativeImpacts.isEmpty {
                earlySignalEmptyState
            } else {
                if !positiveByMetric.isEmpty {
                    ForEach(positiveByMetric.prefix(2), id: \.metric) { group in
                        metricRow(group: group, isEarly: true)
                    }
                }

                if !negativeImpacts.isEmpty {
                    watchOutRow(isEarly: true)
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

            // Per-Metric Breakdown
            if !positiveByMetric.isEmpty {
                ForEach(positiveByMetric, id: \.metric) { group in
                    metricRow(group: group, isEarly: false)
                }
            }

            // Watch Out — negative correlations
            if !negativeImpacts.isEmpty {
                watchOutRow(isEarly: false)
            }

            // Try Today — undone habits with proven upside
            if !tryTodaySuggestions.isEmpty {
                tryTodayRow
            }

            // Week-over-week context
            if !healthTrends.isEmpty {
                trendContext
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    // MARK: - Section Header

    private var sectionHeader: some View {
        HStack(spacing: 6) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.green)

            Text("What's Working")
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
    }

    // MARK: - Per-Metric Rows

    private func metricRow(group: (metric: String, icon: String, color: Color, impacts: [HabitImpact]), isEarly: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: group.icon)
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(group.color)

                Text(shortMetricName(group.metric))
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(group.color)
                    .textCase(.uppercase)
                    .tracking(0.5)

                if let trend = healthTrends.first(where: { $0.metric == group.metric || $0.title == group.metric }) {
                    let dir = trend.changePercentage >= 0 ? "↑" : "↓"
                    Text("\(dir)\(abs(Int(trend.changePercentage)))% this week")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.35))
                }

                Spacer()
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(group.impacts.prefix(4)) { impact in
                        habitImpactPill(impact: impact, metricColor: group.color, isEarly: isEarly)
                    }
                }
            }
        }
    }

    private func habitImpactPill(impact: HabitImpact, metricColor: Color, isEarly: Bool) -> some View {
        HStack(spacing: 5) {
            Image(systemName: impact.habitType.icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(impact.habitType.color)

            Text(impact.habitType.displayName(viewContext))
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.85))

            Text(formatChange(impact))
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.green)

            if isEarly || impact.confidenceLevel == .earlySignal {
                Image(systemName: "sparkle")
                    .font(.system(size: 6, weight: .bold))
                    .foregroundColor(.cyan)
            } else if impact.confidenceLevel == .high {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 8))
                    .foregroundColor(.green.opacity(0.6))
            }

            if let freqText = frequencyLabel(for: impact) {
                Text(freqText)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
            }
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 8)
                        .stroke(metricColor.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Watch Out Row

    private func watchOutRow(isEarly: Bool) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.orange)

                Text("Watch Out")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.orange)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Spacer()
            }

            let uniqueNegative = deduplicatedNegatives()

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(uniqueNegative.prefix(3)) { impact in
                        HStack(spacing: 5) {
                            Image(systemName: impact.habitType.icon)
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(impact.habitType.color)

                            Text(impact.habitType.displayName(viewContext))
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.85))

                            Text("→")
                                .font(.system(size: 9))
                                .foregroundColor(.white.opacity(0.25))

                            Text("\(shortMetricName(impact.metricName)) \(formatNegativeChange(impact))")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.orange)

                            if isEarly {
                                Image(systemName: "sparkle")
                                    .font(.system(size: 6, weight: .bold))
                                    .foregroundColor(.cyan)
                            }
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.05))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 8)
                                        .stroke(Color.orange.opacity(0.15), lineWidth: 1)
                                )
                        )
                    }
                }
            }
        }
    }

    // MARK: - Try Today Row

    private var tryTodayRow: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "lightbulb.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.yellow)

                Text("Try Today")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.yellow)
                    .textCase(.uppercase)
                    .tracking(0.5)

                Spacer()
            }

            ForEach(tryTodaySuggestions.prefix(2)) { impact in
                tryTodaySuggestionRow(impact: impact)
            }
        }
    }

    private func tryTodaySuggestionRow(impact: HabitImpact) -> some View {
        let name = impact.habitType.displayName(viewContext)
        let pct = abs(Int(impact.percentageChange))
        let metric = shortMetricName(impact.metricName)

        return HStack(spacing: 8) {
            ZStack {
                Circle()
                    .fill(impact.habitType.color.opacity(0.15))
                    .frame(width: 28, height: 28)
                Image(systemName: impact.habitType.icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(impact.habitType.color)
            }

            VStack(alignment: .leading, spacing: 1) {
                Text(name)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))

                Text("Usually boosts \(metric) by \(pct)%")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }

            Spacer(minLength: 0)
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.yellow.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.yellow.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Week-over-Week Trend Context

    private var trendContext: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 5) {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))

                Text("This Week vs Last")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .tracking(0.5)

                Spacer()
            }

            HStack(spacing: 0) {
                ForEach(healthTrends.prefix(4)) { trend in
                    VStack(spacing: 3) {
                        Image(systemName: trend.icon)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(trend.color)

                        Text(shortMetricName(trend.title))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))

                        let dir = trend.changePercentage >= 0 ? "+" : ""
                        Text("\(dir)\(Int(trend.changePercentage))%")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(trend.isPositive ? .green : .orange)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.03))
            )
        }
    }

    // MARK: - Empty State

    private var earlySignalEmptyState: some View {
        HStack(spacing: 10) {
            Image(systemName: "waveform.path.ecg")
                .font(.system(size: 18))
                .foregroundColor(.cyan.opacity(0.5))

            VStack(alignment: .leading, spacing: 2) {
                Text("Collecting enough data to find patterns")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))

                Text("Day \(totalDaysTracked) — correlations need ~14 days for reliable signals")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
    }

    // MARK: - Helpers

    private func shortMetricName(_ name: String) -> String {
        switch name {
        case "Sleep Duration": return "Sleep"
        case "Resting Heart Rate": return "RHR"
        case "Pain Level": return "Pain"
        default: return name
        }
    }

    private func formatChange(_ impact: HabitImpact) -> String {
        let pct = abs(Int(impact.percentageChange))
        if impact.metricName == "RHR" || impact.metricName == "Pain Level" {
            return impact.isPositive ? "↓\(pct)%" : "↑\(pct)%"
        }
        return impact.isPositive ? "+\(pct)%" : "-\(pct)%"
    }

    private func formatNegativeChange(_ impact: HabitImpact) -> String {
        let pct = abs(Int(impact.percentageChange))
        if impact.metricName == "RHR" {
            return "+\(pct)%"
        }
        return "-\(pct)%"
    }

    private func frequencyLabel(for impact: HabitImpact) -> String? {
        let calendar = Calendar.current
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let count = sessions.filter { session in
            guard let date = session.date else { return false }
            return date >= sevenDaysAgo && session.therapyType == impact.habitType.rawValue
        }.count

        if count > 0 { return "\(count)x/wk" }
        return nil
    }

    private func deduplicatedNegatives() -> [HabitImpact] {
        var seen = Set<String>()
        return negativeImpacts.filter { impact in
            let key = impact.habitType.rawValue
            guard !seen.contains(key) else { return false }
            seen.insert(key)
            return true
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
