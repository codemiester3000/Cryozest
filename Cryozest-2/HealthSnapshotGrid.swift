import SwiftUI

enum SnapshotMetric: Identifiable {
    case sleep, hrv, rhr, steps
    var id: Self { self }
}

struct HealthSnapshotGrid: View {
    @ObservedObject var recoveryModel: RecoveryGraphModel
    @ObservedObject var sleepModel: DailySleepViewModel
    var rhrImpacts: [HabitImpact] = []

    @State private var selectedMetric: SnapshotMetric?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "heart.text.square.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.pink)

                Text("Health Snapshot")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white.opacity(0.9))

                Spacer()
            }

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 10),
                GridItem(.flexible(), spacing: 10)
            ], spacing: 10) {
                if recoveryModel.isLoading {
                    ForEach(0..<4, id: \.self) { _ in
                        SnapshotSkeletonCell()
                    }
                } else {
                    SnapshotCell(icon: "bed.double.fill", title: "Sleep",
                                 value: sleepValueText, unit: "hrs",
                                 color: .indigo, trend: sleepTrend)
                        .onTapGesture { selectedMetric = .sleep }

                    SnapshotCell(icon: "waveform.path.ecg", title: "HRV",
                                 value: hrvValueText, unit: "ms",
                                 color: .purple, trend: hrvTrend)
                        .onTapGesture { selectedMetric = .hrv }

                    SnapshotCell(icon: "heart.fill", title: "Resting HR",
                                 value: rhrValueText, unit: "bpm",
                                 color: .red, trend: rhrTrend)
                        .onTapGesture { selectedMetric = .rhr }

                    SnapshotCell(icon: "figure.walk", title: "Steps",
                                 value: stepsValueText, unit: "",
                                 color: .green, trend: nil)
                        .onTapGesture { selectedMetric = .steps }
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.08), lineWidth: 1)
                )
        )
        .sheet(item: $selectedMetric) { metric in
            metricDetailSheet(for: metric)
        }
    }

    // MARK: - Detail Sheet

    @ViewBuilder
    private func metricDetailSheet(for metric: SnapshotMetric) -> some View {
        ZStack {
            Color(red: 0.06, green: 0.10, blue: 0.18)
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Drag handle + close
                HStack {
                    Capsule()
                        .fill(Color.white.opacity(0.2))
                        .frame(width: 36, height: 4)
                    Spacer()
                }
                .frame(maxWidth: .infinity)
                .overlay(alignment: .trailing) {
                    Button(action: { selectedMetric = nil }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.4))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 16)
                .padding(.bottom, 8)

                ScrollView {
                    switch metric {
                    case .sleep:
                        SleepDetailView(recoveryModel: recoveryModel, sleepModel: sleepModel)
                    case .hrv:
                        HRVDetailView(model: recoveryModel)
                    case .rhr:
                        HeartRateDetailView(model: recoveryModel, rhrImpacts: rhrImpacts)
                    case .steps:
                        StepsDetailView(model: recoveryModel)
                    }
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Values

    private var sleepValueText: String {
        if let duration = recoveryModel.previousNightSleepDuration,
           let hours = Double(duration) {
            return String(format: "%.1f", hours)
        }
        return "--"
    }

    private var hrvValueText: String {
        if let hrv = recoveryModel.avgHrvDuringSleep {
            return "\(hrv)"
        }
        return "--"
    }

    private var rhrValueText: String {
        if let rhr = recoveryModel.mostRecentRestingHeartRate {
            return "\(rhr)"
        }
        return "--"
    }

    private var stepsValueText: String {
        if let steps = recoveryModel.mostRecentSteps {
            let value = Int(steps)
            if value >= 1000 {
                return String(format: "%.1fk", Double(value) / 1000.0)
            }
            return "\(value)"
        }
        return "--"
    }

    // MARK: - Trends

    private var sleepTrend: TrendDirection? {
        guard let pct = recoveryModel.sleepScorePercentage else { return nil }
        if pct > 55 { return .up }
        if pct < 45 { return .down }
        return .neutral
    }

    private var hrvTrend: TrendDirection? {
        guard let pct = recoveryModel.hrvSleepPercentage else { return nil }
        if pct > 55 { return .up }
        if pct < 45 { return .down }
        return .neutral
    }

    private var rhrTrend: TrendDirection? {
        guard let pct = recoveryModel.restingHeartRatePercentage else { return nil }
        if pct > 55 { return .down }
        if pct < 45 { return .up }
        return .neutral
    }
}

// MARK: - Snapshot Cell

struct SnapshotCell: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color
    let trend: TrendDirection?

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(color)
                    .frame(width: 22, height: 22)
                    .background(
                        Circle()
                            .fill(color.opacity(0.15))
                    )

                Text(title)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
                    .lineLimit(1)

                Spacer()

                if let trend = trend {
                    Image(systemName: trend.icon)
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(trend.color)
                }
            }

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.white)

                if !unit.isEmpty {
                    Text(unit)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}

struct SnapshotSkeletonCell: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                SkeletonCircle(size: 22)
                SkeletonLine(width: 50, height: 11)
                Spacer()
            }
            SkeletonLine(width: 60, height: 22)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }
}
