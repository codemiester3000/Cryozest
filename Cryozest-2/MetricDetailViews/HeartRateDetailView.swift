//
//  HeartRateDetailView.swift
//  Cryozest-2
//
//  Redesigned: tabbed charts (Today/7Day/30Day), workout overlays,
//  waking vs sleep HR bar graphs, gamified tier system.
//

import SwiftUI
import Charts
import HealthKit

struct HeartRateDetailView: View {
    @ObservedObject var model: RecoveryGraphModel
    var rhrImpacts: [HabitImpact] = []

    @Environment(\.managedObjectContext) private var viewContext

    // MARK: - State

    @State private var currentRHR: Int?
    @State private var avg30Day: Int?
    @State private var avg7Day: Int?
    @State private var avg1Day: Int?

    @State private var selectedChartTab: ChartTab = .today

    // Today's intraday HR data
    @State private var todayHRSamples: [(Date, Double)] = []
    @State private var todayWorkouts: [WorkoutOverlay] = []

    // 7-day daily RHR
    @State private var last7DaysRHR: [(Date, Int)] = []

    // 30-day daily RHR
    @State private var last30DaysRHR: [(Date, Int)] = []

    // Waking vs sleep avg HR
    @State private var wakingAvgHR: Int?
    @State private var sleepAvgHR: Int?

    enum ChartTab: String, CaseIterable {
        case today = "Today"
        case sevenDay = "7 Day"
        case thirtyDay = "30 Day"
    }

    struct WorkoutOverlay: Identifiable {
        let id = UUID()
        let startDate: Date
        let endDate: Date
        let name: String
        let color: Color
    }

    private let shortDateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "M/d"
        return f
    }()

    private let timeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "ha"
        f.amSymbol = "a"
        f.pmSymbol = "p"
        return f
    }()

    // MARK: - Body

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            heroCard
            chartSection
            heartRateInsightsCard
            tierCard
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .onAppear { loadAllData() }
        .onChange(of: model.selectedDate) { _ in loadAllData() }
    }

    // MARK: - Load Data

    private func loadAllData() {
        let date = model.selectedDate
        let hkm = HealthKitManager.shared
        let calendar = Calendar.current

        // Current day RHR
        hkm.fetchMostRecentRestingHeartRate(for: date) { rhr, _ in
            DispatchQueue.main.async { self.currentRHR = rhr }
        }

        // N-day averages
        hkm.fetchNDayAvgRestingHeartRate(numDays: 30) { val in
            DispatchQueue.main.async { self.avg30Day = val }
        }
        hkm.fetchNDayAvgRestingHeartRate(numDays: 7) { val in
            DispatchQueue.main.async { self.avg7Day = val }
        }
        hkm.fetchNDayAvgRestingHeartRate(numDays: 1) { val in
            DispatchQueue.main.async { self.avg1Day = val }
        }

        // Today's intraday HR
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        hkm.fetchHeartRateData(from: startOfDay, to: endOfDay) { samples, _ in
            let bpmUnit = HKUnit(from: "count/min")
            let pts: [(Date, Double)] = (samples ?? []).map { sample in
                (sample.startDate, sample.quantity.doubleValue(for: bpmUnit))
            }
            DispatchQueue.main.async { self.todayHRSamples = pts }
        }

        // Today's workouts
        hkm.fetchWorkouts(from: startOfDay, to: endOfDay) { workouts, _ in
            let overlays: [WorkoutOverlay] = (workouts ?? []).map { w in
                WorkoutOverlay(
                    startDate: w.startDate,
                    endDate: w.endDate,
                    name: w.workoutActivityType.commonName,
                    color: w.workoutActivityType.overlayColor
                )
            }
            DispatchQueue.main.async { self.todayWorkouts = overlays }
        }

        // 7-day and 30-day RHR trend
        fetchRHRTrend(days: 7, from: date) { entries in
            DispatchQueue.main.async { self.last7DaysRHR = entries }
        }
        fetchRHRTrend(days: 30, from: date) { entries in
            DispatchQueue.main.async { self.last30DaysRHR = entries }
        }

        // Waking vs sleep HR
        hkm.fetchAvgHeartRateDuringWakingHours(for: date) { val in
            DispatchQueue.main.async { self.wakingAvgHR = val != nil ? Int(val!) : nil }
        }
        hkm.fetchAverageRHRDuringSleep(for: date) { val in
            DispatchQueue.main.async { self.sleepAvgHR = val != nil ? Int(val!) : nil }
        }
    }

    private func fetchRHRTrend(days: Int, from date: Date, completion: @escaping ([(Date, Int)]) -> Void) {
        let calendar = Calendar.current
        let hkm = HealthKitManager.shared
        let group = DispatchGroup()
        var entries: [(Date, Int)] = []
        let lock = NSLock()

        for offset in 0..<days {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: date) else { continue }
            group.enter()
            hkm.fetchMostRecentRestingHeartRate(for: day) { rhr, _ in
                if let rhr = rhr {
                    lock.lock()
                    entries.append((day, rhr))
                    lock.unlock()
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            completion(entries.sorted { $0.0 < $1.0 })
        }
    }

    // MARK: - Section 1: Hero Card

    private var heroCard: some View {
        VStack(spacing: 14) {
            // Top row: averages
            HStack(spacing: 0) {
                avgPill(label: "30d", value: avg30Day)
                Spacer()
                avgPill(label: "7d", value: avg7Day)
                Spacer()
                avgPill(label: "1d", value: avg1Day)
            }

            // Large RHR number
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                if let hr = currentRHR {
                    Text("\(hr)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                } else {
                    Text("--")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.3))
                }
                Text("bpm")
                    .font(.system(size: 18, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            // Contextual subtitle
            if let hr = currentRHR, let avg = avg30Day, avg > 0 {
                let diff = avg - hr
                if diff > 0 {
                    Text("\(diff) bpm below your 30-day avg")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.green)
                } else if diff < 0 {
                    Text("\(abs(diff)) bpm above your 30-day avg")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.orange)
                } else {
                    Text("At your 30-day average")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
            }

            // Fitness badge
            let tier = currentTier
            HStack(spacing: 5) {
                Image(systemName: tier.icon)
                    .font(.system(size: 10, weight: .bold))
                Text(tier.label)
                    .font(.system(size: 11, weight: .bold))
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            .foregroundColor(tier.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(Capsule().fill(tier.color.opacity(0.15)))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 24)
        .padding(.horizontal, 20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.red.opacity(0.2), Color.red.opacity(0.08)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.red.opacity(0.3), lineWidth: 1)
                )
        )
    }

    private func avgPill(label: String, value: Int?) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.4))
            Text(value != nil ? "\(value!) bpm" : "--")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.06))
        )
    }

    // MARK: - Section 2: Tabbed Chart

    private var chartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Tab picker
            HStack(spacing: 4) {
                ForEach(ChartTab.allCases, id: \.self) { tab in
                    Button(action: {
                        withAnimation(.easeInOut(duration: 0.2)) { selectedChartTab = tab }
                    }) {
                        Text(tab.rawValue)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(selectedChartTab == tab ? .white : .white.opacity(0.4))
                            .padding(.horizontal, 14)
                            .padding(.vertical, 7)
                            .background(
                                Capsule()
                                    .fill(selectedChartTab == tab ? Color.red.opacity(0.25) : Color.clear)
                            )
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }

            if #available(iOS 16.0, *) {
                switch selectedChartTab {
                case .today:
                    todayChart
                case .sevenDay:
                    rhrTrendChart(data: last7DaysRHR, strideCount: 1)
                case .thirtyDay:
                    rhrTrendChart(data: last30DaysRHR, strideCount: 7)
                }
            } else {
                Text("Charts require iOS 16+")
                    .font(.system(size: 14))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    // MARK: Today Chart (intraday HR with workout overlays)

    @available(iOS 16.0, *)
    private var todayChart: some View {
        VStack(alignment: .leading, spacing: 4) {
            if todayHRSamples.isEmpty {
                Text("No heart rate data yet today")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 180)
            } else {
                Chart {
                    // Workout overlay rectangles
                    ForEach(todayWorkouts) { workout in
                        RectangleMark(
                            xStart: .value("Start", workout.startDate),
                            xEnd: .value("End", workout.endDate),
                            yStart: nil,
                            yEnd: nil
                        )
                        .foregroundStyle(workout.color.opacity(0.15))
                    }

                    // HR line
                    ForEach(Array(todayHRSamples.enumerated()), id: \.offset) { _, point in
                        LineMark(
                            x: .value("Time", point.0),
                            y: .value("HR", point.1)
                        )
                        .foregroundStyle(Color.red)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Time", point.0),
                            y: .value("HR", point.1)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.red.opacity(0.2), Color.red.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)
                    }

                    // Workout start vertical lines
                    ForEach(todayWorkouts) { workout in
                        RuleMark(x: .value("Workout", workout.startDate))
                            .foregroundStyle(workout.color.opacity(0.7))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [4, 3]))
                            .annotation(position: .top, alignment: .leading) {
                                Text(workout.name)
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(workout.color)
                                    .padding(.horizontal, 4)
                                    .padding(.vertical, 2)
                                    .background(
                                        RoundedRectangle(cornerRadius: 3)
                                            .fill(workout.color.opacity(0.15))
                                    )
                            }
                    }
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .chartXAxis {
                    AxisMarks(values: .stride(by: .hour, count: 3)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(timeFormatter.string(from: date))
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let hr = value.as(Int.self) {
                                Text("\(hr)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.08))
                    }
                }
                .frame(height: 180)
            }
        }
    }

    // MARK: RHR Trend Chart (7-day or 30-day)

    @available(iOS 16.0, *)
    private func rhrTrendChart(data: [(Date, Int)], strideCount: Int) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            if data.isEmpty {
                Text("Not enough data")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .frame(height: 180)
            } else {
                Chart {
                    // Average reference line
                    if let avg = avg30Day {
                        RuleMark(y: .value("Avg", avg))
                            .foregroundStyle(Color.white.opacity(0.25))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .annotation(position: .trailing, alignment: .leading) {
                                Text("avg")
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                    }

                    ForEach(data, id: \.0) { date, rhr in
                        let isAboveAvg = avg30Day != nil && rhr > avg30Day!
                        let pointColor: Color = isAboveAvg ? .orange : .green

                        LineMark(
                            x: .value("Date", date, unit: .day),
                            y: .value("RHR", rhr)
                        )
                        .foregroundStyle(Color.cyan)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Date", date, unit: .day),
                            y: .value("RHR", rhr)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [Color.cyan.opacity(0.2), Color.cyan.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", date, unit: .day),
                            y: .value("RHR", rhr)
                        )
                        .foregroundStyle(pointColor)
                        .symbolSize(20)
                    }
                }
                .chartYScale(domain: .automatic(includesZero: false))
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: strideCount)) { value in
                        if let date = value.as(Date.self) {
                            AxisValueLabel {
                                Text(shortDateFormatter.string(from: date))
                                    .font(.system(size: 9, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }
                }
                .chartYAxis {
                    AxisMarks(position: .leading) { value in
                        AxisValueLabel {
                            if let rhr = value.as(Int.self) {
                                Text("\(rhr)")
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                            .foregroundStyle(Color.white.opacity(0.08))
                    }
                }
                .frame(height: 180)
            }
        }
    }

    // MARK: - Section 3: Heart Rate Insights (waking vs sleep bar graphs)

    private var heartRateInsightsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Heart Rate Insights")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            // 30-day avg RHR callout
            if let avg = avg30Day {
                HStack(spacing: 10) {
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 40, height: 40)
                        Image(systemName: "heart.fill")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.red)
                    }
                    VStack(alignment: .leading, spacing: 2) {
                        Text("30-Day Avg RHR")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                        Text("\(avg) bpm")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    Spacer()
                }
            }

            Divider().background(Color.white.opacity(0.1))

            // Waking vs Sleep dual bar graph
            VStack(alignment: .leading, spacing: 10) {
                Text("Waking vs Sleep")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))

                hrComparisonBar(
                    label: "Awake",
                    icon: "sun.max.fill",
                    value: wakingAvgHR,
                    color: .orange,
                    maxVal: barMaxVal
                )

                hrComparisonBar(
                    label: "Asleep",
                    icon: "moon.fill",
                    value: sleepAvgHR,
                    color: .indigo,
                    maxVal: barMaxVal
                )
            }

            // What helps your RHR
            if let topImpact = rhrImpacts.first(where: { $0.isPositive }) {
                Divider().background(Color.white.opacity(0.1))

                HStack(spacing: 10) {
                    ZStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(topImpact.habitType.color.opacity(0.15))
                            .frame(width: 32, height: 32)
                        Image(systemName: topImpact.habitType.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(topImpact.habitType.color)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("What helps your RHR")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))

                        HStack(spacing: 4) {
                            Text(topImpact.habitType.displayName(viewContext))
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.white)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white.opacity(0.3))
                            Text("RHR ↓\(abs(Int(topImpact.percentageChange)))%")
                                .font(.system(size: 13, weight: .bold))
                                .foregroundColor(.green)
                        }
                    }
                    Spacer()
                }
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    private var barMaxVal: Int {
        let vals = [wakingAvgHR, sleepAvgHR].compactMap { $0 }
        return (vals.max() ?? 80) + 10
    }

    private func hrComparisonBar(label: String, icon: String, value: Int?, color: Color, maxVal: Int) -> some View {
        HStack(spacing: 10) {
            HStack(spacing: 5) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
                Text(label)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
            .frame(width: 75, alignment: .leading)

            GeometryReader { geo in
                let fraction = value != nil ? CGFloat(value!) / CGFloat(maxVal) : 0
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 5)
                        .fill(Color.white.opacity(0.06))

                    RoundedRectangle(cornerRadius: 5)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.6), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(fraction * geo.size.width, 0))
                }
            }
            .frame(height: 24)

            Text(value != nil ? "\(value!) bpm" : "--")
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .frame(width: 60, alignment: .trailing)
        }
    }

    // MARK: - Section 4: Gamified Tier Card

    private var tierCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 8) {
                Image(systemName: "trophy.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.yellow)
                Text("Your RHR Tier")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
            }

            // Tier ladder
            VStack(spacing: 6) {
                ForEach(HRTier.allTiers, id: \.label) { tier in
                    let isCurrentTier = currentTier.label == tier.label
                    HStack(spacing: 10) {
                        Image(systemName: tier.icon)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(tier.color)
                            .frame(width: 24)

                        Text(tier.label)
                            .font(.system(size: 13, weight: isCurrentTier ? .bold : .medium))
                            .foregroundColor(isCurrentTier ? .white : .white.opacity(0.4))

                        Spacer()

                        Text(tier.range)
                            .font(.system(size: 11, weight: .medium, design: .monospaced))
                            .foregroundColor(isCurrentTier ? tier.color : .white.opacity(0.3))

                        if isCurrentTier {
                            Image(systemName: "arrowtriangle.left.fill")
                                .font(.system(size: 8))
                                .foregroundColor(tier.color)
                        }
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(isCurrentTier ? tier.color.opacity(0.1) : Color.clear)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(isCurrentTier ? tier.color.opacity(0.3) : Color.clear, lineWidth: 1)
                            )
                    )
                }
            }

            // Progress hint
            if let hr = currentRHR {
                let tier = currentTier
                if let nextTier = tier.nextTier {
                    let gap = hr - nextTier.upperBound
                    if gap > 0 {
                        Text("\(gap) bpm to reach \(nextTier.label)")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(nextTier.color.opacity(0.8))
                            .frame(maxWidth: .infinity, alignment: .center)
                            .padding(.top, 4)
                    }
                } else {
                    Text("Top tier — keep it up!")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.cyan.opacity(0.8))
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
            }
        }
        .padding(16)
        .background(cardBackground)
    }

    // MARK: - Tier Logic

    private var currentTier: HRTier {
        guard let hr = currentRHR else { return HRTier.allTiers.last! }
        return HRTier.allTiers.first(where: { hr <= $0.upperBound }) ?? HRTier.allTiers.last!
    }

    // MARK: - Card Background

    private var cardBackground: some View {
        RoundedRectangle(cornerRadius: 14)
            .fill(Color.white.opacity(0.05))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.white.opacity(0.08), lineWidth: 1)
            )
    }
}

// MARK: - HR Tier Model

struct HRTier: Equatable {
    let label: String
    let icon: String
    let color: Color
    let range: String
    let upperBound: Int

    var nextTier: HRTier? {
        guard let idx = Self.allTiers.firstIndex(of: self), idx > 0 else { return nil }
        return Self.allTiers[idx - 1]
    }

    static let allTiers: [HRTier] = [
        HRTier(label: "Elite", icon: "bolt.heart.fill", color: .cyan, range: "< 50 bpm", upperBound: 49),
        HRTier(label: "Excellent", icon: "star.fill", color: .green, range: "50-59 bpm", upperBound: 59),
        HRTier(label: "Good", icon: "hand.thumbsup.fill", color: .blue, range: "60-69 bpm", upperBound: 69),
        HRTier(label: "Average", icon: "equal.circle.fill", color: .yellow, range: "70-79 bpm", upperBound: 79),
        HRTier(label: "Below Average", icon: "arrow.up.circle.fill", color: .orange, range: "80+ bpm", upperBound: 999),
    ]
}

// MARK: - Supporting Types

struct WeeklyHRStats {
    let averageRHR: Int
    let lowestHR: Int
    let highestHR: Int
    let timeInZones: [HRZone: Double]
}

enum HRZone {
    case resting, light, moderate, vigorous
}

// MARK: - Workout Activity Helpers

extension HKWorkoutActivityType {
    var commonName: String {
        switch self {
        case .running: return "Run"
        case .cycling: return "Ride"
        case .walking: return "Walk"
        case .swimming: return "Swim"
        case .yoga: return "Yoga"
        case .functionalStrengthTraining, .traditionalStrengthTraining: return "Strength"
        case .highIntensityIntervalTraining: return "HIIT"
        case .rowing: return "Row"
        case .elliptical: return "Elliptical"
        case .hiking: return "Hike"
        default: return "Workout"
        }
    }

    var overlayColor: Color {
        switch self {
        case .running: return .green
        case .cycling: return .orange
        case .swimming: return .cyan
        case .yoga: return .purple
        case .functionalStrengthTraining, .traditionalStrengthTraining: return .red
        case .highIntensityIntervalTraining: return .pink
        case .walking, .hiking: return .mint
        default: return .yellow
        }
    }
}
