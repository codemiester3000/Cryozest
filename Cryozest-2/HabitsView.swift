//
//  HabitsView.swift
//  Cryozest-2
//
//  Modern habit tracking interface with calendar, daily completion, and goals
//  Designed following 2024-2025 UX best practices
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
    @State private var showUndoButton = false
    @State private var lastCompletedSession: TherapySessionEntity?

    private var sortedSessions: [TherapySessionEntity] {
        let therapyTypeSessions = sessions.filter { $0.therapyType == therapyTypeSelection.selectedTherapyType.rawValue }
        return therapyTypeSessions.sorted(by: { $0.date! > $1.date! })
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

    private func updateSessionDates() {
        self.sessionDates = sessions
            .filter { $0.therapyType == therapyTypeSelection.selectedTherapyType.rawValue }
            .compactMap { $0.date }
    }

    var body: some View {
        ZStack {
            // Background gradient
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

            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    // Header
                    HStack {
                        Text("Habits")
                            .font(.system(size: 34, weight: .bold))
                            .foregroundColor(.white)

                        Spacer()

                        // Settings button
                        Button(action: {
                            showHabitSelection = true
                        }) {
                            Image(systemName: "gear")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Circle().fill(Color.white.opacity(0.1)))
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 60)

                    // Therapy type selector - compact pills
                    TherapyTypePills(therapyTypeSelection: therapyTypeSelection)
                        .padding(.horizontal, 20)

                    // 1. Calendar Heatmap
                    ModernCalendarHeatmap(
                        sessionDates: $sessionDates,
                        therapyType: therapyTypeSelection.selectedTherapyType
                    )
                    .padding(.horizontal, 20)

                    // 2. Daily Completion Button
                    DailyCompletionCard(
                        isCompleted: isCompletedToday,
                        therapyType: therapyTypeSelection.selectedTherapyType,
                        onTap: {
                            logTodaySession()
                        }
                    )
                    .padding(.horizontal, 20)
                    .overlay(
                        CompletionAnimationOverlay(
                            show: $showCompletionAnimation,
                            scale: $animationScale,
                            opacity: $animationOpacity,
                            color: therapyTypeSelection.selectedTherapyType.color
                        )
                    )

                    // Undo button (shown after completion)
                    if showUndoButton {
                        Button(action: undoCompletion) {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.uturn.backward")
                                    .font(.system(size: 14, weight: .semibold))
                                Text("Undo")
                                    .font(.system(size: 15, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 12)
                            .background(
                                Capsule()
                                    .fill(Color.orange)
                            )
                            .shadow(color: Color.black.opacity(0.2), radius: 8, x: 0, y: 4)
                        }
                        .transition(.asymmetric(
                            insertion: .scale.combined(with: .opacity),
                            removal: .opacity
                        ))
                        .padding(.horizontal, 20)
                    }

                    // 3. Weekly Goal Progress
                    WeeklyGoalProgressView(therapyTypeSelection: therapyTypeSelection)
                        .padding(.horizontal, 20)

                    // Recent sessions (optional)
                    if !sortedSessions.isEmpty {
                        RecentSessionsList(
                            sessions: Array(sortedSessions.prefix(5)),
                            therapyType: therapyTypeSelection.selectedTherapyType
                        )
                        .padding(.horizontal, 20)
                    }
                }
                .padding(.bottom, 100)
            }
        }
        .onAppear {
            updateSessionDates()
        }
        .onChange(of: therapyTypeSelection.selectedTherapyType) { _ in
            updateSessionDates()
        }
        .sheet(isPresented: $showHabitSelection) {
            TherapyTypeSelectionView()
                .environment(\.managedObjectContext, viewContext)
        }
    }

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

            // Show undo button
            showUndoButton = true

            // Auto-hide undo button after 5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation {
                    showUndoButton = false
                }
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

            withAnimation {
                showUndoButton = false
            }

            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        } catch {
            print("Error undoing session: \(error)")
        }
    }

    private func triggerCompletionAnimation() {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()

        // Show animation
        showCompletionAnimation = true
        animationScale = 0.5
        animationOpacity = 0

        // Animate in
        withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
            animationScale = 1.2
            animationOpacity = 1.0
        }

        // Animate out
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
            withAnimation(.easeOut(duration: 0.3)) {
                animationOpacity = 0
                animationScale = 1.5
            }
        }

        // Hide
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            showCompletionAnimation = false
        }
    }
}

// MARK: - Therapy Type Pills (Compact Selector)

struct TherapyTypePills: View {
    @ObservedObject var therapyTypeSelection: TherapyTypeSelection
    @Environment(\.managedObjectContext) private var viewContext

    private let allTypes: [TherapyType] = [.running, .weightTraining, .cycling, .meditation, .walking]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(allTypes, id: \.self) { type in
                    Button(action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            therapyTypeSelection.selectedTherapyType = type
                        }
                    }) {
                        HStack(spacing: 8) {
                            Image(systemName: type.icon)
                                .font(.system(size: 14, weight: .semibold))

                            Text(type.displayName(viewContext))
                                .font(.system(size: 15, weight: .semibold))
                        }
                        .foregroundColor(therapyTypeSelection.selectedTherapyType == type ? .white : .white.opacity(0.6))
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(
                            Capsule()
                                .fill(therapyTypeSelection.selectedTherapyType == type ?
                                     type.color.opacity(0.3) :
                                     Color.white.opacity(0.08))
                                .overlay(
                                    Capsule()
                                        .stroke(
                                            therapyTypeSelection.selectedTherapyType == type ?
                                            type.color.opacity(0.6) :
                                            Color.white.opacity(0.15),
                                            lineWidth: 1
                                        )
                                )
                        )
                    }
                    .buttonStyle(ScaleButtonStyle())
                }
            }
            .padding(.horizontal, 4)
        }
    }
}

// MARK: - Modern Calendar Heatmap

struct ModernCalendarHeatmap: View {
    @Binding var sessionDates: [Date]
    let therapyType: TherapyType

    @State private var currentMonth: Date = Date()
    @State private var dragOffset: CGFloat = 0

    private var daysInMonth: [Date] {
        let calendar = Calendar.current
        guard let monthInterval = calendar.dateInterval(of: .month, for: currentMonth) else {
            return []
        }

        let days = calendar.generateDates(
            inside: monthInterval,
            matching: DateComponents(hour: 12)
        )

        return days
    }

    private func hasSession(on date: Date) -> Bool {
        sessionDates.contains(where: { Calendar.current.isDate($0, inSameDayAs: date) })
    }

    private let dayFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "E"
        return formatter
    }()

    private let monthYearFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        return formatter
    }()

    var body: some View {
        VStack(spacing: 12) {
            // Month navigation
            HStack {
                Button(action: previousMonth) {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }

                Spacer()

                Text(monthYearFormatter.string(from: currentMonth))
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Button(action: nextMonth) {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Circle().fill(Color.white.opacity(0.1)))
                }
            }

            // Calendar grid
            VStack(spacing: 8) {
                // Day labels
                HStack(spacing: 3) {
                    ForEach(0..<min(7, daysInMonth.count), id: \.self) { col in
                        Text(String(dayFormatter.string(from: daysInMonth[col]).prefix(1)))
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(maxWidth: .infinity)
                    }
                }

                // Calendar days
                let columns = 7
                let rows = Int(ceil(Double(daysInMonth.count) / Double(columns)))

                VStack(spacing: 3) {
                    ForEach(0..<rows, id: \.self) { row in
                        HStack(spacing: 3) {
                            ForEach(0..<columns, id: \.self) { col in
                                let index = row * columns + col
                                if index < daysInMonth.count {
                                    let date = daysInMonth[index]
                                    let completed = hasSession(on: date)
                                    let isToday = Calendar.current.isDateInToday(date)
                                    let dayNumber = Calendar.current.component(.day, from: date)

                                    ZStack {
                                        RoundedRectangle(cornerRadius: 6)
                                            .fill(completed ?
                                                 therapyType.color.opacity(0.8) :
                                                 Color.white.opacity(0.08))
                                            .frame(height: 36)

                                        Text("\(dayNumber)")
                                            .font(.system(size: 12, weight: completed ? .bold : .medium))
                                            .foregroundColor(completed ? .white : .white.opacity(0.4))

                                        if isToday {
                                            RoundedRectangle(cornerRadius: 6)
                                                .stroke(therapyType.color, lineWidth: 2)
                                                .frame(height: 36)
                                        }
                                    }
                                } else {
                                    RoundedRectangle(cornerRadius: 6)
                                        .fill(Color.clear)
                                        .frame(height: 36)
                                }
                            }
                        }
                    }
                }
            }
        }
        .padding(16)
        .background(
            ZStack {
                RoundedRectangle(cornerRadius: 20)
                    .fill(Color.white.opacity(0.06))

                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [
                                Color.white.opacity(0.2),
                                Color.white.opacity(0.1)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .gesture(
            DragGesture(minimumDistance: 30)
                .onChanged { value in
                    dragOffset = value.translation.width
                }
                .onEnded { value in
                    let threshold: CGFloat = 50
                    if value.translation.width > threshold {
                        // Swipe right - go to previous month
                        previousMonth()
                    } else if value.translation.width < -threshold {
                        // Swipe left - go to next month
                        nextMonth()
                    }
                    dragOffset = 0
                }
        )
    }

    private func previousMonth() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()

            withAnimation(.easeInOut(duration: 0.3)) {
                currentMonth = newMonth
            }
        }
    }

    private func nextMonth() {
        let calendar = Calendar.current
        if let newMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) {
            // Haptic feedback
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()

            withAnimation(.easeInOut(duration: 0.3)) {
                currentMonth = newMonth
            }
        }
    }
}

// MARK: - Daily Completion Card

struct DailyCompletionCard: View {
    let isCompleted: Bool
    let therapyType: TherapyType
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 16) {
                // Checkbox circle
                ZStack {
                    Circle()
                        .fill(isCompleted ?
                             therapyType.color :
                             Color.white.opacity(0.1))
                        .frame(width: 56, height: 56)

                    if isCompleted {
                        Image(systemName: "checkmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    } else {
                        Circle()
                            .stroke(
                                LinearGradient(
                                    colors: [
                                        therapyType.color.opacity(0.6),
                                        therapyType.color.opacity(0.3)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 3
                            )
                            .frame(width: 56, height: 56)
                    }
                }

                // Text
                VStack(alignment: .leading, spacing: 4) {
                    Text(isCompleted ? "Completed Today!" : "Complete Today's Session")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(.white)

                    Text(isCompleted ? "Great work!" : "Tap to mark as done")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.white.opacity(0.6))
                }

                Spacer()

                if !isCompleted {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white.opacity(0.3))
                }
            }
            .padding(20)
            .background(
                ZStack {
                    RoundedRectangle(cornerRadius: 20)
                        .fill(
                            isCompleted ?
                            LinearGradient(
                                colors: [
                                    therapyType.color.opacity(0.3),
                                    therapyType.color.opacity(0.2)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ) :
                            LinearGradient(
                                colors: [
                                    Color.white.opacity(0.08),
                                    Color.white.opacity(0.06)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    RoundedRectangle(cornerRadius: 20)
                        .stroke(
                            LinearGradient(
                                colors: [
                                    therapyType.color.opacity(isCompleted ? 0.6 : 0.3),
                                    therapyType.color.opacity(isCompleted ? 0.4 : 0.1)
                                ],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: isCompleted ? 2 : 1
                        )
                }
            )
            .shadow(
                color: isCompleted ? therapyType.color.opacity(0.3) : Color.clear,
                radius: 12,
                x: 0,
                y: 4
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .disabled(isCompleted)
    }
}

// MARK: - Completion Animation Overlay

struct CompletionAnimationOverlay: View {
    @Binding var show: Bool
    @Binding var scale: CGFloat
    @Binding var opacity: Double
    let color: Color

    var body: some View {
        if show {
            ZStack {
                // Ripple circles
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .stroke(color.opacity(0.3), lineWidth: 2)
                        .frame(width: 80, height: 80)
                        .scaleEffect(scale * (1 + CGFloat(index) * 0.3))
                        .opacity(opacity * (1 - Double(index) * 0.3))
                }

                // Center checkmark
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 70, height: 70)
                        .blur(radius: 10)

                    Circle()
                        .fill(color)
                        .frame(width: 60, height: 60)

                    Image(systemName: "checkmark")
                        .font(.system(size: 30, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(scale)
                .shadow(color: color.opacity(0.5), radius: 20)

                // Particle burst
                ForEach(0..<8, id: \.self) { index in
                    Circle()
                        .fill(color)
                        .frame(width: 6, height: 6)
                        .offset(
                            x: cos(Double(index) * .pi / 4) * 60 * scale,
                            y: sin(Double(index) * .pi / 4) * 60 * scale
                        )
                        .opacity(opacity * 0.8)
                }
            }
            .opacity(opacity)
            .allowsHitTesting(false)
        }
    }
}

// MARK: - Recent Sessions List

struct RecentSessionsList: View {
    let sessions: [TherapySessionEntity]
    let therapyType: TherapyType

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(therapyType.color)

                Text("Recent Sessions")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)

                Spacer()

                Text("\(sessions.count)")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(therapyType.color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(
                        Capsule()
                            .fill(therapyType.color.opacity(0.2))
                    )
            }
            .padding(.bottom, 4)

            ForEach(sessions, id: \.self) { session in
                if let date = session.date {
                    HStack {
                        Circle()
                            .fill(therapyType.color)
                            .frame(width: 8, height: 8)

                        Text(dateFormatter.string(from: date))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))

                        Spacer()
                    }
                    .padding(.vertical, 8)
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                )
        )
    }
}

