//
//  LargeHeartRateWidget.swift
//  Cryozest-2
//
//  Large resting heart rate widget showing current RHR and trends
//

import SwiftUI
import HealthKit

struct LargeHeartRateWidget: View {
    @ObservedObject var model: RecoveryGraphModel
    @Binding var expandedMetric: MetricType?
    var selectedDate: Date

    @State private var todayRHRReadings: [(String, Int)] = []
    @State private var animate = true
    @State private var hasSamplesForSelectedDate = false

    private var currentRHR: Int? {
        model.mostRecentRestingHeartRate
    }

    private var weeklyAverageRHR: Int? {
        model.avgRestingHeartRate60Days
    }

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
        hasSamplesForSelectedDate || !todayRHRReadings.isEmpty
    }

    var body: some View {
        if hasData {
            expandedView
        } else {
            collapsedView
        }
    }

    private var collapsedView: some View {
        HStack(spacing: 14) {
            // Animated heart icon
            ZStack {
                // Pulse ring
                Circle()
                    .stroke(trendColor.opacity(0.3), lineWidth: 2)
                    .frame(width: 40, height: 40)
                    .scaleEffect(animate ? 1.0 : 1.15)
                    .opacity(animate ? 1.0 : 0.0)

                // Icon background
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [trendColor.opacity(0.2), trendColor.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 40, height: 40)

                Image(systemName: "heart.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(trendColor)
            }

            // Main content
            VStack(alignment: .leading, spacing: 3) {
                Text("Resting Heart Rate")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))

                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    if let rhr = currentRHR {
                        Text("\(rhr)")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white)

                        Text("bpm")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    } else {
                        Text("--")
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(.white.opacity(0.3))

                        Text("bpm")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
            }

            Spacer()

            // Trend & average section
            VStack(alignment: .trailing, spacing: 4) {
                // Trend badge
                HStack(spacing: 3) {
                    Image(systemName: trendIcon)
                        .font(.system(size: 9, weight: .bold))
                    Text(trend.rawValue)
                        .font(.system(size: 11, weight: .bold))
                }
                .foregroundColor(trendColor)
                .padding(.horizontal, 8)
                .padding(.vertical, 3)
                .background(
                    Capsule()
                        .fill(trendColor.opacity(0.15))
                )

                // Weekly average
                if let avg = weeklyAverageRHR {
                    Text("Avg: \(avg)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                } else {
                    Text("Avg: --")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.08),
                            Color.white.opacity(0.05)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(
                            LinearGradient(
                                colors: [trendColor.opacity(0.3), trendColor.opacity(0.1)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1
                        )
                )
        )
        .shadow(color: trendColor.opacity(0.1), radius: 4, x: 0, y: 2)
        .onAppear {
            withAnimation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
            ) {
                animate = false
            }
        }
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

            // Heart rate graph
            VStack(alignment: .leading, spacing: 6) {
                Text(Calendar.current.isDateInToday(selectedDate) ? "Last 8 Hours" : "Throughout Day")
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
        .onAppear {
            withAnimation(.easeInOut(duration: 2)) {
                animate = false
            }
            fetchTodayRHRReadings()
        }
        .onChange(of: selectedDate) { _ in
            fetchTodayRHRReadings()
        }
    }

    private func fetchTodayRHRReadings() {
        // Clear data flag while fetching
        hasSamplesForSelectedDate = false

        let calendar = Calendar.current

        // Determine the time range based on selected date
        let isToday = calendar.isDateInToday(selectedDate)
        let endTime: Date
        let startTime: Date

        if isToday {
            // For today, fetch last 8 hours from now
            endTime = Date()
            startTime = calendar.date(byAdding: .hour, value: -8, to: endTime) ?? endTime
        } else {
            // For past dates, fetch the entire day
            let startOfDay = calendar.startOfDay(for: selectedDate)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
            startTime = startOfDay
            endTime = endOfDay
        }

        print("🫀 Fetching heart rate data from \(startTime) to \(endTime) for selected date: \(selectedDate)")

        HealthKitManager.shared.fetchHeartRateData(from: startTime, to: endTime) { samples, error in
            if let error = error {
                print("🫀 Error fetching heart rate data: \(error)")
                DispatchQueue.main.async {
                    self.hasSamplesForSelectedDate = false
                    self.todayRHRReadings = []
                }
                return
            }

            guard let samples = samples, !samples.isEmpty else {
                print("🫀 No heart rate samples found for selected date")
                DispatchQueue.main.async {
                    self.todayRHRReadings = []
                    self.hasSamplesForSelectedDate = false
                }
                return
            }

            print("🫀 Found \(samples.count) heart rate samples for selected date")

            // Mark that we have samples for this date
            DispatchQueue.main.async {
                self.hasSamplesForSelectedDate = true
            }

            // Group readings by hour and calculate average
            var hourlyReadings: [Int: [Double]] = [:]

            for sample in samples {
                let hour = calendar.component(.hour, from: sample.endDate)
                let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                hourlyReadings[hour, default: []].append(heartRate)
            }

            let readings: [(String, Int)]

            if isToday {
                // For today, show last 8 hours
                let currentHour = calendar.component(.hour, from: Date())
                var orderedHours: [Int] = []
                for i in (0..<8).reversed() {
                    let hour = (currentHour - i + 24) % 24
                    orderedHours.append(hour)
                }

                readings = orderedHours.compactMap { hour -> (String, Int)? in
                    guard let values = hourlyReadings[hour], !values.isEmpty else {
                        return nil
                    }
                    let avgValue = Int(values.reduce(0, +) / Double(values.count))
                    let timeString = String(format: "%02d:00", hour)
                    return (timeString, avgValue)
                }
            } else {
                // For past dates, show evenly distributed samples (max 8 hours with data)
                let hoursWithData = hourlyReadings.keys.sorted()
                let sampledHours: [Int]

                if hoursWithData.count <= 8 {
                    sampledHours = hoursWithData
                } else {
                    // Sample evenly across the day
                    let step = max(1, hoursWithData.count / 8)
                    sampledHours = stride(from: 0, to: hoursWithData.count, by: step)
                        .prefix(8)
                        .map { hoursWithData[$0] }
                }

                readings = sampledHours.compactMap { hour -> (String, Int)? in
                    guard let values = hourlyReadings[hour], !values.isEmpty else {
                        return nil
                    }
                    let avgValue = Int(values.reduce(0, +) / Double(values.count))
                    let timeString = String(format: "%02d:00", hour)
                    return (timeString, avgValue)
                }
            }

            print("🫀 Created \(readings.count) hourly readings")
            DispatchQueue.main.async {
                self.todayRHRReadings = readings
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
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.05))

                if readings.isEmpty {
                    // Empty state
                    VStack(spacing: 6) {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 20, weight: .regular))
                            .foregroundColor(.white.opacity(0.3))
                        Text("No recent readings")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                } else {
                    let values = readings.map { $0.1 }
                    let maxValue = values.max() ?? 100
                    let minValue = values.min() ?? 40
                    let range = Double(maxValue - minValue)

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
}
