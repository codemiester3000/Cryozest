//
//  LargeHeartRateWidget.swift
//  Cryozest-2
//
//  Large resting heart rate widget showing current RHR and trends
//

import SwiftUI

struct LargeHeartRateWidget: View {
    @ObservedObject var model: RecoveryGraphModel
    @Binding var expandedMetric: MetricType?

    @State private var currentRHR: Int?
    @State private var weeklyAverageRHR: Int?
    @State private var todayRHRReadings: [(String, Int)] = []
    @State private var isPressed = false
    @State private var animate = true

    private var trend: RHRTrend {
        guard let current = currentRHR, let average = weeklyAverageRHR else {
            return .stable
        }
        let diff = current - average
        if diff <= -3 {
            return .improving
        } else if diff >= 3 {
            return .elevated
        } else {
            return .stable
        }
    }

    private var trendColor: Color {
        switch trend {
        case .improving: return .green
        case .stable: return .cyan
        case .elevated: return .orange
        }
    }

    private var trendIcon: String {
        switch trend {
        case .improving: return "arrow.down.right"
        case .stable: return "arrow.right"
        case .elevated: return "arrow.up.right"
        }
    }

    private var hasData: Bool {
        currentRHR != nil || !todayRHRReadings.isEmpty
    }

    var body: some View {
        if hasData {
            expandedView
        } else {
            collapsedView
        }
    }

    private var collapsedView: some View {
        HStack(spacing: 12) {
            Image(systemName: "heart.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.red)
                .frame(width: 32, height: 32)
                .background(
                    Circle()
                        .fill(Color.red.opacity(0.15))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("Resting Heart Rate")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)

                Text("Wear your Apple Watch to track")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }

            Spacer()

            Image(systemName: "applewatch")
                .font(.system(size: 20, weight: .medium))
                .foregroundColor(.red.opacity(0.5))
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.red.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private var expandedView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Compact header with icon inline
            HStack(alignment: .center) {
                // Icon inline with main metric
                Image(systemName: "heart.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(.red)
                    .frame(width: 40, height: 40)
                    .background(
                        Circle()
                            .fill(Color.red.opacity(0.15))
                    )

                // Main metric display
                VStack(alignment: .leading, spacing: 2) {
                    Text("Resting Heart Rate")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        if let rhr = currentRHR {
                            Text("\(rhr)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(animate ? trendColor : .white)
                        } else {
                            Text("--")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white.opacity(0.3))
                        }

                        Text("bpm")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                Spacer()

                // Trend badge
                VStack(alignment: .trailing, spacing: 2) {
                    HStack(spacing: 3) {
                        Image(systemName: trendIcon)
                            .font(.system(size: 10, weight: .bold))
                        Text(trend.rawValue)
                            .font(.system(size: 12, weight: .bold))
                    }
                    .foregroundColor(trendColor)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(trendColor.opacity(0.15))
                            .overlay(
                                Capsule()
                                    .stroke(trendColor.opacity(0.3), lineWidth: 1)
                            )
                    )

                    if let avg = weeklyAverageRHR {
                        Text("Avg: \(avg) bpm")
                            .font(.system(size: 10, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }

            // Today's RHR readings graph
            VStack(alignment: .leading, spacing: 6) {
                Text("Today's Readings")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))

                RHRReadingsGraph(readings: todayRHRReadings, color: trendColor)
                    .frame(height: 65)
            }

            // Stats row
            HStack(spacing: 10) {
                // Weekly average comparison
                HStack(spacing: 5) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.cyan)

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Weekly Avg")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))

                        if let avg = weeklyAverageRHR {
                            Text("\(avg) bpm")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white)
                        } else {
                            Text("-- bpm")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider()
                    .frame(height: 24)
                    .background(Color.white.opacity(0.2))

                // Difference from average
                HStack(spacing: 5) {
                    if let current = currentRHR, let avg = weeklyAverageRHR {
                        let diff = current - avg
                        Image(systemName: diff < 0 ? "arrow.down" : "arrow.up")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(diff < 0 ? .green : .orange)

                        VStack(alignment: .leading, spacing: 1) {
                            Text("vs Average")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))

                            Text("\(abs(diff)) bpm")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(diff < 0 ? .green : .orange)
                        }
                    } else {
                        Image(systemName: "minus")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.3))

                        VStack(alignment: .leading, spacing: 1) {
                            Text("vs Average")
                                .font(.system(size: 8, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))

                            Text("-- bpm")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.white.opacity(0.3))
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .padding(14)
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
                        .stroke(animate ? trendColor.opacity(0.5) : Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .shadow(color: animate ? trendColor.opacity(0.25) : Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
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

enum RHRTrend: String {
    case improving = "Improving"
    case stable = "Stable"
    case elevated = "Elevated"
}

struct RHRReadingsGraph: View {
    let readings: [(String, Int)]
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let values = readings.map { $0.1 }
            let maxValue = values.max() ?? 100
            let minValue = values.min() ?? 40
            let range = Double(maxValue - minValue)

            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.05))

                VStack(spacing: 0) {
                    // Graph area
                    ZStack(alignment: .bottomLeading) {
                        // Y-axis labels
                        VStack {
                            Text("\(maxValue)")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                            Spacer()
                            Text("\(minValue)")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        .frame(width: 25)
                        .padding(.leading, 4)

                        // Graph
                        HStack(alignment: .bottom, spacing: 0) {
                            ForEach(Array(readings.enumerated()), id: \.offset) { index, reading in
                                VStack(spacing: 4) {
                                    // Value label
                                    Text("\(reading.1)")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundColor(color)
                                        .opacity(0.9)

                                    // Bar
                                    let height = range > 0 ? CGFloat(Double(reading.1 - minValue) / range) * (geometry.size.height - 40) : 0
                                    RoundedRectangle(cornerRadius: 4)
                                        .fill(
                                            LinearGradient(
                                                colors: [color, color.opacity(0.6)],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(height: max(height, 4))

                                    // Time label
                                    Text(reading.0)
                                        .font(.system(size: 8, weight: .medium))
                                        .foregroundColor(.white.opacity(0.5))
                                }
                                .frame(maxWidth: .infinity)
                            }
                        }
                        .padding(.leading, 30)
                        .padding(.trailing, 8)
                    }
                }
                .padding(8)
            }
        }
    }
}
