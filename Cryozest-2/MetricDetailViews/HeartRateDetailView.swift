//
//  HeartRateDetailView.swift
//  Cryozest-2
//
//  Enhanced heart rate detail view with trends and statistics
//

import SwiftUI
import Charts

struct HeartRateDetailView: View {
    @ObservedObject var model: RecoveryGraphModel

    @State private var currentHR: Int?
    @State private var last7DaysRHR: [(Date, Int)] = []
    @State private var todayHourlyHR: [(Int, Int)] = []
    @State private var weekStats: WeeklyHRStats?

    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                currentHRCard

                weeklyStatsCard

                rhrTrendCard

                hrZonesCard

                infoCard
            }
        }
    }

    private var currentHRCard: some View {
        VStack(spacing: 8) {
                Text("Current Heart Rate")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    if let hr = currentHR {
                        Text("\(hr)")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.red)
                    } else {
                        Text("--")
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.3))
                    }

                    Text("bpm")
                        .font(.system(size: 18, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))
                }
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.red.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.red.opacity(0.3), lineWidth: 1)
                    )
            )
    }

    private var weeklyStatsCard: some View {
        VStack(alignment: .leading, spacing: 12) {
                Text("This Week")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))

                if let stats = weekStats {
                    HStack(spacing: 12) {
                        HRStatCard(
                            icon: "heart",
                            label: "Avg RHR",
                            value: "\(stats.averageRHR)",
                            unit: "bpm",
                            color: .cyan
                        )

                        HRStatCard(
                            icon: "arrow.down.heart",
                            label: "Lowest",
                            value: "\(stats.lowestHR)",
                            unit: "bpm",
                            color: .green
                        )
                    }

                    HStack(spacing: 12) {
                        HRStatCard(
                            icon: "arrow.up.heart.fill",
                            label: "Highest",
                            value: "\(stats.highestHR)",
                            unit: "bpm",
                            color: .red
                        )

                        HRStatCard(
                            icon: "figure.run",
                            label: "Active Time",
                            value: String(format: "%.1f", stats.timeInZones[.moderate, default: 0] + stats.timeInZones[.vigorous, default: 0]),
                            unit: "hrs",
                            color: .orange
                        )
                    }
                } else {
                    Text("No data available")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
    }

    private var rhrTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
                Text("Resting Heart Rate Trend")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))

                if #available(iOS 16.0, *) {
                    Chart {
                        ForEach(last7DaysRHR, id: \.0) { date, rhr in
                            LineMark(
                                x: .value("Date", date, unit: .day),
                                y: .value("RHR", rhr)
                            )
                            .foregroundStyle(Color.cyan)
                            .interpolationMethod(.catmullRom)
                            .symbol(Circle().strokeBorder(lineWidth: 2))
                            .symbolSize(50)

                            AreaMark(
                                x: .value("Date", date, unit: .day),
                                y: .value("RHR", rhr)
                            )
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [Color.cyan.opacity(0.3), Color.cyan.opacity(0.05)],
                                    startPoint: .top,
                                    endPoint: .bottom
                                )
                            )
                            .interpolationMethod(.catmullRom)
                        }
                    }
                    .chartYScale(domain: .automatic(includesZero: false))
                    .chartXAxis {
                        AxisMarks(values: .stride(by: .day)) { value in
                            if let date = value.as(Date.self) {
                                AxisValueLabel {
                                    Text(dayFormatter.string(from: date))
                                        .font(.system(size: 10, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                        }
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading) { value in
                            AxisValueLabel {
                                if let rhr = value.as(Int.self) {
                                    Text("\(rhr)")
                                        .font(.system(size: 10, weight: .medium, design: .rounded))
                                        .foregroundColor(.white.opacity(0.6))
                                }
                            }
                            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                                .foregroundStyle(Color.white.opacity(0.1))
                        }
                    }
                    .frame(height: 140)
                    .padding(.vertical, 8)
                } else {
                    Text("Chart requires iOS 16+")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
    }

    private var hrZonesCard: some View {
        VStack(alignment: .leading, spacing: 12) {
                Text("Time in Heart Rate Zones (Today)")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))

                if let stats = weekStats {
                    VStack(spacing: 10) {
                        HRZoneRow(
                            zone: "Resting (<100 bpm)",
                            hours: stats.timeInZones[.resting, default: 0],
                            color: .cyan
                        )

                        HRZoneRow(
                            zone: "Light (100-120 bpm)",
                            hours: stats.timeInZones[.light, default: 0],
                            color: .green
                        )

                        HRZoneRow(
                            zone: "Moderate (120-150 bpm)",
                            hours: stats.timeInZones[.moderate, default: 0],
                            color: .orange
                        )

                        HRZoneRow(
                            zone: "Vigorous (150+ bpm)",
                            hours: stats.timeInZones[.vigorous, default: 0],
                            color: .red
                        )
                    }
                } else {
                    Text("No data available")
                        .font(.system(size: 14, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: "info.circle.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.red)

                    Text("About Heart Rate")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)
                }

                Text("Your resting heart rate is a key indicator of cardiovascular fitness. Lower is generally better, with most adults ranging between 60-100 bpm. Athletes often have RHR in the 40-60 range.")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(4)
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.red.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.red.opacity(0.2), lineWidth: 1)
                    )
            )
    }
}

struct WeeklyHRStats {
    let averageRHR: Int
    let lowestHR: Int
    let highestHR: Int
    let timeInZones: [HRZone: Double]
}

enum HRZone {
    case resting
    case light
    case moderate
    case vigorous
}

struct HRZoneRow: View {
    let zone: String
    let hours: Double
    let color: Color

    var body: some View {
        HStack {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)

            Text(zone)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundColor(.white.opacity(0.8))

            Spacer()

            Text(String(format: "%.1f hrs", hours))
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(color)
        }
        .padding(.vertical, 6)
    }
}

struct HRStatCard: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(color)

            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text(unit)
                        .font(.system(size: 11, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }

                Text(label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
