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
                        ZStack {
                            // Glow effect
                            if currentStreak > 0 {
                                Circle()
                                    .fill(Color.orange.opacity(0.3))
                                    .frame(width: 32, height: 32)
                                    .blur(radius: 8)
                            }
                            Image(systemName: "flame.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.orange, .red],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }

                        Text("\(currentStreak)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Text("Day Streak")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)

                // Divider with gradient
                Rectangle()
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.05), Color.white.opacity(0.2), Color.white.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                    .frame(width: 1, height: 50)

                // Best Streak
                VStack(spacing: 6) {
                    HStack(spacing: 6) {
                        ZStack {
                            // Glow effect
                            if bestStreak > 0 {
                                Circle()
                                    .fill(Color.yellow.opacity(0.3))
                                    .frame(width: 32, height: 32)
                                    .blur(radius: 8)
                            }
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(
                                    LinearGradient(
                                        colors: [.yellow, .orange],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                        }

                        Text("\(bestStreak)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                    }

                    Text("Best Streak")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(16)
        }
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.12), Color.white.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Top highlight
                VStack {
                    RoundedRectangle(cornerRadius: 16)
                        .fill(
                            LinearGradient(
                                colors: [Color.white.opacity(0.1), Color.clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(height: 40)
                    Spacer()
                }
                .clipShape(RoundedRectangle(cornerRadius: 16))
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
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
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.12), Color.white.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Subtle color tint from habit
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [habitColor.opacity(0.08), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
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
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)

                if let badge = badge {
                    Text(badge)
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(badgeColor ?? .white)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill((badgeColor ?? .white).opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke((badgeColor ?? .white).opacity(0.3), lineWidth: 0.5)
                                )
                        )
                }
            }

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.08), Color.white.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.08), lineWidth: 0.5)
                )
        )
    }
}

// MARK: - Goals Card

struct GoalsCard: View {
    let weeklyGoal: Int
    let currentProgress: Int
    let habitColor: Color

    @State private var animateProgress = false

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
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)

                    Text("\(currentProgress)/\(weeklyGoal) sessions")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                if remaining > 0 {
                    Text("\(remaining) more")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(habitColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(habitColor.opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(habitColor.opacity(0.3), lineWidth: 0.5)
                                )
                        )
                } else {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Goal Met!")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.2))
                            .overlay(
                                Capsule()
                                    .stroke(Color.green.opacity(0.3), lineWidth: 0.5)
                            )
                    )
                }
            }

            // Progress Bar with glow
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 12)

                    // Glow layer
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [habitColor.opacity(0.8), habitColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: animateProgress ? geometry.size.width * progress : 0, height: 12)
                        .blur(radius: 4)
                        .opacity(0.5)

                    // Progress
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [habitColor.opacity(0.9), habitColor],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: animateProgress ? geometry.size.width * progress : 0, height: 12)
                        .overlay(
                            // Shine effect
                            RoundedRectangle(cornerRadius: 8)
                                .fill(
                                    LinearGradient(
                                        colors: [Color.white.opacity(0.3), Color.clear],
                                        startPoint: .top,
                                        endPoint: .bottom
                                    )
                                )
                                .frame(height: 6)
                                .offset(y: -3)
                                .mask(
                                    RoundedRectangle(cornerRadius: 8)
                                        .frame(width: animateProgress ? geometry.size.width * progress : 0, height: 12)
                                )
                        )
                }
            }
            .frame(height: 12)
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [Color.white.opacity(0.12), Color.white.opacity(0.06)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )

                // Subtle color tint
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            colors: [habitColor.opacity(0.06), Color.clear],
                            startPoint: .top,
                            endPoint: .center
                        )
                    )
            }
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.2), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 10, x: 0, y: 5)
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.7).delay(0.2)) {
                animateProgress = true
            }
        }
    }
}
