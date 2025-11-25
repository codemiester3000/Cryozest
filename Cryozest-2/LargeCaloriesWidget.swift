//
//  LargeCaloriesWidget.swift
//  Cryozest-2
//
//  Full-width Calories Burned widget with inline expansion
//

import SwiftUI

struct LargeCaloriesWidget: View {
    @ObservedObject var model: RecoveryGraphModel
    @Binding var expandedMetric: MetricType?
    var namespace: Namespace.ID

    @State private var flameAnimation: CGFloat = 0

    private var totalCalories: Int {
        Int((model.mostRecentActiveCalories ?? 0) + (model.mostRecentRestingCalories ?? 0))
    }

    private var activeCalories: Int {
        Int(model.mostRecentActiveCalories ?? 0)
    }

    private var restingCalories: Int {
        Int(model.mostRecentRestingCalories ?? 0)
    }

    private var activePercentage: Double {
        totalCalories > 0 ? Double(activeCalories) / Double(totalCalories) : 0
    }

    private var isExpanded: Bool {
        expandedMetric == .calories
    }

    var body: some View {
        Group {
            if isExpanded {
                expandedView
            } else {
                collapsedView
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                flameAnimation = 1.0
            }
        }
    }

    // MARK: - Collapsed View (Half-width compact)
    private var collapsedView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top row: Icon and percentage
            HStack {
                ZStack {
                    Circle()
                        .fill(Color.orange.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: "flame.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.orange)
                }

                Spacer()

                // Active percentage badge
                Text("\(Int(activePercentage * 100))% active")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(Color.orange.opacity(0.15))
                    )
            }

            // Title
            Text("Calories")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            // Value
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(totalCalories)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("kcal")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            // Mini breakdown
            HStack(spacing: 8) {
                HStack(spacing: 3) {
                    Circle()
                        .fill(Color.orange)
                        .frame(width: 5, height: 5)
                    Text("\(activeCalories)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }

                HStack(spacing: 3) {
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 5, height: 5)
                    Text("\(restingCalories)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.1), Color.white.opacity(0.05)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.orange.opacity(0.2), lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                expandedMetric = .calories
            }
        }
    }

    // MARK: - Expanded View
    private var expandedView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.orange.opacity(0.2))
                            .frame(width: 40, height: 40)

                        Image(systemName: "flame.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.orange)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Calories Burned")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(totalCalories)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            Text("kcal")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }

                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        expandedMetric = nil
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(16)

            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // Large ring visualization
                    caloriesRingVisualization

                    // Breakdown cards
                    breakdownSection

                    // Info card
                    infoCard
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.12), Color.white.opacity(0.06)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.orange.opacity(0.3), lineWidth: 1.5)
                )
        )
        .shadow(color: Color.orange.opacity(0.2), radius: 16, y: 8)
    }

    private var caloriesRingVisualization: some View {
        ZStack {
            // Background ring
            Circle()
                .stroke(Color.white.opacity(0.08), lineWidth: 16)
                .frame(width: 140, height: 140)

            // Resting calories (cyan)
            Circle()
                .trim(from: 0, to: 1 - CGFloat(activePercentage))
                .stroke(Color.cyan.opacity(0.6), style: StrokeStyle(lineWidth: 16, lineCap: .round))
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(-90 + 360 * activePercentage))

            // Active calories (orange)
            Circle()
                .trim(from: 0, to: CGFloat(activePercentage))
                .stroke(
                    AngularGradient(colors: [.orange, .red.opacity(0.8)], center: .center),
                    style: StrokeStyle(lineWidth: 16, lineCap: .round)
                )
                .frame(width: 140, height: 140)
                .rotationEffect(.degrees(-90))

            VStack(spacing: 4) {
                Text("\(totalCalories)")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("total kcal")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
    }

    private var breakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Breakdown")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
                .textCase(.uppercase)
                .tracking(0.5)

            HStack(spacing: 12) {
                breakdownCard(
                    title: "Active",
                    value: activeCalories,
                    icon: "figure.run",
                    color: .orange,
                    percentage: activePercentage
                )

                breakdownCard(
                    title: "Resting",
                    value: restingCalories,
                    icon: "bed.double.fill",
                    color: .cyan,
                    percentage: 1 - activePercentage
                )
            }
        }
    }

    private func breakdownCard(title: String, value: Int, icon: String, color: Color, percentage: Double) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)

                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))
            }

            Text("\(value)")
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text("\(Int(percentage * 100))% of total")
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(color.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.25), lineWidth: 1)
                )
        )
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.orange)

                Text("About Calories")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text("Active calories are burned through movement and exercise. Resting calories (BMR) are burned by your body's basic functions like breathing and circulation throughout the day.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.orange.opacity(0.08))
        )
    }
}
