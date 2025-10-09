//
//  ProjectionWidget.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//  Goal projection based on current pace
//

import SwiftUI
import CoreData

struct ProjectionWidget: View {
    let sessions: [TherapySessionEntity]
    let therapyType: TherapyType

    @ObservedObject private var goalManager = GoalManager.shared

    private var monthlyGoal: Int {
        goalManager.getMonthlyGoal(for: therapyType)
    }

    private var projectedTotal: Int {
        let calendar = Calendar.current
        let today = Date()
        let month = calendar.component(.month, from: today)
        let year = calendar.component(.year, from: today)

        // Get start of current month
        let components = DateComponents(year: year, month: month, day: 1)
        guard let monthStart = calendar.date(from: components) else { return 0 }

        // Count sessions this month
        let sessionsThisMonth = sessions.filter { session in
            guard let date = session.date,
                  session.therapyType == therapyType.rawValue else {
                return false
            }
            return date >= monthStart && date <= today
        }.count

        // Calculate days elapsed and total days in month
        let daysElapsed = calendar.dateComponents([.day], from: monthStart, to: today).day ?? 0
        let range = calendar.range(of: .day, in: .month, for: today)
        let totalDays = range?.count ?? 30

        // Project based on pace
        guard daysElapsed > 0 else { return 0 }
        let pace = Double(sessionsThisMonth) / Double(daysElapsed)
        return Int(pace * Double(totalDays))
    }

    private var currentMonthSessions: Int {
        let calendar = Calendar.current
        let today = Date()
        let month = calendar.component(.month, from: today)
        let year = calendar.component(.year, from: today)

        let components = DateComponents(year: year, month: month, day: 1)
        guard let monthStart = calendar.date(from: components) else { return 0 }

        return sessions.filter { session in
            guard let date = session.date,
                  session.therapyType == therapyType.rawValue else {
                return false
            }
            return date >= monthStart && date <= today
        }.count
    }

    private var progressPercentage: Double {
        guard monthlyGoal > 0 else { return 0 }
        return min(Double(currentMonthSessions) / Double(monthlyGoal), 1.0) * 100
    }

    private var isOnTrack: Bool {
        projectedTotal >= monthlyGoal
    }

    var body: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(therapyType.color)

                Text("Monthly Projection")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                HStack(spacing: 4) {
                    Image(systemName: isOnTrack ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(isOnTrack ? .green : .orange)

                    Text(isOnTrack ? "On Track" : "Behind")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(isOnTrack ? .green : .orange)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill((isOnTrack ? Color.green : Color.orange).opacity(0.15))
                )
            }

            HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Current")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(currentMonthSessions)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text("/ \(monthlyGoal)")
                            .font(.system(size: 16, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    // Progress bar
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.1))

                            RoundedRectangle(cornerRadius: 4)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            therapyType.color,
                                            therapyType.color.opacity(0.7)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * CGFloat(progressPercentage / 100))
                        }
                    }
                    .frame(height: 8)
                }

                Divider()
                    .background(Color.white.opacity(0.2))

                VStack(alignment: .leading, spacing: 8) {
                    Text("Projected")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))

                    Text("\(projectedTotal)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(isOnTrack ? .green : .orange)

                    Text("sessions")
                        .font(.system(size: 12, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .frame(maxWidth: .infinity)

            if !isOnTrack && projectedTotal < monthlyGoal {
                let needed = monthlyGoal - projectedTotal
                HStack(spacing: 4) {
                    Image(systemName: "lightbulb.fill")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.yellow)

                    Text("Add \(needed) more session\(needed == 1 ? "" : "s") to reach your goal")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding(8)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.yellow.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 8)
                                .stroke(Color.yellow.opacity(0.2), lineWidth: 1)
                        )
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
