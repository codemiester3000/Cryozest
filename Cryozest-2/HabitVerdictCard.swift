import SwiftUI

struct HabitVerdictCard: View {
    let verdict: HabitVerdict
    let mode: CardMode

    @Environment(\.managedObjectContext) private var viewContext

    enum CardMode {
        case hero
        case compact
    }

    // MARK: - Colors

    private var verdictColor: Color {
        switch verdict.verdict {
        case .mvp, .strong: return .green
        case .promising: return .cyan
        case .mixed: return .yellow
        case .concerning: return .orange
        case .insufficient: return .gray
        }
    }

    // MARK: - Body

    var body: some View {
        switch mode {
        case .hero:
            heroCard
        case .compact:
            compactCard
        }
    }

    // MARK: - Hero Card

    private var heroCard: some View {
        HStack(spacing: 0) {
            // Left accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(verdictColor)
                .frame(width: 3)
                .padding(.vertical, 4)

            VStack(alignment: .leading, spacing: 10) {
                // Header row: icon + name + streak badge
                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(verdict.habitType.color.opacity(0.15))
                            .frame(width: 36, height: 36)
                        Image(systemName: verdict.habitType.icon)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(verdict.habitType.color)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text(verdict.habitType.displayName(viewContext))
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)

                        Text(verdict.headline)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(verdictColor)
                    }

                    Spacer()

                    if verdict.currentStreak >= 3 {
                        streakBadge
                    }
                }

                // Metric grid
                metricGrid

                // Footer: lag + frequency
                HStack(spacing: 12) {
                    if let lag = verdict.bestMetric?.lagDescription {
                        Text(lag)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.cyan)
                    }

                    if verdict.weeklyFrequency > 0 {
                        Text("\(verdict.weeklyFrequency)x this week")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
            }
            .padding(.leading, 10)
            .padding(.vertical, 2)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(verdictColor.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Compact Card

    private var compactCard: some View {
        HStack(spacing: 0) {
            // Left accent bar
            RoundedRectangle(cornerRadius: 2)
                .fill(verdictColor)
                .frame(width: 3)
                .padding(.vertical, 4)

            HStack(spacing: 10) {
                // Icon
                ZStack {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(verdict.habitType.color.opacity(0.12))
                        .frame(width: 28, height: 28)
                    Image(systemName: verdict.habitType.icon)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(verdict.habitType.color)
                }

                // Name + headline + frequency
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 6) {
                        Text(verdict.habitType.displayName(viewContext))
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)

                        if verdict.currentStreak >= 3 {
                            streakBadgeSmall
                        }
                    }

                    Text(verdict.headline)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(verdictColor)

                    if verdict.weeklyFrequency > 0 {
                        Text("\(verdict.weeklyFrequency)x/wk")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.35))
                    }
                }

                Spacer()

                // Right-aligned metric changes (up to 3)
                VStack(alignment: .trailing, spacing: 3) {
                    ForEach(verdict.impacts.prefix(3)) { impact in
                        HStack(spacing: 4) {
                            Text(shortMetric(impact.metricName))
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))

                            Text(formatChange(impact))
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(impact.isPositive ? .green : .orange)
                        }
                    }
                }
            }
            .padding(.leading, 10)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    // MARK: - Metric Grid (Hero)

    private var metricGrid: some View {
        HStack(spacing: 8) {
            ForEach(verdict.impacts.prefix(5)) { impact in
                metricCell(impact: impact)
            }
        }
    }

    private func metricCell(impact: HabitImpact) -> some View {
        VStack(spacing: 4) {
            Text(shortMetric(impact.metricName))
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(metricColor(impact.metricName))
                .textCase(.uppercase)

            Text(formatChange(impact))
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(impact.isPositive ? .green : .orange)

            ConfidenceIndicator(level: impact.confidenceLevel)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.04))
        )
    }

    // MARK: - Streak Badges

    private var streakBadge: some View {
        HStack(spacing: 3) {
            Image(systemName: "flame.fill")
                .font(.system(size: 10, weight: .bold))
            Text("\(verdict.currentStreak)-day streak")
                .font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(.orange)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.12))
        )
    }

    private var streakBadgeSmall: some View {
        HStack(spacing: 2) {
            Image(systemName: "flame.fill")
                .font(.system(size: 7, weight: .bold))
            Text("\(verdict.currentStreak)")
                .font(.system(size: 9, weight: .bold))
        }
        .foregroundColor(.orange)
        .padding(.horizontal, 5)
        .padding(.vertical, 2)
        .background(
            Capsule()
                .fill(Color.orange.opacity(0.12))
        )
    }

    // MARK: - Helpers

    private func shortMetric(_ name: String) -> String {
        switch name {
        case "Sleep Duration": return "Sleep"
        case "Resting Heart Rate": return "RHR"
        case "Pain Level": return "Pain"
        default: return name
        }
    }

    private func metricColor(_ name: String) -> Color {
        switch name {
        case "HRV": return .purple
        case "Sleep Duration": return .indigo
        case "RHR", "Resting Heart Rate": return .red
        case "Pain Level": return .orange
        case "Hydration": return .cyan
        default: return .white.opacity(0.6)
        }
    }

    private func formatChange(_ impact: HabitImpact) -> String {
        let pct = abs(Int(impact.percentageChange))
        if impact.metricName == "RHR" || impact.metricName == "Resting Heart Rate" || impact.metricName == "Pain Level" {
            return impact.isPositive ? "\u{2193}\(pct)%" : "\u{2191}\(pct)%"
        }
        return impact.isPositive ? "+\(pct)%" : "-\(pct)%"
    }
}
