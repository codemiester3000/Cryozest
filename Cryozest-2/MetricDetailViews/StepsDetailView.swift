//
//  StepsDetailView.swift
//  Cryozest-2
//
//  Redesigned with ring progress, streak tracking, bar chart,
//  and gamified distance milestones.
//

import SwiftUI
import Charts

struct StepsDetailView: View {
    @ObservedObject var model: RecoveryGraphModel

    @State private var stepsHistory: [Date: Double] = [:]
    @State private var isLoadingHistory = true

    private let dailyStepGoal = 10_000

    private var steps: Int { Int(model.mostRecentSteps ?? 0) }
    private var goalProgress: Double { min(Double(steps) / Double(dailyStepGoal), 1.0) }

    private var last7Days: [Date] {
        let calendar = Calendar.current
        let ref = calendar.startOfDay(for: model.selectedDate)
        return (0..<7).compactMap { calendar.date(byAdding: .day, value: -$0, to: ref) }.reversed()
    }

    private var daysGoalMet: Int {
        last7Days.filter { (stepsHistory[$0] ?? 0) >= Double(dailyStepGoal) }.count
    }

    private var averageStepsLast7Days: Int {
        let vals = last7Days.compactMap { stepsHistory[$0] }
        guard !vals.isEmpty else { return 0 }
        return Int(vals.reduce(0, +) / Double(vals.count))
    }

    private var currentStreak: Int {
        let calendar = Calendar.current
        let ref = calendar.startOfDay(for: model.selectedDate)
        var streak = 0
        for i in 0..<30 {
            guard let day = calendar.date(byAdding: .day, value: -i, to: ref) else { break }
            if (stepsHistory[day] ?? 0) >= Double(dailyStepGoal) {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }

    private var distanceKm: Double { Double(steps) * 0.000762 }
    private var caloriesEstimate: Int { Int(Double(steps) * 0.04) }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            heroRing
            statsRow
            if !isLoadingHistory { weekBarChart }
            distanceAndCalories
            streakCard
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .onAppear { loadStepsHistory() }
        .onChange(of: model.selectedDate) { _ in loadStepsHistory() }
    }

    // MARK: - Hero Ring

    private var heroRing: some View {
        VStack(spacing: 16) {
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.green.opacity(0.12), lineWidth: 12)
                    .frame(width: 150, height: 150)

                // Progress ring
                Circle()
                    .trim(from: 0, to: goalProgress)
                    .stroke(
                        AngularGradient(
                            colors: [.green.opacity(0.6), .green, .mint],
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360 * goalProgress)
                        ),
                        style: StrokeStyle(lineWidth: 12, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 150, height: 150)

                // Center content
                VStack(spacing: 2) {
                    Text(steps >= 1000 ? String(format: "%.1fk", Double(steps) / 1000.0) : "\(steps)")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("of \(dailyStepGoal / 1000)k goal")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            // Completion badge
            if goalProgress >= 1.0 {
                HStack(spacing: 5) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 12, weight: .bold))
                    Text("Goal Complete!")
                        .font(.system(size: 12, weight: .bold))
                        .textCase(.uppercase)
                        .tracking(0.5)
                }
                .foregroundColor(.green)
                .padding(.horizontal, 12)
                .padding(.vertical, 5)
                .background(Capsule().fill(Color.green.opacity(0.15)))
            } else {
                let remaining = dailyStepGoal - steps
                Text("\(remaining.formatted()) steps to go")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.green.opacity(0.15), Color.green.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.green.opacity(0.25), lineWidth: 1)
                )
        )
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 10) {
            miniStat(icon: "chart.bar.fill", label: "7d Avg", value: averageStepsLast7Days.formatted(), color: .cyan)
            miniStat(icon: "flame.fill", label: "Goal Met", value: "\(daysGoalMet)/7", color: .orange)
            miniStat(icon: "bolt.fill", label: "Streak", value: "\(currentStreak)d", color: .yellow)
        }
    }

    private func miniStat(icon: String, label: String, value: String, color: Color) -> some View {
        VStack(spacing: 6) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.12))
                    .frame(width: 30, height: 30)
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
            }
            Text(value)
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundColor(.white)
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Week Bar Chart

    private var weekBarChart: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Last 7 Days")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            if #available(iOS 16.0, *) {
                Chart {
                    // Goal reference line
                    RuleMark(y: .value("Goal", dailyStepGoal))
                        .foregroundStyle(Color.white.opacity(0.2))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .annotation(position: .trailing, alignment: .leading) {
                            Text("goal")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(.white.opacity(0.3))
                        }

                    ForEach(last7Days, id: \.self) { date in
                        let daySteps = Int(stepsHistory[date] ?? 0)
                        let metGoal = daySteps >= dailyStepGoal

                        BarMark(
                            x: .value("Day", date, unit: .day),
                            y: .value("Steps", daySteps)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: metGoal
                                    ? [Color.green.opacity(0.6), Color.green]
                                    : [Color.white.opacity(0.15), Color.white.opacity(0.25)],
                                startPoint: .bottom,
                                endPoint: .top
                            )
                        )
                        .cornerRadius(4)
                    }
                }
                .chartYScale(domain: .automatic(includesZero: true))
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: 1)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(dayAbbreviation(date))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let val = value.as(Int.self) {
                                Text(val >= 1000 ? "\(val / 1000)k" : "\(val)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.06))
                    }
                }
                .frame(height: 170)
            } else {
                Text("Charts require iOS 16+")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(maxWidth: .infinity)
                    .padding()
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    // MARK: - Distance & Calories

    private var distanceAndCalories: some View {
        HStack(spacing: 10) {
            // Distance
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.blue.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: "map.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.blue)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Distance")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                    Text(String(format: "%.1f km", distanceKm))
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                    )
            )

            // Calories
            HStack(spacing: 10) {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.12))
                        .frame(width: 36, height: 36)
                    Image(systemName: "flame.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.orange)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Calories")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                    Text("\(caloriesEstimate)")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.orange.opacity(0.15), lineWidth: 1)
                    )
            )
        }
    }

    // MARK: - Streak Card

    private var streakCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "flame.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.orange)
                Text("Goal Streak")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            // Mini calendar dots for last 7 days
            HStack(spacing: 6) {
                ForEach(last7Days, id: \.self) { date in
                    let met = (stepsHistory[date] ?? 0) >= Double(dailyStepGoal)
                    VStack(spacing: 4) {
                        ZStack {
                            Circle()
                                .fill(met ? Color.green : Color.white.opacity(0.08))
                                .frame(width: 28, height: 28)
                            if met {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 10, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                        Text(dayAbbreviation(date))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    if date != last7Days.last {
                        Spacer(minLength: 0)
                    }
                }
            }

            if currentStreak > 0 {
                Text("\(currentStreak)-day streak — keep it going!")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.orange)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.top, 4)
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    // MARK: - Helpers

    private func dayAbbreviation(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEE"
        return f.string(from: date).prefix(3).uppercased()
    }

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }

    private func loadStepsHistory() {
        isLoadingHistory = true
        HealthKitManager.shared.fetchStepsForLastNDays(numberOfDays: 7, referenceDate: model.selectedDate) { history in
            stepsHistory = history
            isLoadingHistory = false
        }
    }
}
