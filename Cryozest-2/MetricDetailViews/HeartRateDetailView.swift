//
//  HeartRateDetailView.swift
//  Cryozest-2
//
//  Redesigned heart rate detail view with hero card, 30-day trend,
//  RHR range visualization, and habit correlations.
//

import SwiftUI
import Charts

struct HeartRateDetailView: View {
    @ObservedObject var model: RecoveryGraphModel
    var rhrImpacts: [HabitImpact] = []

    @Environment(\.managedObjectContext) private var viewContext

    @State private var currentHR: Int?
    @State private var last30DaysRHR: [(Date, Int)] = []
    @State private var weekStats: WeeklyHRStats?

    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()

    private let shortDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "M/d"
        return formatter
    }()

    private var avg60Day: Int? {
        model.avgRestingHeartRate60Days
    }

    private var fitnessClassification: (label: String, color: Color) {
        guard let hr = currentHR else { return ("--", .gray) }
        switch hr {
        case ..<50: return ("Athlete", .cyan)
        case 50..<60: return ("Excellent", .green)
        case 60..<70: return ("Good", .blue)
        case 70..<80: return ("Average", .yellow)
        default: return ("Above Avg", .orange)
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            heroCard
            weeklyStatsCards
            rhrTrendCard
            rhrInsightsCard
            infoCard
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .onAppear { loadData() }
        .onChange(of: model.selectedDate) { _ in loadData() }
    }

    // MARK: - Load Data (30 days)

    private func loadData() {
        let date = model.selectedDate
        let hkm = HealthKitManager.shared
        let calendar = Calendar.current

        // Current/selected day RHR
        hkm.fetchMostRecentRestingHeartRate(for: date) { rhr, _ in
            DispatchQueue.main.async { self.currentHR = rhr }
        }

        // Last 30 days RHR trend
        var rhrEntries: [(Date, Int)] = []
        let group = DispatchGroup()
        for offset in 0..<30 {
            guard let day = calendar.date(byAdding: .day, value: -offset, to: date) else { continue }
            group.enter()
            hkm.fetchMostRecentRestingHeartRate(for: day) { rhr, _ in
                if let rhr = rhr {
                    DispatchQueue.main.async {
                        rhrEntries.append((day, rhr))
                    }
                }
                group.leave()
            }
        }
        group.notify(queue: .main) {
            self.last30DaysRHR = rhrEntries.sorted { $0.0 < $1.0 }

            let values = rhrEntries.map { $0.1 }
            if !values.isEmpty {
                self.weekStats = WeeklyHRStats(
                    averageRHR: values.reduce(0, +) / values.count,
                    lowestHR: values.min() ?? 0,
                    highestHR: values.max() ?? 0,
                    timeInZones: [:]
                )
            }
        }
    }

    // MARK: - Section 1: Hero Card

    private var heroCard: some View {
        VStack(spacing: 12) {
            // Fitness badge
            let classification = fitnessClassification
            HStack(spacing: 5) {
                Image(systemName: "heart.circle.fill")
                    .font(.system(size: 10, weight: .bold))
                Text(classification.label)
                    .font(.system(size: 11, weight: .bold))
                    .textCase(.uppercase)
                    .tracking(0.5)
            }
            .foregroundColor(classification.color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(
                Capsule()
                    .fill(classification.color.opacity(0.15))
            )

            // Large RHR number
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                if let hr = currentHR {
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
            if let hr = currentHR, let avg = avg60Day, avg > 0 {
                let diff = avg - hr
                if diff > 0 {
                    Text("\(diff) bpm below your 60-day avg")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.green)
                } else if diff < 0 {
                    Text("\(abs(diff)) bpm above your 60-day avg")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.orange)
                } else {
                    Text("At your 60-day average")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                }
            }
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

    // MARK: - Section 2: Weekly Stats (3 cards)

    private var weeklyStatsCards: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("This Week")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            if let stats = weekStats {
                HStack(spacing: 10) {
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

                    // Week change
                    let weekChange = computeWeekChange()
                    HRStatCard(
                        icon: weekChange >= 0 ? "arrow.up.right" : "arrow.down.right",
                        label: "Week Δ",
                        value: "\(abs(weekChange))%",
                        unit: weekChange < 0 ? "↓" : "↑",
                        color: weekChange <= 0 ? .green : .orange
                    )
                }
            } else {
                Text("No data available")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    private func computeWeekChange() -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: model.selectedDate)
        guard let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: today),
              let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: today) else { return 0 }

        let thisWeek = last30DaysRHR.filter { $0.0 >= oneWeekAgo && $0.0 <= today }.map { $0.1 }
        let lastWeek = last30DaysRHR.filter { $0.0 >= twoWeeksAgo && $0.0 < oneWeekAgo }.map { $0.1 }

        guard !thisWeek.isEmpty, !lastWeek.isEmpty else { return 0 }

        let thisAvg = Double(thisWeek.reduce(0, +)) / Double(thisWeek.count)
        let lastAvg = Double(lastWeek.reduce(0, +)) / Double(lastWeek.count)

        guard lastAvg > 0 else { return 0 }
        return Int(((thisAvg - lastAvg) / lastAvg) * 100)
    }

    // MARK: - Section 3: 30-Day RHR Trend

    private var rhrTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("30-Day RHR Trend")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            if #available(iOS 16.0, *) {
                Chart {
                    // Reference line for 60-day average
                    if let avg = avg60Day {
                        RuleMark(y: .value("Avg", Int(avg)))
                            .foregroundStyle(Color.white.opacity(0.25))
                            .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 4]))
                            .annotation(position: .trailing, alignment: .leading) {
                                Text("avg")
                                    .font(.system(size: 8, weight: .medium))
                                    .foregroundColor(.white.opacity(0.3))
                            }
                    }

                    ForEach(last30DaysRHR, id: \.0) { date, rhr in
                        let isAboveAvg = avg60Day != nil && rhr > avg60Day!
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
                    AxisMarks(values: .stride(by: .day, count: 7)) { value in
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
                .frame(height: 160)
                .padding(.vertical, 8)
            } else {
                Text("Chart requires iOS 16+")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding()
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    // MARK: - Section 4: Heart Rate Insights (replaces broken HR Zones)

    private var rhrInsightsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Heart Rate Insights")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            // RHR Range bar
            if let stats = weekStats {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Your RHR Range (30 days)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))

                    // Range visualization
                    rhrRangeBar(stats: stats)
                        .frame(height: 16)

                    HStack {
                        Text("\(stats.lowestHR) bpm")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.green)
                        Spacer()
                        if avg60Day != nil {
                            Text("▲ avg")
                                .font(.system(size: 9, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                        }
                        Spacer()
                        Text("\(stats.highestHR) bpm")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                }

                // What helps your RHR
                if let topImpact = rhrImpacts.first(where: { $0.isPositive }) {
                    Divider()
                        .background(Color.white.opacity(0.1))
                        .padding(.vertical, 4)

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
            } else {
                Text("Track more days to see your RHR range")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
    }

    // MARK: - RHR Range Bar

    private func rhrRangeBar(stats: WeeklyHRStats) -> some View {
        GeometryReader { geo in
            let minBpm = max(stats.lowestHR - 5, 35)
            let maxBpm = stats.highestHR + 5
            let range = max(maxBpm - minBpm, 1)

            let lowX = CGFloat(stats.lowestHR - minBpm) / CGFloat(range) * geo.size.width
            let highX = CGFloat(stats.highestHR - minBpm) / CGFloat(range) * geo.size.width
            let avgX: CGFloat? = avg60Day != nil
                ? CGFloat(avg60Day! - minBpm) / CGFloat(range) * geo.size.width
                : nil

            ZStack(alignment: .leading) {
                // Background track
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.08))
                    .frame(height: 8)

                // Active range
                RoundedRectangle(cornerRadius: 4)
                    .fill(
                        LinearGradient(
                            colors: [.green, .cyan, .orange],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(highX - lowX, 4), height: 8)
                    .offset(x: lowX)

                // Average marker
                if let ax = avgX {
                    Rectangle()
                        .fill(Color.white)
                        .frame(width: 2, height: 16)
                        .offset(x: ax - 1)
                }
            }
        }
    }

    // MARK: - Section 5: Info Card

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.red.opacity(0.8))

                Text("About Resting Heart Rate")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text("Your resting heart rate is a key indicator of cardiovascular fitness. Lower is generally better, with most adults ranging between 60-100 bpm. Athletes often have RHR in the 40-60 range. Track trends over weeks rather than daily fluctuations.")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
                .lineSpacing(4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.red.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.red.opacity(0.15), lineWidth: 1)
                )
        )
    }
}

// MARK: - Supporting Types

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

struct HRStatCard: View {
    let icon: String
    let label: String
    let value: String
    let unit: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(color)

            VStack(spacing: 3) {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(value)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)

                    Text(unit)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }

                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .lineLimit(1)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(color.opacity(0.2), lineWidth: 1)
                )
        )
    }
}
