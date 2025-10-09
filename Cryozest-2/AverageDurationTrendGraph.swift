//
//  AverageDurationTrendGraph.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//  Line graph showing average session duration over time
//

import SwiftUI
import CoreData

struct AverageDurationTrendGraph: View {
    let sessions: [TherapySessionEntity]
    let therapyType: TherapyType
    let timeframe: Timeframe

    enum Timeframe {
        case week
        case month
        case year

        var bucketCount: Int {
            switch self {
            case .week: return 7
            case .month: return 4
            case .year: return 12
            }
        }

        var label: String {
            switch self {
            case .week: return "Last 7 Days"
            case .month: return "Last 4 Weeks"
            case .year: return "Last 12 Months"
            }
        }
    }

    private var trendData: [Double] {
        let calendar = Calendar.current
        let today = Date()
        var buckets: [Double] = []

        for i in 0..<timeframe.bucketCount {
            let startDate: Date?
            let endDate: Date?

            switch timeframe {
            case .week:
                endDate = calendar.date(byAdding: .day, value: -i, to: today)
                startDate = calendar.startOfDay(for: endDate!)
            case .month:
                endDate = calendar.date(byAdding: .weekOfYear, value: -i, to: today)
                startDate = calendar.date(byAdding: .weekOfYear, value: -1, to: endDate!)
            case .year:
                endDate = calendar.date(byAdding: .month, value: -i, to: today)
                startDate = calendar.date(byAdding: .month, value: -1, to: endDate!)
            }

            guard let start = startDate, let end = endDate else {
                buckets.append(0)
                continue
            }

            let relevantSessions = sessions.filter { session in
                guard let date = session.date,
                      session.therapyType == therapyType.rawValue else {
                    return false
                }
                return date >= start && date <= end
            }

            let average = relevantSessions.isEmpty ? 0 : relevantSessions.reduce(0) { $0 + $1.duration } / Double(relevantSessions.count)
            buckets.append(average)
        }

        return buckets.reversed()
    }

    private var maxDuration: Double {
        trendData.max() ?? 1
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(therapyType.color)

                Text("Average Duration Trend")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)

                Spacer()

                Text(timeframe.label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }

            GeometryReader { geometry in
                ZStack(alignment: .bottomLeading) {
                    // Grid lines
                    VStack(spacing: 0) {
                        ForEach(0..<4) { _ in
                            Divider()
                                .background(Color.white.opacity(0.1))
                            Spacer()
                        }
                    }

                    // Line graph
                    Path { path in
                        guard trendData.count > 0 else { return }

                        let width = geometry.size.width
                        let height = geometry.size.height
                        let stepX = width / CGFloat(trendData.count - 1)

                        for (index, value) in trendData.enumerated() {
                            let x = CGFloat(index) * stepX
                            let y = height - (CGFloat(value) / CGFloat(maxDuration) * height)

                            if index == 0 {
                                path.move(to: CGPoint(x: x, y: y))
                            } else {
                                path.addLine(to: CGPoint(x: x, y: y))
                            }
                        }
                    }
                    .stroke(therapyType.color, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))

                    // Data points
                    ForEach(Array(trendData.enumerated()), id: \.offset) { index, value in
                        let width = geometry.size.width
                        let height = geometry.size.height
                        let stepX = width / CGFloat(trendData.count - 1)
                        let x = CGFloat(index) * stepX
                        let y = height - (CGFloat(value) / CGFloat(maxDuration) * height)

                        Circle()
                            .fill(therapyType.color)
                            .frame(width: 8, height: 8)
                            .position(x: x, y: y)
                    }
                }
            }
            .frame(height: 120)

            // Duration labels
            HStack {
                Text("0m")
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))

                Spacer()

                Text(formatDuration(maxDuration))
                    .font(.system(size: 10, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.06)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration) / 60
        return "\(minutes)m"
    }
}
