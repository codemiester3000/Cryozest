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
    @State private var heartPulse = false
    @State private var monitoringPulse = false

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
                // Animated heart icon with pulse
                ZStack {
                    // Outer pulse rings for monitoring indication
                    Circle()
                        .stroke(Color.red.opacity(0.3), lineWidth: 2)
                        .frame(width: 40, height: 40)
                        .scaleEffect(animate ? 1.0 : 1.3)
                        .opacity(animate ? 0.7 : 0.0)

                    Circle()
                        .stroke(Color.red.opacity(0.2), lineWidth: 1.5)
                        .frame(width: 40, height: 40)
                        .scaleEffect(animate ? 1.0 : 1.5)
                        .opacity(animate ? 0.5 : 0.0)

                    // Icon background with subtle glow
                    Circle()
                        .fill(Color.red.opacity(monitoringPulse ? 0.2 : 0.15))
                        .frame(width: 40, height: 40)
                        .shadow(color: Color.red.opacity(monitoringPulse ? 0.4 : 0.2), radius: monitoringPulse ? 8 : 4)

                    // Heart icon with subtle scale animation
                    Image(systemName: "heart.fill")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.red)
                        .scaleEffect(heartPulse ? 1.1 : 1.0)
                }

                // Main metric display
                VStack(alignment: .leading, spacing: 2) {
                    HStack(spacing: 4) {
                        Text("Heart Rate")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))

                        // LIVE indicator for recent data
                        if let recentTime = mostRecentReadingTime,
                           Date().timeIntervalSince(recentTime) < 300 { // < 5 minutes
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 5, height: 5)
                                    .opacity(animate ? 0.4 : 1.0)

                                Text("LIVE")
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.red)
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.red.opacity(0.15))
                            )
                        } else {
                            // Monitoring indicator when not live
                            HStack(spacing: 3) {
                                Circle()
                                    .fill(Color.cyan)
                                    .frame(width: 4, height: 4)
                                    .opacity(monitoringPulse ? 0.3 : 0.8)

                                Text("MONITORING")
                                    .font(.system(size: 7, weight: .semibold))
                                    .foregroundColor(.cyan.opacity(0.7))
                            }
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(
                                Capsule()
                                    .fill(Color.cyan.opacity(0.1))
                            )
                        }
                    }

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
                }
                .padding(.top, 8)
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
            ZStack {
                // Decorative ECG wave pattern in background
                GeometryReader { geo in
                    Path { path in
                        let width = geo.size.width
                        let height = geo.size.height
                        let waveHeight: CGFloat = 20
                        let waveWidth: CGFloat = 40

                        path.move(to: CGPoint(x: 0, y: height - 30))

                        var x: CGFloat = 0
                        while x < width {
                            // ECG-style wave pattern
                            path.addLine(to: CGPoint(x: x, y: height - 30))
                            path.addLine(to: CGPoint(x: x + 5, y: height - 30 - waveHeight))
                            path.addLine(to: CGPoint(x: x + 10, y: height - 30))
                            path.addLine(to: CGPoint(x: x + 15, y: height - 30 + waveHeight/2))
                            path.addLine(to: CGPoint(x: x + 20, y: height - 30))
                            x += waveWidth
                        }
                    }
                    .stroke(Color.red.opacity(0.08), lineWidth: 1.5)
                }
            }
        )
        .modernWidgetCard(style: .healthData)
        .overlay(
            // Corner health status badge
            VStack {
                HStack {
                    Spacer()
                    if trend == .improving {
                        HStack(spacing: 3) {
                            Image(systemName: "heart.circle.fill")
                                .font(.system(size: 10, weight: .bold))
                            Text("Healthy")
                                .font(.system(size: 9, weight: .bold))
                        }
                        .foregroundColor(.green)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(
                            Capsule()
                                .fill(Color.green.opacity(0.2))
                                .overlay(
                                    Capsule()
                                        .stroke(Color.green.opacity(0.4), lineWidth: 1)
                                )
                        )
                        .offset(x: -12, y: 12)
                    }
                }
                Spacer()
            }
        )
        .onAppear {
            print("🫀 [WIDGET] LargeHeartRateWidget appeared with selectedDate: \(selectedDate)")
            print("🫀 [WIDGET] Current todayRHRReadings count: \(todayRHRReadings.count)")

            // Continuous pulse animation for monitoring rings
            withAnimation(
                Animation.easeInOut(duration: 2.0)
                    .repeatForever(autoreverses: true)
            ) {
                animate = false
            }

            // Subtle heart beat pulse
            withAnimation(
                Animation.easeInOut(duration: 0.8)
                    .repeatForever(autoreverses: true)
            ) {
                heartPulse = true
            }

            // Monitoring indicator pulse
            withAnimation(
                Animation.easeInOut(duration: 1.5)
                    .repeatForever(autoreverses: true)
            ) {
                monitoringPulse = true
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
            let calendar = Calendar.current
            let startOfNewDate = calendar.startOfDay(for: newDate)
            print("🫀 [WIDGET] Selected date changed to: \(newDate) (startOfDay: \(startOfNewDate))")
            fetchTodayRHRReadings()
        }
        .onDisappear {
            // Clean up notification observer
            NotificationCenter.default.removeObserver(self, name: NSNotification.Name("HeartRateDataRefreshed"), object: nil)
        }
        .id(Calendar.current.startOfDay(for: selectedDate))
    }

    private func fetchTodayRHRReadings() {
        // Clear existing readings immediately to prevent showing stale data
        DispatchQueue.main.async {
            self.todayRHRReadings = []
        }

        let calendar = Calendar.current

        // CRITICAL: Ensure we're using start of day for the selected date
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay

        // For today, limit endOfDay to current time
        let effectiveEndOfDay: Date
        if calendar.isDateInToday(selectedDate) {
            effectiveEndOfDay = min(endOfDay, Date())
        } else {
            effectiveEndOfDay = endOfDay
        }

        print("🫀 [DEBUG] Fetching heart rate data for selected date: \(selectedDate)")
        print("🫀 [DEBUG] Start of day: \(startOfDay)")
        print("🫀 [DEBUG] End of day: \(effectiveEndOfDay)")
        print("🫀 [DEBUG] Is today: \(calendar.isDateInToday(selectedDate))")

        HealthKitManager.shared.fetchHeartRateData(from: startOfDay, to: effectiveEndOfDay) { samples, error in
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

            print("🫀 [SUCCESS] Found \(samples.count) heart rate samples BEFORE filtering")
            if let firstSample = samples.first {
                print("🫀 [DEBUG] First sample date: \(firstSample.endDate)")
            }
            if let lastSample = samples.last {
                print("🫀 [DEBUG] Last sample date: \(lastSample.endDate)")
            }

            // CRITICAL: Filter samples to ONLY include data from the selected day
            let filteredSamples = samples.filter { sample in
                calendar.isDate(sample.endDate, inSameDayAs: startOfDay)
            }

            print("🫀 [FILTER] Filtered to \(filteredSamples.count) samples that are actually from selected day")

            guard !filteredSamples.isEmpty else {
                print("🫀 [WARNING] No samples found after filtering for selected day")
                DispatchQueue.main.async {
                    self.todayRHRReadings = []
                }
                return
            }

            // Log the actual date range of filtered samples
            if let firstFiltered = filteredSamples.first {
                print("🫀 [DEBUG] First FILTERED sample: \(firstFiltered.endDate)")
            }
            if let lastFiltered = filteredSamples.last {
                print("🫀 [DEBUG] Last FILTERED sample: \(lastFiltered.endDate)")
            }

            // Group readings by hour and calculate average
            var hourlyReadings: [Int: [Double]] = [:]

            for sample in filteredSamples {
                let hour = calendar.component(.hour, from: sample.endDate)
                let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                hourlyReadings[hour, default: []].append(heartRate)

                // Log each sample for debugging
                print("🫀 [SAMPLE] \(sample.endDate) - Hour: \(hour), HR: \(Int(heartRate)) bpm")
            }

            print("🫀 [DEBUG] Grouped into \(hourlyReadings.count) hours with data")

            // Get all hours with data, sorted
            let hoursWithData = hourlyReadings.keys.sorted()
            print("🫀 [DEBUG] Hours with data: \(hoursWithData)")

            // Show all hours without sampling to ensure recent data is visible
            // The graph component will handle displaying them appropriately
            let sampledHours: [Int] = hoursWithData

            print("🫀 [DEBUG] Showing all hours: \(sampledHours)")

            // Create a dictionary of all 24 hours with optional values
            var hourlyData: [Int: Int] = [:]
            for hour in sampledHours {
                let values = hourlyReadings[hour]!
                let avgValue = Int(values.reduce(0, +) / Double(values.count))
                hourlyData[hour] = avgValue

                let period = hour >= 12 ? "PM" : "AM"
                let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
                print("🫀 [DEBUG] Hour \(displayHour) \(period): \(values.count) samples, avg = \(avgValue) bpm")
            }

            // Create readings array with all 24 hours (will show bars only where we have data)
            let readings: [(String, Int)] = (0...23).map { hour in
                let period = hour >= 12 ? "PM" : "AM"
                let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
                let timeString = "\(displayHour) \(period)"
                let value = hourlyData[hour] ?? 0  // 0 means no data for this hour
                return (timeString, value)
            }

            print("🫀 [SUCCESS] Created 24-hour readings array with \(hourlyData.count) hours having data")
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
                    // Split into AM (0-11) and PM (12-23)
                    let amReadings = Array(readings[0...11])
                    let pmReadings = Array(readings[12...23])

                    // Get min/max from non-zero values only
                    let nonZeroValues = readings.map { $0.1 }.filter { $0 > 0 }
                    let maxValue = nonZeroValues.max() ?? 100
                    let minValue = nonZeroValues.min() ?? 40
                    let range = Double(maxValue - minValue)

                    VStack(spacing: 8) {
                        // AM Row (12am - 11am)
                        HourRow(hourReadings: amReadings, minValue: minValue, maxValue: maxValue, range: range, color: color, rowHeight: (geometry.size.height - 24) / 2)

                        // PM Row (12pm - 11pm)
                        HourRow(hourReadings: pmReadings, minValue: minValue, maxValue: maxValue, range: range, color: color, rowHeight: (geometry.size.height - 24) / 2)
                    }
                    .padding(8)
                }
            }
        }
    }
}

struct HourRow: View {
    let hourReadings: [(String, Int)]
    let minValue: Int
    let maxValue: Int
    let range: Double
    let color: Color
    let rowHeight: CGFloat

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(Array(hourReadings.enumerated()), id: \.offset) { index, reading in
                if reading.1 > 0 {
                    // Has data - show bar
                    VStack(spacing: 2) {
                        // Value label
                        Text("\(reading.1)")
                            .font(.system(size: 7, weight: .bold))
                            .foregroundColor(color)
                            .opacity(0.9)

                        // Bar
                        let height = range > 0 ? CGFloat(Double(reading.1 - minValue) / range) * (rowHeight - 20) : 0
                        RoundedRectangle(cornerRadius: 3)
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
                            .font(.system(size: 7, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .frame(maxWidth: .infinity)
                } else {
                    // No data - show empty placeholder
                    VStack(spacing: 2) {
                        Spacer()
                            .frame(height: 10)

                        // Empty placeholder
                        RoundedRectangle(cornerRadius: 3)
                            .fill(Color.white.opacity(0.1))
                            .frame(height: 4)

                        // Time label
                        Text(reading.0)
                            .font(.system(size: 7, weight: .medium))
                            .foregroundColor(.white.opacity(0.3))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
        }
    }
}
