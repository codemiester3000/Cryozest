//
//  LargeStepsWidget.swift
//  Cryozest-2
//
//  Clean, minimal steps widget with horizontal progress bar
//

import SwiftUI

struct LargeStepsWidget: View {
    @ObservedObject var model: RecoveryGraphModel
    @ObservedObject var goalManager = StepGoalManager.shared
    @Binding var expandedMetric: MetricType?
    var namespace: Namespace.ID
    var selectedDate: Date

    @State private var showGoalConfig = false
    @State private var animateProgress = false
    @State private var weeklyStepsData: [DailySteps] = []
    @State private var isPressed = false
    @State private var currentSteps: Int = 0
    @State private var isLoadingSteps = false

    private var displaySteps: Int {
        if MockDataHelper.useMockData {
            return MockDataHelper.mockSteps
        }
        return currentSteps
    }

    private var goalProgress: Double {
        Double(displaySteps) / Double(goalManager.dailyStepGoal)
    }

    // Whoop-inspired gradient based on progress
    private var progressColor: Color {
        if goalProgress >= 1.0 {
            return Color(red: 0.25, green: 0.85, blue: 0.45) // Vibrant green
        } else if goalProgress >= 0.75 {
            return Color(red: 0.3, green: 0.75, blue: 0.95) // Light blue
        } else if goalProgress >= 0.5 {
            return Color(red: 0.4, green: 0.65, blue: 1.0) // Medium blue
        } else {
            return Color(red: 0.5, green: 0.55, blue: 0.7) // Muted blue-gray
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

    // MARK: - Collapsed View (Whoop-inspired circular gauge)

    private var collapsedView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Text("Steps")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))

                Spacer()

                // Goal config button
                Button(action: { showGoalConfig = true }) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 13))
                        .foregroundColor(.white.opacity(0.4))
                }
                .buttonStyle(PlainButtonStyle())
            }
            .padding(.bottom, 20)

            // Main content with circular gauge
            HStack(spacing: 24) {
                // Circular progress gauge - true Whoop style
                ZStack {
                    // Background ring
                    Circle()
                        .stroke(
                            Color.white.opacity(0.08),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)

                    // Progress ring with gradient
                    Circle()
                        .trim(from: 0, to: animateProgress ? min(goalProgress, 1.0) : 0)
                        .stroke(
                            AngularGradient(
                                gradient: Gradient(colors: [
                                    progressColor.opacity(0.7),
                                    progressColor,
                                    goalProgress >= 1.0 ? Color(red: 0.2, green: 0.8, blue: 0.4) : progressColor
                                ]),
                                center: .center,
                                startAngle: .degrees(-90),
                                endAngle: .degrees(270 * min(goalProgress, 1.0) - 90)
                            ),
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .frame(width: 120, height: 120)
                        .rotationEffect(.degrees(-90))
                        .shadow(color: progressColor.opacity(0.3), radius: 8, x: 0, y: 0)

                    // Center content
                    VStack(spacing: 4) {
                        // Step count
                        Text(formatStepsShort(displaySteps))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())

                        // Percentage
                        Text("\(Int(min(goalProgress, 1.0) * 100))%")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(progressColor.opacity(0.9))
                    }
                }

                // Stats column
                VStack(alignment: .leading, spacing: 16) {
                    // Goal status
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Goal")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))

                        HStack(spacing: 6) {
                            Text(formatSteps(goalManager.dailyStepGoal))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.85))

                            if goalProgress >= 1.0 {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                            }
                        }
                    }

                    // Distance
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Distance")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))

                        let distanceKm = Double(displaySteps) * 0.000762
                        let distanceMi = distanceKm * 0.621371

                        Text(String(format: "%.1f mi", distanceMi))
                            .font(.system(size: 16, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.85))
                    }

                    // Remaining or completion
                    VStack(alignment: .leading, spacing: 4) {
                        Text(goalProgress < 1.0 ? "Remaining" : "Achieved")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))

                        if goalProgress < 1.0 {
                            Text(formatStepsShort(goalManager.dailyStepGoal - displaySteps))
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(progressColor.opacity(0.9))
                        } else {
                            Text("+\(formatStepsShort(displaySteps - goalManager.dailyStepGoal))")
                                .font(.system(size: 16, weight: .bold, design: .rounded))
                                .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
                        }
                    }
                }

                Spacer()
            }
        }
        .padding(20)
        .feedWidgetStyle(style: .activity)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .contentShape(Rectangle())
        .onLongPressGesture(minimumDuration: 0.5, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .simultaneousGesture(
            TapGesture()
                .onEnded { _ in
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                        expandedMetric = .steps
                    }
                }
        )
        .onAppear {
            fetchStepsForDate()
            loadWeeklyData()
            withAnimation(.easeOut(duration: 1.2).delay(0.3)) {
                animateProgress = true
            }
        }
        .onChange(of: selectedDate) { newDate in
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            print("👣 [STEPS] Date changed to: \(formatter.string(from: newDate))")
            animateProgress = false
            currentSteps = 0
            fetchStepsForDate()
            loadWeeklyData()
            withAnimation(.easeOut(duration: 0.8).delay(0.1)) {
                animateProgress = true
            }
        }
        .onChange(of: displaySteps) { _ in
            animateProgress = false
            withAnimation(.spring(response: 0.8, dampingFraction: 0.75).delay(0.1)) {
                animateProgress = true
            }
        }
        .sheet(isPresented: $showGoalConfig) {
            StepGoalConfigView()
        }
        .id("\(Calendar.current.startOfDay(for: selectedDate).timeIntervalSince1970)-\(displaySteps)")
    }

    // MARK: - Expanded View

    private var expandedView: some View {
        VStack(spacing: 20) {
            // Header
            HStack(alignment: .center) {
                Image(systemName: "figure.walk")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(progressColor)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(progressColor.opacity(0.15))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Steps")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(formatSteps(displaySteps))
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .contentTransition(.numericText())

                        Text("/ \(formatSteps(goalManager.dailyStepGoal))")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }

                Spacer()

                // Close button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        expandedMetric = nil
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            // Horizontal progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 8)

                    RoundedRectangle(cornerRadius: 4)
                        .fill(
                            LinearGradient(
                                colors: [
                                    Color(red: 0.2, green: 0.6, blue: 1.0),
                                    goalProgress >= 1.0 ? Color(red: 0.2, green: 0.8, blue: 0.4) : Color(red: 0.3, green: 0.7, blue: 1.0)
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(goalProgress, 1.0), height: 8)
                }
            }
            .frame(height: 8)

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)

            // 7-Day Overview with horizontal bars
            VStack(alignment: .leading, spacing: 12) {
                Text("This Week")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))

                VStack(spacing: 8) {
                    ForEach(weeklyStepsData.indices, id: \.self) { index in
                        let dayData = weeklyStepsData[index]
                        let isToday = index == weeklyStepsData.count - 1
                        weekDayRow(dayData: dayData, isToday: isToday)
                    }
                }
            }

            // Week stats
            weekStatsSection

            // Edit Goal button
            Button(action: {
                showGoalConfig = true
            }) {
                HStack(spacing: 8) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 14, weight: .semibold))
                    Text("Edit Step Goal")
                        .font(.system(size: 14, weight: .semibold))
                }
                .foregroundColor(Color(red: 0.2, green: 0.6, blue: 1.0))
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(red: 0.2, green: 0.6, blue: 1.0).opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color(red: 0.2, green: 0.6, blue: 1.0).opacity(0.2), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(PlainButtonStyle())
        }
        .padding(20)
        .feedWidgetStyle(style: .activity)
        .onAppear {
            fetchStepsForDate()
            loadWeeklyData()
        }
        .onChange(of: selectedDate) { _ in
            currentSteps = 0
            weeklyStepsData = []
            fetchStepsForDate()
            loadWeeklyData()
        }
        .sheet(isPresented: $showGoalConfig) {
            StepGoalConfigView()
        }
        .id("\(Calendar.current.startOfDay(for: selectedDate).timeIntervalSince1970)-steps-expanded")
    }

    // MARK: - Components

    private var goalBadge: some View {
        HStack(spacing: 4) {
            if goalProgress >= 1.0 {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 10, weight: .bold))
                Text("Done")
                    .font(.system(size: 11, weight: .semibold))
            } else {
                Text("\(Int(goalProgress * 100))%")
                    .font(.system(size: 11, weight: .semibold))
            }
        }
        .foregroundColor(goalProgress >= 1.0 ? Color(red: 0.2, green: 0.8, blue: 0.4) : .white.opacity(0.6))
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(goalProgress >= 1.0 ? Color(red: 0.2, green: 0.8, blue: 0.4).opacity(0.15) : Color.white.opacity(0.08))
        )
    }

    private func weekDayRow(dayData: DailySteps, isToday: Bool) -> some View {
        let progress = Double(dayData.steps) / Double(goalManager.dailyStepGoal)
        let barColor = progress >= 1.0 ? Color(red: 0.2, green: 0.8, blue: 0.4) : Color(red: 0.2, green: 0.6, blue: 1.0)

        return HStack(spacing: 12) {
            // Day label
            Text(dayData.dayLabel)
                .font(.system(size: 12, weight: isToday ? .bold : .medium))
                .foregroundColor(isToday ? .white : .white.opacity(0.5))
                .frame(width: 20, alignment: .leading)

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.08))
                        .frame(height: 6)

                    RoundedRectangle(cornerRadius: 3)
                        .fill(barColor.opacity(isToday ? 1.0 : 0.7))
                        .frame(width: geometry.size.width * min(progress, 1.0), height: 6)
                }
            }
            .frame(height: 6)

            // Step count
            Text(formatStepsShort(dayData.steps))
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundColor(isToday ? .white : .white.opacity(0.5))
                .frame(width: 40, alignment: .trailing)

            // Checkmark if goal met
            if progress >= 1.0 {
                Image(systemName: "checkmark")
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(Color(red: 0.2, green: 0.8, blue: 0.4))
            } else {
                Color.clear.frame(width: 9)
            }
        }
    }

    private var weekStatsSection: some View {
        let totalSteps = weeklyStepsData.reduce(0) { $0 + $1.steps }
        let avgSteps = weeklyStepsData.isEmpty ? 0 : totalSteps / weeklyStepsData.count
        let daysGoalMet = weeklyStepsData.filter { $0.steps >= goalManager.dailyStepGoal }.count

        return HStack(spacing: 0) {
            weekStatItem(
                title: "Total",
                value: formatStepsShort(totalSteps)
            )
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 1, height: 32)

            weekStatItem(
                title: "Daily Avg",
                value: formatStepsShort(avgSteps)
            )
            .frame(maxWidth: .infinity)

            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(width: 1, height: 32)

            weekStatItem(
                title: "Goals Met",
                value: "\(daysGoalMet)/7",
                valueColor: daysGoalMet >= 5 ? Color(red: 0.2, green: 0.8, blue: 0.4) : .white
            )
            .frame(maxWidth: .infinity)
        }
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.04))
        )
    }

    private func weekStatItem(title: String, value: String, valueColor: Color = .white) -> some View {
        VStack(spacing: 4) {
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

    // Fetch steps for the selected date
    private func fetchStepsForDate() {
        guard !MockDataHelper.useMockData else { return }

        isLoadingSteps = true
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? selectedDate

        let formatter = DateFormatter()
        formatter.dateStyle = .short
        print("👣 [STEPS] Fetching steps for: \(formatter.string(from: selectedDate))")
        print("👣 [STEPS] Date range: \(startOfDay) to \(endOfDay)")

        HealthKitManager.shared.fetchStepCount(from: startOfDay, to: endOfDay) { steps, error in
            DispatchQueue.main.async {
                self.isLoadingSteps = false
                if let steps = steps {
                    print("👣 [STEPS] Fetched \(Int(steps)) steps for \(formatter.string(from: self.selectedDate))")
                    self.currentSteps = Int(steps)
                } else {
                    print("👣 [STEPS] No steps data for \(formatter.string(from: self.selectedDate)), error: \(String(describing: error))")
                    self.currentSteps = 0
                }
            }
        }
    }

    private func loadWeeklyData() {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: selectedDate)

        // Fetch real data for the last 7 days
        var tempData: [DailySteps] = []
        let group = DispatchGroup()

        for daysAgo in 0..<7 {
            let date = calendar.date(byAdding: .day, value: -(6 - daysAgo), to: endDate)!
            let dayFormatter = DateFormatter()
            dayFormatter.dateFormat = "E"
            let dayLabel = String(dayFormatter.string(from: date).prefix(1))

            if MockDataHelper.useMockData {
                let baseVariation = Double.random(in: 0.5...1.3)
                let steps = Int(Double(goalManager.dailyStepGoal) * baseVariation)
                tempData.append(DailySteps(date: date, steps: steps, dayLabel: dayLabel))
            } else {
                group.enter()
                let startOfDay = calendar.startOfDay(for: date)
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? date

                HealthKitManager.shared.fetchStepCount(from: startOfDay, to: endOfDay) { steps, error in
                    let stepCount = Int(steps ?? 0)
                    tempData.append(DailySteps(date: date, steps: stepCount, dayLabel: dayLabel))
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            self.weeklyStepsData = tempData.sorted { $0.date < $1.date }
        }
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
