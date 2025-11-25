//
//  LargeStepsWidget.swift
//  Cryozest-2
//
//  Professional steps widget with Whoop-inspired circular progress design
//

import SwiftUI

struct LargeStepsWidget: View {
    @ObservedObject var model: RecoveryGraphModel
    @ObservedObject var goalManager = StepGoalManager.shared
    @Binding var expandedMetric: MetricType?
    var namespace: Namespace.ID

    @State private var showGoalConfig = false
    @State private var animateRing = false
    @State private var weeklyStepsData: [DailySteps] = []

    private var currentSteps: Int {
        Int(model.mostRecentSteps ?? 0)
    }

    private var goalProgress: Double {
        Double(currentSteps) / Double(goalManager.dailyStepGoal)
    }

    private var progressColor: Color {
        if goalProgress >= 1.0 {
            return .green
        } else if goalProgress >= 0.7 {
            return .cyan
        } else if goalProgress >= 0.4 {
            return .orange
        } else {
            return .orange.opacity(0.7)
        }
    }

    private var isExpanded: Bool {
        expandedMetric == .steps
    }

    var body: some View {
        if isExpanded {
            expandedView
        } else {
            collapsedView
        }
    }

    // MARK: - Collapsed View

    private var collapsedView: some View {
        HStack(spacing: 20) {
            // Circular progress ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: 8)
                    .frame(width: 90, height: 90)

                // Progress ring
                Circle()
                    .trim(from: 0, to: animateRing ? min(goalProgress, 1.0) : 0)
                    .stroke(
                        AngularGradient(
                            colors: [progressColor, progressColor.opacity(0.6)],
                            center: .center,
                            startAngle: .degrees(-90),
                            endAngle: .degrees(270)
                        ),
                        style: StrokeStyle(lineWidth: 8, lineCap: .round)
                    )
                    .frame(width: 90, height: 90)
                    .rotationEffect(.degrees(-90))

                // Overflow ring (when exceeding goal)
                if goalProgress > 1.0 {
                    Circle()
                        .trim(from: 0, to: animateRing ? min(goalProgress - 1.0, 1.0) : 0)
                        .stroke(
                            Color.green.opacity(0.5),
                            style: StrokeStyle(lineWidth: 4, lineCap: .round)
                        )
                        .frame(width: 78, height: 78)
                        .rotationEffect(.degrees(-90))
                }

                // Center content
                VStack(spacing: 2) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(progressColor)

                    Text(formatSteps(currentSteps))
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
            }

            // Right side content
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    Text("Steps")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    // Goal badge
                    goalBadge
                }

                // Stats row
                HStack(spacing: 16) {
                    let distanceKm = Double(currentSteps) * 0.000762
                    let distanceMi = distanceKm * 0.621371
                    statItem(
                        value: String(format: "%.1f km / %.1f mi", distanceKm, distanceMi),
                        unit: "",
                        icon: "location.fill"
                    )

                    if goalProgress < 1.0 {
                        statItem(
                            value: formatStepsShort(goalManager.dailyStepGoal - currentSteps),
                            unit: "left",
                            icon: "arrow.right"
                        )
                    } else {
                        statItem(
                            value: "+\(formatStepsShort(currentSteps - goalManager.dailyStepGoal))",
                            unit: "bonus",
                            icon: "star.fill",
                            color: .green
                        )
                    }
                }

                // Goal target
                HStack(spacing: 4) {
                    Image(systemName: "target")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                    Text("Goal: \(formatSteps(goalManager.dailyStepGoal))")
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
                .onTapGesture {
                    showGoalConfig = true
                }
            }
        }
        .padding(20)
        .modernWidgetCard(style: .activity)
        .contentShape(Rectangle())
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                expandedMetric = .steps
            }
        }
        .onAppear {
            loadWeeklyData()
            withAnimation(.easeOut(duration: 1.0).delay(0.2)) {
                animateRing = true
            }
        }
        .onChange(of: currentSteps) { _ in
            withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                animateRing = true
            }
        }
        .sheet(isPresented: $showGoalConfig) {
            StepGoalConfigView()
        }
    }

    // MARK: - Expanded View

    private var expandedView: some View {
        VStack(spacing: 20) {
            // Header with progress ring
            HStack(spacing: 20) {
                // Circular progress ring (smaller in expanded)
                ZStack {
                    Circle()
                        .stroke(Color.white.opacity(0.1), lineWidth: 6)
                        .frame(width: 70, height: 70)

                    Circle()
                        .trim(from: 0, to: min(goalProgress, 1.0))
                        .stroke(
                            AngularGradient(
                                colors: [progressColor, progressColor.opacity(0.6)],
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270)
                            ),
                            style: StrokeStyle(lineWidth: 6, lineCap: .round)
                        )
                        .frame(width: 70, height: 70)
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text(formatSteps(currentSteps))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("Steps")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)

                        Spacer()

                        goalBadge
                    }

                    Text("Today's Progress")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.08))
                .frame(height: 1)

            // 7-Day Overview
            VStack(alignment: .leading, spacing: 12) {
                Text("This Week")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))

                // Mini progress rings row
                HStack(spacing: 0) {
                    ForEach(weeklyStepsData.indices, id: \.self) { index in
                        let dayData = weeklyStepsData[index]
                        miniDayRing(dayData: dayData, isToday: index == weeklyStepsData.count - 1)
                            .frame(maxWidth: .infinity)
                    }
                }
            }

            // Week stats
            weekStatsSection

        }
        .padding(20)
        .modernWidgetCard(style: .activity)
        .contentShape(Rectangle())
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                expandedMetric = nil
            }
        }
        .onAppear {
            loadWeeklyData()
        }
    }

    // MARK: - Components

    private var goalBadge: some View {
        HStack(spacing: 4) {
            if goalProgress >= 1.0 {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10, weight: .bold))
                Text("Goal Met")
                    .font(.system(size: 11, weight: .bold))
            } else {
                Image(systemName: "target")
                    .font(.system(size: 10, weight: .semibold))
                Text("\(Int(goalProgress * 100))%")
                    .font(.system(size: 11, weight: .bold))
            }
        }
        .foregroundColor(goalProgress >= 1.0 ? .green : progressColor)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill((goalProgress >= 1.0 ? Color.green : progressColor).opacity(0.15))
                .overlay(
                    Capsule()
                        .stroke((goalProgress >= 1.0 ? Color.green : progressColor).opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func statItem(value: String, unit: String, icon: String, color: Color = .white) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(color.opacity(0.6))

            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundColor(color)

            Text(unit)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(color.opacity(0.5))
        }
    }

    private func miniDayRing(dayData: DailySteps, isToday: Bool) -> some View {
        let progress = Double(dayData.steps) / Double(goalManager.dailyStepGoal)
        let ringColor: Color = progress >= 1.0 ? .green : (progress >= 0.5 ? .cyan : .orange)

        return VStack(spacing: 6) {
            ZStack {
                // Background
                Circle()
                    .stroke(Color.white.opacity(0.1), lineWidth: isToday ? 4 : 3)
                    .frame(width: isToday ? 36 : 30, height: isToday ? 36 : 30)

                // Progress
                Circle()
                    .trim(from: 0, to: min(progress, 1.0))
                    .stroke(
                        ringColor,
                        style: StrokeStyle(lineWidth: isToday ? 4 : 3, lineCap: .round)
                    )
                    .frame(width: isToday ? 36 : 30, height: isToday ? 36 : 30)
                    .rotationEffect(.degrees(-90))

                // Checkmark for completed days
                if progress >= 1.0 {
                    Image(systemName: "checkmark")
                        .font(.system(size: isToday ? 12 : 10, weight: .bold))
                        .foregroundColor(.green)
                }
            }

            // Day label
            Text(dayData.dayLabel)
                .font(.system(size: isToday ? 11 : 10, weight: isToday ? .bold : .medium))
                .foregroundColor(isToday ? .white : .white.opacity(0.5))
        }
    }

    private var weekStatsSection: some View {
        let totalSteps = weeklyStepsData.reduce(0) { $0 + $1.steps }
        let avgSteps = weeklyStepsData.isEmpty ? 0 : totalSteps / weeklyStepsData.count
        let daysGoalMet = weeklyStepsData.filter { $0.steps >= goalManager.dailyStepGoal }.count
        let streak = calculateStreak()

        return HStack(spacing: 0) {
            weekStatItem(
                title: "Total",
                value: formatStepsShort(totalSteps),
                icon: "sum"
            )
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 30)
                .background(Color.white.opacity(0.1))

            weekStatItem(
                title: "Daily Avg",
                value: formatStepsShort(avgSteps),
                icon: "chart.line.uptrend.xyaxis"
            )
            .frame(maxWidth: .infinity)

            Divider()
                .frame(height: 30)
                .background(Color.white.opacity(0.1))

            weekStatItem(
                title: "Goal Days",
                value: "\(daysGoalMet)/7",
                icon: "checkmark.circle",
                valueColor: daysGoalMet >= 5 ? .green : (daysGoalMet >= 3 ? .cyan : .orange)
            )
            .frame(maxWidth: .infinity)

            if streak > 1 {
                Divider()
                    .frame(height: 30)
                    .background(Color.white.opacity(0.1))

                weekStatItem(
                    title: "Streak",
                    value: "\(streak)d",
                    icon: "flame.fill",
                    valueColor: .orange
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }

    private func weekStatItem(title: String, value: String, icon: String, valueColor: Color = .white) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.4))

            Text(value)
                .font(.system(size: 15, weight: .bold, design: .rounded))
                .foregroundColor(valueColor)

            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
        }
    }

    // MARK: - Helpers

    private func formatSteps(_ steps: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: steps)) ?? "\(steps)"
    }

    private func formatStepsShort(_ steps: Int) -> String {
        if steps >= 10000 {
            return String(format: "%.1fk", Double(steps) / 1000.0)
        } else if steps >= 1000 {
            return String(format: "%.1fk", Double(steps) / 1000.0)
        } else {
            return "\(steps)"
        }
    }

    private func loadWeeklyData() {
        let calendar = Calendar.current
        let today = Date()

        weeklyStepsData = (0..<7).map { daysAgo in
            let date = calendar.date(byAdding: .day, value: -(6 - daysAgo), to: today)!
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "E"
            let dayLabel = String(dayFormatter.string(from: date).prefix(1))

            // For today, use actual data; for past days, use stored/mock data
            let steps: Int
            if daysAgo == 6 {
                steps = currentSteps
            } else {
                // In production, this would fetch from HealthKit history
                // For now, generate realistic mock data based on goal
                let baseVariation = Double.random(in: 0.5...1.3)
                steps = Int(Double(goalManager.dailyStepGoal) * baseVariation)
            }

            return DailySteps(date: date, steps: steps, dayLabel: dayLabel)
        }
    }

    private func calculateStreak() -> Int {
        var streak = 0
        for dayData in weeklyStepsData.reversed() {
            if dayData.steps >= goalManager.dailyStepGoal {
                streak += 1
            } else {
                break
            }
        }
        return streak
    }
}

// MARK: - Supporting Types

struct DailySteps {
    let date: Date
    let steps: Int
    let dayLabel: String
}

// MARK: - Quick Stat View (kept for backward compatibility)

struct QuickStatView: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))

                Text(value)
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
