//
//  InsightCardComponents.swift
//  Cryozest-2
//
//  Whoop-inspired professional design - data-focused, minimal, clean
//

import SwiftUI
import CoreData

// MARK: - Top Impact Card (Reimagined as clean data display)
struct TopImpactCard: View {
    let impact: HabitImpact
    let rank: Int
    @Environment(\.managedObjectContext) private var managedObjectContext

    var body: some View {
        HStack(spacing: 16) {
            // Rank indicator - minimal
            Text("\(rank)")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundColor(rankColor)
                .frame(width: 32)

            // Habit icon - clean circle
            ZStack {
                Circle()
                    .fill(impact.habitType.color.opacity(0.15))
                    .frame(width: 44, height: 44)

                Image(systemName: impact.habitType.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(impact.habitType.color)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(impact.habitType.displayName(managedObjectContext))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                HStack(spacing: 6) {
                    Text(formatValueWithUnit(impact.baselineValue, metric: impact.metricName))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))

                    Image(systemName: "arrow.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.white.opacity(0.3))

                    Text(formatValueWithUnit(impact.habitValue, metric: impact.metricName))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(impact.habitType.color)
                }
            }

            Spacer()

            // Impact value - prominent
            VStack(alignment: .trailing, spacing: 2) {
                Text(impact.changeDescription)
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(impact.isPositive ? .green : .red)

                Text(impact.metricName)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(.vertical, 12)
    }

    private var rankColor: Color {
        switch rank {
        case 1: return Color(red: 1.0, green: 0.84, blue: 0.0)
        case 2: return Color(red: 0.75, green: 0.75, blue: 0.75)
        case 3: return Color(red: 0.8, green: 0.5, blue: 0.2)
        default: return .white.opacity(0.4)
        }
    }

    private func formatValueWithUnit(_ value: Double, metric: String) -> String {
        switch metric {
        case "Sleep Duration": return String(format: "%.1fh", value)
        case "HRV": return "\(Int(value)) ms"
        case "RHR": return "\(Int(value)) bpm"
        default:
            if value >= 100 { return String(format: "%.0f", value) }
            else if value >= 10 { return String(format: "%.1f", value) }
            else { return String(format: "%.2f", value) }
        }
    }
}

// MARK: - Metric Impact Row (Clean horizontal layout)
struct MetricImpactRow: View {
    let impact: HabitImpact
    @Environment(\.managedObjectContext) private var managedObjectContext

    var body: some View {
        HStack(spacing: 14) {
            // Habit indicator
            ZStack {
                Circle()
                    .fill(impact.habitType.color.opacity(0.12))
                    .frame(width: 38, height: 38)

                Image(systemName: impact.habitType.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(impact.habitType.color)
            }

            // Habit name and confidence
            VStack(alignment: .leading, spacing: 2) {
                Text(impact.habitType.displayName(managedObjectContext))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Text("\(impact.sampleSize) days tracked")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.35))
            }

            Spacer()

            // Values comparison
            HStack(spacing: 8) {
                Text(formatValueWithUnit(impact.baselineValue, metric: impact.metricName))
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(.white.opacity(0.2))

                Text(formatValueWithUnit(impact.habitValue, metric: impact.metricName))
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(impact.isPositive ? .green : .red)
            }

            // Change indicator
            Text(impact.changeDescription)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(impact.isPositive ? .green : .red)
                .frame(width: 55, alignment: .trailing)
        }
        .padding(.vertical, 10)
    }

    private func formatValueWithUnit(_ value: Double, metric: String) -> String {
        switch metric {
        case "Sleep Duration": return String(format: "%.1fh", value)
        case "HRV": return "\(Int(value)) ms"
        case "RHR": return "\(Int(value)) bpm"
        default:
            if value >= 100 { return String(format: "%.0f", value) }
            else if value >= 10 { return String(format: "%.1f", value) }
            else { return String(format: "%.2f", value) }
        }
    }
}

// MARK: - Empty State (Minimal design)
struct InsightsEmptyStateCard: View {
    let title: String
    let message: String
    let icon: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 32, weight: .light))
                .foregroundColor(.white.opacity(0.25))

            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            Text(message)
                .font(.system(size: 13, weight: .regular))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Section Header (Clean, minimal)
struct InsightsSectionHeader: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)

            Text(title)
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(.white.opacity(0.6))
                .textCase(.uppercase)
                .tracking(0.5)

            Spacer()
        }
    }
}

// MARK: - Health Trend Card (Data-focused display)
struct HealthTrendCard: View {
    let trend: HealthTrend

    var body: some View {
        HStack(spacing: 16) {
            // Metric icon
            ZStack {
                Circle()
                    .fill(trend.color.opacity(0.12))
                    .frame(width: 44, height: 44)

                Image(systemName: trend.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(trend.color)
            }

            // Content
            VStack(alignment: .leading, spacing: 4) {
                Text(trend.title)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                HStack(spacing: 6) {
                    Text(formatValueWithUnit(trend.previousValue, metric: trend.metric))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))

                    Image(systemName: "arrow.right")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.white.opacity(0.3))

                    Text(formatValueWithUnit(trend.currentValue, metric: trend.metric))
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(trend.color)
                }
            }

            Spacer()

            // Change display
            VStack(alignment: .trailing, spacing: 2) {
                HStack(spacing: 3) {
                    Image(systemName: trend.isPositive ? "arrow.up" : "arrow.down")
                        .font(.system(size: 11, weight: .bold))

                    Text(trend.changeDescription)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                }
                .foregroundColor(trend.isPositive ? .green : .red)

                Text("vs last week")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.35))
            }
        }
        .padding(.vertical, 12)
    }

    private func formatValueWithUnit(_ value: Double, metric: String) -> String {
        switch metric {
        case "RHR": return "\(Int(value)) bpm"
        case "HRV": return "\(Int(value)) ms"
        case "Sleep": return String(format: "%.1fh", value)
        case "Steps": return String(format: "%.0f", value)
        case "Calories": return "\(Int(value)) cal"
        default:
            if value >= 100 { return String(format: "%.0f", value) }
            else if value >= 10 { return String(format: "%.1f", value) }
            else { return String(format: "%.2f", value) }
        }
    }
}

// MARK: - Loading Skeleton (Minimal)
struct InsightsLoadingSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 20) {
            ForEach(0..<4, id: \.self) { _ in
                HStack(spacing: 14) {
                    Circle()
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 6) {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.06))
                            .frame(width: 100, height: 14)

                        RoundedRectangle(cornerRadius: 4)
                            .fill(Color.white.opacity(0.04))
                            .frame(width: 70, height: 12)
                    }

                    Spacer()

                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.06))
                        .frame(width: 50, height: 20)
                }
                .padding(.vertical, 10)
            }
        }
        .opacity(isAnimating ? 0.6 : 1.0)
        .animation(
            Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true),
            value: isAnimating
        )
        .onAppear { isAnimating = true }
    }
}

// MARK: - Section Divider (Subtle)
struct InsightsDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.white.opacity(0.06))
            .frame(height: 1)
            .padding(.vertical, 16)
    }
}
