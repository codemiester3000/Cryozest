//
//  WeeklyMoodScoresView.swift
//  Cryozest-2
//
//  Collapsible view showing mood scores for the last 4 weeks
//

import SwiftUI

struct WeeklyMoodScoresView: View {
    let ratings: [WellnessRating]

    @State private var isExpanded = false

    // Calculate weekly mood data for last 4 weeks
    private var weeklyData: [WeekMoodData] {
        let calendar = Calendar.current
        let today = Date()

        return (0..<4).compactMap { weekOffset -> WeekMoodData? in
            // Calculate week start (most recent week first)
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: today) else {
                return nil
            }

            // Get all ratings for this week
            let weekRatings = ratings.filter { rating in
                guard let ratingDate = rating.date else { return false }
                let daysDiff = calendar.dateComponents([.day], from: weekStart, to: ratingDate).day ?? 0
                return daysDiff >= -6 && daysDiff <= 0
            }

            guard !weekRatings.isEmpty else {
                return nil
            }

            // Calculate average
            let sum = weekRatings.reduce(0.0) { $0 + Double($1.rating) }
            let average = sum / Double(weekRatings.count)

            // Format week label
            let weekEndDate = calendar.date(byAdding: .day, value: -1, to: weekStart) ?? weekStart
            let weekLabel = formatWeekLabel(start: calendar.date(byAdding: .day, value: -6, to: weekStart) ?? weekStart, end: weekEndDate)

            return WeekMoodData(
                weekLabel: weekLabel,
                averageScore: average,
                ratingCount: weekRatings.count,
                weekOffset: weekOffset
            )
        }
    }

    private func formatWeekLabel(start: Date, end: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"

        let calendar = Calendar.current
        let isSameMonth = calendar.component(.month, from: start) == calendar.component(.month, from: end)

        if isSameMonth {
            formatter.dateFormat = "d"
            let startDay = formatter.string(from: start)
            formatter.dateFormat = "MMM d"
            let endFormatted = formatter.string(from: end)
            return "\(endFormatted.components(separatedBy: " ")[0]) \(startDay)-\(endFormatted.components(separatedBy: " ")[1])"
        } else {
            return "\(formatter.string(from: start)) - \(formatter.string(from: end))"
        }
    }

    private func moodColor(for score: Double) -> Color {
        switch score {
        case 4.5...5.0: return .cyan
        case 3.5..<4.5: return .green
        case 2.5..<3.5: return .yellow
        case 1.5..<2.5: return .orange
        default: return .red
        }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Collapsed header
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                    isExpanded.toggle()
                }
            }) {
                HStack {
                    Image(systemName: "chart.bar.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.purple)

                    Text("Weekly Mood Scores")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    Image(systemName: "chevron.down")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.6))
                        .rotationEffect(.degrees(isExpanded ? 180 : 0))
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.purple.opacity(0.3), lineWidth: 1)
                        )
                )
            }

            // Expanded content
            if isExpanded {
                VStack(spacing: 10) {
                    ForEach(weeklyData) { weekData in
                        WeekMoodRow(data: weekData, color: moodColor(for: weekData.averageScore))
                    }
                }
                .padding(.top, 12)
            }
        }
    }
}

struct WeekMoodData: Identifiable {
    let id = UUID()
    let weekLabel: String
    let averageScore: Double
    let ratingCount: Int
    let weekOffset: Int
}

struct WeekMoodRow: View {
    let data: WeekMoodData
    let color: Color

    var body: some View {
        HStack {
            // Week label
            VStack(alignment: .leading, spacing: 4) {
                Text(data.weekLabel)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Text("\(data.ratingCount) day\(data.ratingCount == 1 ? "" : "s")")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)

                    // Progress
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (data.averageScore / 5.0), height: 8)
                }
            }
            .frame(width: 100, height: 8)

            // Score
            Text(String(format: "%.1f", data.averageScore))
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(color)
                .frame(width: 36, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
