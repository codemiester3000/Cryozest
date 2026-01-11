//
//  LargeHeartRateWidget.swift
//  Cryozest-2
//
//  Clean, minimal heart rate widget
//

import SwiftUI
import HealthKit

struct LargeHeartRateWidget: View {
    @ObservedObject var model: RecoveryGraphModel
    @Binding var expandedMetric: MetricType?
    var selectedDate: Date

    @State private var todayRHRReadings: [(String, Int)] = []
    @State private var showGraph = false
    @State private var lastHourAvgHR: Int? = nil
    @State private var lastHourLabel: String = ""
    @State private var dataLoadId: UUID = UUID()
    @State private var isPressed = false
    @State private var heartPulse = false

    // Accent color - consistent red for heart rate
    private let accentColor = Color(red: 0.95, green: 0.3, blue: 0.3)

    private var currentRHR: Int? {
        if MockDataHelper.useMockData {
            return MockDataHelper.mockHeartRate
        }
        return model.mostRecentRestingHeartRate
    }

    private var mostRecentReadingTime: Date? {
        if MockDataHelper.useMockData {
            return Date().addingTimeInterval(-600) // 10 minutes ago
        }
        return model.mostRecentRestingHeartRateTime
    }

    private var weeklyAverageRHR: Int? {
        if MockDataHelper.useMockData {
            return MockDataHelper.mockAverageHeartRate
        }
        return model.avgRestingHeartRate60Days
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
        case .improving: return Color(red: 0.2, green: 0.8, blue: 0.4)
        case .stable: return .white.opacity(0.6)
        case .elevated: return Color(red: 1.0, green: 0.6, blue: 0.2)
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

    var namespace: Namespace.ID

    private var isExpanded: Bool {
        expandedMetric == .rhr
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            if isExpanded {
                inlineExpandedView
            } else {
                collapsedView
                    .onTapGesture {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()

                        withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                            expandedMetric = .rhr
                        }
                    }
            }
        }
    }

    private var collapsedView: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header row
            HStack(alignment: .center) {
                // Icon with subtle pulse
                ZStack {
                    // Glow when data is recent
                    if let _ = currentRHR {
                        Circle()
                            .fill(accentColor.opacity(0.25))
                            .frame(width: 44, height: 44)
                            .blur(radius: 6)
                            .scaleEffect(heartPulse ? 1.1 : 1.0)
                    }

                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [accentColor.opacity(0.25), accentColor.opacity(0.15)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 40, height: 40)
                        .overlay(
                            Circle()
                                .stroke(accentColor.opacity(0.3), lineWidth: 1)
                        )

                    Image(systemName: "heart.fill")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(accentColor)
                        .scaleEffect(heartPulse ? 1.1 : 1.0)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text("Heart Rate")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        if let rhr = currentRHR {
                            Text("\(rhr)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        } else {
                            Text("--")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.3))
                        }

                        Text("bpm")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }

                Spacer()

                // Trend badge
                HStack(spacing: 4) {
                    Text(trend.rawValue)
                        .font(.system(size: 11, weight: .semibold))
                }
                .foregroundColor(trendColor)
                .padding(.horizontal, 10)
                .padding(.vertical, 5)
                .background(
                    Capsule()
                        .fill(trendColor.opacity(0.2))
                        .overlay(
                            Capsule()
                                .stroke(trendColor.opacity(0.3), lineWidth: 0.5)
                        )
                )
            }

            // Stats row
            HStack(spacing: 16) {
                if let timeText = timeAgoText {
                    HStack(spacing: 4) {
                        Image(systemName: "clock")
                            .font(.system(size: 10))
                            .foregroundColor(.white.opacity(0.4))
                        Text(timeText)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                if let avg = weeklyAverageRHR {
                    HStack(spacing: 4) {
                        Text("Avg: \(avg) bpm")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                Spacer()
            }
        }
        .padding(20)
        .feedWidgetStyle(style: .healthData)
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .onAppear {
            fetchTodayRHRReadings()
            fetchLastHourAvgHR()

            // Subtle heartbeat animation
            withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                heartPulse = true
            }
        }
        .onChange(of: selectedDate) { _ in
            fetchTodayRHRReadings()
        }
        .id(Calendar.current.startOfDay(for: selectedDate))
    }

    private var inlineExpandedView: some View {
        HeartRateExpandedChart(
            model: model,
            expandedMetric: $expandedMetric,
            selectedDate: selectedDate,
            currentRHR: currentRHR,
            weeklyAverageRHR: weeklyAverageRHR,
            lastHourAvgHR: lastHourAvgHR,
            trend: trend,
            trendColor: trendColor,
            accentColor: accentColor
        )
    }

    private func fetchTodayRHRReadings() {
        print("🫀 [FETCH] fetchTodayRHRReadings called, isExpanded: \(isExpanded)")

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
                self.dataLoadId = UUID()  // Trigger animation
                print("🫀 [DEBUG] todayRHRReadings now has \(self.todayRHRReadings.count) items")
            }
        }
    }

    private func fetchLastHourAvgHR() {
        let calendar = Calendar.current
        let now = Date()

        // Calculate the last full hour period
        // If it's 7:30, we want 6:00-7:00
        // lastFullHourEnd = 7:00, lastFullHourStart = 6:00
        var components = calendar.dateComponents([.year, .month, .day, .hour], from: now)
        components.minute = 0
        components.second = 0

        guard let lastFullHourEnd = calendar.date(from: components),
              let lastFullHourStart = calendar.date(byAdding: .hour, value: -1, to: lastFullHourEnd) else {
            return
        }

        // Create the label (e.g., "6-7 PM")
        let startHour = calendar.component(.hour, from: lastFullHourStart)
        let endHour = calendar.component(.hour, from: lastFullHourEnd)

        let startDisplay = startHour == 0 ? 12 : (startHour > 12 ? startHour - 12 : startHour)
        let endDisplay = endHour == 0 ? 12 : (endHour > 12 ? endHour - 12 : endHour)
        let period = endHour >= 12 ? "PM" : "AM"

        let label = "\(startDisplay)-\(endDisplay) \(period)"

        DispatchQueue.main.async {
            self.lastHourLabel = label
        }

        // Fetch heart rate data for that hour
        HealthKitManager.shared.fetchHeartRateData(from: lastFullHourStart, to: lastFullHourEnd) { samples, error in
            guard let samples = samples, !samples.isEmpty, error == nil else {
                DispatchQueue.main.async {
                    self.lastHourAvgHR = nil
                }
                return
            }

            // Filter to only include samples within the hour range
            let filteredSamples = samples.filter { sample in
                sample.endDate >= lastFullHourStart && sample.endDate < lastFullHourEnd
            }

            guard !filteredSamples.isEmpty else {
                DispatchQueue.main.async {
                    self.lastHourAvgHR = nil
                }
                return
            }

            // Calculate average
            let totalHR = filteredSamples.reduce(0.0) { sum, sample in
                sum + sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            }
            let avgHR = Int(totalHR / Double(filteredSamples.count))

            DispatchQueue.main.async {
                self.lastHourAvgHR = avgHR
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
    var animateIn: Bool = true

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
                        HourRow(hourReadings: amReadings, minValue: minValue, maxValue: maxValue, range: range, color: color, rowHeight: (geometry.size.height - 24) / 2, animateIn: animateIn, rowOffset: 0)

                        // PM Row (12pm - 11pm)
                        HourRow(hourReadings: pmReadings, minValue: minValue, maxValue: maxValue, range: range, color: color, rowHeight: (geometry.size.height - 24) / 2, animateIn: animateIn, rowOffset: 12)
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
    var animateIn: Bool = true
    var rowOffset: Int = 0

    // Color coding based on heart rate zones
    private func colorForHeartRate(_ bpm: Int) -> Color {
        switch bpm {
        case 0:
            return .clear
        case 1..<50:
            return Color.purple  // Very low
        case 50..<60:
            return Color.blue    // Low resting
        case 60..<80:
            return Color.green   // Normal resting
        case 80..<100:
            return Color.cyan    // Elevated
        case 100..<120:
            return Color.yellow  // Moderate activity
        case 120..<140:
            return Color.orange  // High activity
        default:
            return Color.red     // Very high
        }
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: 2) {
            ForEach(Array(hourReadings.enumerated()), id: \.offset) { index, reading in
                if reading.1 > 0 {
                    // Has data - show bar
                    let barColor = colorForHeartRate(reading.1)

                    AnimatedBarView(
                        value: reading.1,
                        timeLabel: reading.0,
                        barColor: barColor,
                        minValue: minValue,
                        range: range,
                        rowHeight: rowHeight,
                        animateIn: animateIn,
                        delayIndex: rowOffset + index
                    )
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

struct AnimatedBarView: View {
    let value: Int
    let timeLabel: String
    let barColor: Color
    let minValue: Int
    let range: Double
    let rowHeight: CGFloat
    let animateIn: Bool
    let delayIndex: Int

    @State private var animatedHeight: CGFloat = 0
    @State private var showLabel: Bool = false
    @State private var pulseScale: CGFloat = 1.0

    private var targetHeight: CGFloat {
        let normalizedHeight = range > 0 ? CGFloat(Double(value - minValue) / range) : 0
        let minBarHeight: CGFloat = 6
        let maxBarHeight = rowHeight - 15
        let scaledHeight = pow(normalizedHeight, 0.7)
        return minBarHeight + (scaledHeight * (maxBarHeight - minBarHeight))
    }

    var body: some View {
        VStack(spacing: 2) {
            // Value label
            Text("\(value)")
                .font(.system(size: 7, weight: .bold))
                .foregroundColor(barColor)
                .opacity(showLabel ? 0.9 : 0)
                .scaleEffect(showLabel ? 1.0 : 0.5)

            // Animated bar
            RoundedRectangle(cornerRadius: 3)
                .fill(
                    LinearGradient(
                        colors: [barColor, barColor.opacity(0.6)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .frame(height: animatedHeight)
                .scaleEffect(x: pulseScale, y: 1.0, anchor: .bottom)
                .shadow(color: barColor.opacity(animatedHeight > 0 ? 0.4 : 0), radius: 4, x: 0, y: 0)

            // Time label
            Text(timeLabel)
                .font(.system(size: 7, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
        }
        .onChange(of: animateIn) { shouldAnimate in
            if shouldAnimate {
                triggerAnimation()
            } else {
                // Reset for next animation
                animatedHeight = 0
                showLabel = false
                pulseScale = 1.0
            }
        }
        .onAppear {
            // Always trigger animation on appear if animateIn is true
            if animateIn {
                triggerAnimation()
            }
        }
    }

    private func triggerAnimation() {
        // Staggered delay based on index - creates wave effect
        let delay = Double(delayIndex) * 0.02

        // Grow the bar up with a smooth easeOut animation (less bouncy)
        withAnimation(.easeOut(duration: 0.25).delay(delay)) {
            animatedHeight = targetHeight
        }

        // Show the label slightly after
        withAnimation(.easeOut(duration: 0.15).delay(delay + 0.15)) {
            showLabel = true
        }

        // Subtle pulse effect when bar reaches full height
        DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.2) {
            withAnimation(.easeInOut(duration: 0.1)) {
                pulseScale = 1.08
            }
            withAnimation(.easeInOut(duration: 0.1).delay(0.1)) {
                pulseScale = 1.0
            }
        }
    }
}

struct HeartRateStatCard: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            // Icon
            ZStack {
                Circle()
                    .fill(color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }

            // Text
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))

                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)
            }

            Spacer()
        }
        .padding(12)
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

// MARK: - Heart Rate Time Range
enum HeartRateTimeRange: String, CaseIterable {
    case day = "Day"
    case week = "Week"
    case month = "Month"
}

// MARK: - Heart Rate Data Point
struct HeartRateDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Int
}

// MARK: - Health Event Types
enum HealthEventType {
    case workout(HKWorkoutActivityType)
    case medication

    var icon: String {
        switch self {
        case .workout: return "figure.run.circle.fill"
        case .medication: return "pill.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .workout: return Color(red: 0.95, green: 0.3, blue: 0.3)
        case .medication: return Color(red: 0.4, green: 0.7, blue: 1.0)
        }
    }
}

// MARK: - Health Event
struct HealthEvent: Identifiable {
    let id = UUID()
    let date: Date
    let type: HealthEventType
    let title: String
    let subtitle: String?
    let duration: TimeInterval?
}

// MARK: - Heart Rate Expanded Chart
struct HeartRateExpandedChart: View {
    @ObservedObject var model: RecoveryGraphModel
    @Binding var expandedMetric: MetricType?
    var selectedDate: Date
    var currentRHR: Int?
    var weeklyAverageRHR: Int?
    var lastHourAvgHR: Int?
    var trend: RHRTrend
    var trendColor: Color
    var accentColor: Color

    @State private var selectedTimeRange: HeartRateTimeRange = .day
    @State private var heartRateData: [HeartRateDataPoint] = []
    @State private var healthEvents: [HealthEvent] = []
    @State private var showGraph = false
    @State private var selectedDataPoint: HeartRateDataPoint?
    @State private var selectedEvent: HealthEvent?
    @State private var minHR: Int = 40
    @State private var maxHR: Int = 120

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            // Header with close button
            HStack(alignment: .center) {
                Image(systemName: "heart.fill")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(accentColor)
                    .frame(width: 36, height: 36)
                    .background(
                        Circle()
                            .fill(accentColor.opacity(0.15))
                    )

                VStack(alignment: .leading, spacing: 2) {
                    Text("Heart Rate")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))

                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        if let rhr = currentRHR {
                            Text("\(rhr)")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                        } else {
                            Text("--")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white.opacity(0.3))
                        }

                        Text("bpm")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }

                Spacer()

                // Close button
                Button(action: {
                    let generator = UIImpactFeedbackGenerator(style: .light)
                    generator.impactOccurred()
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        selectedEvent = nil
                        expandedMetric = nil
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            // Divider
            Rectangle()
                .fill(Color.white.opacity(0.06))
                .frame(height: 1)

            // Time Range Selector
            HStack(spacing: 0) {
                ForEach(HeartRateTimeRange.allCases, id: \.self) { range in
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .light)
                        generator.impactOccurred()

                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedTimeRange = range
                        }
                        fetchHeartRateData()
                    }) {
                        Text(range.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(selectedTimeRange == range ? .white : .white.opacity(0.5))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedTimeRange == range ? accentColor.opacity(0.2) : Color.clear)
                            )
                    }
                }
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.06))
            )

            // Heart rate line chart
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(chartTitle)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))

                    Spacer()

                    if let selected = selectedDataPoint {
                        HStack(spacing: 4) {
                            Text("\(selected.value) bpm")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(accentColor)

                            Text("•")
                                .foregroundColor(.white.opacity(0.3))

                            Text(timeFormatter.string(from: selected.date))
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }

                HeartRateLineChart(
                    dataPoints: heartRateData,
                    healthEvents: healthEvents,
                    minValue: minHR,
                    maxValue: maxHR,
                    accentColor: accentColor,
                    selectedDataPoint: $selectedDataPoint,
                    selectedEvent: $selectedEvent,
                    showGraph: showGraph,
                    timeRange: selectedTimeRange
                )
                .frame(height: 240)

                // Time labels directly below graph
                if !heartRateData.isEmpty {
                    XAxisLabels(
                        dataPoints: heartRateData,
                        width: UIScreen.main.bounds.width - 80,
                        timeRange: selectedTimeRange
                    )
                    .padding(.top, 4)
                }
            }

            // Stats row
            HStack(spacing: 0) {
                VStack(spacing: 4) {
                    Text(weeklyAverageRHR.map { "\($0)" } ?? "--")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Avg")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 1, height: 32)

                VStack(spacing: 4) {
                    Text("\(minHR)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Min")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)

                Rectangle()
                    .fill(Color.white.opacity(0.06))
                    .frame(width: 1, height: 32)

                VStack(spacing: 4) {
                    Text("\(maxHR)")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("Max")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
                .frame(maxWidth: .infinity)
            }
            .padding(.vertical, 12)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color.white.opacity(0.04))
            )

            // Selected Event Detail Card
            if let event = selectedEvent {
                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 10) {
                        // Event icon
                        ZStack {
                            Circle()
                                .fill(event.type.color.opacity(0.2))
                                .frame(width: 40, height: 40)

                            Image(systemName: event.type.icon)
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(event.type.color)
                        }

                        VStack(alignment: .leading, spacing: 3) {
                            Text(event.title)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)

                            if let subtitle = event.subtitle {
                                Text(subtitle)
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }

                        Spacer()

                        // Close button
                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                selectedEvent = nil
                            }
                        }) {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 20))
                                .foregroundColor(.white.opacity(0.4))
                        }
                    }

                    HStack(spacing: 16) {
                        HStack(spacing: 4) {
                            Image(systemName: "clock")
                                .font(.system(size: 11))
                                .foregroundColor(.white.opacity(0.5))
                            Text(shortTimeFormatter.string(from: event.date))
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.white.opacity(0.6))
                        }

                        if let duration = event.duration {
                            HStack(spacing: 4) {
                                Image(systemName: "timer")
                                    .font(.system(size: 11))
                                    .foregroundColor(.white.opacity(0.5))
                                Text(formatDuration(duration))
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [
                                    event.type.color.opacity(0.15),
                                    event.type.color.opacity(0.08)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(event.type.color.opacity(0.3), lineWidth: 1.5)
                        )
                )
                .transition(.asymmetric(
                    insertion: .scale.combined(with: .opacity),
                    removal: .scale.combined(with: .opacity)
                ))
            }

            // Events Legend
            if !healthEvents.isEmpty && selectedEvent == nil {
                VStack(alignment: .leading, spacing: 10) {
                    Text("Events")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))

                    HStack(spacing: 16) {
                        // Workout indicator
                        if healthEvents.contains(where: { if case .workout = $0.type { return true }; return false }) {
                            HStack(spacing: 6) {
                                Image(systemName: "figure.run.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 0.95, green: 0.3, blue: 0.3))
                                Text("Workout")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }

                        // Medication indicator
                        if healthEvents.contains(where: { if case .medication = $0.type { return true }; return false }) {
                            HStack(spacing: 6) {
                                Image(systemName: "pill.circle.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(Color(red: 0.4, green: 0.7, blue: 1.0))
                                Text("Medication")
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                        }

                        Spacer()

                        Text("\(healthEvents.count) event\(healthEvents.count == 1 ? "" : "s")")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(.vertical, 10)
                .padding(.horizontal, 14)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.04))
                )
            }
        }
        .padding(20)
        .feedWidgetStyle(style: .healthData)
        .onAppear {
            fetchHeartRateData()
            fetchHealthEvents()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
                    showGraph = true
                }
            }
        }
        .onChange(of: selectedDate) { _ in
            // Refresh data when date changes (e.g., swiping to previous day)
            fetchHeartRateData()
            fetchHealthEvents()
        }
        .onChange(of: selectedTimeRange) { _ in
            // Refresh when time range changes
            fetchHeartRateData()
            fetchHealthEvents()
        }
    }

    private func formatDuration(_ duration: TimeInterval) -> String {
        let minutes = Int(duration / 60)
        if minutes < 60 {
            return "\(minutes)m"
        } else {
            let hours = minutes / 60
            let remainingMinutes = minutes % 60
            if remainingMinutes > 0 {
                return "\(hours)h \(remainingMinutes)m"
            } else {
                return "\(hours)h"
            }
        }
    }

    private var chartTitle: String {
        switch selectedTimeRange {
        case .day:
            return "Today's Heart Rate"
        case .week:
            return "This Week"
        case .month:
            return "This Month"
        }
    }

    private var timeFormatter: DateFormatter {
        let formatter = DateFormatter()
        switch selectedTimeRange {
        case .day:
            formatter.dateFormat = "h:mm a"
        case .week:
            formatter.dateFormat = "EEE h a"
        case .month:
            formatter.dateFormat = "MMM d"
        }
        return formatter
    }

    private var shortTimeFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mm a"
        return formatter
    }

    private func fetchHeartRateData() {
        let calendar = Calendar.current
        let endDate = calendar.isDateInToday(selectedDate) ? Date() : calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: selectedDate)) ?? selectedDate

        let startDate: Date
        switch selectedTimeRange {
        case .day:
            startDate = calendar.startOfDay(for: selectedDate)
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        case .month:
            startDate = calendar.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        }

        HealthKitManager.shared.fetchHeartRateData(from: startDate, to: endDate) { samples, error in
            guard let samples = samples, !samples.isEmpty, error == nil else {
                DispatchQueue.main.async {
                    self.heartRateData = []
                }
                return
            }

            // Convert samples to data points and apply smoothing based on time range
            let rawDataPoints = samples.map { sample in
                HeartRateDataPoint(
                    date: sample.endDate,
                    value: Int(sample.quantity.doubleValue(for: HKUnit(from: "count/min")))
                )
            }.sorted { $0.date < $1.date }

            // Apply smoothing for week and month views
            let smoothedDataPoints: [HeartRateDataPoint]
            switch self.selectedTimeRange {
            case .day:
                // For day view, show all data points (no smoothing)
                smoothedDataPoints = rawDataPoints
            case .week:
                // For week view, aggregate by hour
                smoothedDataPoints = self.aggregateDataByHour(rawDataPoints)
            case .month:
                // For month view, aggregate by 4-hour blocks
                smoothedDataPoints = self.aggregateDataByTimeInterval(rawDataPoints, intervalHours: 4)
            }

            // Calculate min/max with padding
            let values = smoothedDataPoints.map { $0.value }
            let minValue = values.min() ?? 40
            let maxValue = values.max() ?? 120
            let padding = max(5, (maxValue - minValue) / 5)

            DispatchQueue.main.async {
                self.heartRateData = smoothedDataPoints
                self.minHR = max(30, minValue - padding)
                self.maxHR = min(200, maxValue + padding)
            }
        }
    }

    // Aggregate data by hour (for week view)
    private func aggregateDataByHour(_ dataPoints: [HeartRateDataPoint]) -> [HeartRateDataPoint] {
        let calendar = Calendar.current
        var hourlyBuckets: [Date: [Int]] = [:]

        for point in dataPoints {
            let hourStart = calendar.date(bySettingHour: calendar.component(.hour, from: point.date),
                                          minute: 0,
                                          second: 0,
                                          of: point.date) ?? point.date
            hourlyBuckets[hourStart, default: []].append(point.value)
        }

        return hourlyBuckets.map { date, values in
            let avgValue = values.reduce(0, +) / values.count
            return HeartRateDataPoint(date: date, value: avgValue)
        }.sorted { $0.date < $1.date }
    }

    // Aggregate data by custom time interval (for month view)
    private func aggregateDataByTimeInterval(_ dataPoints: [HeartRateDataPoint], intervalHours: Int) -> [HeartRateDataPoint] {
        guard let firstDate = dataPoints.first?.date,
              let lastDate = dataPoints.last?.date else {
            return []
        }

        let intervalSeconds = TimeInterval(intervalHours * 3600)
        var buckets: [Date: [Int]] = [:]

        for point in dataPoints {
            let timeSinceStart = point.date.timeIntervalSince(firstDate)
            let bucketIndex = Int(timeSinceStart / intervalSeconds)
            let bucketStart = firstDate.addingTimeInterval(TimeInterval(bucketIndex) * intervalSeconds)
            buckets[bucketStart, default: []].append(point.value)
        }

        return buckets.map { date, values in
            let avgValue = values.reduce(0, +) / values.count
            return HeartRateDataPoint(date: date, value: avgValue)
        }.sorted { $0.date < $1.date }
    }

    private func fetchHealthEvents() {
        let calendar = Calendar.current
        let endDate = calendar.isDateInToday(selectedDate) ? Date() : calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: selectedDate)) ?? selectedDate

        let startDate: Date
        switch selectedTimeRange {
        case .day:
            startDate = calendar.startOfDay(for: selectedDate)
        case .week:
            startDate = calendar.date(byAdding: .day, value: -7, to: endDate) ?? endDate
        case .month:
            startDate = calendar.date(byAdding: .day, value: -30, to: endDate) ?? endDate
        }

        var allEvents: [HealthEvent] = []

        // Fetch workouts
        HealthKitManager.shared.fetchWorkouts(from: startDate, to: endDate) { workouts, error in
            if let workouts = workouts, error == nil {
                let workoutEvents = workouts.map { workout in
                    HealthEvent(
                        date: workout.startDate,
                        type: .workout(workout.workoutActivityType),
                        title: self.workoutTypeName(workout.workoutActivityType),
                        subtitle: self.workoutSubtitle(workout),
                        duration: workout.duration
                    )
                }
                allEvents.append(contentsOf: workoutEvents)
            }

            // TODO: Fetch medications from Core Data
            // For now, we'll just use workout events
            DispatchQueue.main.async {
                self.healthEvents = allEvents.sorted { $0.date < $1.date }
            }
        }
    }

    private func workoutTypeName(_ type: HKWorkoutActivityType) -> String {
        switch type {
        case .running: return "Running"
        case .cycling: return "Cycling"
        case .swimming: return "Swimming"
        case .walking: return "Walking"
        case .hiking: return "Hiking"
        case .functionalStrengthTraining: return "Strength Training"
        case .yoga: return "Yoga"
        case .elliptical: return "Elliptical"
        case .rowing: return "Rowing"
        case .pilates: return "Pilates"
        case .basketball: return "Basketball"
        case .boxing: return "Boxing"
        case .dance: return "Dance"
        case .stairClimbing: return "Stair Climbing"
        default: return "Workout"
        }
    }

    private func workoutSubtitle(_ workout: HKWorkout) -> String {
        let calories = workout.totalEnergyBurned?.doubleValue(for: .kilocalorie()) ?? 0
        if calories > 0 {
            return "\(Int(calories)) cal"
        }
        return formatDuration(workout.duration)
    }
}

// MARK: - Heart Rate Line Chart
struct HeartRateLineChart: View {
    let dataPoints: [HeartRateDataPoint]
    let healthEvents: [HealthEvent]
    let minValue: Int
    let maxValue: Int
    let accentColor: Color
    @Binding var selectedDataPoint: HeartRateDataPoint?
    @Binding var selectedEvent: HealthEvent?
    var showGraph: Bool
    var timeRange: HeartRateTimeRange

    @State private var animationProgress: CGFloat = 0

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Background
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))

                if dataPoints.isEmpty {
                    // Empty state
                    VStack(spacing: 8) {
                        Image(systemName: "heart.text.square")
                            .font(.system(size: 24, weight: .regular))
                            .foregroundColor(.white.opacity(0.3))
                        Text("No heart rate data")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                    }
                } else {
                    // Chart content
                    ZStack(alignment: .topLeading) {
                        // Y-axis labels and grid lines
                        YAxisLabels(minValue: minValue, maxValue: maxValue, height: geometry.size.height)

                        // Main chart area with padding for labels
                        HStack(spacing: 0) {
                            // Y-axis space
                            Color.clear
                                .frame(width: 40)

                            // Chart area
                            ZStack(alignment: .leading) {
                                // Grid lines
                                GridLines(count: 5, height: geometry.size.height - 20)
                                    .padding(.top, 10)

                                // Heart rate line and gradient (behind markers)
                                HeartRateLine(
                                    dataPoints: dataPoints,
                                    minValue: minValue,
                                    maxValue: maxValue,
                                    width: geometry.size.width - 40,
                                    height: geometry.size.height - 20,
                                    accentColor: accentColor,
                                    animationProgress: animationProgress
                                )
                                .padding(.top, 10)
                                .allowsHitTesting(false)

                                // Health event markers (on top, tappable)
                                ForEach(healthEvents) { event in
                                    HealthEventMarker(
                                        event: event,
                                        dataPoints: dataPoints,
                                        width: geometry.size.width - 40,
                                        height: geometry.size.height - 20,
                                        isSelected: selectedEvent?.id == event.id,
                                        onTap: {
                                            let generator = UIImpactFeedbackGenerator(style: .medium)
                                            generator.impactOccurred()
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                selectedEvent = event
                                            }
                                        }
                                    )
                                    .padding(.top, 10)
                                }
                            }
                        }
                    }
                }
            }
        }
        .onChange(of: showGraph) { show in
            if show {
                withAnimation(.easeOut(duration: 1.2)) {
                    animationProgress = 1.0
                }
            } else {
                animationProgress = 0
            }
        }
        .onAppear {
            if showGraph {
                withAnimation(.easeOut(duration: 1.2)) {
                    animationProgress = 1.0
                }
            }
        }
    }
}

// MARK: - Y-Axis Labels
struct YAxisLabels: View {
    let minValue: Int
    let maxValue: Int
    let height: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(0..<5) { index in
                let value = maxValue - (index * (maxValue - minValue) / 4)
                Text("\(value)")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(width: 35, alignment: .trailing)
                    .offset(y: index == 0 ? 4 : (index == 4 ? -4 : 0))

                if index < 4 {
                    Spacer()
                }
            }
        }
        .frame(height: height - 20)
        .padding(.top, 10)
        .padding(.leading, 8)
    }
}

// MARK: - Grid Lines
struct GridLines: View {
    let count: Int
    let height: CGFloat

    var body: some View {
        VStack(spacing: 0) {
            ForEach(0..<count, id: \.self) { index in
                Rectangle()
                    .fill(Color.white.opacity(index == count - 1 ? 0.15 : 0.06))
                    .frame(height: 1)

                if index < count - 1 {
                    Spacer()
                }
            }
        }
        .frame(height: height)
    }
}

// MARK: - X-Axis Labels
struct XAxisLabels: View {
    let dataPoints: [HeartRateDataPoint]
    let width: CGFloat
    let timeRange: HeartRateTimeRange

    private var labelPoints: [(String, CGFloat)] {
        guard !dataPoints.isEmpty else { return [] }

        let labelCount: Int
        let formatter = DateFormatter()

        switch timeRange {
        case .day:
            labelCount = 6 // Every 4 hours: 12am, 4am, 8am, 12pm, 4pm, 8pm
            formatter.dateFormat = "ha"
        case .week:
            labelCount = 7 // Every day
            formatter.dateFormat = "EEE"
        case .month:
            labelCount = 6 // Every ~5 days
            formatter.dateFormat = "M/d"
        }

        var labels: [(String, CGFloat)] = []

        // Evenly distribute labels across the width
        for i in 0..<labelCount {
            let fraction = CGFloat(i) / CGFloat(labelCount - 1)
            let dataIndex = Int(fraction * CGFloat(dataPoints.count - 1))
            let point = dataPoints[dataIndex]
            let x = fraction * width

            let labelText = formatter.string(from: point.date).lowercased()
            labels.append((labelText, x))
        }

        return labels
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(labelPoints.indices, id: \.self) { index in
                if index == 0 {
                    Text(labelPoints[index].0)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if index == labelPoints.count - 1 {
                    Text(labelPoints[index].0)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .trailing)
                } else {
                    Text(labelPoints[index].0)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .frame(maxWidth: .infinity, alignment: .center)
                }
            }
        }
        .frame(width: width, height: 20)
    }
}

// MARK: - Health Event Marker
struct HealthEventMarker: View {
    let event: HealthEvent
    let dataPoints: [HeartRateDataPoint]
    let width: CGFloat
    let height: CGFloat
    let isSelected: Bool
    let onTap: () -> Void

    @State private var isPressed = false

    private var xPosition: CGFloat? {
        guard !dataPoints.isEmpty,
              let firstDate = dataPoints.first?.date,
              let lastDate = dataPoints.last?.date else {
            return nil
        }

        let totalDuration = lastDate.timeIntervalSince(firstDate)
        guard totalDuration > 0 else { return nil }

        let eventOffset = event.date.timeIntervalSince(firstDate)
        return CGFloat(eventOffset / totalDuration) * width
    }

    var body: some View {
        GeometryReader { geometry in
            if let x = xPosition, x >= 0, x <= width {
                // Use HStack to position at exact x location
                HStack(spacing: 0) {
                    Spacer()
                        .frame(width: max(0, x - 15))

                    // Wide tappable button area (30pt wide)
                    Button(action: {
                        print("🎯 Event marker tapped: \(event.title)")
                        onTap()
                    }) {
                        ZStack {
                            // Wide invisible tap area
                            Color.clear
                                .frame(width: 30, height: geometry.size.height)

                            // Vertical line
                            VStack(spacing: 0) {
                                // Icon at top
                                ZStack {
                                    // Glow effect when selected
                                    if isSelected {
                                        Circle()
                                            .fill(event.type.color.opacity(0.4))
                                            .frame(width: 36, height: 36)
                                            .blur(radius: 6)
                                    }

                                    // Icon background circle
                                    Circle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    event.type.color,
                                                    event.type.color.opacity(0.8)
                                                ],
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .frame(width: isSelected ? 32 : 24, height: isSelected ? 32 : 24)
                                        .overlay(
                                            Circle()
                                                .stroke(Color.white, lineWidth: isSelected ? 2.5 : 2)
                                        )
                                        .shadow(color: event.type.color.opacity(0.6), radius: isSelected ? 8 : 4)

                                    // Icon
                                    Image(systemName: event.type.icon)
                                        .font(.system(size: isSelected ? 16 : 12, weight: .bold))
                                        .foregroundColor(.white)
                                }
                                .scaleEffect(isPressed ? 0.85 : 1.0)
                                .padding(.bottom, 4)

                                // Vertical line extending down
                                ZStack {
                                    // Solid gradient background
                                    Rectangle()
                                        .fill(
                                            LinearGradient(
                                                colors: [
                                                    event.type.color.opacity(isSelected ? 0.8 : 0.5),
                                                    event.type.color.opacity(isSelected ? 0.6 : 0.3)
                                                ],
                                                startPoint: .top,
                                                endPoint: .bottom
                                            )
                                        )
                                        .frame(width: isSelected ? 3 : 2.5)
                                        .shadow(color: event.type.color.opacity(isSelected ? 0.5 : 0.3), radius: isSelected ? 6 : 3)

                                    // Dashed overlay
                                    Rectangle()
                                        .stroke(
                                            style: StrokeStyle(
                                                lineWidth: isSelected ? 3 : 2.5,
                                                dash: [8, 4]
                                            )
                                        )
                                        .foregroundColor(isSelected ? event.type.color.opacity(0.9) : event.type.color.opacity(0.7))
                                        .frame(width: isSelected ? 3 : 2.5)
                                }
                            }
                        }
                    }
                    .buttonStyle(PlainButtonStyle())
                    .simultaneousGesture(
                        DragGesture(minimumDistance: 0)
                            .onChanged { _ in
                                isPressed = true
                            }
                            .onEnded { _ in
                                isPressed = false
                            }
                    )

                    Spacer()
                }
                .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isSelected)
                .animation(.spring(response: 0.2, dampingFraction: 0.6), value: isPressed)
            }
        }
    }
}

// MARK: - Heart Rate Line
struct HeartRateLine: View {
    let dataPoints: [HeartRateDataPoint]
    let minValue: Int
    let maxValue: Int
    let width: CGFloat
    let height: CGFloat
    let accentColor: Color
    let animationProgress: CGFloat

    // Heart rate zone colors (Whoop-inspired)
    private func colorForHeartRate(_ bpm: Int) -> Color {
        switch bpm {
        case 0..<60:
            return Color(red: 0.5, green: 0.6, blue: 0.7) // Gray-blue (rest)
        case 60..<100:
            return Color(red: 0.4, green: 0.7, blue: 1.0) // Light blue (recovery)
        case 100..<120:
            return Color(red: 0.3, green: 0.8, blue: 0.9) // Cyan (light cardio)
        case 120..<140:
            return Color(red: 0.4, green: 0.9, blue: 0.5) // Green (moderate cardio)
        case 140..<160:
            return Color(red: 1.0, green: 0.7, blue: 0.3) // Orange (intense)
        default:
            return Color(red: 1.0, green: 0.4, blue: 0.4) // Red (peak)
        }
    }

    private func normalizedY(for value: Int) -> CGFloat {
        let range = CGFloat(maxValue - minValue)
        guard range > 0 else { return height / 2 }
        let normalized = CGFloat(value - minValue) / range
        return height * (1 - normalized)
    }

    private func path(in size: CGSize) -> Path {
        var path = Path()
        guard dataPoints.count > 1 else { return path }

        let points: [(x: CGFloat, y: CGFloat)] = dataPoints.enumerated().map { index, point in
            let x = CGFloat(index) / CGFloat(dataPoints.count - 1) * size.width
            let y = normalizedY(for: point.value)
            return (x, y)
        }

        path.move(to: CGPoint(x: points[0].x, y: points[0].y))

        // Create smooth curve using quadratic bezier
        for i in 1..<points.count {
            let current = points[i]
            let previous = points[i - 1]
            let midX = (previous.x + current.x) / 2

            path.addQuadCurve(
                to: CGPoint(x: current.x, y: current.y),
                control: CGPoint(x: midX, y: previous.y)
            )
        }

        return path
    }

    private func gradientPath(in size: CGSize) -> Path {
        var path = self.path(in: size)

        // Close the path for gradient fill
        if let lastPoint = dataPoints.last {
            let lastX = CGFloat(dataPoints.count - 1) / CGFloat(dataPoints.count - 1) * size.width
            path.addLine(to: CGPoint(x: lastX, y: size.height))
            path.addLine(to: CGPoint(x: 0, y: size.height))
        }
        path.closeSubpath()

        return path
    }

    // Create gradient colors based on heart rate values
    private var lineGradient: LinearGradient {
        let avgHR = dataPoints.map { $0.value }.reduce(0, +) / max(1, dataPoints.count)
        let dominantColor = colorForHeartRate(avgHR)

        return LinearGradient(
            colors: [
                dominantColor,
                dominantColor.opacity(0.8)
            ],
            startPoint: .leading,
            endPoint: .trailing
        )
    }

    private var fillGradient: LinearGradient {
        let avgHR = dataPoints.map { $0.value }.reduce(0, +) / max(1, dataPoints.count)
        let dominantColor = colorForHeartRate(avgHR)

        return LinearGradient(
            colors: [
                dominantColor.opacity(0.3 * animationProgress),
                dominantColor.opacity(0.15 * animationProgress),
                dominantColor.opacity(0.05 * animationProgress),
                Color.clear
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Gradient fill under the line
                gradientPath(in: geometry.size)
                    .fill(fillGradient)

                // Main line with gradient stroke
                path(in: geometry.size)
                    .trim(from: 0, to: animationProgress)
                    .stroke(lineGradient, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                    .shadow(color: Color.white.opacity(0.2 * animationProgress), radius: 2, x: 0, y: 1)

                // Segment-based coloring overlay for visual richness
                if animationProgress > 0.5 {
                    ForEach(0..<max(1, dataPoints.count - 1), id: \.self) { index in
                        if index < dataPoints.count - 1 {
                            let currentPoint = dataPoints[index]
                            let nextPoint = dataPoints[index + 1]
                            let avgBPM = (currentPoint.value + nextPoint.value) / 2
                            let segmentColor = colorForHeartRate(avgBPM)

                            let x1 = CGFloat(index) / CGFloat(dataPoints.count - 1) * geometry.size.width
                            let y1 = normalizedY(for: currentPoint.value)
                            let x2 = CGFloat(index + 1) / CGFloat(dataPoints.count - 1) * geometry.size.width
                            let y2 = normalizedY(for: nextPoint.value)

                            Path { path in
                                path.move(to: CGPoint(x: x1, y: y1))
                                let midX = (x1 + x2) / 2
                                path.addQuadCurve(
                                    to: CGPoint(x: x2, y: y2),
                                    control: CGPoint(x: midX, y: y1)
                                )
                            }
                            .trim(from: 0, to: min(1.0, (animationProgress * CGFloat(dataPoints.count - 1) - CGFloat(index))))
                            .stroke(
                                segmentColor.opacity(0.6),
                                style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                            )
                        }
                    }
                }
            }
        }
        .frame(height: height)
    }
}

// MARK: - Expanded Heart Rate Widget
struct ExpandedHeartRateWidget: View {
    @ObservedObject var model: RecoveryGraphModel
    @Binding var expandedMetric: MetricType?
    var namespace: Namespace.ID
    let selectedDate: Date

    @State private var todayRHRReadings: [(String, Int)] = []
    @State private var animate = false
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

    private var trendColor: Color {
        guard let current = currentRHR, let avg = weeklyAverageRHR else { return .cyan }
        let diff = current - avg
        if diff < -3 {
            return .green
        } else if diff > 3 {
            return .orange
        } else {
            return .cyan
        }
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack(alignment: .center) {
                    // Animated heart icon
                    ZStack {
                        // Outer pulse rings
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

                        // Icon background
                        Circle()
                            .fill(Color.red.opacity(monitoringPulse ? 0.2 : 0.15))
                            .frame(width: 40, height: 40)
                            .shadow(color: Color.red.opacity(monitoringPulse ? 0.4 : 0.2), radius: monitoringPulse ? 8 : 4)

                        // Heart icon
                        Image(systemName: "heart.fill")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(.red)
                            .scaleEffect(heartPulse ? 1.1 : 1.0)
                    }

                    // Main metric display
                    VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 4) {
                            Text("Heart Rate")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))

                            // LIVE indicator
                            if let recentTime = mostRecentReadingTime,
                               Date().timeIntervalSince(recentTime) < 300 {
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
                                // Monitoring indicator
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

                        HStack(alignment: .lastTextBaseline, spacing: 3) {
                            if let rhr = currentRHR {
                                Text("\(rhr)")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(.white)
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

                    // Close button
                    Button(action: {
                        let generator = UIImpactFeedbackGenerator(style: .medium)
                        generator.impactOccurred()

                        withAnimation(.spring(response: 0.8, dampingFraction: 0.85)) {
                            expandedMetric = nil
                        }
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                // Detailed graph
                VStack(alignment: .leading, spacing: 8) {
                    Text("Throughout Day")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))

                    RHRReadingsGraph(readings: todayRHRReadings, color: trendColor)
                        .frame(height: 200)
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.red.opacity(0.1), lineWidth: 1)
                        )
                )

                // Stats row
                HStack(spacing: 12) {
                    HeartRateStatCard(
                        icon: "chart.line.uptrend.xyaxis",
                        label: "Weekly Avg",
                        value: weeklyAverageRHR.map { "\($0) bpm" } ?? "-- bpm",
                        color: .cyan
                    )

                    if let current = currentRHR, let avg = weeklyAverageRHR {
                        let diff = current - avg
                        HeartRateStatCard(
                            icon: diff < 0 ? "arrow.down.heart" : "arrow.up",
                            label: "vs Average",
                            value: "\(abs(diff)) bpm",
                            color: diff < 0 ? .green : .orange
                        )
                    }
                }
            }
            .padding(16)
        }
        .feedWidgetStyle(style: .healthData)
        .matchedGeometryEffect(id: "heart-rate-widget", in: namespace)
        .onAppear {
            // Fetch heart rate data
            fetchTodayRHRReadings()

            // Start animations
            withAnimation(Animation.easeInOut(duration: 2.5).repeatForever(autoreverses: true)) {
                animate = true
            }
            withAnimation(Animation.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                heartPulse = true
            }
            withAnimation(Animation.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
                monitoringPulse = true
            }
        }
    }

    private func fetchTodayRHRReadings() {
        DispatchQueue.main.async {
            self.todayRHRReadings = []
        }

        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) ?? startOfDay
        let effectiveEndOfDay = calendar.isDateInToday(selectedDate) ? min(endOfDay, Date()) : endOfDay

        HealthKitManager.shared.fetchHeartRateData(from: startOfDay, to: effectiveEndOfDay) { samples, error in
            guard let samples = samples, !samples.isEmpty, error == nil else {
                DispatchQueue.main.async { self.todayRHRReadings = [] }
                return
            }

            let filteredSamples = samples.filter { calendar.isDate($0.endDate, inSameDayAs: startOfDay) }
            guard !filteredSamples.isEmpty else {
                DispatchQueue.main.async { self.todayRHRReadings = [] }
                return
            }

            var hourlyReadings: [Int: [Double]] = [:]
            for sample in filteredSamples {
                let hour = calendar.component(.hour, from: sample.endDate)
                let heartRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                hourlyReadings[hour, default: []].append(heartRate)
            }

            var hourlyData: [Int: Int] = [:]
            for (hour, values) in hourlyReadings {
                hourlyData[hour] = Int(values.reduce(0, +) / Double(values.count))
            }

            let readings: [(String, Int)] = (0...23).map { hour in
                let period = hour >= 12 ? "PM" : "AM"
                let displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour)
                let timeString = "\(displayHour) \(period)"
                let value = hourlyData[hour] ?? 0
                return (timeString, value)
            }

            DispatchQueue.main.async {
                self.todayRHRReadings = readings
            }
        }
    }
}
