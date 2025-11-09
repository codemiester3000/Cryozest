//
//  HRVDetailView.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//

import SwiftUI

struct HRVDetailView: View {
    @ObservedObject var model: RecoveryGraphModel
    @State private var dataPoints: [DataPoint] = []
    @State private var isLoading = true

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Current value card
            VStack(spacing: 8) {
                Text("Current HRV")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))

                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(model.lastKnownHRV)")
                        .font(.system(size: 48, weight: .bold))
                        .foregroundColor(.cyan)

                    Text("ms")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }

                trendIndicator
            }
            .frame(maxWidth: .infinity)
            .padding(20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.cyan.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                    )
            )

            // 7-day trend chart
            VStack(alignment: .leading, spacing: 12) {
                Text("7-Day Trend")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)

                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .cyan))
                        .frame(maxWidth: .infinity)
                        .frame(height: 180)
                } else {
                    MetricChartView(
                        dataPoints: dataPoints,
                        chartType: .line,
                        color: .cyan,
                        unit: "ms"
                    )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                    )
            )

            // Stats summary
            HStack(spacing: 12) {
                statCard(title: "Min", value: "\(Int(dataPoints.map { $0.value }.min() ?? 0))", unit: "ms")
                statCard(title: "Avg", value: "\(Int(dataPoints.map { $0.value }.reduce(0, +) / Double(max(dataPoints.count, 1))))", unit: "ms")
                statCard(title: "Max", value: "\(Int(dataPoints.map { $0.value }.max() ?? 0))", unit: "ms")
            }

            // Educational info
            infoCard(
                title: "What is HRV?",
                description: "Heart Rate Variability measures the variation in time between heartbeats. Higher HRV generally indicates better recovery and cardiovascular fitness."
            )

            zoneIndicator
        }
        .onAppear {
            loadData()
        }
    }

    private var trendIndicator: some View {
        HStack(spacing: 6) {
            let trend = calculateTrend()
            Image(systemName: trend > 0 ? "arrow.up.right" : trend < 0 ? "arrow.down.right" : "arrow.right")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(trend > 0 ? .green : trend < 0 ? .red : .gray)

            Text(abs(trend) > 0 ? "\(abs(Int(trend)))% vs last week" : "No change")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private var zoneIndicator: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Recovery Status")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)

            let currentHRV = model.lastKnownHRV
            let status = getRecoveryStatus(hrv: currentHRV)

            HStack(spacing: 12) {
                Circle()
                    .fill(status.color)
                    .frame(width: 12, height: 12)

                VStack(alignment: .leading, spacing: 4) {
                    Text(status.label)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)

                    Text(status.description)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))
                }
            }
            .padding(16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(status.color.opacity(0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(status.color.opacity(0.3), lineWidth: 1)
                    )
            )
        }
    }

    private func statCard(title: String, value: String, unit: String) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)

                Text(unit)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }

    private func infoCard(title: String, description: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.cyan)

                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text(description)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.cyan.opacity(0.1))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.cyan.opacity(0.2), lineWidth: 1)
                )
        )
    }

    private func loadData() {
        isLoading = true

        // Fetch 7 days of HRV data
        let calendar = Calendar.current
        let today = Date()
        var days: [Date] = []

        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                days.append(date)
            }
        }

        days = days.reversed()

        // Fetch HRV for each individual day
        var fetchedData: [Date: Double] = [:]
        let group = DispatchGroup()

        for day in days {
            group.enter()
            HealthKitManager.shared.fetchAvgHRVForDay(date: day) { hrvValue in
                if let hrv = hrvValue, hrv > 0 {
                    fetchedData[day] = hrv
                }
                group.leave()
            }
        }

        group.notify(queue: .main) {
            if !fetchedData.isEmpty {
                self.dataPoints = days.compactMap { date in
                    guard let value = fetchedData[date] else { return nil }
                    return DataPoint(date: date, value: value)
                }
            } else {
                // Fallback to demo data
                self.dataPoints = days.map { date in
                    DataPoint(date: date, value: Double.random(in: 40...80))
                }
            }
            isLoading = false
        }
    }

    private func calculateTrend() -> Double {
        guard dataPoints.count >= 2 else { return 0 }

        let recent = Array(dataPoints.suffix(3)).map { $0.value }.reduce(0, +) / 3.0
        let previous = Array(dataPoints.prefix(3)).map { $0.value }.reduce(0, +) / 3.0

        guard previous > 0 else { return 0 }
        return ((recent - previous) / previous) * 100
    }

    private func getRecoveryStatus(hrv: Int) -> (label: String, description: String, color: Color) {
        switch hrv {
        case 0..<30:
            return ("Poor Recovery", "Consider taking a rest day", .red)
        case 30..<50:
            return ("Fair Recovery", "Light activity recommended", .orange)
        case 50..<70:
            return ("Good Recovery", "Ready for moderate training", .yellow)
        default:
            return ("Excellent Recovery", "Fully recovered, ready for intense training", .green)
        }
    }
}
