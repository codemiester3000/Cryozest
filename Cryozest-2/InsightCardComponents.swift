//
//  InsightCardComponents.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//

import SwiftUI
import CoreData

// MARK: - Top Impact Card
struct TopImpactCard: View {
    let impact: HabitImpact
    let rank: Int
    @Environment(\.managedObjectContext) private var managedObjectContext

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Rank badge
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: rankGradientColors,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 44, height: 44)

                    Text("\(rank)")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                }

                // Habit icon
                ZStack {
                    Circle()
                        .fill(impact.habitType.color.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: impact.habitType.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(impact.habitType.color)
                }

                // Details
                VStack(alignment: .leading, spacing: 4) {
                    Text(impact.habitType.displayName(managedObjectContext))
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    Text(impact.metricName)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                // Impact change
                Text(impact.changeDescription)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(impact.isPositive ? .green : .red)
            }

            // Value comparison
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Without")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))

                    Text(formatValueWithUnit(impact.baselineValue, metric: impact.metricName))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                }

                Image(systemName: "arrow.right")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.3))

                VStack(alignment: .leading, spacing: 4) {
                    Text("With \(impact.habitType.displayName(managedObjectContext))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(impact.habitType.color.opacity(0.8))
                        .lineLimit(1)

                    Text(formatValueWithUnit(impact.habitValue, metric: impact.metricName))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(impact.habitType.color)
                }

                Spacer()

                // Data quality indicator
                HStack(spacing: 4) {
                    Image(systemName: impact.sampleSize >= 14 ? "checkmark.circle.fill" : (impact.sampleSize >= 7 ? "circle.lefthalf.filled" : "circle.dotted"))
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(dataQualityColor)

                    Text("\(impact.sampleSize) days")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(dataQualityColor)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [impact.habitType.color.opacity(0.3), impact.habitType.color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
    }

    private var rankGradientColors: [Color] {
        switch rank {
        case 1:
            return [Color(red: 1.0, green: 0.84, blue: 0.0), Color(red: 1.0, green: 0.65, blue: 0.0)]
        case 2:
            return [Color(red: 0.75, green: 0.75, blue: 0.75), Color(red: 0.65, green: 0.65, blue: 0.65)]
        case 3:
            return [Color(red: 0.8, green: 0.5, blue: 0.2), Color(red: 0.7, green: 0.4, blue: 0.1)]
        default:
            return [Color.white.opacity(0.3), Color.white.opacity(0.2)]
        }
    }

    private var dataQualityColor: Color {
        if impact.sampleSize >= 14 {
            return .green.opacity(0.8)
        } else if impact.sampleSize >= 7 {
            return .orange.opacity(0.8)
        } else {
            return .yellow.opacity(0.8)
        }
    }

    private func formatValueWithUnit(_ value: Double, metric: String) -> String {
        switch metric {
        case "Sleep Duration":
            return String(format: "%.1fh", value)
        case "HRV":
            return "\(Int(value)) ms"
        case "RHR":
            return "\(Int(value)) bpm"
        default:
            if value >= 100 {
                return String(format: "%.0f", value)
            } else if value >= 10 {
                return String(format: "%.1f", value)
            } else {
                return String(format: "%.2f", value)
            }
        }
    }
}

// MARK: - Metric Impact Row
struct MetricImpactRow: View {
    let impact: HabitImpact
    @Environment(\.managedObjectContext) private var managedObjectContext

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 12) {
                // Habit icon
                ZStack {
                    Circle()
                        .fill(impact.habitType.color.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: impact.habitType.icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(impact.habitType.color)
                }

                // Habit name
                VStack(alignment: .leading, spacing: 2) {
                    Text(impact.habitType.displayName(managedObjectContext))
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)

                    Text(dataQualityLabel)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(dataQualityColor)
                }

                Spacer()

                // Change percentage
                Text(impact.changeDescription)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(impact.isPositive ? .green : .red)
            }

            // Comparison values
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Without")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))

                    Text(formatValueWithUnit(impact.baselineValue, metric: impact.metricName))
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.7))
                }

                Image(systemName: "arrow.right")
                    .font(.system(size: 12))
                    .foregroundColor(.white.opacity(0.3))

                VStack(alignment: .leading, spacing: 4) {
                    Text("With \(impact.habitType.displayName(managedObjectContext))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(impact.habitType.color.opacity(0.8))
                        .lineLimit(1)

                    Text(formatValueWithUnit(impact.habitValue, metric: impact.metricName))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(impact.habitType.color)
                }

                Spacer()
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(impact.habitType.color.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var dataQualityLabel: String {
        if impact.sampleSize >= 14 {
            return "\(impact.sampleSize) days • High confidence"
        } else if impact.sampleSize >= 7 {
            return "\(impact.sampleSize) days • Medium confidence"
        } else {
            return "\(impact.sampleSize) days • Low confidence"
        }
    }

    private var dataQualityColor: Color {
        if impact.sampleSize >= 14 {
            return .green.opacity(0.8)
        } else if impact.sampleSize >= 7 {
            return .orange.opacity(0.8)
        } else {
            return .yellow.opacity(0.8)
        }
    }

    private func formatValueWithUnit(_ value: Double, metric: String) -> String {
        switch metric {
        case "Sleep Duration":
            return String(format: "%.1fh", value)
        case "HRV":
            return "\(Int(value)) ms"
        case "RHR":
            return "\(Int(value)) bpm"
        default:
            if value >= 100 {
                return String(format: "%.0f", value)
            } else if value >= 10 {
                return String(format: "%.1f", value)
            } else {
                return String(format: "%.2f", value)
            }
        }
    }
}

// MARK: - Empty State Card
struct InsightsEmptyStateCard: View {
    let title: String
    let message: String
    let icon: String

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.1))
                    .frame(width: 60, height: 60)

                Image(systemName: icon)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
            }

            VStack(spacing: 8) {
                Text(title)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Text(message)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .multilineTextAlignment(.center)
                    .lineSpacing(4)
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

// MARK: - Section Header
struct InsightsSectionHeader: View {
    let title: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }

            Text(title)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            Spacer()
        }
    }
}

// MARK: - Health Trend Card
struct HealthTrendCard: View {
    let trend: HealthTrend

    var body: some View {
        HStack(spacing: 16) {
            // Icon
            ZStack {
                Circle()
                    .fill(trend.color.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: trend.icon)
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundColor(trend.color)
            }

            // Content
            VStack(alignment: .leading, spacing: 6) {
                Text(trend.title)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Text(trend.description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(2)

                HStack(spacing: 8) {
                    Text(formatValueWithUnit(trend.previousValue, metric: trend.metric))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))

                    Image(systemName: "arrow.right")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.3))

                    Text(formatValueWithUnit(trend.currentValue, metric: trend.metric))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(trend.color)
                }
            }

            Spacer()

            // Change indicator
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Image(systemName: trend.isPositive ? "arrow.up.right" : "arrow.down.right")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(trend.isPositive ? .green : .red)

                    Text(trend.changeDescription)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(trend.isPositive ? .green : .red)
                }

                Text("7-day avg")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(trend.color.opacity(0.2), lineWidth: 1.5)
                )
        )
    }

    private func formatValueWithUnit(_ value: Double, metric: String) -> String {
        switch metric {
        case "RHR":
            return "\(Int(value)) bpm"
        case "HRV":
            return "\(Int(value)) ms"
        case "Sleep":
            return String(format: "%.1fh", value)
        case "Steps":
            return String(format: "%.0f", value)
        case "Calories":
            return "\(Int(value)) cal"
        default:
            if value >= 100 {
                return String(format: "%.0f", value)
            } else if value >= 10 {
                return String(format: "%.1f", value)
            } else {
                return String(format: "%.2f", value)
            }
        }
    }
}

// MARK: - Loading Skeleton
struct InsightsLoadingSkeleton: View {
    @State private var isAnimating = false

    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<3, id: \.self) { _ in
                HStack(spacing: 16) {
                    Circle()
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 44, height: 44)

                    VStack(alignment: .leading, spacing: 8) {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 16)
                            .frame(maxWidth: 120)

                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 14)
                            .frame(maxWidth: 80)
                    }

                    Spacer()

                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 60, height: 24)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 16)
                        .fill(Color.white.opacity(0.05))
                )
            }
        }
        .opacity(isAnimating ? 0.5 : 1.0)
        .animation(
            Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: true),
            value: isAnimating
        )
        .onAppear {
            isAnimating = true
        }
    }
}
