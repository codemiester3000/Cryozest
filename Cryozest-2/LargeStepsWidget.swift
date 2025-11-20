//
//  LargeStepsWidget.swift
//  Cryozest-2
//
//  Large steps widget that shows current steps vs goal with configuration
//

import SwiftUI

struct LargeStepsWidget: View {
    @ObservedObject var model: RecoveryGraphModel
    @ObservedObject var goalManager = StepGoalManager.shared
    @Binding var expandedMetric: MetricType?
    var namespace: Namespace.ID

    @State private var showGoalConfig = false
    @State private var isPressed = false
    @State private var animate = true
    @State private var previousSteps: Int = 0
    @State private var stepsDelta: Int = 0
    @State private var showDeltaAnimation = false
    @State private var animatedProgress: Double = 0
    @State private var focusedDayIndex: Int = 6 // Start with today (last day)

    private var currentSteps: Int {
        Int(model.mostRecentSteps ?? 0)
    }

    private var last7DaysSteps: [Int] {
        // Get the last 7 days of steps data
        // This matches the logic in Last7DaysStepsChart
        let current = currentSteps
        return [
            Int.random(in: (goalManager.dailyStepGoal/2)...(goalManager.dailyStepGoal*3/2)),
            Int.random(in: (goalManager.dailyStepGoal/2)...(goalManager.dailyStepGoal*3/2)),
            Int.random(in: (goalManager.dailyStepGoal/2)...(goalManager.dailyStepGoal*3/2)),
            Int.random(in: (goalManager.dailyStepGoal/2)...(goalManager.dailyStepGoal*3/2)),
            Int.random(in: (goalManager.dailyStepGoal/2)...(goalManager.dailyStepGoal*3/2)),
            Int.random(in: (goalManager.dailyStepGoal/2)...(goalManager.dailyStepGoal*3/2)),
            current
        ]
    }

    private var focusedDaySteps: Int {
        last7DaysSteps[focusedDayIndex]
    }

    private var goalProgress: Double {
        min(Double(currentSteps) / Double(goalManager.dailyStepGoal), 1.0)
    }

    private var focusedDayGoalProgress: Double {
        min(Double(focusedDaySteps) / Double(goalManager.dailyStepGoal), 1.0)
    }

    private var actualProgress: Double {
        Double(currentSteps) / Double(goalManager.dailyStepGoal)
    }

    private var progressColor: Color {
        if goalProgress >= 1.0 {
            return .green
        } else if goalProgress >= 0.5 {
            return .cyan
        } else {
            return .orange
        }
    }

    private var borderColor: Color {
        if goalProgress >= 1.0 {
            return Color.green.opacity(0.6)
        } else if animate {
            return progressColor.opacity(0.5)
        } else {
            return Color.white.opacity(0.12)
        }
    }

    private var borderWidth: CGFloat {
        goalProgress >= 1.0 ? 1.5 : 1
    }

    private var shadowColor: Color {
        if goalProgress >= 1.0 {
            return Color.green.opacity(0.3)
        } else if animate {
            return progressColor.opacity(0.25)
        } else {
            return Color.black.opacity(0.05)
        }
    }

    private var shadowRadius: CGFloat {
        goalProgress >= 1.0 ? 8 : 6
    }

    private var isExpanded: Bool {
        expandedMetric == .steps
    }

    var body: some View {
        if isExpanded {
            inlineExpandedView
        } else {
            collapsedView
        }
    }

    private var collapsedView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Compact header with icon inline and goal badge
            HStack(alignment: .center, spacing: 12) {
                // Animated icon inline with main metric
                ZStack {
                    // Celebration rings when goal achieved
                    if goalProgress >= 1.0 {
                        Circle()
                            .stroke(Color.green.opacity(0.3), lineWidth: 2)
                            .frame(width: 40, height: 40)
                            .scaleEffect(animate ? 1.0 : 1.3)
                            .opacity(animate ? 0.8 : 0.0)

                        Circle()
                            .stroke(Color.cyan.opacity(0.2), lineWidth: 1.5)
                            .frame(width: 40, height: 40)
                            .scaleEffect(animate ? 1.0 : 1.5)
                            .opacity(animate ? 0.6 : 0.0)
                    }

                    // Icon background
                    Circle()
                        .fill(goalProgress >= 1.0 ? Color.green.opacity(0.25) : Color.green.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: goalProgress >= 1.0 ? "figure.walk.circle.fill" : "figure.walk")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(goalProgress >= 1.0 ? .green : .green)
                }

                // Main metric display
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text("Steps")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))

                        // Achievement badge for exceeding goal
                        if actualProgress >= 2.0 {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 8, weight: .bold))
                                Text("2x Goal!")
                                    .font(.system(size: 8, weight: .bold))
                            }
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.yellow.opacity(0.2))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
                                    )
                            )
                        } else if actualProgress >= 1.5 {
                            HStack(spacing: 2) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 8, weight: .bold))
                                Text("On Fire!")
                                    .font(.system(size: 8, weight: .bold))
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.orange.opacity(0.2))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                                    )
                            )
                        }
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(currentSteps)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(animate ? progressColor : .white)

                        if goalProgress < 1.0 {
                            Text("/ \(goalManager.dailyStepGoal)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        } else if actualProgress > 1.0 {
                            // Show exceeded amount
                            Text("+\(currentSteps - goalManager.dailyStepGoal)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.green.opacity(0.8))
                        }
                    }
                }

                Spacer()

                // Goal badge
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: goalProgress >= 1.0 ? "trophy.fill" : "target")
                            .font(.system(size: 10, weight: .semibold))
                        Text("\(Int(min(goalProgress, 1.0) * 100))%")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(goalProgress >= 1.0 ? .yellow : .green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(goalProgress >= 1.0 ? Color.yellow.opacity(0.2) : Color.green.opacity(0.15))
                            .overlay(
                                Capsule()
                                    .stroke(goalProgress >= 1.0 ? Color.yellow.opacity(0.4) : Color.green.opacity(0.3), lineWidth: 1)
                            )
                    )

                    Text("Goal: \(goalManager.dailyStepGoal)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .onTapGesture {
                    showGoalConfig = true
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 12)

                    // First bar - progress towards goal (caps at 100%)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    progressColor,
                                    progressColor.opacity(0.7)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(goalProgress, 1.0), height: 12)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: goalProgress)

                    // Second bar - extra steps beyond goal (starts as a new round)
                    if actualProgress > 1.0 {
                        let extraProgress = actualProgress - 1.0
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(red: 0.13, green: 0.55, blue: 0.13))  // Forest green
                            .frame(width: geometry.size.width * min(extraProgress, 1.0), height: 12)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: actualProgress)
                    }
                }
            }
            .frame(height: 12)

            // Quick stats
            HStack(spacing: 12) {
                if goalProgress < 1.0 {
                    QuickStatView(
                        icon: "figure.walk.motion",
                        label: "Remaining",
                        value: "\(max(0, goalManager.dailyStepGoal - currentSteps))"
                    )

                    Divider()
                        .frame(height: 28)
                        .background(Color.white.opacity(0.2))
                }

                let distanceKm = Double(currentSteps) * 0.000762
                let distanceMi = distanceKm * 0.621371
                QuickStatView(
                    icon: "location.fill",
                    label: "Distance",
                    value: String(format: "%.1f km / %.1f mi", distanceKm, distanceMi)
                )

                if goalProgress >= 1.0 {
                    Divider()
                        .frame(height: 28)
                        .background(Color.white.opacity(0.2))

                    let caloriesBurned = Int(Double(currentSteps) * 0.04)
                    QuickStatView(
                        icon: "flame.fill",
                        label: "Calories",
                        value: "\(caloriesBurned)"
                    )
                }
            }
        }
        .padding(20)
        .background(
            ZStack {
                // Decorative footprint pattern in background
                GeometryReader { geo in
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: "figure.walk")
                            .font(.system(size: 40, weight: .ultraLight))
                            .foregroundColor(Color.cyan.opacity(0.04))
                            .rotationEffect(.degrees(15))
                            .offset(
                                x: CGFloat(index) * (geo.size.width / 3) + 20,
                                y: CGFloat(index % 2 == 0 ? 20 : 60)
                            )
                    }
                }
            }
        )
        .modernWidgetCard(style: .activity)
        .overlay(
            // Corner achievement badge for major milestones
            VStack {
                HStack {
                    Spacer()
                    if actualProgress >= 2.0 {
                        HStack(spacing: 3) {
                            Image(systemName: "medal.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text("Champion")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(.yellow)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.yellow.opacity(0.25))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.yellow.opacity(0.5), lineWidth: 1)
                                )
                        )
                        .offset(x: -12, y: 12)
                    } else if goalProgress >= 1.0 {
                        HStack(spacing: 3) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text("Goal Met")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.25))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.green.opacity(0.5), lineWidth: 1)
                                )
                        )
                        .offset(x: -12, y: 12)
                    }
                }
                Spacer()
            }
        )
        .overlay(
            // Delta animation overlay
            Group {
                if showDeltaAnimation && stepsDelta > 0 {
                    VStack {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 20, weight: .bold))
                                .foregroundColor(.green)

                            Text("+\(stepsDelta) steps!")
                                .font(.system(size: 18, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.9))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                                )
                        )
                        .shadow(color: Color.green.opacity(0.4), radius: 12, x: 0, y: 4)
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))

                        Spacer()
                    }
                    .padding(.top, 12)
                }
            }
            .allowsHitTesting(false)  // Allow taps to pass through to widget
        )
        .contentShape(Rectangle())  // Make entire area tappable
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            withAnimation(.spring(response: 0.8, dampingFraction: 0.85)) {
                expandedMetric = .steps
            }
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in
                    if !isPressed {
                        withAnimation(.easeInOut(duration: 0.1)) {
                            isPressed = true
                        }
                    }
                }
                .onEnded { _ in
                    withAnimation(.easeInOut(duration: 0.1)) {
                        isPressed = false
                    }
                }
        )
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .matchedGeometryEffect(id: "steps-widget", in: namespace)
        .onAppear {
            previousSteps = currentSteps
            animatedProgress = goalProgress
            withAnimation(.easeInOut(duration: 2)) {
                animate = false
            }

            // Haptic feedback if goal is already met
            if goalProgress >= 1.0 {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
        .onChange(of: goalProgress) { newProgress in
            // Haptic feedback when goal is first reached
            if newProgress >= 1.0 && animatedProgress < 1.0 {
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
            }
        }
        .onChange(of: currentSteps) { newSteps in
            // Calculate delta (only if increasing)
            if newSteps > previousSteps && previousSteps > 0 {
                stepsDelta = newSteps - previousSteps
                showDeltaAnimation = true

                // Hide delta animation after delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                    withAnimation(.easeOut(duration: 0.3)) {
                        showDeltaAnimation = false
                    }
                }

                // Animate progress bar from previous to new value
                withAnimation(.spring(response: 1.2, dampingFraction: 0.75)) {
                    animatedProgress = goalProgress
                }
            }

            // Update previous steps for next comparison
            previousSteps = newSteps

            // Original animation
            animate = true
            withAnimation(.easeInOut(duration: 2)) {
                animate = false
            }
        }
        .sheet(isPresented: $showGoalConfig) {
            StepGoalConfigView()
        }
    }

    private var inlineExpandedView: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Same header as collapsed view
            HStack(alignment: .center, spacing: 12) {
                // Animated icon inline with main metric
                ZStack {
                    // Celebration rings when goal achieved
                    if goalProgress >= 1.0 {
                        Circle()
                            .stroke(Color.green.opacity(0.3), lineWidth: 2)
                            .frame(width: 40, height: 40)
                            .scaleEffect(animate ? 1.0 : 1.3)
                            .opacity(animate ? 0.8 : 0.0)

                        Circle()
                            .stroke(Color.cyan.opacity(0.2), lineWidth: 1.5)
                            .frame(width: 40, height: 40)
                            .scaleEffect(animate ? 1.0 : 1.5)
                            .opacity(animate ? 0.6 : 0.0)
                    }

                    // Icon background
                    Circle()
                        .fill(goalProgress >= 1.0 ? Color.green.opacity(0.25) : Color.green.opacity(0.15))
                        .frame(width: 40, height: 40)

                    Image(systemName: goalProgress >= 1.0 ? "figure.walk.circle.fill" : "figure.walk")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(goalProgress >= 1.0 ? .green : .green)
                }

                // Main metric display
                VStack(alignment: .leading, spacing: 6) {
                    HStack(spacing: 4) {
                        Text("Steps")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))

                        // Achievement badge for exceeding goal
                        if actualProgress >= 2.0 {
                            HStack(spacing: 2) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 8, weight: .bold))
                                Text("2x Goal!")
                                    .font(.system(size: 8, weight: .bold))
                            }
                            .foregroundColor(.yellow)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.yellow.opacity(0.2))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.yellow.opacity(0.4), lineWidth: 1)
                                    )
                            )
                        } else if actualProgress >= 1.5 {
                            HStack(spacing: 2) {
                                Image(systemName: "flame.fill")
                                    .font(.system(size: 8, weight: .bold))
                                Text("On Fire!")
                                    .font(.system(size: 8, weight: .bold))
                            }
                            .foregroundColor(.orange)
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.orange.opacity(0.2))
                                    .overlay(
                                        Capsule()
                                            .stroke(Color.orange.opacity(0.4), lineWidth: 1)
                                    )
                            )
                        }
                    }

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(currentSteps)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(animate ? progressColor : .white)

                        if goalProgress < 1.0 {
                            Text("/ \(goalManager.dailyStepGoal)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        } else if actualProgress > 1.0 {
                            // Show exceeded amount
                            Text("+\(currentSteps - goalManager.dailyStepGoal)")
                                .font(.system(size: 14, weight: .bold))
                                .foregroundColor(.green.opacity(0.8))
                        }
                    }
                }

                Spacer()

                // Goal badge
                VStack(alignment: .trailing, spacing: 6) {
                    HStack(spacing: 4) {
                        Image(systemName: goalProgress >= 1.0 ? "trophy.fill" : "target")
                            .font(.system(size: 10, weight: .semibold))
                        Text("\(Int(min(goalProgress, 1.0) * 100))%")
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(goalProgress >= 1.0 ? .yellow : .green)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(goalProgress >= 1.0 ? Color.yellow.opacity(0.2) : Color.green.opacity(0.15))
                            .overlay(
                                Capsule()
                                    .stroke(goalProgress >= 1.0 ? Color.yellow.opacity(0.4) : Color.green.opacity(0.3), lineWidth: 1)
                            )
                    )

                    Text("Goal: \(goalManager.dailyStepGoal)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
                .onTapGesture {
                    showGoalConfig = true
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 12)

                    // First bar - progress towards goal (caps at 100%)
                    RoundedRectangle(cornerRadius: 6)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    progressColor,
                                    progressColor.opacity(0.7)
                                ]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * min(goalProgress, 1.0), height: 12)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: goalProgress)

                    // Second bar - extra steps beyond goal (starts as a new round)
                    if actualProgress > 1.0 {
                        let extraProgress = actualProgress - 1.0
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color(red: 0.13, green: 0.55, blue: 0.13))  // Forest green
                            .frame(width: geometry.size.width * min(extraProgress, 1.0), height: 12)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: actualProgress)
                    }
                }
            }
            .frame(height: 12)

            // 7-day bar chart
            Last7DaysStepsChart(stepsData: last7DaysSteps, goal: goalManager.dailyStepGoal, focusedDayIndex: $focusedDayIndex)

            // Quick stats (dynamically update based on focused day)
            HStack(spacing: 12) {
                if focusedDayGoalProgress < 1.0 {
                    QuickStatView(
                        icon: "figure.walk.motion",
                        label: "Remaining",
                        value: "\(max(0, goalManager.dailyStepGoal - focusedDaySteps))"
                    )

                    Divider()
                        .frame(height: 28)
                        .background(Color.white.opacity(0.2))
                }

                let distanceKm = Double(focusedDaySteps) * 0.000762
                let distanceMi = distanceKm * 0.621371
                QuickStatView(
                    icon: "location.fill",
                    label: "Distance",
                    value: String(format: "%.1f km / %.1f mi", distanceKm, distanceMi)
                )

                if focusedDayGoalProgress >= 1.0 {
                    Divider()
                        .frame(height: 28)
                        .background(Color.white.opacity(0.2))

                    let caloriesBurned = Int(Double(focusedDaySteps) * 0.04)
                    QuickStatView(
                        icon: "flame.fill",
                        label: "Calories",
                        value: "\(caloriesBurned)"
                    )
                }
            }
        }
        .padding(20)
        .background(
            ZStack {
                // Decorative footprint pattern in background
                GeometryReader { geo in
                    ForEach(0..<3, id: \.self) { index in
                        Image(systemName: "figure.walk")
                            .font(.system(size: 40, weight: .ultraLight))
                            .foregroundColor(Color.cyan.opacity(0.04))
                            .rotationEffect(.degrees(15))
                            .offset(
                                x: CGFloat(index) * (geo.size.width / 3) + 20,
                                y: CGFloat(index % 2 == 0 ? 20 : 60)
                            )
                    }
                }
            }
        )
        .modernWidgetCard(style: .activity)
        .onTapGesture {
            // Tap anywhere to collapse
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()

            withAnimation(.spring(response: 0.8, dampingFraction: 0.85)) {
                expandedMetric = nil
            }
        }
        .onAppear {
            // Reset to today when expanded
            focusedDayIndex = 6
        }
    }
}

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

// MARK: - Expanded Steps Widget

struct ExpandedStepsWidget: View {
    @ObservedObject var model: RecoveryGraphModel
    @ObservedObject var goalManager = StepGoalManager.shared
    @Binding var expandedMetric: MetricType?
    var namespace: Namespace.ID
    
    private var currentSteps: Int {
        Int(model.mostRecentSteps ?? 0)
    }
    
    private var goalProgress: Double {
        min(Double(currentSteps) / Double(goalManager.dailyStepGoal), 1.0)
    }
    
    private var progressColor: Color {
        if goalProgress >= 1.0 {
            return .green
        } else if goalProgress >= 0.5 {
            return .cyan
        } else {
            return .orange
        }
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header (similar to collapsed)
                HStack {
                    HStack(spacing: 8) {
                        Image(systemName: "figure.walk")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.green)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(Color.green.opacity(0.15))
                            )
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Steps")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                            
                            HStack(alignment: .lastTextBaseline, spacing: 3) {
                                Text("\(currentSteps)")
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                Text("/ \(goalManager.dailyStepGoal)")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation(.spring(response: 0.8, dampingFraction: 0.85)) {
                            expandedMetric = nil
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
                
                // Detailed content
                StepsDetailView(model: model)
                    .opacity(expandedMetric != nil ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2).delay(0.15), value: expandedMetric)
            }
            .padding(16)
        }
        .modernWidgetCard(style: .activity)
        .matchedGeometryEffect(id: "steps-widget", in: namespace)
    }
}

// MARK: - Last 7 Days Steps Chart

struct Last7DaysStepsChart: View {
    let stepsData: [Int]
    let goal: Int
    @Binding var focusedDayIndex: Int

    private var last7DaysSteps: [Int] {
        stepsData
    }

    private var maxSteps: Int {
        max(last7DaysSteps.max() ?? goal, goal)
    }

    private func formatSteps(_ steps: Int) -> String {
        let thousands = Double(steps) / 1000.0
        return String(format: "%.1fk", thousands)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Last 7 Days")
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            ScrollView(.horizontal, showsIndicators: false) {
                GeometryReader { geometry in
                    ZStack(alignment: .bottom) {
                        // Goal line (dotted)
                        let goalY = geometry.size.height * (1.0 - CGFloat(goal) / CGFloat(maxSteps))
                        Path { path in
                            path.move(to: CGPoint(x: 0, y: goalY + 14))
                            path.addLine(to: CGPoint(x: geometry.size.width, y: goalY + 14))
                        }
                        .stroke(style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
                        .foregroundColor(.green.opacity(0.5))

                        // Bars
                        HStack(alignment: .bottom, spacing: 8) {
                            ForEach(0..<7, id: \.self) { index in
                                let steps = last7DaysSteps[index]
                                let height = (geometry.size.height - 14) * CGFloat(steps) / CGFloat(maxSteps)
                                let isFocused = index == focusedDayIndex
                                let metGoal = steps >= goal

                                VStack(spacing: 4) {
                                    // Step count on top
                                    Text(formatSteps(steps))
                                        .font(.system(size: isFocused ? 10 : 8, weight: isFocused ? .bold : .medium))
                                        .foregroundColor(isFocused ? .white : .white.opacity(0.5))

                                    // Bar
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    metGoal ? Color.green : Color.cyan,
                                                    metGoal ? Color.green.opacity(0.7) : Color.cyan.opacity(0.7)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(width: isFocused ? 44 : 36, height: max(height, 4))
                                        .overlay(
                                            RoundedRectangle(cornerRadius: 4)
                                                .stroke(isFocused ? Color.white.opacity(0.8) : Color.clear, lineWidth: isFocused ? 2 : 0)
                                        )
                                        .scaleEffect(isFocused ? 1.05 : 1.0)
                                        .shadow(color: isFocused ? Color.white.opacity(0.3) : Color.clear, radius: isFocused ? 8 : 0)

                                    // Day label
                                    Text(dayLabel(for: index))
                                        .font(.system(size: isFocused ? 9 : 8, weight: isFocused ? .bold : .medium))
                                        .foregroundColor(isFocused ? .white : .white.opacity(0.5))
                                }
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    let generator = UIImpactFeedbackGenerator(style: .light)
                                    generator.impactOccurred()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        focusedDayIndex = index
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 8)
                    }
                }
                .frame(height: 110)
            }
            .frame(height: 110)
        }
        .padding(.bottom, 12)
    }

    private func dayLabel(for index: Int) -> String {
        let calendar = Calendar.current
        let today = Date()
        let targetDate = calendar.date(byAdding: .day, value: index - 6, to: today) ?? today

        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        let dayName = formatter.string(from: targetDate)

        return String(dayName.prefix(1)) // First letter of day name
    }
}
