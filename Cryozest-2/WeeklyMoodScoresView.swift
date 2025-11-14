//
//  WeeklyMoodScoresView.swift
//  Cryozest-2
//
//  Collapsible view showing mood scores for the last 4 weeks (Monday-Sunday)
//

import SwiftUI

struct WeeklyMoodScoresView: View {
    let ratings: [WellnessRating]

    @State private var isExpanded = false

    // Calculate weekly mood data for last 4 complete weeks (Monday-Sunday)
    private var weeklyData: [WeekMoodData] {
        let calendar = Calendar.current
        let today = Date()

        // Find the most recent Monday
        var components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: today)
        guard let mostRecentMonday = calendar.date(from: components) else {
            return []
        }

        return (1...4).compactMap { weekOffset -> WeekMoodData? in
            // Calculate week start (Monday) for each previous complete week
            guard let weekStart = calendar.date(byAdding: .weekOfYear, value: -weekOffset, to: mostRecentMonday),
                  let weekEnd = calendar.date(byAdding: .day, value: 6, to: weekStart) else {
                return nil
            }

            // Get ratings for each day of the week
            var dailyRatings: [Int?] = []
            var totalScore: Double = 0
            var ratingCount = 0

            for dayOffset in 0..<7 {
                guard let dayDate = calendar.date(byAdding: .day, value: dayOffset, to: weekStart) else {
                    dailyRatings.append(nil)
                    continue
                }

                // Find rating for this specific day
                let dayRating = ratings.first { rating in
                    guard let ratingDate = rating.date else { return false }
                    return calendar.isDate(ratingDate, inSameDayAs: dayDate)
                }

                if let rating = dayRating {
                    let score = Int(rating.rating)
                    dailyRatings.append(score)
                    totalScore += Double(score)
                    ratingCount += 1
                } else {
                    dailyRatings.append(nil)
                }
            }

            guard ratingCount > 0 else {
                return nil
            }

            let average = totalScore / Double(ratingCount)

            // Format week label
            let weekLabel = formatWeekLabel(start: weekStart, end: weekEnd)

            return WeekMoodData(
                weekLabel: weekLabel,
                averageScore: average,
                ratingCount: ratingCount,
                weekOffset: weekOffset,
                dailyRatings: dailyRatings,
                weekStart: weekStart
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
                            .onTapGesture {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) {
                                    isExpanded = false
                                }
                            }
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
    let dailyRatings: [Int?] // Mon-Sun ratings (nil if no rating)
    let weekStart: Date
}

struct WeekMoodRow: View {
    let data: WeekMoodData
    let color: Color

    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    private func colorForRating(_ rating: Int) -> Color {
        switch rating {
        case 5: return .green
        case 4: return Color(red: 0.6, green: 0.9, blue: 0.3)
        case 3: return .yellow
        case 2: return .orange
        case 1: return .red
        default: return .white.opacity(0.1)
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Top row: Week label, average score
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(data.weekLabel)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.white)

                    Text("\(data.ratingCount)/7 days")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                // Large average score
                VStack(spacing: 2) {
                    Text(String(format: "%.1f", data.averageScore))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(color)

                    Text("avg")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            // Daily ratings row
            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { index in
                    VStack(spacing: 4) {
                        // Day label
                        Text(dayLabels[index])
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))

                        // Rating circle
                        ZStack {
                            Circle()
                                .fill(data.dailyRatings[index] != nil ? colorForRating(data.dailyRatings[index]!) : Color.white.opacity(0.1))
                                .frame(width: 32, height: 32)

                            if let rating = data.dailyRatings[index] {
                                Text("\(rating)")
                                    .font(.system(size: 13, weight: .bold))
                                    .foregroundColor(.white)
                            } else {
                                Text("—")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                        }
                        .shadow(color: data.dailyRatings[index] != nil ? colorForRating(data.dailyRatings[index]!).opacity(0.3) : Color.clear, radius: 4, x: 0, y: 2)
                    }
                    .frame(maxWidth: .infinity)
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 10)

                    // Progress with gradient
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                colors: [color, color.opacity(0.6)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * (data.averageScore / 5.0), height: 10)
                        .shadow(color: color.opacity(0.4), radius: 4, x: 0, y: 2)
                }
            }
            .frame(height: 10)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.08), Color.white.opacity(0.04)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(
                            LinearGradient(
                                colors: [color.opacity(0.4), color.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .shadow(color: color.opacity(0.15), radius: 8, x: 0, y: 4)
    }
}
