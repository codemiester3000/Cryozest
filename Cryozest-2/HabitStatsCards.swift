//
//  HabitStatsCards.swift
//  Cryozest-2
//
//  UI components for habit statistics
//

import SwiftUI

// MARK: - Streak Card

struct StreakCard: View {
    let currentStreak: Int
    let bestStreak: Int
    let habitColor: Color

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 16) {
                // Current Streak
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.orange)

                        Text("\(currentStreak)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Text("Day Streak")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)

                // Divider
                Rectangle()
                    .fill(Color.white.opacity(0.15))
                    .frame(width: 1, height: 50)

                // Best Streak
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        Image(systemName: "trophy.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.yellow)

                        Text("\(bestStreak)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }

                    Text("Best Streak")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.12), Color.white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(habitColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

// MARK: - Quick Stats Card

struct QuickStatsCard: View {
    let stats: HabitStats
    let habitColor: Color

    private var weekComparison: String {
        let diff = stats.thisWeekCount - stats.lastWeekCount
        if diff > 0 {
            return "+\(diff)"
        } else if diff < 0 {
            return "\(diff)"
        } else {
            return "–"
        }
    }

    private var weekComparisonColor: Color {
        let diff = stats.thisWeekCount - stats.lastWeekCount
        if diff > 0 {
            return .green
        } else if diff < 0 {
            return .red
        } else {
            return .white.opacity(0.4)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                // Total Sessions
                StatItem(
                    value: "\(stats.totalSessions)",
                    label: "Total Sessions",
                    color: habitColor
                )

                // This Week
                StatItem(
                    value: "\(stats.thisWeekCount)",
                    label: "This Week",
                    color: habitColor,
                    badge: weekComparison,
                    badgeColor: weekComparisonColor
                )
            }

            HStack(spacing: 12) {
                // This Month
                StatItem(
                    value: "\(stats.thisMonthCount)",
                    label: "This Month",
                    color: habitColor
                )

                // Avg Per Week
                StatItem(
                    value: String(format: "%.1f", stats.averagePerWeek),
                    label: "Avg/Week",
                    color: habitColor
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.12), Color.white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(habitColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct StatItem: View {
    let value: String
    let label: String
    let color: Color
    var badge: String? = nil
    var badgeColor: Color? = nil

    var body: some View {
        VStack(spacing: 6) {
            HStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                        .foregroundColor(badgeColor ?? .white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill((badgeColor ?? .white).opacity(0.15))
                        )
                }
            }

            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }
}

// MARK: - Goals Card

struct GoalsCard: View {
    let weeklyGoal: Int
    let currentProgress: Int
    let habitColor: Color

    private var progress: Double {
        guard weeklyGoal > 0 else { return 0 }
        return min(Double(currentProgress) / Double(weeklyGoal), 1.0)
    }

    private var remaining: Int {
        max(0, weeklyGoal - currentProgress)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Goal")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text("\(currentProgress)/\(weeklyGoal) sessions")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                if remaining > 0 {
                    Text("\(remaining) more")
                        .font(.system(size: 13, weight: .semibold, design: .rounded))
                        .foregroundColor(habitColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(habitColor.opacity(0.15))
                        )
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Goal Met!")
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.15))
                    )
                }
            }

            // Progress Bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 12)

                    // Progress
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [habitColor, habitColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progress, height: 12)
                }
            }
            .frame(height: 12)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.12), Color.white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(habitColor.opacity(0.3), lineWidth: 1)
                )
        )
    }
}
