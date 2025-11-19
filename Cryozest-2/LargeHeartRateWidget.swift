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

    private var currentRHR: Int? {
        model.mostRecentRestingHeartRate
    }

    private var mostRecentReadingTime: Date? {
        model.mostRecentRestingHeartRateTime
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

    private var timeAgoText: String? {
        guard let recentTime = mostRecentReadingTime else { return nil }

        let now = Date()
        let interval = now.timeIntervalSince(recentTime)
        let minutes = Int(interval / 60)
        let hours = Int(interval / 3600)

        if minutes < 1 {
            return "Just now"
        } else if minutes < 60 {
            return "\(minutes) min ago"
        } else if hours < 24 {
            return "\(hours) hr\(hours == 1 ? "" : "s") ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days) day\(days == 1 ? "" : "s") ago"
        }
    }

    var body: some View {
        // Always show expanded view with graph
        expandedView
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
                Text("Heart Rate")
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
        .padding(16)
        .modernWidgetCard(style: .healthData)
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
                    Text("Heart Rate")
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

                    if let timeText = timeAgoText {
                        Text(timeText)
                            .font(.system(size: 10, weight: .medium))
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
                Text("Throughout Day")
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
            print("🫀 [WIDGET] LargeHeartRateWidget appeared with selectedDate: \(selectedDate)")
            print("🫀 [WIDGET] Current todayRHRReadings count: \(todayRHRReadings.count)")
            withAnimation(.easeInOut(duration: 2)) {
                animate = false
            }
            fetchTodayRHRReadings()

            // Listen for heart rate data refresh notifications
            NotificationCenter.default.addObserver(
                forName: NSNotification.Name("HeartRateDataRefreshed"),
                object: nil,
                queue: .main
            ) { _ in
                print("🫀 [WIDGET] Received heart rate refresh notification, updating graph")
                fetchTodayRHRReadings()
            }
        }
        .onChange(of: selectedDate) { newDate in
            print("🫀 [WIDGET] Selected date changed to: \(newDate)")
            fetchTodayRHRReadings()
        }
        .onDisappear {
            // Clean up notification observer
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name("HeartRateDataRefreshed"), object: nil)
        }
    }

    private func fetchTodayRHRReadings() {
        let calendar = Calendar.current

        // Fetch entire day for selected date
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

        print("🫀 [DEBUG] Fetching heart rate data from \(startOfDay) to \(endOfDay) for selected date: \(selectedDate)")
        print("🫀 [DEBUG] Is today: \(calendar.isDateInToday(selectedDate))")

        HealthKitManager.shared.fetchHeartRateData(from: startOfDay, to: endOfDay) { samples, error in
            if let error = error {
                print("🫀 [ERROR] Error fetching heart rate data: \(error)")
                DispatchQueue.main.async {
                    self.todayRHRReadings = []
                }
                return
            }

            guard let samples = samples, !samples.isEmpty else {
                print("🫀 [WARNING] No heart rate samples found for selected date")
                DispatchQueue.main.async {
                    self.todayRHRReadings = []
                }
                return
            }

            print("🫀 [SUCCESS] Found \(samples.count) heart rate samples for selected date")
            if let firstSample = samples.first {
                print("🫀 [DEBUG] First sample date: \(firstSample.endDate)")
            }
            if let lastSample = samples.last {
                print("🫀 [DEBUG] Last sample date: \(lastSample.endDate)")
            }

            // Group readings by hour and calculate average
            var hourlyReadings: [Int: [Double]] = [:]

            for sample in samples {
                let hour = calendar.component(.hour, from: sample.endDate)
                let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                hourlyReadings[hour, default: []].append(heartRate)
            }

            print("🫀 [DEBUG] Grouped into \(hourlyReadings.count) hours with data")

            // Get all hours with data, sorted
            let hoursWithData = hourlyReadings.keys.sorted()
            print("🫀 [DEBUG] Hours with data: \(hoursWithData)")

            // Sample hours if we have too many (max 10 for readability)
            let sampledHours: [Int]
            if hoursWithData.count <= 10 {
                sampledHours = hoursWithData
            } else {
                // Sample evenly across available hours
                let step = max(1, hoursWithData.count / 10)
                sampledHours = stride(from: 0, to: hoursWithData.count, by: step)
                    .prefix(10)
                    .map { hoursWithData[$0] }
            }

            print("🫀 [DEBUG] Sampled hours: \(sampledHours)")

            // Create readings for all sampled hours
            let readings: [(String, Int)] = sampledHours.map { hour in
                let values = hourlyReadings[hour]!
                let avgValue = Int(values.reduce(0, +) / Double(values.count))

                // Convert to 12-hour format with AM/PM
                let period = hour >= 12 ? "PM" : "AM"
                let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
                let timeString = "\(displayHour) \(period)"

                print("🫀 [DEBUG] Hour \(timeString): \(values.count) samples, avg = \(avgValue) bpm")
                return (timeString, avgValue)
            }

            print("🫀 [SUCCESS] Created \(readings.count) hourly readings: \(readings)")
            DispatchQueue.main.async {
                print("🫀 [DEBUG] Setting todayRHRReadings on main thread")
                self.todayRHRReadings = readings
                print("🫀 [DEBUG] todayRHRReadings now has \(self.todayRHRReadings.count) items")
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
        let _ = print("🫀 [GRAPH] RHRReadingsGraph rendering with \(readings.count) readings: \(readings)")

        GeometryReader { geometry in
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.05))

                if readings.isEmpty {
                    let _ = print("🫀 [GRAPH] Showing empty state")
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
                    let _ = print("🫀 [GRAPH] Showing graph with data")
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
