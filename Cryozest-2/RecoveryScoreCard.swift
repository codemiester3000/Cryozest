import SwiftUI

struct RecoveryScoreCard: View {
    @ObservedObject var recoveryModel: RecoveryGraphModel

    @State private var showDetail = false

    private var score: Int? {
        guard let last = recoveryModel.recoveryScores.last, last > 0 else { return nil }
        return last
    }

    var body: some View {
        Button(action: { showDetail = true }) {
            Group {
                if let score = score {
                    filledCard(score: score)
                } else {
                    emptyState
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
        }
        .buttonStyle(PlainButtonStyle())
        .sheet(isPresented: $showDetail) {
            RecoveryDetailSheet(model: recoveryModel, dismiss: { showDetail = false })
        }
    }

    // MARK: - Filled Card

    private func filledCard(score: Int) -> some View {
        let color = Self.colorForScore(score)

        return VStack(spacing: 16) {
            // Row 1: Ring + status
            HStack(spacing: 16) {
                // Score ring
                ZStack {
                    Circle()
                        .stroke(color.opacity(0.12), lineWidth: 7)

                    Circle()
                        .trim(from: 0, to: CGFloat(score) / 100.0)
                        .stroke(color, style: StrokeStyle(lineWidth: 7, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    Text("\(score)")
                        .font(.system(size: 24, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(width: 68, height: 68)

                VStack(alignment: .leading, spacing: 4) {
                    Text("Recovery")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                        .textCase(.uppercase)
                        .tracking(0.8)

                    Text(Self.statusLabel(score))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(color)

                    Text(Self.guidanceText(score))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.45))
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }

            // Row 2: 7-day trend bars
            if recoveryModel.recoveryScores.count > 1 {
                trendBars(color: color)
            }

            // Row 3: What's driving it
            HStack(spacing: 10) {
                if let hrv = recoveryModel.avgHrvDuringSleep {
                    driverStat(
                        label: "Sleep HRV",
                        current: "\(hrv)",
                        unit: "ms",
                        baseline: recoveryModel.avgHrvDuringSleep60Days.map { "\($0)" },
                        pct: recoveryModel.hrvSleepPercentage,
                        invertColor: false
                    )
                }

                if let rhr = recoveryModel.mostRecentRestingHeartRate {
                    driverStat(
                        label: "Resting HR",
                        current: "\(rhr)",
                        unit: "bpm",
                        baseline: recoveryModel.avgRestingHeartRate60Days.map { "\($0)" },
                        pct: recoveryModel.restingHeartRatePercentage,
                        invertColor: true
                    )
                }
            }
        }
    }

    private func trendBars(color: Color) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text("7-Day Trend")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))

                Spacer()

                if recoveryModel.weeklyAverage > 0 {
                    Text("Avg \(recoveryModel.weeklyAverage)%")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(Self.colorForScore(recoveryModel.weeklyAverage))
                }
            }

            HStack(alignment: .bottom, spacing: 4) {
                let days = recoveryModel.getLastSevenDays()
                let scores = recoveryModel.recoveryScores
                let maxScore = max(scores.max() ?? 100, 1)

                ForEach(Array(zip(days, scores).enumerated()), id: \.offset) { index, pair in
                    let (day, value) = pair
                    let isToday = index == scores.count - 1

                    VStack(spacing: 3) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(
                                isToday
                                    ? Self.colorForScore(value)
                                    : Self.colorForScore(value).opacity(0.5)
                            )
                            .frame(height: max(CGFloat(value) / CGFloat(maxScore) * 32, 4))

                        Text(day.prefix(1))
                            .font(.system(size: 9, weight: isToday ? .bold : .medium))
                            .foregroundColor(isToday ? .white.opacity(0.7) : .white.opacity(0.3))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 48)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.04))
        )
    }

    private func driverStat(label: String, current: String, unit: String, baseline: String?, pct: Int?, invertColor: Bool) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.white.opacity(0.35))
                .textCase(.uppercase)
                .tracking(0.3)

            HStack(alignment: .firstTextBaseline, spacing: 3) {
                Text(current)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text(unit)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
            }

            if let base = baseline {
                HStack(spacing: 4) {
                    Text("avg \(base)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))

                    if let pct = pct, pct != 0 {
                        let isGood = invertColor ? (pct < 0) : (pct > 0)
                        Text("\(pct > 0 ? "+" : "")\(pct)%")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(isGood ? .green : .orange)
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Empty State

    private var emptyState: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 5)
                    .frame(width: 48, height: 48)

                Text("--")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundColor(.white.opacity(0.2))
            }

            VStack(alignment: .leading, spacing: 3) {
                Text("Recovery")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))

                Text("Wear your Apple Watch to sleep to see your recovery score")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.3))
                    .lineLimit(2)
            }

            Spacer()
        }
    }

    // MARK: - Shared Helpers

    static func colorForScore(_ value: Int) -> Color {
        switch value {
        case 85...100: return .green
        case 67..<85: return .yellow
        case 34..<67: return .orange
        default: return .red
        }
    }

    static func statusLabel(_ score: Int) -> String {
        switch score {
        case 85...100: return "Peak"
        case 67..<85: return "Good"
        case 50..<67: return "Fair"
        case 34..<50: return "Low"
        default: return "Rest"
        }
    }

    static func guidanceText(_ score: Int) -> String {
        switch score {
        case 85...100: return "Push hard today"
        case 67..<85: return "Ready for a solid effort"
        case 50..<67: return "Moderate activity today"
        case 34..<50: return "Consider lighter activity"
        default: return "Prioritize rest"
        }
    }
}

// MARK: - Detail Sheet

private struct RecoveryDetailSheet: View {
    @ObservedObject var model: RecoveryGraphModel
    let dismiss: () -> Void

    private var score: Int { model.recoveryScores.last ?? 0 }
    private var scoreColor: Color { RecoveryScoreCard.colorForScore(score) }

    var body: some View {
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
                    Button(action: dismiss) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 28))
                            .foregroundColor(.white.opacity(0.3))
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 14)
                .padding(.bottom, 4)

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        heroSection
                        todayGuidance
                        hrvSection
                        rhrSection

                        if model.recoveryScores.count > 1 {
                            weeklyTrend
                        }

                        howItWorks
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 12)
                    .padding(.bottom, 40)
                }
            }
        }
        .presentationDetents([.large])
    }

    // MARK: - Hero

    private var heroSection: some View {
        HStack(spacing: 20) {
            // Ring
            ZStack {
                Circle()
                    .stroke(scoreColor.opacity(0.12), lineWidth: 10)

                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100.0)
                    .stroke(scoreColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))

                VStack(spacing: 1) {
                    Text("\(score)")
                        .font(.system(size: 38, weight: .black, design: .rounded))
                        .foregroundColor(.white)
                }
            }
            .frame(width: 100, height: 100)

            VStack(alignment: .leading, spacing: 6) {
                Text("Recovery")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                    .textCase(.uppercase)
                    .tracking(0.8)

                Text(RecoveryScoreCard.statusLabel(score))
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(scoreColor)

                if model.weeklyAverage > 0 {
                    Text("7-day avg: \(model.weeklyAverage)%")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            Spacer()
        }
    }

    // MARK: - Today's Guidance

    private var todayGuidance: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: guidanceIcon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(scoreColor)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(scoreColor.opacity(0.12))
                )

            Text(detailedGuidance)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.75))
                .lineSpacing(5)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(scoreColor.opacity(0.06))
        )
    }

    // MARK: - HRV Section

    private var hrvSection: some View {
        Group {
            if let hrv = model.avgHrvDuringSleep,
               let baseline = model.avgHrvDuringSleep60Days, baseline > 0 {
                metricComparisonCard(
                    title: "Heart Rate Variability",
                    subtitle: "During sleep",
                    current: hrv,
                    baseline: baseline,
                    unit: "ms",
                    explanation: hrvExplanation(hrv: hrv, baseline: baseline),
                    color: .purple,
                    higherIsBetter: true
                )
            }
        }
    }

    // MARK: - RHR Section

    private var rhrSection: some View {
        Group {
            if let rhr = model.mostRecentRestingHeartRate,
               let baseline = model.avgRestingHeartRate60Days, baseline > 0 {
                metricComparisonCard(
                    title: "Resting Heart Rate",
                    subtitle: "Most recent",
                    current: rhr,
                    baseline: baseline,
                    unit: "bpm",
                    explanation: rhrExplanation(rhr: rhr, baseline: baseline),
                    color: .red,
                    higherIsBetter: false
                )
            }
        }
    }

    private func metricComparisonCard(title: String, subtitle: String, current: Int, baseline: Int, unit: String, explanation: String, color: Color, higherIsBetter: Bool) -> some View {
        let diff = current - baseline
        let pct = baseline > 0 ? Int((Double(abs(diff)) / Double(baseline) * 100).rounded()) : 0
        let isGood = higherIsBetter ? (diff >= 0) : (diff <= 0)
        let directionWord = diff > 0 ? "above" : (diff < 0 ? "below" : "at")

        return VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack(spacing: 0) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white.opacity(0.9))

                    Text(subtitle)
                        .font(.system(size: 11, weight: .medium))
                        .foregroundColor(.white.opacity(0.35))
                }

                Spacer()

                // Verdict pill
                if diff != 0 {
                    HStack(spacing: 4) {
                        Image(systemName: isGood ? "checkmark.circle.fill" : "exclamationmark.circle.fill")
                            .font(.system(size: 11, weight: .semibold))
                        Text(isGood ? "Helping recovery" : "Limiting recovery")
                            .font(.system(size: 11, weight: .semibold))
                    }
                    .foregroundColor(isGood ? .green : .orange)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill((isGood ? Color.green : Color.orange).opacity(0.12))
                    )
                }
            }

            // Visual comparison
            HStack(spacing: 0) {
                // Current
                VStack(spacing: 6) {
                    Text("Today")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.35))
                        .textCase(.uppercase)
                        .tracking(0.3)

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(current)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        Text(unit)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.35))
                    }
                }
                .frame(maxWidth: .infinity)

                // Arrow + delta
                VStack(spacing: 4) {
                    Image(systemName: diff > 0 ? "arrow.up.right" : diff < 0 ? "arrow.down.right" : "equal")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(isGood ? .green : (diff == 0 ? .white.opacity(0.3) : .orange))

                    if pct > 0 {
                        Text("\(pct)% \(directionWord)")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(isGood ? .green : .orange)
                    }
                }
                .frame(width: 80)

                // Baseline
                VStack(spacing: 6) {
                    Text("60-Day Avg")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.35))
                        .textCase(.uppercase)
                        .tracking(0.3)

                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text("\(baseline)")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundColor(.white.opacity(0.5))
                        Text(unit)
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.2))
                    }
                }
                .frame(maxWidth: .infinity)
            }

            // Explanation
            Text(explanation)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .lineSpacing(3)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    // MARK: - Weekly Trend

    private var weeklyTrend: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("This Week")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))

                Spacer()

                if let ctx = trendContextText {
                    HStack(spacing: 4) {
                        Image(systemName: trendIcon)
                            .font(.system(size: 10, weight: .bold))
                        Text(ctx)
                            .font(.system(size: 11, weight: .medium))
                    }
                    .foregroundColor(trendColor)
                }
            }

            HStack(alignment: .bottom, spacing: 5) {
                let days = model.getLastSevenDays()
                let scores = model.recoveryScores
                let maxVal = max(scores.max() ?? 100, 1)

                ForEach(Array(zip(days, scores).enumerated()), id: \.offset) { index, pair in
                    let (day, value) = pair
                    let isLast = index == scores.count - 1
                    let barColor = RecoveryScoreCard.colorForScore(value)

                    VStack(spacing: 5) {
                        Text("\(value)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(isLast ? .white : .white.opacity(0.4))

                        RoundedRectangle(cornerRadius: 4)
                            .fill(isLast ? barColor : barColor.opacity(0.45))
                            .frame(height: max(CGFloat(value) / CGFloat(maxVal) * 80, 6))

                        Text(day)
                            .font(.system(size: 10, weight: isLast ? .bold : .medium))
                            .foregroundColor(isLast ? .white.opacity(0.8) : .white.opacity(0.3))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 120)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    // MARK: - How It Works

    private var howItWorks: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "info.circle")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))

                Text("How This Is Calculated")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))
            }

            VStack(alignment: .leading, spacing: 8) {
                howItWorksRow(
                    weight: "35%",
                    label: "HRV vs your 14-day baseline",
                    color: .purple
                )
                howItWorksRow(
                    weight: "25%",
                    label: "Resting HR vs baseline",
                    color: .red
                )
                howItWorksRow(
                    weight: "15%",
                    label: "Respiratory rate vs baseline",
                    color: .cyan
                )
                howItWorksRow(
                    weight: "10%",
                    label: "Wrist temperature deviation",
                    color: .orange
                )
                howItWorksRow(
                    weight: "15%",
                    label: "Sleep deficit penalty",
                    color: .indigo
                )
            }

            Text("Each metric is compared to your personal 14-day rolling baseline using Z-scores. The score reflects how tonight compares to your recent norm, accounting for HRV, heart rate, breathing, temperature, and sleep duration.")
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.35))
                .lineSpacing(3)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.03))
        )
    }

    private func howItWorksRow(weight: String, label: String, color: Color) -> some View {
        HStack(spacing: 10) {
            Text(weight)
                .font(.system(size: 12, weight: .black, design: .rounded))
                .foregroundColor(color)
                .frame(width: 32, alignment: .trailing)

            RoundedRectangle(cornerRadius: 1)
                .fill(color.opacity(0.4))
                .frame(width: 2, height: 14)

            Text(label)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(.white.opacity(0.6))
        }
    }

    // MARK: - Helpers

    private var guidanceIcon: String {
        switch score {
        case 80...100: return "flame.fill"
        case 65..<80: return "figure.run"
        case 50..<65: return "figure.walk"
        case 35..<50: return "bed.double.fill"
        default: return "moon.zzz.fill"
        }
    }

    private var detailedGuidance: String {
        switch score {
        case 80...100:
            return "Your body is fully recovered. Today is ideal for high-intensity training or pushing personal bests."
        case 65..<80:
            return "You're well-recovered and can handle a solid training session. Good day for structured workouts."
        case 50..<65:
            return "Recovery is moderate. Stick to lighter activity today \u{2014} technique work, easy cardio, or mobility."
        case 35..<50:
            return "Your body is showing accumulated stress. A light recovery day with walking or stretching is best."
        default:
            return "Your body needs rest. Skip intense training and focus on sleep, hydration, and nutrition."
        }
    }

    private func hrvExplanation(hrv: Int, baseline: Int) -> String {
        let diff = hrv - baseline
        if diff > 10 {
            return "Well above your baseline \u{2014} strong sign of recovery."
        } else if diff > 0 {
            return "Slightly above your baseline \u{2014} decent recovery."
        } else if diff > -10 {
            return "Near your baseline \u{2014} your body is managing but not fully recovered."
        } else {
            return "Below your baseline \u{2014} often means fatigue, poor sleep, or stress."
        }
    }

    private func rhrExplanation(rhr: Int, baseline: Int) -> String {
        let diff = rhr - baseline
        if diff < -3 {
            return "Well below your norm \u{2014} strong cardiovascular recovery."
        } else if diff <= 0 {
            return "At or below your baseline \u{2014} recovering normally."
        } else if diff < 5 {
            return "Slightly elevated \u{2014} can indicate fatigue, dehydration, or stress."
        } else {
            return "Significantly elevated \u{2014} often signals overtraining or illness."
        }
    }

    private var trendContextText: String? {
        let scores = model.recoveryScores
        guard scores.count >= 4 else { return nil }
        let half = scores.count / 2
        let recentAvg = Double(Array(scores.suffix(half)).reduce(0, +)) / Double(half)
        let olderAvg = Double(Array(scores.prefix(half)).reduce(0, +)) / Double(half)
        let diff = recentAvg - olderAvg
        if diff > 5 { return "Trending up" }
        if diff < -5 { return "Trending down" }
        return "Steady"
    }

    private var trendIcon: String {
        guard let text = trendContextText else { return "arrow.right" }
        if text == "Trending up" { return "arrow.up.right" }
        if text == "Trending down" { return "arrow.down.right" }
        return "arrow.right"
    }

    private var trendColor: Color {
        guard let text = trendContextText else { return .white.opacity(0.4) }
        if text == "Trending up" { return .green }
        if text == "Trending down" { return .orange }
        return .white.opacity(0.4)
    }
}
