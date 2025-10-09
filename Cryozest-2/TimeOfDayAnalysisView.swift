//
//  TimeOfDayAnalysisView.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//  Breakdown of session activity by time of day
//

import SwiftUI
import CoreData

struct TimeOfDayAnalysisView: View {
    let sessions: [TherapySessionEntity]
    let therapyType: TherapyType

    enum TimeOfDay: String, CaseIterable {
        case morning = "Morning"
        case afternoon = "Afternoon"
        case evening = "Evening"
        case night = "Night"

        var icon: String {
            switch self {
            case .morning: return "sunrise.fill"
            case .afternoon: return "sun.max.fill"
            case .evening: return "sunset.fill"
            case .night: return "moon.stars.fill"
            }
        }

        var color: Color {
            switch self {
            case .morning: return .orange
            case .afternoon: return .yellow
            case .evening: return .pink
            case .night: return .purple
            }
        }

        func contains(hour: Int) -> Bool {
            switch self {
            case .morning: return hour >= 6 && hour < 12
            case .afternoon: return hour >= 12 && hour < 17
            case .evening: return hour >= 17 && hour < 21
            case .night: return hour >= 21 || hour < 6
            }
        }
    }

    private var timeDistribution: [TimeOfDay: Int] {
        let calendar = Calendar.current
        var distribution: [TimeOfDay: Int] = [:]

        sessions
            .filter { $0.therapyType == therapyType.rawValue }
            .compactMap { $0.date }
            .forEach { date in
                let hour = calendar.component(.hour, from: date)
                if let timeOfDay = TimeOfDay.allCases.first(where: { $0.contains(hour: hour) }) {
                    distribution[timeOfDay, default: 0] += 1
                }
            }

        return distribution
    }

    private var totalSessions: Int {
        timeDistribution.values.reduce(0, +)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(therapyType.color)

                Text("Time of Day Analysis")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }

            VStack(spacing: 12) {
                ForEach(TimeOfDay.allCases, id: \.self) { timeOfDay in
                    let count = timeDistribution[timeOfDay] ?? 0
                    let percentage = totalSessions > 0 ? Double(count) / Double(totalSessions) * 100 : 0

                    HStack(spacing: 12) {
                        ZStack {
                            Circle()
                                .fill(timeOfDay.color.opacity(0.2))
                                .frame(width: 32, height: 32)
                            Image(systemName: timeOfDay.icon)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(timeOfDay.color)
                        }

                        VStack(alignment: .leading, spacing: 2) {
                            Text(timeOfDay.rawValue)
                                .font(.system(size: 13, weight: .medium, design: .rounded))
                                .foregroundColor(.white)

                            Text("\(count) sessions")
                                .font(.system(size: 11, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))
                        }

                        Spacer()

                        Text(String(format: "%.0f%%", percentage))
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(timeOfDay.color)

                        // Bar
                        GeometryReader { geometry in
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.1))

                                RoundedRectangle(cornerRadius: 4)
                                    .fill(timeOfDay.color)
                                    .frame(width: geometry.size.width * CGFloat(percentage / 100))
                            }
                        }
                        .frame(width: 80, height: 8)
                    }
                }
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
