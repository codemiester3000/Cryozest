//
//  WellnessInsightsSection.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//

import SwiftUI
import CoreData
import Charts

struct WellnessInsightsSection: View {
    @Environment(\.managedObjectContext) private var viewContext

    let ratings: [WellnessRating]
    let sessions: [TherapySessionEntity]
    let therapyTypes: [TherapyType]

    private var weeklyAverage: Double? {
        WellnessImpactAnalyzer.weeklyAverage(ratings: ratings)
    }

    private var previousWeekAverage: Double? {
        WellnessImpactAnalyzer.previousWeekAverage(ratings: ratings)
    }

    private var impacts: [WellnessImpact] {
        WellnessImpactAnalyzer.calculateImpacts(
            ratings: ratings,
            sessions: sessions,
            therapyTypes: therapyTypes
        )
    }

    private var trendData: [TrendDataPoint] {
        WellnessImpactAnalyzer.getTrendData(ratings: ratings)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            InsightsSectionHeader(
                title: "Wellness Trends",
                icon: "heart.fill",
                color: .pink
            )
            .padding(.horizontal)

            if ratings.isEmpty {
                InsightsEmptyStateCard(
                    title: "Start Rating Your Days",
                    message: "Check in daily on the home screen to track your wellness and see which habits make you feel best.",
                    icon: "star.fill"
                )
                .padding(.horizontal)
            } else {
                // Weekly Average
                if let average = weeklyAverage {
                    weeklyAverageCard(average: average)
                        .padding(.horizontal)
                }

                // Trend Chart
                if trendData.count >= 3 {
                    wellnessTrendChart
                        .padding(.horizontal)
                }

            }
        }
    }

    private func weeklyAverageCard(average: Double) -> some View {
        let previousAvg = previousWeekAverage
        let change = previousAvg != nil ? average - previousAvg! : nil
        let percentageChange = previousAvg != nil && previousAvg! > 0 ? ((average - previousAvg!) / previousAvg!) * 100 : nil

        let moodLabel: String = {
            switch average {
            case 4.5...5.0: return "Great"
            case 3.5..<4.5: return "Good"
            case 2.5..<3.5: return "Okay"
            case 1.5..<2.5: return "Not great"
            default: return "Rough"
            }
        }()

        let moodColor: Color = {
            switch average {
            case 4.5...5.0: return .cyan
            case 3.5..<4.5: return .green
            case 2.5..<3.5: return .yellow
            case 1.5..<2.5: return .orange
            default: return .red
            }
        }()

        return VStack(spacing: 12) {
            HStack(alignment: .center) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Average This Week")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))

                    HStack(spacing: 10) {
                        // Rating circles
                        HStack(spacing: 3) {
                            ForEach(1...5, id: \.self) { index in
                                Circle()
                                    .fill(Double(index) <= average ? moodColor : Color.white.opacity(0.2))
                                    .frame(width: 10, height: 10)
                            }
                        }

                        Text(String(format: "%.1f", average))
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)

                        Text(moodLabel)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(moodColor)
                    }
                }

                Spacer()

                // Change indicator with percentage
                VStack(spacing: 3) {
                    Text("vs Last Week")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                        .textCase(.uppercase)

                    if let change = change, let percentChange = percentageChange, abs(change) >= 0.1 {
                        HStack(spacing: 4) {
                            Image(systemName: change >= 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(change >= 0 ? .green : .red)

                            VStack(alignment: .leading, spacing: 2) {
                                Text(String(format: "%.0f%%", abs(percentChange)))
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(change >= 0 ? .green : .red)

                                Text(String(format: "%+.1f pts", change))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white.opacity(0.4))

                            Text("No change")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.5))
                        }
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .fill(Color.white.opacity(0.1))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                        )
                    }
                }
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
                        .stroke(
                            LinearGradient(
                                colors: [moodColor.opacity(0.4), moodColor.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
    }

    private var wellnessTrendChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Heatmap
            MoodHeatmap(ratings: ratings)

            // Legend - compact single row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    MoodLegendItem(rating: 5, label: "Excellent")
                    MoodLegendItem(rating: 4, label: "Good")
                    MoodLegendItem(rating: 3, label: "Okay")
                    MoodLegendItem(rating: 2, label: "Not great")
                    MoodLegendItem(rating: 1, label: "Terrible")
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.pink.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

struct WellnessImpactCard: View {
    let impact: WellnessImpact
    let viewContext: NSManagedObjectContext

    var body: some View {
        HStack(spacing: 16) {
            // Therapy icon
            ZStack {
                Circle()
                    .fill(impact.habitType.color.opacity(0.2))
                    .frame(width: 50, height: 50)

                Image(systemName: impact.habitType.icon)
                    .font(.system(size: 24))
                    .foregroundColor(impact.habitType.color)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(impact.habitType.displayName(viewContext))
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                Text("\(String(format: "%.1f", impact.averageRatingWithHabit))★ with vs \(String(format: "%.1f", impact.averageRatingWithoutHabit))★ without")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            // Impact badge
            Text(impact.impactDescription)
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(impact.isPositive ? Color.green : Color.orange)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(impact.isPositive ? Color.green.opacity(0.15) : Color.orange.opacity(0.15))
                )
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [impact.habitType.color.opacity(0.3), impact.habitType.color.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
    }
}

struct MoodHeatmap: View {
    let ratings: [WellnessRating]

    private let weekdayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    /// Build a proper calendar grid: 4 full weeks + current partial week, aligned to weekdays
    private var calendarGrid: [[Date?]] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Go back 28 days (4 weeks) from the start of the current week
        let todayWeekday = calendar.component(.weekday, from: today) // 1=Sun, 2=Mon...
        let mondayOffset = todayWeekday == 1 ? -6 : (2 - todayWeekday) // Offset to Monday
        let thisMonday = calendar.date(byAdding: .day, value: mondayOffset, to: today)!
        let startDate = calendar.date(byAdding: .day, value: -28, to: thisMonday)!

        var weeks: [[Date?]] = []
        var currentWeek: [Date?] = []
        var date = startDate

        while date <= today {
            currentWeek.append(date)
            if currentWeek.count == 7 {
                weeks.append(currentWeek)
                currentWeek = []
            }
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }
        // Pad the last partial week
        if !currentWeek.isEmpty {
            while currentWeek.count < 7 {
                currentWeek.append(nil)
            }
            weeks.append(currentWeek)
        }

        return weeks
    }

    private func getRating(for date: Date) -> Int? {
        let calendar = Calendar.current
        for rating in ratings {
            if let ratingDate = rating.date, calendar.isDate(ratingDate, inSameDayAs: date) {
                return Int(rating.rating)
            }
        }
        return nil
    }

    private func colorForRating(_ rating: Int?) -> Color {
        guard let rating = rating else { return Color.white.opacity(0.06) }
        switch rating {
        case 5: return Color.green
        case 4: return Color(red: 0.6, green: 0.9, blue: 0.3)
        case 3: return Color.yellow
        case 2: return Color.orange
        case 1: return Color(red: 0.9, green: 0.4, blue: 0.4)
        default: return Color.white.opacity(0.06)
        }
    }

    var body: some View {
        VStack(spacing: 8) {
            // Weekday labels
            HStack(spacing: 4) {
                ForEach(0..<7, id: \.self) { i in
                    Text(weekdayLabels[i])
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                        .frame(maxWidth: .infinity)
                }
            }

            // Calendar rows
            ForEach(Array(calendarGrid.enumerated()), id: \.offset) { _, week in
                HStack(spacing: 4) {
                    ForEach(0..<7, id: \.self) { dayIndex in
                        if let date = week[dayIndex] {
                            let rating = getRating(for: date)
                            let isToday = Calendar.current.isDateInToday(date)
                            let dayNum = Calendar.current.component(.day, from: date)

                            ZStack {
                                RoundedRectangle(cornerRadius: 6)
                                    .fill(colorForRating(rating))
                                    .frame(height: 36)

                                Text("\(dayNum)")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(rating != nil ? .white : .white.opacity(0.2))

                                if isToday {
                                    RoundedRectangle(cornerRadius: 6)
                                        .stroke(Color.white, lineWidth: 2)
                                        .frame(height: 36)
                                }
                            }
                        } else {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.clear)
                                .frame(height: 36)
                        }
                    }
                }
            }
        }
    }
}

struct MoodLegendItem: View {
    let rating: Int
    let label: String

    private var color: Color {
        switch rating {
        case 5: return .green                           // Best
        case 4: return Color(red: 0.6, green: 0.9, blue: 0.3) // Yellow-green
        case 3: return .yellow                           // Neutral
        case 2: return .orange                           // Orange-red
        case 1: return Color(red: 0.9, green: 0.4, blue: 0.4) // Softer red for worst
        default: return .white.opacity(0.1)
        }
    }

    var body: some View {
        HStack(spacing: 4) {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}
