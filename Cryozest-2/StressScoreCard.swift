import SwiftUI

struct StressScoreCard: View {
    @ObservedObject var stressModel: StressScoreModel

    @State private var showDetail = false

    private var mostRecentScore: (score: Int, daysAgo: Int)? {
        if let today = stressModel.todayStressScore {
            return (today, 0)
        }
        let scores = stressModel.last7DaysStress
        for i in stride(from: scores.count - 1, through: 0, by: -1) {
            if let value = scores[i] {
                return (value, scores.count - 1 - i)
            }
        }
        return nil
    }

    static func scoreDateText(daysAgo: Int) -> String {
        if daysAgo == 0 { return "" }
        let calendar = Calendar.current
        let date = calendar.date(byAdding: .day, value: -daysAgo, to: calendar.startOfDay(for: Date()))!
        let formatter = DateFormatter()
        formatter.dateFormat = "EEE, MMM d"
        return "Updated \(formatter.string(from: date))"
    }

    var body: some View {
        Button(action: { showDetail = true }) {
            Group {
                if let result = mostRecentScore {
                    filledCard(score: result.score, daysAgo: result.daysAgo)
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
            StressDetailSheet(model: stressModel, dismiss: { showDetail = false })
        }
    }

    // MARK: - Filled Card

    private func filledCard(score: Int, daysAgo: Int = 0) -> some View {
        let color = StressScoreModel.stressColorForScore(score)

        return VStack(spacing: 16) {
            // Row 1: Ring + status
            HStack(spacing: 16) {
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
                    Text("Stress")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.white.opacity(0.4))
                        .textCase(.uppercase)
                        .tracking(0.8)

                    if daysAgo > 0 {
                        Text(Self.scoreDateText(daysAgo: daysAgo))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.orange.opacity(0.8))
                    }

                    Text(StressScoreModel.stressStatusLabel(score))
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(color)

                    Text(StressScoreModel.stressGuidanceText(score))
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.45))
                        .lineLimit(1)
                }

                Spacer(minLength: 0)
            }

            // Row 2: 7-day trend bars
            if stressModel.last7DaysStress.count > 1 && stressModel.last7DaysStress.compactMap({ $0 }).count > 0 {
                trendBars(color: color)
            }

            // Row 3: What's driving it
            driverStats
        }
    }

    // MARK: - Driver Stats

    private var driverStats: some View {
        HStack(spacing: 10) {
            if let z = stressModel.zScores {
                if let zHRV = z.hrv {
                    driverChip(label: "HRV", zScore: zHRV, invertColor: true)
                }
                if let zRHR = z.rhr {
                    driverChip(label: "RHR", zScore: zRHR, invertColor: false)
                }
                if let zResp = z.respRate {
                    driverChip(label: "Resp", zScore: zResp, invertColor: false)
                }
                if let zTemp = z.wristTemp {
                    driverChip(label: "Temp", zScore: zTemp, invertColor: false)
                }
            }

            if let deficit = stressModel.sleepDeficit, deficit > 0 {
                sleepDeficitChip(deficit: deficit)
            }
        }
    }

    private func driverChip(label: String, zScore: Double, invertColor: Bool) -> some View {
        let isElevated = invertColor ? (zScore < -0.5) : (zScore > 0.5)
        let chipColor: Color = isElevated ? .orange : .green

        return VStack(spacing: 3) {
            Text(label)
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white.opacity(0.35))
                .textCase(.uppercase)
                .tracking(0.3)

            HStack(spacing: 2) {
                Image(systemName: isElevated ? "arrow.up.right" : "checkmark")
                    .font(.system(size: 8, weight: .bold))
                Text(String(format: "%.1f", abs(zScore)))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
            }
            .foregroundColor(chipColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.04))
        )
    }

    private func sleepDeficitChip(deficit: Double) -> some View {
        let pct = Int((deficit * 100).rounded())
        let chipColor: Color = deficit > 0.15 ? .orange : .green

        return VStack(spacing: 3) {
            Text("Sleep")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(.white.opacity(0.35))
                .textCase(.uppercase)
                .tracking(0.3)

            HStack(spacing: 2) {
                Image(systemName: deficit > 0.15 ? "moon.zzz" : "checkmark")
                    .font(.system(size: 8, weight: .bold))
                Text("-\(pct)%")
                    .font(.system(size: 10, weight: .bold, design: .rounded))
            }
            .foregroundColor(chipColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color.white.opacity(0.04))
        )
    }

    // MARK: - Trend Bars

    private func trendBars(color: Color) -> some View {
        VStack(spacing: 6) {
            HStack {
                Text("7-Day Trend")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.4))

                Spacer()

                if let avg = stressModel.weeklyAvgStress {
                    Text("Avg \(avg)")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(StressScoreModel.stressColorForScore(avg))
                }
            }

            HStack(alignment: .bottom, spacing: 4) {
                let days = stressModel.getLastSevenDays()
                let scores = stressModel.last7DaysStress
                let validScores = scores.compactMap { $0 }
                let maxScore = max(validScores.max() ?? 100, 1)

                ForEach(Array(zip(days, scores).enumerated()), id: \.offset) { index, pair in
                    let (day, value) = pair
                    let isToday = index == scores.count - 1

                    VStack(spacing: 3) {
                        if let value = value {
                            // Has data — show colored bar
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    isToday
                                        ? StressScoreModel.stressColorForScore(value)
                                        : StressScoreModel.stressColorForScore(value).opacity(0.5)
                                )
                                .frame(height: max(CGFloat(value) / CGFloat(maxScore) * 32, 4))
                        } else {
                            // No data — show dashed placeholder
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 4)
                        }

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
                Text("Stress Score")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.5))

                if let reason = stressModel.insufficientDataReason {
                    Text(reason)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                        .lineLimit(3)
                } else {
                    Text("Wear your Apple Watch to generate a score")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                        .lineLimit(2)
                }
            }

            Spacer()
        }
    }
}

// MARK: - Detail Sheet

private struct StressDetailSheet: View {
    @ObservedObject var model: StressScoreModel
    let dismiss: () -> Void

    private var mostRecentResult: (score: Int, daysAgo: Int)? {
        if let today = model.todayStressScore {
            return (today, 0)
        }
        let scores = model.last7DaysStress
        for i in stride(from: scores.count - 1, through: 0, by: -1) {
            if let value = scores[i] {
                return (value, scores.count - 1 - i)
            }
        }
        return nil
    }
    private var hasScore: Bool { mostRecentResult != nil }
    private var score: Int { mostRecentResult?.score ?? 0 }
    private var scoreDaysAgo: Int { mostRecentResult?.daysAgo ?? 0 }
    private var scoreColor: Color { hasScore ? StressScoreModel.stressColorForScore(score) : .white.opacity(0.2) }

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

                        if hasScore {
                            todayGuidance
                            zScoreBreakdown
                            sleepDeficitSection
                        } else {
                            // Empty state — no score available
                            noScoreExplanation
                        }

                        if model.last7DaysStress.count > 1 && model.last7DaysStress.compactMap({ $0 }).count > 0 {
                            weeklyTrend
                        }

                        baselineInfo
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

    // MARK: - No Score Explanation

    private var noScoreExplanation: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: "applewatch.slash")
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white.opacity(0.35))
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(Color.white.opacity(0.06))
                )

            VStack(alignment: .leading, spacing: 4) {
                Text("No Score Available")
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white.opacity(0.7))

                Text(model.insufficientDataReason ?? "Wear your Apple Watch to generate a stress score.")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.45))
                    .lineSpacing(3)
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.04))
        )
    }

    // MARK: - Hero

    private var heroSection: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(scoreColor.opacity(0.12), lineWidth: 10)

                if hasScore {
                    Circle()
                        .trim(from: 0, to: CGFloat(score) / 100.0)
                        .stroke(scoreColor, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 1) {
                        Text("\(score)")
                            .font(.system(size: 38, weight: .black, design: .rounded))
                            .foregroundColor(.white)
                    }
                } else {
                    Text("--")
                        .font(.system(size: 30, weight: .bold, design: .rounded))
                        .foregroundColor(.white.opacity(0.2))
                }
            }
            .frame(width: 100, height: 100)

            VStack(alignment: .leading, spacing: 6) {
                Text("Stress Score")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.4))
                    .textCase(.uppercase)
                    .tracking(0.8)

                if hasScore {
                    if scoreDaysAgo > 0 {
                        Text(StressScoreCard.scoreDateText(daysAgo: scoreDaysAgo))
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.orange.opacity(0.8))
                    }

                    Text(StressScoreModel.stressStatusLabel(score))
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(scoreColor)
                } else {
                    Text("No Data")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white.opacity(0.25))
                }

                if let avg = model.weeklyAvgStress {
                    Text("7-day avg: \(avg)")
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

    // MARK: - Z-Score Breakdown

    private var zScoreBreakdown: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("What's Driving Your Score")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.white.opacity(0.9))

            if let z = model.zScores {
                let w = model.computedWeights

                if let zHRV = z.hrv {
                    metricRow(
                        name: "Heart Rate Variability",
                        zScore: zHRV,
                        weight: w?.label(for: "hrv") ?? "35%",
                        explanation: hrvExplanation(zHRV),
                        color: .purple,
                        invertColor: true
                    )
                }

                if let zRHR = z.rhr {
                    metricRow(
                        name: "Resting Heart Rate",
                        zScore: zRHR,
                        weight: w?.label(for: "rhr") ?? "25%",
                        explanation: rhrExplanation(zRHR),
                        color: .red,
                        invertColor: false
                    )
                }

                if let zResp = z.respRate {
                    metricRow(
                        name: "Respiratory Rate",
                        zScore: zResp,
                        weight: w?.label(for: "resp") ?? "15%",
                        explanation: respExplanation(zResp),
                        color: .cyan,
                        invertColor: false
                    )
                }

                if let zTemp = z.wristTemp {
                    metricRow(
                        name: "Wrist Temperature",
                        zScore: zTemp,
                        weight: w?.label(for: "temp") ?? "10%",
                        explanation: tempExplanation(zTemp),
                        color: .orange,
                        invertColor: false
                    )
                }
            }
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

    private func metricRow(name: String, zScore: Double, weight: String, explanation: String, color: Color, invertColor: Bool) -> some View {
        let isGood = invertColor ? (zScore > 0) : (zScore < 0.5)
        let statusColor: Color = abs(zScore) < 0.5 ? .green : (isGood ? .green : .orange)

        return VStack(alignment: .leading, spacing: 8) {
            HStack {
                HStack(spacing: 6) {
                    Circle()
                        .fill(color)
                        .frame(width: 8, height: 8)
                    Text(name)
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }

                Spacer()

                HStack(spacing: 4) {
                    Text(String(format: "%+.1f", zScore))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(statusColor)
                    Text("(\(weight))")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                }
            }

            Text(explanation)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.white.opacity(0.45))
                .lineSpacing(2)
        }
        .padding(.vertical, 4)
    }

    // MARK: - Sleep Deficit

    private var sleepDeficitSection: some View {
        Group {
            if let deficit = model.sleepDeficit {
                let pct = Int((deficit * 100).rounded())
                let isSignificant = deficit > 0.15
                let deficitColor: Color = isSignificant ? .orange : .green

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "moon.zzz.fill")
                                .font(.system(size: 13))
                                .foregroundColor(.indigo)
                            Text("Sleep Deficit")
                                .font(.system(size: 15, weight: .semibold))
                                .foregroundColor(.white.opacity(0.9))
                        }

                        Spacer()

                        Text(pct == 0 ? "None" : "-\(pct)%")
                            .font(.system(size: 14, weight: .bold, design: .rounded))
                            .foregroundColor(deficitColor)
                    }

                    // Progress bar
                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 8)

                            RoundedRectangle(cornerRadius: 4)
                                .fill(deficitColor)
                                .frame(width: geo.size.width * CGFloat(min(deficit, 1.0)), height: 8)
                        }
                    }
                    .frame(height: 8)

                    Text(deficit < 0.05
                         ? "You met your sleep target. No penalty applied."
                         : deficit < 0.20
                            ? "Slight sleep debt. Minor impact on recovery."
                            : "Significant sleep deficit. This is reducing your recovery.")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.45))
                        .lineSpacing(2)

                    Text("Weight: \(model.computedWeights?.label(for: "sleep") ?? "15%")")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
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
        }
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
                let scores = model.last7DaysStress
                let validScores = scores.compactMap { $0 }
                let maxVal = max(validScores.max() ?? 100, 1)

                ForEach(Array(zip(days, scores).enumerated()), id: \.offset) { index, pair in
                    let (day, value) = pair
                    let isLast = index == scores.count - 1

                    VStack(spacing: 5) {
                        if let value = value {
                            Text("\(value)")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(isLast ? .white : .white.opacity(0.4))

                            let barColor = StressScoreModel.stressColorForScore(value)
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isLast ? barColor : barColor.opacity(0.45))
                                .frame(height: max(CGFloat(value) / CGFloat(maxVal) * 80, 6))
                        } else {
                            Text("—")
                                .font(.system(size: 10, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.2))

                            RoundedRectangle(cornerRadius: 4)
                                .fill(Color.white.opacity(0.06))
                                .frame(height: 6)
                        }

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

    // MARK: - Baseline Info

    private var baselineInfo: some View {
        Group {
            if model.baselineDayCount < 14 {
                HStack(spacing: 12) {
                    Image(systemName: "chart.line.uptrend.xyaxis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.blue)

                    VStack(alignment: .leading, spacing: 3) {
                        Text("Building Your Baseline")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))

                        Text("Day \(model.baselineDayCount) of 14 \u{2014} your score blends population averages with your personal data until we have 14 nights.")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.4))
                            .lineSpacing(3)
                    }
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.blue.opacity(0.06))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue.opacity(0.15), lineWidth: 1)
                        )
                )
            }
        }
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
                let w = model.computedWeights
                howItWorksRow(weight: w?.label(for: "hrv") ?? "35%", label: "HRV vs your 14-day baseline", color: .purple)
                howItWorksRow(weight: w?.label(for: "rhr") ?? "25%", label: "Resting HR vs baseline", color: .red)
                if model.zScores?.respRate != nil {
                    howItWorksRow(weight: w?.label(for: "resp") ?? "15%", label: "Respiratory rate vs baseline", color: .cyan)
                }
                if model.hasTemperatureData {
                    howItWorksRow(weight: w?.label(for: "temp") ?? "10%", label: "Wrist temperature deviation", color: .orange)
                }
                if model.sleepDeficit != nil {
                    howItWorksRow(weight: w?.label(for: "sleep") ?? "15%", label: "Sleep deficit penalty", color: .indigo)
                }
            }

            Text("Each metric is compared to your personal 14-day rolling average using Z-scores. Higher stress means your body is deviating from its norm in ways associated with fatigue, illness, or overtraining.")
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
        case 0...33:   return "leaf.fill"
        case 34...50:  return "figure.walk"
        case 51...66:  return "exclamationmark.triangle.fill"
        default:       return "bed.double.fill"
        }
    }

    private var detailedGuidance: String {
        switch score {
        case 0...33:
            return "Your stress levels are low. Your body is well-recovered and ready for whatever you throw at it."
        case 34...50:
            return "Moderate stress detected. Some metrics are off baseline. You can train but listen to your body."
        case 51...66:
            return "Elevated stress. Multiple metrics are significantly off your baseline. Consider lighter activity and prioritize recovery."
        default:
            return "High stress detected. Your body needs rest. Focus on sleep, hydration, and nutrition today."
        }
    }

    private func hrvExplanation(_ z: Double) -> String {
        if z > 0.5 { return "Above your baseline \u{2014} your nervous system is recovering well." }
        if z > -0.5 { return "Near your baseline \u{2014} normal variability." }
        if z > -1.5 { return "Below baseline \u{2014} often indicates fatigue or stress." }
        return "Significantly depressed \u{2014} strong sign of accumulated stress."
    }

    private func rhrExplanation(_ z: Double) -> String {
        if z < -0.5 { return "Below your baseline \u{2014} strong cardiovascular recovery." }
        if z < 0.5 { return "Near your baseline \u{2014} recovering normally." }
        if z < 1.5 { return "Elevated \u{2014} can indicate fatigue, dehydration, or stress." }
        return "Significantly elevated \u{2014} often signals overtraining or illness."
    }

    private func respExplanation(_ z: Double) -> String {
        if z < 0.5 { return "Normal respiratory rate during sleep." }
        if z < 1.5 { return "Slightly elevated \u{2014} could be a mild stressor." }
        return "Significantly elevated \u{2014} may indicate illness or high stress."
    }

    private func tempExplanation(_ z: Double) -> String {
        if abs(z) < 0.5 { return "Normal wrist temperature \u{2014} no significant deviation." }
        if z > 0.5 { return "Elevated \u{2014} can indicate immune response or overtraining." }
        return "Below baseline \u{2014} less common, may be environmental."
    }

    private var trendContextText: String? {
        let validScores = model.last7DaysStress.compactMap { $0 }
        guard validScores.count >= 4 else { return nil }
        let half = validScores.count / 2
        let recentAvg = Double(Array(validScores.suffix(half)).reduce(0, +)) / Double(half)
        let olderAvg = Double(Array(validScores.prefix(half)).reduce(0, +)) / Double(half)
        let diff = recentAvg - olderAvg
        if diff > 5 { return "Stress rising" }
        if diff < -5 { return "Stress falling" }
        return "Steady"
    }

    private var trendIcon: String {
        guard let text = trendContextText else { return "arrow.right" }
        if text == "Stress rising" { return "arrow.up.right" }
        if text == "Stress falling" { return "arrow.down.right" }
        return "arrow.right"
    }

    private var trendColor: Color {
        guard let text = trendContextText else { return .white.opacity(0.4) }
        if text == "Stress rising" { return .orange }
        if text == "Stress falling" { return .green }
        return .white.opacity(0.4)
    }
}
