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

                    // Weekly Mood Scores (underneath heatmap)
                    WeeklyMoodScoresView(ratings: ratings)
                        .padding(.horizontal)
                        .padding(.top, 4)
                }

                // Habit Impact
                if !impacts.isEmpty {
                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.vertical, 8)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Happiness Boosters")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal)

                        ForEach(impacts.filter { $0.isPositive }) { impact in
                            WellnessImpactCard(impact: impact, viewContext: viewContext)
                                .padding(.horizontal)
                        }
                    }
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
            Text("30-Day Mood Heatmap")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(.white.opacity(0.7))

            // Heatmap
            MoodHeatmap(ratings: ratings)

            // Legend
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 12) {
                    MoodLegendItem(rating: 5, label: "Excellent")
                    MoodLegendItem(rating: 4, label: "Good")
                    MoodLegendItem(rating: 3, label: "Okay")
                }
                HStack(spacing: 12) {
                    MoodLegendItem(rating: 2, label: "Not great")
                    MoodLegendItem(rating: 1, label: "Terrible")
                    HStack(spacing: 6) {
                        RoundedRectangle(cornerRadius: 2)
                            .fill(Color.white.opacity(0.1))
                            .frame(width: 12, height: 12)
                        Text("No rating")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                    }
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

    private let columns = 7

    // Get last 30 days
    private var last30Days: [Date] {
        let calendar = Calendar.current
        let today = Date()
        return (0..<30).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: -dayOffset, to: today)
        }.reversed()
    }

    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()

    private let monthFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM"
        return formatter
    }()

    private let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM yyyy"
        return formatter
    }()

    // Get the month range being displayed
    private var dateRangeText: String {
        guard let firstDate = last30Days.first,
              let lastDate = last30Days.last else {
            return ""
        }

        let calendar = Calendar.current
        let firstMonth = calendar.component(.month, from: firstDate)
        let lastMonth = calendar.component(.month, from: lastDate)
        let firstYear = calendar.component(.year, from: firstDate)
        let lastYear = calendar.component(.year, from: lastDate)

        if firstMonth == lastMonth && firstYear == lastYear {
            // Same month
            return monthYearFormatter.string(from: firstDate)
        } else if firstYear == lastYear {
            // Same year, different months
            return "\(monthFormatter.string(from: firstDate)) - \(monthYearFormatter.string(from: lastDate))"
        } else {
            // Different years
            return "\(monthYearFormatter.string(from: firstDate)) - \(monthYearFormatter.string(from: lastDate))"
        }
    }

    // Get rating for a specific date
    private func getRating(for date: Date) -> Int? {
        let calendar = Calendar.current
        for rating in ratings {
            if let ratingDate = rating.date {
                if calendar.isDate(ratingDate, inSameDayAs: date) {
                    return Int(rating.rating)
                }
            }
        }
        return nil
    }

    // Get color for rating - red to green gradient
    private func colorForRating(_ rating: Int?) -> Color {
        guard let rating = rating else {
            return Color.white.opacity(0.1)
        }

        switch rating {
        case 5: return Color.green                           // Best
        case 4: return Color(red: 0.6, green: 0.9, blue: 0.3) // Yellow-green
        case 3: return Color.yellow                           // Neutral
        case 2: return Color.orange                           // Orange-red
        case 1: return Color.red                              // Worst
        default: return Color.white.opacity(0.1)
        }
    }

    // Group dates by month
    private var datesByMonth: [(monthLabel: String, dates: [Date])] {
        let calendar = Calendar.current
        var grouped: [(String, [Date])] = []

        for date in last30Days {
            let monthLabel = monthYearFormatter.string(from: date)

            if let lastIndex = grouped.indices.last, grouped[lastIndex].0 == monthLabel {
                grouped[lastIndex].1.append(date)
            } else {
                grouped.append((monthLabel, [date]))
            }
        }

        return grouped
    }

    var body: some View {
        VStack(spacing: 12) {
            // Date range header
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))

                Text(dateRangeText)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))

                Spacer()
            }

            // Heatmap grid - organized by month
            VStack(spacing: 4) {
                ForEach(Array(datesByMonth.enumerated()), id: \.offset) { monthIndex, monthGroup in
                    VStack(spacing: 6) {
                        // Month label and divider
                        HStack(spacing: 8) {
                            Text(monthGroup.monthLabel)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.7))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule()
                                        .fill(Color.white.opacity(0.1))
                                        .overlay(
                                            Capsule()
                                                .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                        )
                                )

                            Rectangle()
                                .fill(Color.white.opacity(0.2))
                                .frame(height: 1)
                        }
                        .padding(.top, monthIndex > 0 ? 12 : 0)

                        // Day labels for this month (show first 7 days to get weekday labels)
                        HStack(spacing: 4) {
                            ForEach(0..<min(7, monthGroup.dates.count), id: \.self) { col in
                                Text(String(dayFormatter.string(from: monthGroup.dates[col]).prefix(1)))
                                    .font(.system(size: 10, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.5))
                                    .frame(maxWidth: .infinity)
                            }
                            // Fill remaining columns if less than 7 days
                            if monthGroup.dates.count < 7 {
                                ForEach(monthGroup.dates.count..<7, id: \.self) { _ in
                                    Color.clear.frame(maxWidth: .infinity)
                                }
                            }
                        }

                        // Grid for this month's dates
                        let monthRows = Int(ceil(Double(monthGroup.dates.count) / Double(columns)))
                        VStack(spacing: 4) {
                            ForEach(0..<monthRows, id: \.self) { row in
                                HStack(spacing: 4) {
                                    ForEach(0..<columns, id: \.self) { col in
                                        let index = row * columns + col
                                        if index < monthGroup.dates.count {
                                            let date = monthGroup.dates[index]
                                            let rating = getRating(for: date)
                                            let isToday = Calendar.current.isDateInToday(date)
                                            let dayNumber = Calendar.current.component(.day, from: date)

                                            ZStack {
                                                RoundedRectangle(cornerRadius: 4)
                                                    .fill(colorForRating(rating))
                                                    .frame(height: 32)

                                                // Day number
                                                Text("\(dayNumber)")
                                                    .font(.system(size: 9, weight: .semibold))
                                                    .foregroundColor(rating != nil ? Color.white : Color.white.opacity(0.3))

                                                // Today indicator ring
                                                if isToday {
                                                    RoundedRectangle(cornerRadius: 4)
                                                        .stroke(Color.white, lineWidth: 2)
                                                        .frame(height: 32)
                                                }
                                            }
                                        } else {
                                            // Empty space for incomplete rows
                                            RoundedRectangle(cornerRadius: 4)
                                                .fill(Color.clear)
                                                .frame(height: 32)
                                        }
                                    }
                                }
                            }
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
        case 1: return .red                              // Worst
        default: return .white.opacity(0.1)
        }
    }

    var body: some View {
        HStack(spacing: 6) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
    }
}
