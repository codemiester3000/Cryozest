//
//  WeeklyHeatmapView.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//  Weekly consistency heatmap showing session activity
//

import SwiftUI
import CoreData

struct WeeklyHeatmapView: View {
    let sessions: [TherapySessionEntity]
    let therapyType: TherapyType
    let weeks: Int = 4

    private var heatmapData: [[Bool]] {
        var data: [[Bool]] = []
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        let today = Date()

        // Find the Monday of the current week
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday - 2 + 7) % 7
        guard let thisMonday = calendar.date(byAdding: .day, value: -daysFromMonday, to: calendar.startOfDay(for: today)) else {
            return []
        }

        // Build data for the last N weeks (Monday-Sunday)
        for week in (0..<weeks).reversed() {
            var weekData: [Bool] = []
            guard let weekStart = calendar.date(byAdding: .day, value: -(week * 7), to: thisMonday) else {
                data.append(Array(repeating: false, count: 7))
                continue
            }

            for day in 0..<7 {
                guard let targetDate = calendar.date(byAdding: .day, value: day, to: weekStart) else {
                    weekData.append(false)
                    continue
                }

                let hasSession = sessions.contains { session in
                    guard let sessionDate = session.date,
                          session.therapyType == therapyType.rawValue else {
                        return false
                    }
                    return calendar.isDate(sessionDate, inSameDayAs: targetDate)
                }
                weekData.append(hasSession)
            }
            data.append(weekData)
        }

        return data
    }

    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(therapyType.color)

                Text("Weekly Consistency")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
            }

            VStack(spacing: 8) {
                // Day labels
                HStack(spacing: 8) {
                    ForEach(0..<7, id: \.self) { day in
                        Text(dayLabels[day])
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(maxWidth: .infinity)
                    }
                }

                // Heatmap grid
                ForEach(0..<weeks, id: \.self) { week in
                    HStack(spacing: 8) {
                        ForEach(0..<7, id: \.self) { day in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(heatmapData[week][day] ? therapyType.color : Color.white.opacity(0.1))
                                .frame(maxWidth: .infinity)
                                .aspectRatio(1, contentMode: .fit)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 4)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                    }
                }

                // Legend
                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 12, height: 12)
                        Text("No session")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }

                    HStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(therapyType.color)
                            .frame(width: 12, height: 12)
                        Text("Session completed")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
                }
                .padding(.top, 4)
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
