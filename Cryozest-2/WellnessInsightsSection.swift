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

                // Habit Impact
                if !impacts.isEmpty {
                    Divider()
                        .background(Color.white.opacity(0.2))
                        .padding(.vertical, 8)
                        .padding(.horizontal)

                    VStack(alignment: .leading, spacing: 12) {
                        Text("Happiness Boosters")
                            .font(.system(size: 16, weight: .semibold, design: .rounded))
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
                        .font(.system(size: 12, weight: .medium, design: .rounded))
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
                            .font(.system(size: 24, weight: .bold, design: .rounded))
                            .foregroundColor(.white)

                        Text(moodLabel)
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundColor(moodColor)
                    }
                }

                Spacer()

                // Change indicator with percentage
                VStack(spacing: 3) {
                    if let change = change, let percentChange = percentageChange, abs(change) >= 0.1 {
                        HStack(spacing: 4) {
                            Image(systemName: change >= 0 ? "arrow.up" : "arrow.down")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(change >= 0 ? .green : .red)

                            Text(String(format: "%.0f%%", abs(percentChange)))
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(change >= 0 ? .green : .red)
                        }

                        Text(String(format: "%+.1f", change))
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.6))
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "minus")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white.opacity(0.4))

                            Text("–")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.4))
                        }

                        Text("vs last week")
                            .font(.system(size: 11, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.08))
                )
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
            Text("30-Day Trend")
                .font(.system(size: 15, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.7))

            Chart(trendData) { dataPoint in
                LineMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Rating", dataPoint.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.pink, Color.purple],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))

                AreaMark(
                    x: .value("Date", dataPoint.date),
                    y: .value("Rating", dataPoint.value)
                )
                .foregroundStyle(
                    LinearGradient(
                        colors: [Color.pink.opacity(0.3), Color.purple.opacity(0.1)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
            }
            .chartYScale(domain: 0...5)
            .chartXAxis {
                AxisMarks(values: .stride(by: .day, count: 7)) { _ in
                    AxisValueLabel(format: .dateTime.month().day(), centered: true)
                        .foregroundStyle(Color.white.opacity(0.5))
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisValueLabel()
                        .foregroundStyle(Color.white.opacity(0.5))
                }
            }
            .frame(height: 200)
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
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

                Text(impact.habitType.icon)
                    .font(.system(size: 24))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(impact.habitType.displayName(viewContext))
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Text("\(String(format: "%.1f", impact.averageRatingWithHabit))★ with vs \(String(format: "%.1f", impact.averageRatingWithoutHabit))★ without")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            // Impact badge
            Text(impact.impactDescription)
                .font(.system(size: 18, weight: .bold, design: .rounded))
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
