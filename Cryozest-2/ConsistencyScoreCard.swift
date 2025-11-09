//
//  ConsistencyScoreCard.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//  Consistency score showing target achievement
//

import SwiftUI
import CoreData

struct ConsistencyScoreCard: View {
    let sessions: [TherapySessionEntity]
    let therapyType: TherapyType
    let timeFrame: TimeFrame

    @ObservedObject private var goalManager = GoalManager.shared

    private var targetDays: Int {
        switch timeFrame {
        case .week:
            return goalManager.getWeeklyGoal(for: therapyType)
        case .month:
            return goalManager.getMonthlyGoal(for: therapyType)
        case .allTime:
            return goalManager.getYearlyGoal(for: therapyType)
        }
    }

    private var consistencyScore: Double {
        let calendar = Calendar.current
        let today = Date()

        let startDate: Date
        let totalPossibleDays: Int

        switch timeFrame {
        case .week:
            startDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
            totalPossibleDays = 7
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: today)!
            totalPossibleDays = 30
        case .allTime:
            startDate = calendar.date(byAdding: .year, value: -1, to: today)!
            totalPossibleDays = 365
        }

        let sessionsInPeriod = sessions.filter { session in
            guard let date = session.date,
                  session.therapyType == therapyType.rawValue else {
                return false
            }
            return date >= startDate && date <= today
        }

        let uniqueDays = Set(sessionsInPeriod.compactMap { session -> String? in
            guard let date = session.date else { return nil }
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            return "\(components.year!)-\(components.month!)-\(components.day!)"
        })

        let daysCompleted = uniqueDays.count
        return min(Double(daysCompleted) / Double(targetDays), 1.0) * 100
    }

    private var daysCompleted: Int {
        let calendar = Calendar.current
        let today = Date()

        let startDate: Date
        switch timeFrame {
        case .week:
            startDate = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today))!
        case .month:
            startDate = calendar.date(byAdding: .month, value: -1, to: today)!
        case .allTime:
            startDate = calendar.date(byAdding: .year, value: -1, to: today)!
        }

        let sessionsInPeriod = sessions.filter { session in
            guard let date = session.date,
                  session.therapyType == therapyType.rawValue else {
                return false
            }
            return date >= startDate && date <= today
        }

        let uniqueDays = Set(sessionsInPeriod.compactMap { session -> String? in
            guard let date = session.date else { return nil }
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            return "\(components.year!)-\(components.month!)-\(components.day!)"
        })

        return uniqueDays.count
    }

    private var scoreColor: Color {
        if consistencyScore >= 80 {
            return .green
        } else if consistencyScore >= 50 {
            return .yellow
        } else {
            return .orange
        }
    }

    private var scoreLabel: String {
        if consistencyScore >= 80 {
            return "Excellent"
        } else if consistencyScore >= 50 {
            return "Good"
        } else if consistencyScore > 0 {
            return "Keep Going"
        } else {
            return "Start Strong"
        }
    }

    private var timeFrameLabel: String {
        switch timeFrame {
        case .week:
            return "This Week"
        case .month:
            return "This Month"
        case .allTime:
            return "This Year"
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "target")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(therapyType.color)

                Text("Consistency Score")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                Text(timeFrameLabel)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            ZStack {
                // Background circle
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 12)
                    .frame(width: 140, height: 140)

                // Progress circle
                Circle()
                    .trim(from: 0, to: consistencyScore / 100)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                scoreColor,
                                scoreColor.opacity(0.6)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .frame(width: 140, height: 140)
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: consistencyScore)

                VStack(spacing: 4) {
                    Text(String(format: "%.0f%%", consistencyScore))
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)

                    Text(scoreLabel)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(scoreColor)
                }
            }

            HStack(spacing: 16) {
                VStack(spacing: 4) {
                    Text("\(daysCompleted)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Text("Days Hit")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.08))
                )

                VStack(spacing: 4) {
                    Text("\(targetDays)")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Text("Goal")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.08))
                )
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.06)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }
}
