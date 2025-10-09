//
//  MetricChartView.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//

import SwiftUI
import Charts

enum ChartType {
    case line
    case bar
}

struct DataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct MetricChartView: View {
    let dataPoints: [DataPoint]
    let chartType: ChartType
    let color: Color
    let unit: String

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }

    private var maxValue: Double {
        dataPoints.map { $0.value }.max() ?? 100
    }

    private var minValue: Double {
        dataPoints.map { $0.value }.min() ?? 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if dataPoints.isEmpty {
                emptyStateView
            } else {
                Chart {
                    ForEach(dataPoints) { point in
                        switch chartType {
                        case .line:
                            LineMark(
                                x: .value("Date", point.date),
                                y: .value("Value", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [color, color.opacity(0.6)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                            .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round))

                            AreaMark(
                                x: .value("Date", point.date),
                                y: .value("Value", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [color.opacity(0.3), color.opacity(0.05)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)

                        case .bar:
                            BarMark(
                                x: .value("Date", point.date),
                                y: .value("Value", point.value)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [color, color.opacity(0.7)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .cornerRadius(6)
                        }
                    }
                }
                .chartXAxis {
                    AxisMarks(values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel()
                            .foregroundStyle(Color.white.opacity(0.6))
                            .font(.system(size: 10, weight: .medium))
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5, dash: [2, 2]))
                            .foregroundStyle(Color.white.opacity(0.1))
                        AxisValueLabel()
                            .foregroundStyle(Color.white.opacity(0.6))
                            .font(.system(size: 10, weight: .medium))
                    }
                }
                .frame(height: 180)
                .padding(.vertical, 8)
            }
        }
    }

    private var emptyStateView: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 32, weight: .light))
                .foregroundColor(color.opacity(0.5))

            Text("No data available")
                .font(.system(size: 14, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(height: 180)
        .frame(maxWidth: .infinity)
    }
}
