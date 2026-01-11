//
//  LargeHRVWidget.swift
//  Cryozest-2
//
//  Full-width HRV widget with inline expansion
//

import SwiftUI

struct LargeHRVWidget: View {
    @ObservedObject var model: RecoveryGraphModel
    @Binding var expandedMetric: MetricType?
    var namespace: Namespace.ID

    @State private var weeklyData: [DataPoint] = []
    @State private var isLoadingChart = true

    private var currentHRV: Int {
        model.lastKnownHRV
    }

    private var trend: HRVTrend {
        guard weeklyData.count >= 4 else { return .stable }
        let recentAvg = weeklyData.suffix(3).map { $0.value }.reduce(0, +) / 3.0
        let previousAvg = weeklyData.prefix(3).map { $0.value }.reduce(0, +) / 3.0
        let diff = recentAvg - previousAvg
        if diff >= 5 { return .improving }
        else if diff <= -5 { return .declining }
        else { return .stable }
    }

    private var trendColor: Color {
        switch trend {
        case .improving: return .green
        case .stable: return .cyan
        case .declining: return .orange
        }
    }

    private var recoveryStatus: (label: String, color: Color) {
        switch currentHRV {
        case 0..<30: return ("Poor", .red)
        case 30..<50: return ("Fair", .orange)
        case 50..<70: return ("Good", .green)
        default: return ("Excellent", .cyan)
        }
    }

    private var isExpanded: Bool {
        expandedMetric == .hrv
    }

    var body: some View {
        Group {
            if isExpanded {
                expandedView
            } else {
                collapsedView
            }
        }
        .onAppear {
            loadWeeklyData()
        }
    }

    // MARK: - Collapsed View (Half-width compact)
    private var collapsedView: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Top row: Icon and status
            HStack {
                ZStack {
                    Circle()
                        .fill(trendColor.opacity(0.15))
                        .frame(width: 36, height: 36)

                    Image(systemName: "waveform.path.ecg")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(trendColor)
                }

                Spacer()

                // Status badge
                HStack(spacing: 3) {
                    Circle()
                        .fill(recoveryStatus.color)
                        .frame(width: 5, height: 5)

                    Text(recoveryStatus.label)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(recoveryStatus.color)
                }
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(
                    Capsule()
                        .fill(recoveryStatus.color.opacity(0.15))
                )
            }

            // Title
            Text("HRV")
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            // Value
            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text("\(currentHRV)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("ms")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            // Trend indicator
            HStack(spacing: 3) {
                Image(systemName: trend.icon)
                    .font(.system(size: 9, weight: .bold))
                    .foregroundColor(trendColor)

                Text(trend.label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .contentShape(Rectangle())
        .onTapGesture {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                expandedMetric = .hrv
            }
        }
    }

    // MARK: - Expanded View
    private var expandedView: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header with close button
            HStack {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(trendColor.opacity(0.2))
                            .frame(width: 40, height: 40)

                        Image(systemName: "waveform.path.ecg")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(trendColor)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Heart Rate Variability")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.7))

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text("\(currentHRV)")
                                .font(.system(size: 28, weight: .bold))
                                .foregroundColor(.white)

                            Text("ms")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }

                Spacer()

                Button(action: {
                    withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                        expandedMetric = nil
                    }
                }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(16)

            // Expanded content
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    // 7-day chart
                    VStack(alignment: .leading, spacing: 12) {
                        Text("7-Day Trend")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.6))
                            .textCase(.uppercase)
                            .tracking(0.5)

                        if isLoadingChart {
                            ProgressView()
                                .progressViewStyle(CircularProgressViewStyle(tint: trendColor))
                                .frame(maxWidth: .infinity)
                                .frame(height: 160)
                        } else {
                            HRVChartView(data: weeklyData, color: trendColor)
                                .frame(height: 160)
                        }
                    }
                    .padding(16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.white.opacity(0.05))
                    )

                    // Stats row
                    HStack(spacing: 12) {
                        statCard(title: "Min", value: Int(weeklyData.map { $0.value }.min() ?? 0), color: .orange)
                        statCard(title: "Avg", value: Int(weeklyData.map { $0.value }.reduce(0, +) / Double(max(weeklyData.count, 1))), color: trendColor)
                        statCard(title: "Max", value: Int(weeklyData.map { $0.value }.max() ?? 0), color: .green)
                    }

                    // Recovery status card
                    recoveryStatusCard

                    // Info card
                    infoCard
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 20)
            }
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .shadow(color: Color.black.opacity(0.2), radius: 8, y: 4)
    }

    private func statCard(title: String, value: Int, color: Color) -> some View {
        VStack(spacing: 6) {
            Text(title)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.5))

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text("\(value)")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(color)

                Text("ms")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(color.opacity(0.1))
        )
    }

    private var recoveryStatusCard: some View {
        let status = getFullRecoveryStatus()
        return HStack(spacing: 14) {
            Circle()
                .fill(status.color)
                .frame(width: 14, height: 14)

            VStack(alignment: .leading, spacing: 4) {
                Text(status.label)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Text(status.description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(status.color.opacity(0.12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(status.color.opacity(0.25), lineWidth: 1)
                )
        )
    }

    private var infoCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(trendColor)

                Text("What is HRV?")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white)
            }

            Text("Heart Rate Variability measures the variation in time between heartbeats. Higher HRV generally indicates better recovery and cardiovascular fitness.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.7))
                .lineSpacing(4)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(trendColor.opacity(0.08))
        )
    }

    private func getFullRecoveryStatus() -> (label: String, description: String, color: Color) {
        switch currentHRV {
        case 0..<30:
            return ("Poor Recovery", "Consider taking a rest day", .red)
        case 30..<50:
            return ("Fair Recovery", "Light activity recommended", .orange)
        case 50..<70:
            return ("Good Recovery", "Ready for moderate training", .green)
        default:
            return ("Excellent Recovery", "Fully recovered, ready for intense training", .cyan)
        }
    }

    private func loadWeeklyData() {
        isLoadingChart = true
        let calendar = Calendar.current
        let today = Date()
        var days: [Date] = []

        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                days.append(date)
            }
        }
        days = days.reversed()

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
                self.weeklyData = days.compactMap { date in
                    guard let value = fetchedData[date] else { return nil }
                    return DataPoint(date: date, value: value)
                }
            }
            self.isLoadingChart = false
        }
    }
}

// MARK: - HRV Trend
enum HRVTrend {
    case improving, stable, declining

    var icon: String {
        switch self {
        case .improving: return "arrow.up.right"
        case .stable: return "arrow.right"
        case .declining: return "arrow.down.right"
        }
    }

    var label: String {
        switch self {
        case .improving: return "Improving"
        case .stable: return "Stable"
        case .declining: return "Declining"
        }
    }
}

// MARK: - Mini Sparkline
struct MiniSparkline: View {
    let data: [Double]
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let minVal = data.min() ?? 0
            let maxVal = data.max() ?? 1
            let range = max(maxVal - minVal, 1)

            Path { path in
                guard data.count > 1 else { return }

                let stepX = geometry.size.width / CGFloat(data.count - 1)

                for (index, value) in data.enumerated() {
                    let x = CGFloat(index) * stepX
                    let y = geometry.size.height - ((CGFloat(value) - CGFloat(minVal)) / CGFloat(range)) * geometry.size.height

                    if index == 0 {
                        path.move(to: CGPoint(x: x, y: y))
                    } else {
                        path.addLine(to: CGPoint(x: x, y: y))
                    }
                }
            }
            .stroke(color, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
        }
    }
}

// MARK: - HRV Chart View
struct HRVChartView: View {
    let data: [DataPoint]
    let color: Color

    var body: some View {
        GeometryReader { geometry in
            let values = data.map { $0.value }
            let minVal = (values.min() ?? 0) - 10
            let maxVal = (values.max() ?? 100) + 10
            let range = max(maxVal - minVal, 1)

            ZStack {
                // Grid lines
                VStack(spacing: 0) {
                    ForEach(0..<4) { i in
                        Rectangle()
                            .fill(Color.white.opacity(0.05))
                            .frame(height: 1)
                        if i < 3 {
                            Spacer()
                        }
                    }
                }

                // Line chart
                Path { path in
                    guard data.count > 1 else { return }

                    let stepX = geometry.size.width / CGFloat(data.count - 1)
                    let padding: CGFloat = 20

                    for (index, point) in data.enumerated() {
                        let x = CGFloat(index) * stepX
                        let y = padding + (geometry.size.height - 2 * padding) * (1 - (CGFloat(point.value) - CGFloat(minVal)) / CGFloat(range))

                        if index == 0 {
                            path.move(to: CGPoint(x: x, y: y))
                        } else {
                            path.addLine(to: CGPoint(x: x, y: y))
                        }
                    }
                }
                .stroke(
                    LinearGradient(colors: [color, color.opacity(0.6)], startPoint: .leading, endPoint: .trailing),
                    style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round)
                )

                // Data points
                ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                    let stepX = geometry.size.width / CGFloat(data.count - 1)
                    let padding: CGFloat = 20
                    let x = CGFloat(index) * stepX
                    let y = padding + (geometry.size.height - 2 * padding) * (1 - (CGFloat(point.value) - CGFloat(minVal)) / CGFloat(range))

                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                        .position(x: x, y: y)
                }

                // Day labels
                HStack {
                    ForEach(Array(data.enumerated()), id: \.offset) { index, point in
                        Text(dayLabel(for: point.date))
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.top, geometry.size.height - 12)
            }
        }
    }

    private func dayLabel(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE"
        return formatter.string(from: date).prefix(1).uppercased() + formatter.string(from: date).dropFirst().prefix(1).lowercased()
    }
}
