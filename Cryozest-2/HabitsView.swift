//
//  HabitsView.swift
//  Cryozest-2
//
//  Professional habit tracking interface inspired by Whoop
//  Data-focused design with streaks, statistics, and clean visuals
//

import SwiftUI
import CoreData

struct HabitsView: View {
    @ObservedObject var therapyTypeSelection: TherapyTypeSelection
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        entity: TherapySessionEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TherapySessionEntity.date, ascending: false)]
    )
    private var sessions: FetchedResults<TherapySessionEntity>

    @State private var sessionDates: [Date] = []
    @State private var showCompletionAnimation = false
    @State private var animationScale: CGFloat = 0.5
    @State private var animationOpacity: Double = 0
    @State private var showHabitSelection = false
    @State private var showUndoToast = false
    @State private var lastCompletedSession: TherapySessionEntity?

    private var sortedSessions: [TherapySessionEntity] {
        sessions.filter { $0.therapyType == therapyTypeSelection.selectedTherapyType.rawValue }
               .sorted(by: { $0.date! > $1.date! })
    }

    private var isCompletedToday: Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return sessions.contains { session in
            guard let sessionDate = session.date else { return false }
            return calendar.isDate(sessionDate, inSameDayAs: today) &&
                   session.therapyType == therapyTypeSelection.selectedTherapyType.rawValue
        }
    }

    // Calculate current streak
    private var currentStreak: Int {
        let calendar = Calendar.current
        let sortedDates = sessionDates.sorted(by: >)
        guard !sortedDates.isEmpty else { return 0 }

        var streak = 0
        var checkDate = calendar.startOfDay(for: Date())

        // If not completed today, start checking from yesterday
        if !isCompletedToday {
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

    // Calculate longest streak
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

    // This week's completions
    private var weekCompletions: Int {
        let calendar = Calendar.current
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date()))!
        return sessionDates.filter { $0 >= startOfWeek }.count
    }

    private func updateSessionDates() {
        self.sessionDates = sessions
            .filter { $0.therapyType == therapyTypeSelection.selectedTherapyType.rawValue }
            .compactMap { $0.date }
    }

    var body: some View {
        ZStack {
            // Background - Deep navy base
            Color(red: 0.06, green: 0.10, blue: 0.18)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 20)

                    // Habit selector carousel
                    HabitSelectorStrip(therapyTypeSelection: therapyTypeSelection, sessions: sessions)
                        .padding(.bottom, 24)

                    // Main content
                    VStack(spacing: 20) {
                        // Streak & Stats Hero
                        streakHeroSection
                            .padding(.horizontal, 20)

                        // Today's Action
                        todayActionCard
                            .padding(.horizontal, 20)

                        // Weekly Progress Ring
                        weeklyProgressSection
                            .padding(.horizontal, 20)

                        // Calendar
                        calendarSection
                            .padding(.horizontal, 20)

                        // Statistics
                        statisticsSection
                            .padding(.horizontal, 20)
                    }
                    .padding(.bottom, 120)
                }
            }

            // Completion animation overlay
            if showCompletionAnimation {
                completionOverlay
            }

            // Undo toast
            if showUndoToast {
                VStack {
                    Spacer()
                    undoToast
                        .padding(.horizontal, 20)
                        .padding(.bottom, 100)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
        .onAppear { updateSessionDates() }
        .onChange(of: therapyTypeSelection.selectedTherapyType) { _ in updateSessionDates() }
        .sheet(isPresented: $showHabitSelection) {
            TherapyTypeSelectionView()
                .environment(\.managedObjectContext, viewContext)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            Text("Habits")
                .font(.system(size: 28, weight: .bold))
                .foregroundColor(.white)

            Spacer()

            Button(action: { showHabitSelection = true }) {
                Image(systemName: "plus.circle.fill")
                    .font(.system(size: 24, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
        }
    }

    // MARK: - Streak Hero Section

    private var streakHeroSection: some View {
        HStack(spacing: 16) {
            // Current Streak - Hero display
            VStack(spacing: 4) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text("\(currentStreak)")
                        .font(.system(size: 56, weight: .bold, design: .rounded))
                        .foregroundColor(.white)

                    Text("day")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white.opacity(0.5))
                        .padding(.bottom, 8)
                }

                Text("Current Streak")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))

                // Streak fire indicator
                if currentStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.orange)

                        Text(streakMessage)
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.orange)
                    }
                    .padding(.top, 4)
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
            )

            // Quick Stats
            VStack(spacing: 12) {
                StatPill(value: "\(longestStreak)", label: "Best", icon: "trophy.fill", color: .yellow)
                StatPill(value: "\(weekCompletions)/7", label: "Week", icon: "calendar", color: .cyan)
                StatPill(value: "\(sortedSessions.count)", label: "Total", icon: "checkmark.circle.fill", color: .green)
            }
            .frame(width: 100)
        }
    }

    private var streakMessage: String {
        switch currentStreak {
        case 1...2: return "Good start!"
        case 3...6: return "Building momentum"
        case 7...13: return "One week strong!"
        case 14...29: return "On fire!"
        case 30...: return "Unstoppable!"
        default: return ""
        }
    }

    // MARK: - Today's Action Card

    private var todayActionCard: some View {
        Button(action: { if !isCompletedToday { logTodaySession() } }) {
            HStack(spacing: 16) {
                // Status indicator
                ZStack {
                    Circle()
                        .stroke(
                            isCompletedToday ? therapyTypeSelection.selectedTherapyType.color : Color.white.opacity(0.2),
                            lineWidth: 3
                        )
                        .frame(width: 52, height: 52)

                    if isCompletedToday {
                        Circle()
                            .fill(therapyTypeSelection.selectedTherapyType.color)
                            .frame(width: 44, height: 44)

                        Image(systemName: "checkmark")
                            .font(.system(size: 20, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .fill(Color.white.opacity(0.06))
                            .frame(width: 44, height: 44)

                        Image(systemName: therapyTypeSelection.selectedTherapyType.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(therapyTypeSelection.selectedTherapyType.color)
                    }
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(isCompletedToday ? "Completed" : "Mark Complete")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)

                    Text(isCompletedToday ? "Great work today!" : "Tap to log today's session")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                if !isCompletedToday {
                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(therapyTypeSelection.selectedTherapyType.color)
                        .frame(width: 36, height: 36)
                        .background(
                            Circle()
                                .fill(therapyTypeSelection.selectedTherapyType.color.opacity(0.15))
                        )
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(isCompletedToday ?
                          therapyTypeSelection.selectedTherapyType.color.opacity(0.12) :
                          Color.white.opacity(0.04))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(isCompletedToday ?
                                    therapyTypeSelection.selectedTherapyType.color.opacity(0.3) :
                                    Color.clear, lineWidth: 1)
                    )
            )
        }
        .buttonStyle(PlainButtonStyle())
        .disabled(isCompletedToday)
    }

    // MARK: - Weekly Progress Section

    private var weeklyProgressSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("THIS WEEK")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.5))
                .tracking(0.5)

            HStack(spacing: 8) {
                ForEach(0..<7, id: \.self) { dayOffset in
                    let date = Calendar.current.date(byAdding: .day, value: dayOffset - (Calendar.current.component(.weekday, from: Date()) - 1), to: Date())!
                    let isCompleted = sessionDates.contains { Calendar.current.isDate($0, inSameDayAs: date) }
                    let isToday = Calendar.current.isDateInToday(date)
                    let isFuture = date > Date()
                    let dayLetter = dayLetter(for: date)

                    VStack(spacing: 6) {
                        Text(dayLetter)
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(isToday ? .white : .white.opacity(0.4))

                        ZStack {
                            Circle()
                                .fill(isCompleted ?
                                      therapyTypeSelection.selectedTherapyType.color :
                                      (isFuture ? Color.white.opacity(0.04) : Color.white.opacity(0.08)))
                                .frame(width: 36, height: 36)

                            if isCompleted {
                                Image(systemName: "checkmark")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.white)
                            }

                            if isToday && !isCompleted {
                                Circle()
                                    .stroke(therapyTypeSelection.selectedTherapyType.color, lineWidth: 2)
                                    .frame(width: 36, height: 36)
                            }
                        }
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
            )
        }
    }

    private func dayLetter(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEEE"
        return formatter.string(from: date)
    }

    // MARK: - Calendar Section

    private var calendarSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("ACTIVITY")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.5))
                .tracking(0.5)

            CompactCalendarView(
                sessionDates: $sessionDates,
                therapyType: therapyTypeSelection.selectedTherapyType
            )
        }
    }

    // MARK: - Statistics Section

    private var statisticsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("STATISTICS")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white.opacity(0.5))
                .tracking(0.5)

            VStack(spacing: 0) {
                StatRow(label: "Total Sessions", value: "\(sortedSessions.count)", icon: "number")
                Divider().background(Color.white.opacity(0.06))
                StatRow(label: "Current Streak", value: "\(currentStreak) days", icon: "flame.fill")
                Divider().background(Color.white.opacity(0.06))
                StatRow(label: "Longest Streak", value: "\(longestStreak) days", icon: "trophy.fill")
                Divider().background(Color.white.opacity(0.06))
                StatRow(label: "This Week", value: "\(weekCompletions) of 7", icon: "calendar")
                Divider().background(Color.white.opacity(0.06))
                StatRow(label: "Completion Rate", value: completionRateString, icon: "percent")
            }
            .padding(4)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))
            )
        }
    }

    private var completionRateString: String {
        guard !sortedSessions.isEmpty else { return "0%" }
        let firstDate = sortedSessions.last?.date ?? Date()
        let daysSinceStart = Calendar.current.dateComponents([.day], from: firstDate, to: Date()).day ?? 1
        let rate = Double(sortedSessions.count) / Double(max(daysSinceStart, 1)) * 100
        return String(format: "%.0f%%", min(rate, 100))
    }

    // MARK: - Completion Overlay

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(therapyTypeSelection.selectedTherapyType.color)
                        .frame(width: 80, height: 80)
                        .shadow(color: therapyTypeSelection.selectedTherapyType.color.opacity(0.5), radius: 20)

                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(animationScale)

                if currentStreak > 0 {
                    Text("\(currentStreak) day streak!")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .opacity(animationOpacity)
                }
            }
        }
        .allowsHitTesting(false)
    }

    // MARK: - Undo Toast

    private var undoToast: some View {
        Button(action: undoCompletion) {
            HStack(spacing: 12) {
                Image(systemName: "arrow.uturn.backward")
                    .font(.system(size: 14, weight: .semibold))

                Text("Undo")
                    .font(.system(size: 15, weight: .semibold))

                Spacer()

                Text("5s")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(red: 0.12, green: 0.16, blue: 0.24))
            )
        }
    }

    // MARK: - Actions

    private func logTodaySession() {
        guard !isCompletedToday else { return }

        let newSession = TherapySessionEntity(context: viewContext)
        newSession.date = Date()
        newSession.therapyType = therapyTypeSelection.selectedTherapyType.rawValue

        do {
            try viewContext.save()
            lastCompletedSession = newSession
            updateSessionDates()
            triggerCompletionAnimation()

            withAnimation { showUndoToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation { showUndoToast = false }
            }
        } catch {
            print("Error saving session: \(error)")
        }
    }

    private func undoCompletion() {
        guard let session = lastCompletedSession else { return }

        viewContext.delete(session)
        do {
            try viewContext.save()
            lastCompletedSession = nil
            updateSessionDates()
            withAnimation { showUndoToast = false }

            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        } catch {
            print("Error undoing session: \(error)")
        }
    }

    private func triggerCompletionAnimation() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)

        showCompletionAnimation = true
        animationScale = 0.5
        animationOpacity = 0

        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            animationScale = 1.0
            animationOpacity = 1.0
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.2) {
            withAnimation(.easeOut(duration: 0.3)) {
                animationOpacity = 0
            }
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            showCompletionAnimation = false
        }
    }
}

// MARK: - Habit Selector Strip

struct HabitSelectorStrip: View {
    @ObservedObject var therapyTypeSelection: TherapyTypeSelection
    @Environment(\.managedObjectContext) private var viewContext
    var sessions: FetchedResults<TherapySessionEntity>

    @FetchRequest(
        entity: SelectedTherapy.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \SelectedTherapy.therapyType, ascending: true)]
    )
    private var selectedTherapyTypes: FetchedResults<SelectedTherapy>

    private var availableTypes: [TherapyType] {
        selectedTherapyTypes.compactMap { TherapyType(rawValue: $0.therapyType ?? "") }
    }

    private func isCompletedToday(_ type: TherapyType) -> Bool {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        return sessions.contains { session in
            guard let sessionDate = session.date else { return false }
            return calendar.isDate(sessionDate, inSameDayAs: today) && session.therapyType == type.rawValue
        }
    }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { proxy in
                HStack(spacing: 12) {
                    ForEach(availableTypes, id: \.self) { type in
                        let isSelected = therapyTypeSelection.selectedTherapyType == type
                        let completed = isCompletedToday(type)

                        Button(action: {
                            let generator = UIImpactFeedbackGenerator(style: .light)
                            generator.impactOccurred()
                            withAnimation(.easeOut(duration: 0.2)) {
                                therapyTypeSelection.selectedTherapyType = type
                            }
                        }) {
                            VStack(spacing: 6) {
                                ZStack {
                                    // Background circle
                                    Circle()
                                        .fill(isSelected ? type.color : Color.white.opacity(0.06))
                                        .frame(width: 56, height: 56)

                                    // Icon
                                    Image(systemName: type.icon)
                                        .font(.system(size: 22, weight: .semibold))
                                        .foregroundColor(isSelected ? .white : .white.opacity(0.4))

                                    // Completion badge
                                    if completed {
                                        Circle()
                                            .fill(Color.green)
                                            .frame(width: 18, height: 18)
                                            .overlay(
                                                Image(systemName: "checkmark")
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(.white)
                                            )
                                            .offset(x: 18, y: -18)
                                    }
                                }

                                Text(type.displayName(viewContext))
                                    .font(.system(size: 11, weight: isSelected ? .semibold : .medium))
                                    .foregroundColor(isSelected ? .white : .white.opacity(0.4))
                                    .lineLimit(1)
                            }
                            .frame(width: 72)
                        }
                        .buttonStyle(PlainButtonStyle())
                        .id(type)
                    }
                }
                .padding(.horizontal, 20)
                .onAppear {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        withAnimation { proxy.scrollTo(therapyTypeSelection.selectedTherapyType, anchor: .center) }
                    }
                }
                .onChange(of: therapyTypeSelection.selectedTherapyType) { newValue in
                    withAnimation { proxy.scrollTo(newValue, anchor: .center) }
                }
            }
        }
    }
}

// MARK: - Compact Calendar View

struct CompactCalendarView: View {
    @Binding var sessionDates: [Date]
    let therapyType: TherapyType

    @State private var currentMonth = Date()

    private var monthFormatter: DateFormatter {
        let f = DateFormatter()
        f.dateFormat = "MMMM yyyy"
        return f
    }

    var body: some View {
        VStack(spacing: 12) {
            // Month header
            HStack {
                Text(monthFormatter.string(from: currentMonth))
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(.white)

                Spacer()

                HStack(spacing: 8) {
                    Button(action: { changeMonth(-1) }) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 32, height: 32)
                    }

                    Button(action: { changeMonth(1) }) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(width: 32, height: 32)
                    }
                }
            }

            // Calendar grid
            let days = daysInMonth()
            let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

            LazyVGrid(columns: columns, spacing: 4) {
                // Day headers
                ForEach(["S", "M", "T", "W", "T", "F", "S"], id: \.self) { day in
                    Text(day)
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.45))
                        .frame(height: 20)
                }

                // Empty cells for offset
                ForEach(0..<startingWeekday(), id: \.self) { _ in
                    Text("")
                        .frame(height: 32)
                }

                // Days
                ForEach(days, id: \.self) { date in
                    let completed = sessionDates.contains { Calendar.current.isDate($0, inSameDayAs: date) }
                    let isToday = Calendar.current.isDateInToday(date)

                    ZStack {
                        if completed {
                            Circle()
                                .fill(therapyType.color)
                                .frame(width: 28, height: 28)
                        }

                        Text("\(Calendar.current.component(.day, from: date))")
                            .font(.system(size: 12, weight: completed ? .bold : .medium))
                            .foregroundColor(completed ? .white : .white.opacity(0.4))

                        if isToday && !completed {
                            Circle()
                                .stroke(therapyType.color, lineWidth: 1.5)
                                .frame(width: 28, height: 28)
                        }
                    }
                    .frame(height: 32)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.08))
        )
    }

    private func daysInMonth() -> [Date] {
        let calendar = Calendar.current
        guard let range = calendar.range(of: .day, in: .month, for: currentMonth) else { return [] }
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        return range.compactMap { day -> Date? in
            var dayComponents = components
            dayComponents.day = day
            return calendar.date(from: dayComponents)
        }
    }

    private func startingWeekday() -> Int {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        guard let firstDay = calendar.date(from: components) else { return 0 }
        return calendar.component(.weekday, from: firstDay) - 1
    }

    private func changeMonth(_ delta: Int) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
        withAnimation(.easeInOut(duration: 0.2)) {
            currentMonth = Calendar.current.date(byAdding: .month, value: delta, to: currentMonth) ?? currentMonth
        }
    }
}

// MARK: - Supporting Views

struct StatPill: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(color)

            VStack(alignment: .leading, spacing: 1) {
                Text(value)
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.white)

                Text(label)
                    .font(.system(size: 9, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
            }

            Spacer()
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(Color.white.opacity(0.08))
        )
    }
}

struct StatRow: View {
    let label: String
    let value: String
    let icon: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.5))
                .frame(width: 24)

            Text(label)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.6))

            Spacer()

            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.white)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 12)
    }
}
