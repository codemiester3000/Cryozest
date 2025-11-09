//
//  WeeklyGoalProgressView.swift
//  Cryozest-2
//
//  Weekly goal progress widget showing Monday-Sunday completion status
//

import SwiftUI
import CoreData

struct WeeklyGoalProgressView: View {
    @ObservedObject var therapyTypeSelection: TherapyTypeSelection
    @ObservedObject private var goalManager = GoalManager.shared

    @FetchRequest(
        entity: TherapySessionEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TherapySessionEntity.date, ascending: false)]
    )
    private var sessions: FetchedResults<TherapySessionEntity>

    @State private var showGoalConfig = false

    private var weeklyGoal: Int {
        goalManager.getWeeklyGoal(for: therapyTypeSelection.selectedTherapyType)
    }

    // Get current week's dates (Monday - Sunday)
    private var currentWeekDates: [Date] {
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // Monday
        let today = Date()

        // Find the Monday of the current week
        let weekday = calendar.component(.weekday, from: today)
        let daysFromMonday = (weekday - 2 + 7) % 7 // Monday is 2, calculate days since Monday

        guard let monday = calendar.date(byAdding: .day, value: -daysFromMonday, to: calendar.startOfDay(for: today)) else {
            return []
        }

        // Generate all 7 days (Monday - Sunday)
        return (0..<7).compactMap { dayOffset in
            calendar.date(byAdding: .day, value: dayOffset, to: monday)
        }
    }

    // Check if a habit was completed on a specific date
    private func isCompleted(on date: Date) -> Bool {
        sessions.contains { session in
            guard let sessionDate = session.date else { return false }
            return Calendar.current.isDate(sessionDate, inSameDayAs: date) &&
                   session.therapyType == therapyTypeSelection.selectedTherapyType.rawValue
        }
    }

    // Count completions this week
    private var weeklyCompletions: Int {
        currentWeekDates.filter { isCompleted(on: $0) }.count
    }

    // Progress percentage
    private var progressPercentage: Double {
        guard weeklyGoal > 0 else { return 0 }
        return min(Double(weeklyCompletions) / Double(weeklyGoal), 1.0)
    }

    private var progressColor: Color {
        let percentage = progressPercentage
        if percentage >= 1.0 {
            return .green
        } else if percentage >= 0.5 {
            return therapyTypeSelection.selectedTherapyType.color
        } else {
            return .orange
        }
    }

    var body: some View {
        VStack(spacing: 16) {
            // Header with goal configuration
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Weekly Goal")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)

                    Text("\(weeklyCompletions) of \(weeklyGoal) sessions")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                // Goal config button
                Button(action: { showGoalConfig = true }) {
                    HStack(spacing: 6) {
                        Image(systemName: "target")
                            .font(.system(size: 13, weight: .semibold))
                        Text("Goal")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(therapyTypeSelection.selectedTherapyType.color)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(therapyTypeSelection.selectedTherapyType.color.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(therapyTypeSelection.selectedTherapyType.color.opacity(0.3), lineWidth: 1)
                            )
                    )
                }
            }

            // Progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    // Background
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.white.opacity(0.1))
                        .frame(height: 12)

                    // Progress
                    RoundedRectangle(cornerRadius: 8)
                        .fill(
                            LinearGradient(
                                colors: [progressColor, progressColor.opacity(0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: geometry.size.width * progressPercentage, height: 12)
                        .animation(.spring(response: 0.5, dampingFraction: 0.7), value: progressPercentage)
                }
            }
            .frame(height: 12)

            // Weekly calendar view
            HStack(spacing: 8) {
                ForEach(Array(currentWeekDates.enumerated()), id: \.offset) { index, date in
                    WeekDayCell(
                        date: date,
                        isCompleted: isCompleted(on: date),
                        isToday: Calendar.current.isDateInToday(date),
                        color: therapyTypeSelection.selectedTherapyType.color
                    )
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.1),
                            Color.white.opacity(0.06)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(
                            LinearGradient(
                                colors: [progressColor.opacity(0.4), progressColor.opacity(0.2)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 1.5
                        )
                )
        )
        .sheet(isPresented: $showGoalConfig) {
            WeeklyGoalConfigSheet(therapyType: therapyTypeSelection.selectedTherapyType)
        }
    }
}

struct WeekDayCell: View {
    let date: Date
    let isCompleted: Bool
    let isToday: Bool
    let color: Color

    private var dayLetter: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        let fullDay = formatter.string(from: date)
        return String(fullDay.prefix(1))
    }

    private var dayNumber: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d"
        return formatter.string(from: date)
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(dayLetter)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            ZStack {
                // Background circle
                Circle()
                    .fill(isCompleted ? color.opacity(0.25) : Color.white.opacity(0.08))
                    .frame(width: 36, height: 36)

                // Today indicator ring
                if isToday {
                    Circle()
                        .stroke(color, lineWidth: 2)
                        .frame(width: 36, height: 36)
                }

                // Checkmark or day number
                if isCompleted {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(color)
                } else {
                    Text(dayNumber)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(isToday ? 0.9 : 0.5))
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

struct WeeklyGoalConfigSheet: View {
    let therapyType: TherapyType
    @Environment(\.dismiss) private var dismiss
    @ObservedObject private var goalManager = GoalManager.shared

    @State private var weeklyGoal: Int

    init(therapyType: TherapyType) {
        self.therapyType = therapyType
        _weeklyGoal = State(initialValue: GoalManager.shared.getWeeklyGoal(for: therapyType))
    }

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.05, green: 0.15, blue: 0.25),
                    Color(red: 0.1, green: 0.2, blue: 0.35),
                    Color(red: 0.15, green: 0.25, blue: 0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 24) {
                // Header
                VStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(therapyType.color.opacity(0.2))
                            .frame(width: 80, height: 80)

                        Image(systemName: "target")
                            .font(.system(size: 36, weight: .semibold))
                            .foregroundColor(therapyType.color)
                    }

                    Text("Weekly Goal")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(.white)

                    Text("How many times per week?")
                        .font(.system(size: 15, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }
                .padding(.top, 40)

                Spacer()

                // Goal stepper
                VStack(spacing: 16) {
                    Text("\(weeklyGoal)")
                        .font(.system(size: 72, weight: .bold))
                        .foregroundColor(therapyType.color)

                    Text(weeklyGoal == 1 ? "session per week" : "sessions per week")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.7))

                    // Stepper
                    HStack(spacing: 24) {
                        Button(action: {
                            if weeklyGoal > 1 {
                                weeklyGoal -= 1
                            }
                        }) {
                            Image(systemName: "minus.circle.fill")
                                .font(.system(size: 56))
                                .foregroundColor(weeklyGoal > 1 ? therapyType.color : Color.white.opacity(0.3))
                        }
                        .disabled(weeklyGoal <= 1)

                        Button(action: {
                            if weeklyGoal < 7 {
                                weeklyGoal += 1
                            }
                        }) {
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 56))
                                .foregroundColor(weeklyGoal < 7 ? therapyType.color : Color.white.opacity(0.3))
                        }
                        .disabled(weeklyGoal >= 7)
                    }
                }

                Spacer()

                // Save button
                Button(action: {
                    goalManager.setWeeklyGoal(weeklyGoal, for: therapyType)
                    dismiss()
                }) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18, weight: .semibold))

                        Text("Save Goal")
                            .font(.system(size: 17, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        therapyType.color,
                                        therapyType.color.opacity(0.8)
                                    ]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                    )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 40)
            }
        }
    }
}
