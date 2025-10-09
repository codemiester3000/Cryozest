//
//  PersonalBestsView.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//  Personal records and achievements
//

import SwiftUI
import CoreData

struct PersonalBestsView: View {
    let sessions: [TherapySessionEntity]
    let therapyType: TherapyType

    private var longestSession: (duration: TimeInterval, date: Date)? {
        sessions
            .filter { $0.therapyType == therapyType.rawValue }
            .compactMap { session -> (TimeInterval, Date)? in
                guard let date = session.date else { return nil }
                return (session.duration, date)
            }
            .max { $0.0 < $1.0 }
    }

    private var longestStreak: Int {
        var maxStreak = 0
        var currentStreak = 0
        var previousDate: Date?

        let sortedSessions = sessions
            .filter { $0.therapyType == therapyType.rawValue }
            .compactMap { $0.date }
            .sorted()

        for date in sortedSessions {
            if let prev = previousDate {
                let daysDiff = Calendar.current.dateComponents([.day], from: prev, to: date).day ?? 0
                if daysDiff == 1 {
                    currentStreak += 1
                } else if daysDiff > 1 {
                    maxStreak = max(maxStreak, currentStreak)
                    currentStreak = 1
                }
            } else {
                currentStreak = 1
            }
            previousDate = date
        }

        return max(maxStreak, currentStreak)
    }

    private var mostSessionsInWeek: Int {
        let grouped = Dictionary(grouping: sessions.filter { $0.therapyType == therapyType.rawValue }) { session -> String in
            guard let date = session.date else { return "" }
            let calendar = Calendar.current
            let week = calendar.component(.weekOfYear, from: date)
            let year = calendar.component(.year, from: date)
            return "\(year)-\(week)"
        }

        return grouped.values.map { $0.count }.max() ?? 0
    }

    private var totalSessionsAllTime: Int {
        sessions.filter { $0.therapyType == therapyType.rawValue }.count
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.yellow)

                Text("Personal Bests")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                BestCard(
                    icon: "timer",
                    title: "Longest Session",
                    value: formatDuration(longestSession?.duration ?? 0),
                    subtitle: longestSession != nil ? dateFormatter.string(from: longestSession!.date) : "N/A",
                    color: therapyType.color
                )

                BestCard(
                    icon: "flame.fill",
                    title: "Best Streak",
                    value: "\(longestStreak)",
                    subtitle: longestStreak == 1 ? "day" : "days",
                    color: .orange
                )

                BestCard(
                    icon: "calendar",
                    title: "Best Week",
                    value: "\(mostSessionsInWeek)",
                    subtitle: mostSessionsInWeek == 1 ? "session" : "sessions",
                    color: .cyan
                )

                BestCard(
                    icon: "chart.bar.fill",
                    title: "Total Sessions",
                    value: "\(totalSessionsAllTime)",
                    subtitle: "all time",
                    color: .green
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

    private func formatDuration(_ duration: TimeInterval) -> String {
        let hours = Int(duration) / 3600
        let minutes = (Int(duration) % 3600) / 60

        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

struct BestCard: View {
    let icon: String
    let title: String
    let value: String
    let subtitle: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(color.opacity(0.2))
                    )

                Spacer()
            }

            Text(title)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))
                .lineLimit(1)

            Text(value)
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(subtitle)
                .font(.system(size: 10, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.5))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}
