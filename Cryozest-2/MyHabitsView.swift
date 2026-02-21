//
//  MyHabitsView.swift
//  Cryozest-2
//
//  Reimagined Tab 2: All-habits dashboard with per-habit insights
//  Each habit card shows logging, streaks, and health correlations
//

import SwiftUI
import CoreData

struct MyHabitsView: View {
    @Environment(\.managedObjectContext) private var viewContext

    @FetchRequest(
        entity: TherapySessionEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TherapySessionEntity.date, ascending: false)]
    )
    private var sessions: FetchedResults<TherapySessionEntity>

    @FetchRequest(
        entity: SelectedTherapy.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \SelectedTherapy.therapyType, ascending: true)]
    )
    private var selectedTherapies: FetchedResults<SelectedTherapy>

    var insightsViewModel: InsightsViewModel?

    @State private var expandedHabit: TherapyType? = nil
    @State private var showHabitSelection = false
    @State private var showCompletionAnimation = false
    @State private var animationScale: CGFloat = 0.5
    @State private var animationOpacity: Double = 0
    @State private var completedHabitType: TherapyType? = nil
    @State private var showUndoToast = false
    @State private var lastCompletedSession: TherapySessionEntity?

    private var selectedTherapyTypes: [TherapyType] {
        let types: [TherapyType]
        if selectedTherapies.isEmpty {
            types = [.running, .weightTraining, .cycling, .meditation]
        } else {
            types = selectedTherapies.compactMap { TherapyType(rawValue: $0.therapyType ?? "") }
        }

        // Stack rank by most recent session (just logged = top of list)
        return types.sorted { a, b in
            let aDate = sessions.first(where: { $0.therapyType == a.rawValue })?.date ?? .distantPast
            let bDate = sessions.first(where: { $0.therapyType == b.rawValue })?.date ?? .distantPast
            return aDate > bDate
        }
    }

    // MARK: - Today Summary Computed Properties

    private var todayTotalSessions: Int {
        let calendar = Calendar.current
        return sessions.filter { session in
            guard let date = session.date else { return false }
            return calendar.isDateInToday(date) &&
                   selectedTherapyTypes.contains(where: { $0.rawValue == session.therapyType })
        }.count
    }

    private var habitsCompletedToday: Int {
        let calendar = Calendar.current
        return selectedTherapyTypes.filter { type in
            sessions.contains { session in
                guard let date = session.date else { return false }
                return calendar.isDateInToday(date) && session.therapyType == type.rawValue
            }
        }.count
    }

    private var bestOverallStreak: Int {
        selectedTherapyTypes.map { type in
            let dates = sessions
                .filter { $0.therapyType == type.rawValue }
                .compactMap { $0.date }
                .sorted(by: >)
            guard !dates.isEmpty else { return 0 }
            let calendar = Calendar.current
            var streak = 0
            var checkDate = calendar.startOfDay(for: Date())
            let todayCount = dates.filter { calendar.isDateInToday($0) }.count
            if todayCount == 0 {
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            }
            for date in dates {
                let sessionDay = calendar.startOfDay(for: date)
                if calendar.isDate(sessionDay, inSameDayAs: checkDate) {
                    streak += 1
                    checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
                } else if sessionDay < checkDate {
                    break
                }
            }
            return streak
        }.max() ?? 0
    }

    var body: some View {
        ZStack {
            // Background
            Color(red: 0.06, green: 0.10, blue: 0.18)
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    // Header
                    header
                        .padding(.horizontal, 20)
                        .padding(.top, 12)
                        .padding(.bottom, 16)

                    // Today summary hero
                    if !selectedTherapyTypes.isEmpty {
                        todaySummary
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                    }

                    // Habit cards
                    LazyVStack(spacing: 10) {
                        ForEach(selectedTherapyTypes, id: \.self) { habitType in
                            HabitDashboardCard(
                                habitType: habitType,
                                sessions: sessions,
                                impacts: insightsViewModel?.habitImpactsByType[habitType] ?? [],
                                progress: insightsViewModel?.dataCollectionProgress[habitType],
                                isExpanded: expandedHabit == habitType,
                                onTap: { toggleExpanded(habitType) },
                                onLog: { logSession(for: habitType) },
                                onDelete: { session in deleteSession(session) }
                            )
                        }
                    }
                    .padding(.horizontal, 20)

                    // Empty state
                    if selectedTherapyTypes.isEmpty {
                        emptyState
                            .padding(.horizontal, 20)
                            .padding(.top, 40)
                    }

                    Color.clear
                        .frame(height: 120)
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
        .sheet(isPresented: $showHabitSelection) {
            TherapyTypeSelectionView()
                .environment(\.managedObjectContext, viewContext)
        }
    }

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            Text("My Habits")
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

    // MARK: - Today Summary

    private var todaySummary: some View {
        HStack(spacing: 16) {
            // Completion ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(Color.white.opacity(0.08), lineWidth: 5)
                    .frame(width: 56, height: 56)

                // Progress ring
                Circle()
                    .trim(from: 0, to: selectedTherapyTypes.isEmpty ? 0 :
                          CGFloat(habitsCompletedToday) / CGFloat(selectedTherapyTypes.count))
                    .stroke(
                        LinearGradient(
                            colors: [.cyan, .cyan.opacity(0.6)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 5, lineCap: .round)
                    )
                    .frame(width: 56, height: 56)
                    .rotationEffect(.degrees(-90))

                // Center text
                VStack(spacing: 0) {
                    Text("\(habitsCompletedToday)")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text("/\(selectedTherapyTypes.count)")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.white.opacity(0.4))
                }
            }

            // Stats
            VStack(alignment: .leading, spacing: 6) {
                Text("Today")
                    .font(.system(size: 13, weight: .bold))
                    .foregroundColor(.white.opacity(0.5))
                    .textCase(.uppercase)
                    .tracking(0.5)

                HStack(spacing: 16) {
                    HStack(spacing: 4) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.green)
                        Text("\(todayTotalSessions) sessions")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.8))
                    }

                    if bestOverallStreak > 0 {
                        HStack(spacing: 4) {
                            Image(systemName: "flame.fill")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(.orange)
                            Text("\(bestOverallStreak)d best")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                }
            }

            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.cyan.opacity(0.15), lineWidth: 1)
                )
        )
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "plus.circle")
                .font(.system(size: 48, weight: .light))
                .foregroundColor(.white.opacity(0.25))

            Text("No Habits Selected")
                .font(.system(size: 17, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))

            Text("Tap the + button to add habits and start tracking their impact on your health.")
                .font(.system(size: 14, weight: .regular))
                .foregroundColor(.white.opacity(0.4))
                .multilineTextAlignment(.center)
                .lineSpacing(2)
        }
        .padding(.vertical, 40)
    }

    // MARK: - Completion Overlay

    private var completionOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()

            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(completedHabitType?.color ?? .cyan)
                        .frame(width: 80, height: 80)
                        .shadow(color: (completedHabitType?.color ?? .cyan).opacity(0.5), radius: 20)

                    Image(systemName: "checkmark")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }
                .scaleEffect(animationScale)

                VStack(spacing: 4) {
                    Text("Session Logged!")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)

                    if let habit = completedHabitType {
                        Text(habit.displayName(viewContext))
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))
                    }
                }
                .opacity(animationOpacity)
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

    private func toggleExpanded(_ habitType: TherapyType) {
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()

        withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
            if expandedHabit == habitType {
                expandedHabit = nil
            } else {
                expandedHabit = habitType
            }
        }
    }

    private func logSession(for habitType: TherapyType) {
        let newSession = TherapySessionEntity(context: viewContext)
        newSession.date = Date()
        newSession.therapyType = habitType.rawValue

        do {
            try viewContext.save()
            lastCompletedSession = newSession
            completedHabitType = habitType
            triggerCompletionAnimation()

            withAnimation { showUndoToast = true }
            DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                withAnimation { showUndoToast = false }
            }
        } catch {
            print("Error saving session: \(error)")
        }
    }

    private func deleteSession(_ session: TherapySessionEntity) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            viewContext.delete(session)
            do {
                try viewContext.save()
                let generator = UIImpactFeedbackGenerator(style: .medium)
                generator.impactOccurred()
            } catch {
                print("Error deleting session: \(error)")
            }
        }
    }

    private func undoCompletion() {
        guard let session = lastCompletedSession else { return }

        viewContext.delete(session)
        do {
            try viewContext.save()
            lastCompletedSession = nil
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
