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
    @State private var showGoalCompletedCelebration = false
    @State private var celebrationScale: CGFloat = 0.5
    @State private var celebrationOpacity: Double = 0

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
        VStack(alignment: .leading, spacing: 20) {
            // Compact header with icon inline and goal badge
            HStack(alignment: .center, spacing: 12) {
                // Icon inline with main metric
                Image(systemName: goalProgress >= 1.0 ? "figure.walk.circle.fill" : "figure.walk")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(goalProgress >= 1.0 ? .green : .green)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(goalProgress >= 1.0 ? Color.green.opacity(0.25) : Color.green.opacity(0.15))
                    )

                // Main metric display
                VStack(alignment: .leading, spacing: 6) {
                    Text("Steps")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text("\(currentSteps)")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(animate ? progressColor : .white)

                        if goalProgress < 1.0 {
                            Text("/ \(goalManager.dailyStepGoal)")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }

                Spacer()

                // Goal badge or completion badge
                if goalProgress >= 1.0 {
                    VStack(alignment: .trailing, spacing: 6) {
                        HStack(spacing: 6) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 14, weight: .bold))
                            Text("Complete")
                                .font(.system(size: 13, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(
                            Capsule()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.green,
                                            Color.green.opacity(0.8)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .overlay(
                                    Capsule()
                                        .stroke(Color.white.opacity(0.3), lineWidth: 1.5)
                                )
                        )
                        .shadow(color: Color.green.opacity(0.5), radius: 8, x: 0, y: 4)

                        let overSteps = currentSteps - goalManager.dailyStepGoal
                        if overSteps > 0 {
                            Text("+\(overSteps) extra")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.green)
                        }
                    }
                    .onTapGesture {
                        showGoalConfig = true
                    }
                } else {
                    VStack(alignment: .trailing, spacing: 6) {
                        HStack(spacing: 4) {
                            Image(systemName: "target")
                                .font(.system(size: 10, weight: .semibold))
                            Text("\(Int(goalProgress * 100))%")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.15))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.green.opacity(0.3), lineWidth: 1)
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
            }

            // Progress bar or completion celebration
            if goalProgress >= 1.0 {
                // Goal completed celebration
                ZStack {
                    // Celebration particles (fade out after animation)
                    ForEach(0..<8, id: \.self) { index in
                        Circle()
                            .fill(Color.green.opacity(0.6))
                            .frame(width: 6, height: 6)
                            .offset(
                                x: cos(Double(index) * .pi / 4) * 50 * celebrationScale,
                                y: sin(Double(index) * .pi / 4) * 50 * celebrationScale
                            )
                            .opacity(celebrationOpacity * 0.7)
                    }

                    // Center achievement badge (stays visible)
                    HStack(spacing: 10) {
                        ZStack {
                            Circle()
                                .fill(Color.green.opacity(0.2))
                                .frame(width: 50, height: 50)
                                .blur(radius: 8)

                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            Color.green,
                                            Color.green.opacity(0.8)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 44, height: 44)

                            Image(systemName: "checkmark")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .scaleEffect(celebrationScale)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("Daily Goal Achieved!")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundColor(.white)

                            Text("Keep up the great work")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }

                        Spacer()
                    }
                }
                .frame(height: 60)
            } else {
                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        // Background track
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 12)

                        // Progress fill
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
                            .frame(width: geometry.size.width * goalProgress, height: 12)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: goalProgress)
                    }
                }
                .frame(height: 12)
            }

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
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.06)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(animate ? progressColor.opacity(0.5) : Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .shadow(color: animate ? progressColor.opacity(0.25) : Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
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
            expandedMetric = .steps
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

            // Trigger celebration if goal is already met
            if goalProgress >= 1.0 {
                triggerCelebration()
            }
        }
        .onChange(of: goalProgress) { newProgress in
            // Trigger celebration when goal is first reached
            if newProgress >= 1.0 && animatedProgress < 1.0 {
                triggerCelebration()
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

    private func triggerCelebration() {
        showGoalCompletedCelebration = true

        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            celebrationScale = 1.2
            celebrationOpacity = 1
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                celebrationScale = 1.0
            }
        }

        // Fade out celebration particles
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation(.easeOut(duration: 0.4)) {
                celebrationOpacity = 0
            }
        }

        // Haptic feedback
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
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
                        withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
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
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.08)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.green.opacity(0.3), lineWidth: 1.5)
                )
        )
        .shadow(color: Color.green.opacity(0.3), radius: 12, x: 0, y: 6)
        .matchedGeometryEffect(id: "steps-widget", in: namespace)
    }
}
