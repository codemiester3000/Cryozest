//
//  LargeHeartRateWidget.swift
//  Cryozest-2
//
//  Large heart rate widget showing current HR, recent trend, and status
//

import SwiftUI

struct LargeHeartRateWidget: View {
    @ObservedObject var model: RecoveryGraphModel
    @Binding var expandedMetric: MetricType?

    @State private var currentHeartRate: Int = 72 // FAKE DATA - TODO: Replace with real data
    @State private var last30MinData: [Double] = [68, 70, 69, 71, 73, 75, 72, 70, 69, 72, 74, 76, 78, 75, 73, 71, 69, 70, 72, 74] // FAKE DATA
    @State private var todayMin: Int = 52 // FAKE DATA
    @State private var todayMax: Int = 142 // FAKE DATA
    @State private var recentSpikeMinutesAgo: Int? = 45 // FAKE DATA
    @State private var isPressed = false
    @State private var animate = true

    private var heartRateStatus: HeartRateStatus {
        if currentHeartRate < 60 {
            return .resting
        } else if currentHeartRate < 100 {
            return .elevated
        } else {
            return .active
        }
    }

    private var statusColor: Color {
        switch heartRateStatus {
        case .resting: return .cyan
        case .elevated: return .orange
        case .active: return .red
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header with icon and status
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "heart.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(Color.red.opacity(0.15))
                        )

                    Text("Heart Rate")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.7))
                }

                Spacer()

                // Status badge
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor)
                        .frame(width: 6, height: 6)

                    Text(heartRateStatus.rawValue)
                        .font(.system(size: 12, weight: .semibold, design: .rounded))
                        .foregroundColor(statusColor)
                }
                .padding(.horizontal, 10)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(statusColor.opacity(0.15))
                        .overlay(
                            Capsule()
                                .stroke(statusColor.opacity(0.3), lineWidth: 1)
                        )
                )
            }

            // Current heart rate - large display
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(currentHeartRate)")
                    .font(.system(size: 56, weight: .bold, design: .rounded))
                    .foregroundColor(animate ? statusColor : .white)

                VStack(alignment: .leading, spacing: 2) {
                    Text("bpm")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))

                    Text("current")
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.4))
                }
                .padding(.bottom, 8)
            }

            // 30-minute trend graph
            VStack(alignment: .leading, spacing: 8) {
                Text("Last 30 minutes")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))

                GeometryReader { geometry in
                    HeartRateMiniGraph(data: last30MinData, color: statusColor)
                        .frame(height: 40)
                }
                .frame(height: 40)
            }

            // Today's range and spike indicator
            HStack(spacing: 12) {
                // Range
                HStack(spacing: 6) {
                    Image(systemName: "arrow.up.arrow.down")
                        .font(.system(size: 11, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Today's Range")
                            .font(.system(size: 9, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))

                        Text("\(todayMin)-\(todayMax) bpm")
                            .font(.system(size: 12, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .frame(height: 30)
                    .background(Color.white.opacity(0.2))

                // Recent spike indicator
                if let minutesAgo = recentSpikeMinutesAgo {
                    HStack(spacing: 6) {
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.orange)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Recent Spike")
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))

                            Text("\(minutesAgo)m ago")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.orange)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                } else {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.green)

                        VStack(alignment: .leading, spacing: 2) {
                            Text("Steady")
                                .font(.system(size: 9, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.5))

                            Text("No spikes")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                        }
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
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
                        .stroke(animate ? statusColor.opacity(0.5) : Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .shadow(color: animate ? statusColor.opacity(0.25) : Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .onTapGesture {
            expandedMetric = .rhr // We'll use RHR metric type for now, can create a new one later
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
    }
}

enum HeartRateStatus: String {
    case resting = "Resting"
    case elevated = "Elevated"
    case active = "Active"
}

struct HeartRateMiniGraph: View {
    let data: [Double]
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let maxValue = data.max() ?? 1
            let minValue = data.min() ?? 0
            let range = maxValue - minValue

            ZStack(alignment: .bottom) {
                // Background
                RoundedRectangle(cornerRadius: 6)
                    .fill(Color.white.opacity(0.05))

                // Area chart
                Path { path in
                    guard !data.isEmpty else { return }

                    let width = geometry.size.width
                    let height = geometry.size.height
                    let stepX = width / CGFloat(data.count - 1)

                    // Start from bottom left
                    path.move(to: CGPoint(x: 0, y: height))

                    // Draw line to first point
                    let firstY = height - (CGFloat((data[0] - minValue) / range) * height)
                    path.addLine(to: CGPoint(x: 0, y: firstY))

                    // Draw the curve
                    for (index, value) in data.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = height - (CGFloat((value - minValue) / range) * height)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }

                    // Complete the area
                    path.addLine(to: CGPoint(x: width, y: height))
                    path.closeSubpath()
                }
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            color.opacity(0.3),
                            color.opacity(0.05)
                        ]),
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                // Line on top
                Path { path in
                    guard !data.isEmpty else { return }

                    let width = geometry.size.width
                    let height = geometry.size.height
                    let stepX = width / CGFloat(data.count - 1)

                    let firstY = height - (CGFloat((data[0] - minValue) / range) * height)
                    path.move(to: CGPoint(x: 0, y: firstY))

                    for (index, value) in data.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = height - (CGFloat((value - minValue) / range) * height)
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
                .stroke(color, lineWidth: 2)
            }
        }
    }
}
