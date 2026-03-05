import SwiftUI

struct WeeklyReviewView: View {
    let review: WeeklyReview

    @State private var appeared = false
    @State private var ringProgress: Double = 0
    @State private var barsAnimated = false

    private let cardBg = Color(red: 0.10, green: 0.14, blue: 0.22)

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 20) {
                heroSection

                if !review.dailyRecoveryScores.isEmpty {
                    recoveryChartSection
                }

                statsSection

                if !review.dailyHabitActivity.isEmpty && !review.allHabitNames.isEmpty {
                    activityGridSection
                }

                highlightsSection

                if !review.newPersonalBests.isEmpty {
                    personalBestsSection
                }

                if review.sleepTrend != nil || review.hrvTrend != nil {
                    trendsSection
                }
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 40)
        }
        .onAppear {
            guard !appeared else { return }
            withAnimation(.easeOut(duration: 0.6).delay(0.1)) {
                appeared = true
            }
            if let avg = review.avgRecovery {
                withAnimation(.easeOut(duration: 1.4).delay(0.3)) {
                    ringProgress = Double(avg) / 100.0
                }
            }
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                barsAnimated = true
            }
        }
    }

    // MARK: - Hero Section

    private var heroSection: some View {
        VStack(spacing: 0) {
            if let avg = review.avgRecovery {
                HStack(spacing: 20) {
                    // Recovery Ring
                    ZStack {
                        // Ambient glow
                        Circle()
                            .fill(recoveryColor(avg).opacity(0.08))
                            .frame(width: 144, height: 144)
                            .blur(radius: 20)

                        // Track
                        Circle()
                            .stroke(Color.white.opacity(0.06), lineWidth: 12)
                            .frame(width: 120, height: 120)

                        // Progress arc
                        Circle()
                            .trim(from: 0, to: ringProgress)
                            .stroke(
                                LinearGradient(
                                    colors: ringGradient(avg),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                style: StrokeStyle(lineWidth: 12, lineCap: .round)
                            )
                            .frame(width: 120, height: 120)
                            .rotationEffect(.degrees(-90))
                            .shadow(color: recoveryColor(avg).opacity(0.3), radius: 8)

                        // Center content
                        VStack(spacing: 0) {
                            Text("\(avg)")
                                .font(.system(size: 38, weight: .black, design: .rounded))
                                .foregroundColor(.white)
                            Text("RECOVERY")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.white.opacity(0.35))
                                .tracking(2)
                        }
                    }
                    .frame(width: 144, height: 144)

                    // Grade + Message
                    VStack(alignment: .leading, spacing: 10) {
                        if !review.weekGrade.isEmpty {
                            Text(review.weekGrade)
                                .font(.system(size: 48, weight: .black, design: .rounded))
                                .foregroundColor(.cyan)
                        }

                        Text(review.highlightMessage)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
            } else {
                // No recovery data
                VStack(spacing: 12) {
                    if !review.weekGrade.isEmpty {
                        Text(review.weekGrade)
                            .font(.system(size: 56, weight: .black, design: .rounded))
                            .foregroundColor(.cyan)
                    } else {
                        Image(systemName: "chart.bar.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.cyan.opacity(0.4))
                    }

                    Text(review.highlightMessage)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    // MARK: - Recovery Chart

    private var recoveryChartSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("DAILY RECOVERY")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.35))
                .tracking(1)

            HStack(alignment: .bottom, spacing: 6) {
                ForEach(Array(review.dailyRecoveryScores.enumerated()), id: \.element.id) { index, item in
                    VStack(spacing: 6) {
                        // Score label
                        Text("\(item.score)")
                            .font(.system(size: 10, weight: .bold, design: .rounded))
                            .foregroundColor(barsAnimated ? .white.opacity(0.6) : .clear)
                            .animation(
                                .easeOut(duration: 0.3).delay(Double(index) * 0.07 + 0.3),
                                value: barsAnimated
                            )

                        // Bar
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: barGradient(item.score),
                                    startPoint: .bottom,
                                    endPoint: .top
                                )
                            )
                            .frame(height: barsAnimated ? max(8, CGFloat(item.score) * 1.1) : 8)
                            .animation(
                                .spring(response: 0.5, dampingFraction: 0.7).delay(Double(index) * 0.07),
                                value: barsAnimated
                            )

                        // Day label
                        Text(String(item.day.prefix(3)))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.4))
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .frame(height: 150)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    // MARK: - Stats Section

    private var statsSection: some View {
        HStack(spacing: 10) {
            weekStatTile(
                value: "\(review.totalSessions)",
                label: "Sessions",
                icon: "checkmark.circle.fill",
                color: .green,
                delta: deltaString(current: review.totalSessions, previous: review.previousWeekSessions)
            )
            weekStatTile(
                value: formatMinutes(review.totalMinutes),
                label: "Active Time",
                icon: "timer",
                color: .cyan,
                delta: minutesDelta(current: review.totalMinutes, previous: review.previousWeekMinutes)
            )
            weekStatTile(
                value: "\(review.uniqueHabits)",
                label: "Habits",
                icon: "square.grid.2x2.fill",
                color: .purple,
                delta: nil
            )
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    private func weekStatTile(value: String, label: String, icon: String, color: Color, delta: String?) -> some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.35))

            if let delta = delta {
                Text(delta)
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(deltaColor(delta))
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
    }

    // MARK: - Activity Grid

    private var activityGridSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ACTIVITY")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.35))
                .tracking(1)

            VStack(spacing: 0) {
                // Day headers
                HStack(spacing: 0) {
                    Color.clear.frame(width: 80)
                    ForEach(review.dailyHabitActivity) { day in
                        Text(String(day.day.prefix(1)))
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.white.opacity(0.4))
                            .frame(maxWidth: .infinity)
                    }
                }
                .padding(.bottom, 8)

                // Habit rows
                ForEach(review.allHabitNames, id: \.self) { habitName in
                    HStack(spacing: 0) {
                        Text(habitName)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                            .lineLimit(1)
                            .frame(width: 80, alignment: .leading)

                        ForEach(review.dailyHabitActivity) { day in
                            let done = day.habitNames.contains(habitName)
                            ZStack {
                                Circle()
                                    .fill(done ? Color.green : Color.white.opacity(0.06))
                                    .frame(width: done ? 16 : 10, height: done ? 16 : 10)

                                if done {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 7, weight: .black))
                                        .foregroundColor(.white)
                                }
                            }
                            .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.vertical, 6)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.white.opacity(0.06), lineWidth: 1)
                )
        )
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    // MARK: - Highlights

    private var highlightsSection: some View {
        let highlights = buildHighlights()
        return Group {
            if !highlights.isEmpty {
                VStack(alignment: .leading, spacing: 10) {
                    Text("HIGHLIGHTS")
                        .font(.system(size: 11, weight: .bold))
                        .foregroundColor(.white.opacity(0.35))
                        .tracking(1)

                    VStack(spacing: 8) {
                        ForEach(highlights, id: \.title) { h in
                            highlightCard(icon: h.icon, color: h.color, title: h.title, detail: h.detail)
                        }
                    }
                }
                .opacity(appeared ? 1 : 0)
                .offset(y: appeared ? 0 : 20)
            }
        }
    }

    private struct HighlightItem {
        let icon: String
        let color: Color
        let title: String
        let detail: String
    }

    private func buildHighlights() -> [HighlightItem] {
        var items: [HighlightItem] = []
        if let best = review.bestRecoveryDay {
            items.append(HighlightItem(icon: "star.fill", color: .yellow, title: "Peak Recovery", detail: "\(best.day) — \(best.score)%"))
        }
        if let top = review.topHabit {
            items.append(HighlightItem(icon: "flame.fill", color: .orange, title: "Most Active", detail: "\(top.name) — \(top.count) sessions"))
        }
        if let streak = review.longestStreak, streak.days > 1 {
            items.append(HighlightItem(icon: "bolt.fill", color: .cyan, title: "\(streak.days)-Day Streak", detail: streak.habit))
        }
        if let sleep = review.avgSleepHours {
            items.append(HighlightItem(icon: "moon.fill", color: .indigo, title: "Avg Sleep", detail: String(format: "%.1f hrs/night", sleep)))
        }
        return items
    }

    private func highlightCard(icon: String, color: Color, title: String, detail: String) -> some View {
        HStack(spacing: 14) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(color.opacity(0.15))
                    .frame(width: 40, height: 40)

                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)

                Text(detail)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(cardBg)
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(color.opacity(0.1), lineWidth: 1)
                )
        )
    }

    // MARK: - Personal Bests

    private var personalBestsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("NEW PERSONAL BESTS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.35))
                .tracking(1)

            ForEach(review.newPersonalBests) { best in
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: [Color.yellow, Color.orange],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 42, height: 42)

                        Image(systemName: "trophy.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                        Text("Best \(best.metric)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)

                        Text("\(best.value) — \(best.timeframe)")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundColor(.white.opacity(0.5))
                    }

                    Spacer()
                }
                .padding(14)
                .background(
                    RoundedRectangle(cornerRadius: 14)
                        .fill(
                            LinearGradient(
                                colors: [Color.yellow.opacity(0.08), Color.orange.opacity(0.04)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 14)
                                .stroke(Color.yellow.opacity(0.15), lineWidth: 1)
                        )
                )
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    // MARK: - Trends

    private var trendsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("TRENDS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.35))
                .tracking(1)

            HStack(spacing: 10) {
                if let sleepTrend = review.sleepTrend {
                    trendPill(metric: "Sleep", direction: sleepTrend, icon: "bed.double.fill")
                }
                if let hrvTrend = review.hrvTrend {
                    trendPill(metric: "HRV", direction: hrvTrend, icon: "waveform.path.ecg")
                }
            }
        }
        .opacity(appeared ? 1 : 0)
        .offset(y: appeared ? 0 : 20)
    }

    private func trendPill(metric: String, direction: TrendDirection, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(direction.color)

            Text(metric)
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(.white.opacity(0.8))

            Image(systemName: direction.icon)
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(direction.color)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(direction.color.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(direction.color.opacity(0.12), lineWidth: 1)
                )
        )
    }

    // MARK: - Helpers

    private func recoveryColor(_ score: Int) -> Color {
        if score >= 75 { return .green }
        if score >= 55 { return .yellow }
        return .red
    }

    private func ringGradient(_ score: Int) -> [Color] {
        if score >= 75 { return [.green, .cyan] }
        if score >= 55 { return [.yellow, .orange] }
        return [.red, .orange]
    }

    private func barGradient(_ score: Int) -> [Color] {
        if score >= 75 { return [.green.opacity(0.6), .green] }
        if score >= 55 { return [.yellow.opacity(0.6), .yellow] }
        return [.red.opacity(0.6), .red]
    }

    private func formatMinutes(_ minutes: Int) -> String {
        if minutes >= 60 {
            let h = minutes / 60
            let m = minutes % 60
            return m > 0 ? "\(h)h \(m)m" : "\(h)h"
        }
        return "\(minutes)m"
    }

    private func deltaString(current: Int, previous: Int?) -> String? {
        guard let prev = previous else { return nil }
        let diff = current - prev
        if diff > 0 { return "+\(diff)" }
        if diff < 0 { return "\(diff)" }
        return "same"
    }

    private func minutesDelta(current: Int, previous: Int?) -> String? {
        guard let prev = previous else { return nil }
        let diff = current - prev
        if diff > 0 { return "+\(formatMinutes(diff))" }
        if diff < 0 { return "-\(formatMinutes(abs(diff)))" }
        return "same"
    }

    private func deltaColor(_ delta: String) -> Color {
        if delta.hasPrefix("+") { return .green }
        if delta.hasPrefix("-") { return .red }
        return .white.opacity(0.3)
    }
}
