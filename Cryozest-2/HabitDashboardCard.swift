//
//  HabitDashboardCard.swift
//  Cryozest-2
//
//  Expandable habit card for the My Habits dashboard
//  Shows logging, streaks, and per-habit health correlations
//

import SwiftUI
import CoreData

struct HabitDashboardCard: View {
    let habitType: TherapyType
    let sessions: FetchedResults<TherapySessionEntity>
    let impacts: [HabitImpact]
    let progress: DataCollectionProgress?
    let isExpanded: Bool
    let onTap: () -> Void
    let onLog: () -> Void
    let onDelete: (TherapySessionEntity) -> Void
    var showCheckmark: Bool = false
    var logButtonScale: CGFloat = 1.0

    @Environment(\.managedObjectContext) private var viewContext

    // MARK: - Computed Properties

    private var habitSessions: [TherapySessionEntity] {
        sessions.filter { $0.therapyType == habitType.rawValue }
                .sorted(by: { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) })
    }

    private var todayCount: Int {
        let calendar = Calendar.current
        return sessions.filter { session in
            guard let date = session.date else { return false }
            return calendar.isDateInToday(date) && session.therapyType == habitType.rawValue
        }.count
    }

    private var weekCount: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return sessions.filter { session in
            guard let date = session.date else { return false }
            return date >= startOfWeek && session.therapyType == habitType.rawValue
        }.count
    }

    private var sessionDates: [Date] {
        habitSessions.compactMap { $0.date }
    }

    private var currentStreak: Int {
        let calendar = Calendar.current
        let sortedDates = sessionDates.sorted(by: >)
        guard !sortedDates.isEmpty else { return 0 }

        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        if todayCount == 0 {
            checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
        }

        for date in sortedDates {
            let sessionDay = calendar.startOfDay(for: date)
            if calendar.isDate(sessionDay, inSameDayAs: checkDate) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if sessionDay < checkDate {
                break
            }
        }
        return streak
    }

    private var longestStreak: Int {
        let calendar = Calendar.current
        let sortedDates = sessionDates.map { calendar.startOfDay(for: $0) }.sorted()
        guard !sortedDates.isEmpty else { return 0 }

        var longest = 1
        var current = 1
        var previousDate = sortedDates[0]

        for i in 1..<sortedDates.count {
            let date = sortedDates[i]
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: previousDate),
               calendar.isDate(date, inSameDayAs: nextDay) {
                current += 1
                longest = max(longest, current)
            } else if !calendar.isDate(date, inSameDayAs: previousDate) {
                current = 1
            }
            previousDate = date
        }
        return longest
    }

    private var todaySessions: [TherapySessionEntity] {
        let calendar = Calendar.current
        return sessions.filter { session in
            guard let date = session.date else { return false }
            return calendar.isDateInToday(date) && session.therapyType == habitType.rawValue
        }.sorted(by: { ($0.date ?? .distantPast) > ($1.date ?? .distantPast) })
    }

    // MARK: - Body

    var body: some View {
        VStack(spacing: 0) {
            // Always-visible compact card
            compactContent
                .contentShape(Rectangle())
                .onTapGesture(perform: onTap)

            // Expanded detail section
            if isExpanded {
                Divider()
                    .background(Color.white.opacity(0.06))
                    .padding(.horizontal, 14)

                expandedContent
                    .transition(.opacity)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(isExpanded ?
                      Color.white.opacity(0.08) :
                      Color.white.opacity(0.05))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            isExpanded ? habitType.color.opacity(0.35) : Color.white.opacity(0.06),
                            lineWidth: isExpanded ? 1.5 : 1
                        )
                )
        )
        .shadow(
            color: isExpanded ? habitType.color.opacity(0.15) : Color.clear,
            radius: isExpanded ? 12 : 0,
            x: 0,
            y: isExpanded ? 4 : 0
        )
        .animation(.spring(response: 0.4, dampingFraction: 0.85), value: isExpanded)
    }

    // MARK: - Compact Content

    private var compactContent: some View {
        HStack(spacing: 12) {
            // Habit icon
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(habitType.color.opacity(0.15))
                    .frame(width: 36, height: 36)

                Image(systemName: habitType.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(habitType.color)
            }

            // Name + inline stats
            VStack(alignment: .leading, spacing: 2) {
                Text(habitType.displayName(viewContext))
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)

                HStack(spacing: 6) {
                    if currentStreak > 0 {
                        HStack(spacing: 2) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.orange)
                            Text("\(currentStreak)d")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.orange)
                        }
                    }

                    if todayCount > 0 {
                        HStack(spacing: 2) {
                            Circle()
                                .fill(habitType.color)
                                .frame(width: 4, height: 4)
                            Text("\(todayCount) today")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(habitType.color)
                        }
                    }

                    Text("\(weekCount)/wk")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.3))
                }
            }

            Spacer()

            // Expand chevron
            Image(systemName: "chevron.down")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.25))
                .rotationEffect(.degrees(isExpanded ? -180 : 0))

            // Log button
            Button(action: {
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
                onLog()
            }) {
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                colors: [habitType.color, habitType.color.opacity(0.7)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 34, height: 34)
                        .shadow(color: habitType.color.opacity(0.25), radius: 4, x: 0, y: 2)

                    Image(systemName: showCheckmark ? "checkmark" : "plus")
                        .font(.system(size: showCheckmark ? 15 : 13, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(logButtonScale)
            }
            .buttonStyle(HabitScaleButtonStyle())
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }

    // MARK: - Mini Week Dots (Compact inline version)

    private var miniWeekDots: some View {
        HStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { dayOffset in
                let date = Calendar.current.date(
                    byAdding: .day,
                    value: dayOffset - (Calendar.current.component(.weekday, from: Date()) - 1),
                    to: Date()
                )!
                let dayCount = sessionDates.filter { Calendar.current.isDate($0, inSameDayAs: date) }.count
                let isToday = Calendar.current.isDateInToday(date)
                let isFuture = date > Date()

                VStack(spacing: 2) {
                    Text(dayLetter(for: date))
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(isToday ? .white.opacity(0.7) : .white.opacity(0.25))

                    ZStack {
                        RoundedRectangle(cornerRadius: 4)
                            .fill(dayCount > 0 ?
                                  habitType.color :
                                  (isFuture ? Color.white.opacity(0.02) : Color.white.opacity(0.05)))
                            .frame(height: 18)

                        if dayCount > 0 {
                            Text("\(dayCount)")
                                .font(.system(size: 9, weight: .bold))
                                .foregroundColor(.white)
                        }

                        if isToday && dayCount == 0 {
                            RoundedRectangle(cornerRadius: 4)
                                .stroke(habitType.color.opacity(0.5), lineWidth: 1)
                                .frame(height: 18)
                        }
                    }
                }
                .frame(maxWidth: .infinity)
            }
        }
        .padding(.horizontal, 2)
    }

    private func dayLetter(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE"
        return formatter.string(from: date)
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(spacing: 12) {
            // Quick stats row
            statsRow

            // Today's sessions
            if !todaySessions.isEmpty {
                todaySessionsSection
            }

            // Detailed correlations
            if !impacts.isEmpty {
                correlationsSection
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 12)
        .padding(.bottom, 4)
    }

    // MARK: - Stats Row

    private var statsRow: some View {
        HStack(spacing: 0) {
            statItem(value: "\(currentStreak)", label: "Current", icon: "flame.fill", color: .orange)
            statItem(value: "\(longestStreak)", label: "Best", icon: "trophy.fill", color: .yellow)
            statItem(value: "\(weekCount)", label: "Week", icon: "calendar", color: .cyan)
            statItem(value: "\(habitSessions.count)", label: "Total", icon: "checkmark.circle.fill", color: .green)
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.05))
        )
    }

    private func statItem(value: String, label: String, icon: String, color: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundColor(.white)

            Text(label)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.white.opacity(0.45))
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Today's Sessions

    private var todaySessionsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("TODAY'S SESSIONS")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundColor(.white.opacity(0.4))
                    .tracking(0.5)

                Spacer()

                Text("\(todaySessions.count)")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(habitType.color)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(
                        Capsule()
                            .fill(habitType.color.opacity(0.15))
                    )
            }

            VStack(spacing: 4) {
                ForEach(Array(todaySessions.enumerated()), id: \.element.id) { index, session in
                    HStack(spacing: 10) {
                        Text("#\(index + 1)")
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .foregroundColor(habitType.color)
                            .frame(width: 24)

                        Text(sessionTimeString(session))
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))

                        if session.duration > 0 {
                            Text("\(Int(session.duration / 60))m")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundColor(.white.opacity(0.4))
                        }

                        Spacer()

                        if session.isAppleWatch {
                            Image(systemName: "applewatch")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.green)
                        }

                        Button(action: { onDelete(session) }) {
                            Image(systemName: "trash")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.red.opacity(0.6))
                        }
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.white.opacity(0.03))
                    )
                }
            }
        }
    }

    private func sessionTimeString(_ session: TherapySessionEntity) -> String {
        guard let date = session.date else { return "" }
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    // MARK: - Correlations Section

    private var correlationsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("HEALTH IMPACT")
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(.white.opacity(0.4))
                .tracking(0.5)

            VStack(spacing: 0) {
                ForEach(impacts) { impact in
                    HStack(spacing: 10) {
                        // Metric indicator
                        Image(systemName: metricIcon(impact.metricName))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(metricColor(impact.metricName))
                            .frame(width: 24)

                        // Metric name + direction
                        VStack(alignment: .leading, spacing: 2) {
                            HStack(spacing: 4) {
                                Text(impact.metricName)
                                    .font(.system(size: 13, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.9))

                                ConfidenceIndicator(level: impact.confidenceLevel)
                            }

                            HStack(spacing: 4) {
                                Text(formatValue(impact.baselineValue, metric: impact.metricName))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.35))

                                Image(systemName: "arrow.right")
                                    .font(.system(size: 8, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.2))

                                Text(formatValue(impact.habitValue, metric: impact.metricName))
                                    .font(.system(size: 10, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }

                        Spacer()

                        // Change percentage
                        HStack(spacing: 3) {
                            Image(systemName: impact.isPositive ? "arrow.up.right" : "arrow.down.right")
                                .font(.system(size: 10, weight: .bold))

                            Text(impact.changeDescription)
                                .font(.system(size: 15, weight: .bold, design: .rounded))
                        }
                        .foregroundColor(impact.isPositive ? .green : .red)
                    }
                    .padding(.vertical, 10)
                    .padding(.horizontal, 10)

                    if impact.id != impacts.last?.id {
                        Divider()
                            .background(Color.white.opacity(0.05))
                            .padding(.horizontal, 10)
                    }
                }
            }
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.04))
            )
        }
    }

    // MARK: - Helpers

    private func metricIcon(_ name: String) -> String {
        switch name {
        case "Sleep Duration": return "bed.double.fill"
        case "HRV": return "waveform.path.ecg"
        case "RHR": return "heart.fill"
        case "Pain Level": return "bolt.fill"
        case "Hydration": return "drop.fill"
        default: return "chart.bar.fill"
        }
    }

    private func metricColor(_ name: String) -> Color {
        switch name {
        case "Sleep Duration": return .purple
        case "HRV": return .green
        case "RHR": return .red
        case "Pain Level": return .orange
        case "Hydration": return .cyan
        default: return .white
        }
    }

    private func formatValue(_ value: Double, metric: String) -> String {
        switch metric {
        case "Sleep Duration": return String(format: "%.1fh", value)
        case "HRV": return "\(Int(value)) ms"
        case "RHR": return "\(Int(value)) bpm"
        default:
            if value >= 100 { return String(format: "%.0f", value) }
            else if value >= 10 { return String(format: "%.1f", value) }
            else { return String(format: "%.2f", value) }
        }
    }
}
