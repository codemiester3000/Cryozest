//
//  StepsDetailView.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//

import SwiftUI

struct StepsDetailView: View {
    @ObservedObject var model: RecoveryGraphModel
    @ObservedObject var goalManager = StepGoalManager.shared

    @State private var stepsHistory: [Date: Double] = [:]
    @State private var isLoadingHistory = true

    private var steps: Int {
        Int(model.mostRecentSteps ?? 0)
    }

    private var goalProgress: Double {
        min(Double(steps) / Double(goalManager.dailyStepGoal), 1.0)
    }

    private var last7Days: [Date] {
        let calendar = Calendar.current
        return (0..<7).compactMap { daysAgo in
            calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: Date()))
        }
    }

    private var daysGoalMet: Int {
        stepsHistory.filter { $0.value >= Double(goalManager.dailyStepGoal) }.count
    }

    private var averageStepsLast7Days: Int {
        let calendar = Calendar.current
        let last7Days = (0..<7).compactMap { daysAgo in
            calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: Date()))
        }

        let stepsInLast7Days = last7Days.compactMap { stepsHistory[$0] }
        guard !stepsInLast7Days.isEmpty else { return 0 }
        return Int(stepsInLast7Days.reduce(0, +) / Double(stepsInLast7Days.count))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Current value
            VStack(spacing: 8) {
                Text("Steps Today")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(steps)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.green)

                    Text("steps")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.green.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.green.opacity(0.3), lineWidth: 1)
                    )
            )

            // Goal progress
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    Text("Daily Goal (\(goalManager.dailyStepGoal.formatted()) steps)")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))

                    Spacer()

                    Text("\(Int(goalProgress * 100))%")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(.green)
                }

                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 10)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [.green, .green.opacity(0.7)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * goalProgress, height: 10)
                    }
                }
                .frame(height: 10)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )

            // Statistics grid
            if !isLoadingHistory {
                HStack(spacing: 12) {
                    StatCard(
                        icon: "calendar.badge.checkmark",
                        label: "Goal Met",
                        value: "\(daysGoalMet)/7 days"
                    )

                    StatCard(
                        icon: "chart.line.uptrend.xyaxis",
                        label: "7-Day Avg",
                        value: "\(averageStepsLast7Days)"
                    )
                }
            }

            // Last 14 days history
            if isLoadingHistory {
                HStack {
                    Spacer()
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .green))
                    Spacer()
                }
                .padding()
            } else {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Last 7 Days")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))

                    VStack(spacing: 8) {
                        ForEach(last7Days, id: \.self) { date in
                            DayStepRow(
                                date: date,
                                steps: Int(stepsHistory[date] ?? 0),
                                goal: goalManager.dailyStepGoal
                            )
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
            }

            // Distance estimate
            let distanceKm = Double(steps) * 0.000762
            VStack(alignment: .leading, spacing: 8) {
                Text("Estimated Distance")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))

                Text(String(format: "%.2f km", distanceKm))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.white)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )

            // Info card
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)

                    Text("About Steps")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                }

                Text("Regular walking improves cardiovascular health, strengthens bones, and boosts mood. Set a goal that challenges you while remaining achievable.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.green.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.green.opacity(0.2), lineWidth: 1)
                    )
            )
        }
        .onAppear {
            loadStepsHistory()
        }
    }

    private func loadStepsHistory() {
        isLoadingHistory = true
        HealthKitManager.shared.fetchStepsForLastNDays(numberOfDays: 7) { history in
            stepsHistory = history
            isLoadingHistory = false
        }
    }
}

struct StatCard: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.green)

            VStack(spacing: 4) {
                Text(value)
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Text(label)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.green.opacity(0.2), lineWidth: 1)
                )
        )
    }
}

struct DayStepRow: View {
    let date: Date
    let steps: Int
    let goal: Int

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return formatter
    }

    private var progress: Double {
        min(Double(steps) / Double(goal), 1.0)
    }

    private var isToday: Bool {
        Calendar.current.isDateInToday(date)
    }

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(dateFormatter.string(from: date))
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))

                    if isToday {
                        Text("Today")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.cyan)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.cyan.opacity(0.15))
                            )
                    }
                }

                Text("\(steps.formatted()) steps")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            // Goal achievement indicator
            if steps >= goal {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.green)
            } else {
                Text("\(Int(progress * 100))%")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
            }

            // Mini progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.1))
                        .frame(width: 60, height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(steps >= goal ? Color.green : Color.orange)
                        .frame(width: 60 * progress, height: 6)
                }
            }
            .frame(width: 60, height: 6)
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(steps >= goal ? Color.green.opacity(0.05) : Color.white.opacity(0.03))
        )
    }
}
