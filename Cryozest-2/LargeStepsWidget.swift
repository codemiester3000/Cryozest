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

    @State private var showGoalConfig = false
    @State private var isPressed = false
    @State private var animate = true

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
        VStack(alignment: .leading, spacing: 16) {
            // Header with icon, title, and config button
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "figure.walk")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.green)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.green.opacity(0.15))
                        )

                    Text("Steps")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                Button(action: {
                    showGoalConfig = true
                }) {
                    HStack(spacing: 4) {
                        Image(systemName: "target")
                            .font(.system(size: 12, weight: .semibold))
                        Text("\(goalManager.dailyStepGoal)")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                    }
                    .foregroundColor(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(
                        Capsule()
                            .fill(Color.green.opacity(0.15))
                            .overlay(
                                Capsule()
                                    .stroke(Color.green.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }

            // Steps count and goal
            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(currentSteps)")
                        .font(.system(size: 40, weight: .bold, design: .rounded))
                        .foregroundColor(animate ? progressColor : .white)

                    Text("/ \(goalManager.dailyStepGoal)")
                        .font(.system(size: 20, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }

                Text("\(Int(goalProgress * 100))% of daily goal")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background track
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 16)

                    // Progress fill
                    RoundedRectangle(cornerRadius: 8)
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
                        .frame(width: geometry.size.width * goalProgress, height: 16)
                        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: goalProgress)

                    // Goal marker if exceeded
                    if goalProgress > 1.0 {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: 12, weight: .bold))
                            Text("Goal reached!")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 2)
                        .background(
                            Capsule()
                                .fill(Color.green)
                        )
                        .offset(x: 8, y: -24)
                    }
                }
            }
            .frame(height: 16)

            // Quick stats
            HStack(spacing: 12) {
                QuickStatView(
                    icon: "figure.walk.motion",
                    label: "Remaining",
                    value: "\(max(0, goalManager.dailyStepGoal - currentSteps))"
                )

                Divider()
                    .frame(height: 30)
                    .background(Color.white.opacity(0.2))

                let distanceKm = Double(currentSteps) * 0.000762
                let distanceMi = distanceKm * 0.621371
                QuickStatView(
                    icon: "location.fill",
                    label: "Distance",
                    value: String(format: "%.1f km / %.1f mi", distanceKm, distanceMi)
                )
            }
        }
        .padding(16)
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
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onTapGesture {
            expandedMetric = .steps
        }
        .onLongPressGesture(minimumDuration: 0.0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .onAppear {
            withAnimation(.easeInOut(duration: 2)) {
                animate = false
            }
        }
        .onChange(of: currentSteps) { _ in
            animate = true
            withAnimation(.easeInOut(duration: 2)) {
                animate = false
            }
        }
        .sheet(isPresented: $showGoalConfig) {
            StepGoalConfigView()
        }
    }
}

struct QuickStatView: View {
    let icon: String
    let label: String
    let value: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.green)

            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))

                Text(value)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
