import SwiftUI
import JTAppleCalendar

struct LogbookView: View {
    
    @State private var showAddSession = false
    
    @ObservedObject var therapyTypeSelection: TherapyTypeSelection
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: TherapySessionEntity.entity(),
        sortDescriptors: [])
    private var sessions: FetchedResults<TherapySessionEntity>
    
    @FetchRequest(
        entity: SelectedTherapy.entity(),
        sortDescriptors: []
    )
    private var selectedTherapies: FetchedResults<SelectedTherapy>
    
    var selectedTherapyTypes: [TherapyType] {
        // Convert the selected therapy types from strings to TherapyType values
        if selectedTherapies.isEmpty {
            // Updated for App Store compliance - removed extreme temperature therapies
            return [.running, .weightTraining, .cycling, .meditation]
        } else {
            return selectedTherapies.compactMap { TherapyType(rawValue: $0.therapyType ?? "") }
        }
    }
    
    @State private var sessionDates = [Date]()
    
    let gridItems = [GridItem(.flexible()), GridItem(.flexible())]
    
    init(therapyTypeSelection: TherapyTypeSelection) {
        self.therapyTypeSelection = therapyTypeSelection
    }
    
    private var sortedSessions: [TherapySessionEntity] {
        let therapyTypeSessions = sessions.filter { $0.therapyType == therapyTypeSelection.selectedTherapyType.rawValue }
        return therapyTypeSessions.sorted(by: { $0.date! > $1.date! }) // changed to sort in descending order
    }
    
    private func updateSessionDates() {
        self.sessionDates = sessions
            .filter { $0.therapyType == therapyTypeSelection.selectedTherapyType.rawValue }
            .compactMap { $0.date }
    }

    // Calculate current streak (consecutive days)
    private var currentStreak: Int {
        let calendar = Calendar.current
        let sortedDates = sessionDates.sorted(by: >)

        guard !sortedDates.isEmpty else { return 0 }

        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        for date in sortedDates {
            let sessionDay = calendar.startOfDay(for: date)

            if calendar.isDate(sessionDay, inSameDayAs: currentDate) {
                streak += 1
                currentDate = calendar.date(byAdding: .day, value: -1, to: currentDate) ?? currentDate
            } else if sessionDay < currentDate {
                break
            }
        }

        return streak
    }

    // Calculate longest streak ever
    private var longestStreak: Int {
        let calendar = Calendar.current
        let uniqueDays = Set(sessionDates.map { calendar.startOfDay(for: $0) })
        let sortedDays = uniqueDays.sorted()

        guard !sortedDays.isEmpty else { return 0 }

        var maxStreak = 1
        var currentStreak = 1

        for i in 1..<sortedDays.count {
            let previousDay = sortedDays[i - 1]
            let currentDay = sortedDays[i]

            if let nextDay = calendar.date(byAdding: .day, value: 1, to: previousDay),
               calendar.isDate(nextDay, inSameDayAs: currentDay) {
                currentStreak += 1
                maxStreak = max(maxStreak, currentStreak)
            } else {
                currentStreak = 1
            }
        }

        return maxStreak
    }

    // Sessions this week
    private var thisWeekCount: Int {
        let calendar = Calendar.current
        let now = Date()

        return sessionDates.filter { date in
            calendar.isDate(date, equalTo: now, toGranularity: .weekOfYear)
        }.count
    }

    // Sessions this month
    private var thisMonthCount: Int {
        let calendar = Calendar.current
        let now = Date()

        return sessionDates.filter { date in
            calendar.isDate(date, equalTo: now, toGranularity: .month)
        }.count
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                // Modern gradient background matching app theme
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

                // Subtle gradient overlay
                RadialGradient(
                    gradient: Gradient(colors: [
                        Color.blue.opacity(0.3),
                        Color.clear
                    ]),
                    center: .topTrailing,
                    startRadius: 100,
                    endRadius: 500
                )
                .ignoresSafeArea()

                VStack(alignment: .leading, spacing: 0) {
                    NavigationLink(destination: ManuallyAddSession(), isActive: $showAddSession) {
                        EmptyView()
                    }

                    // Header
                    HStack {
                        Text("Activity")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                            .padding(.leading)

                        Spacer()

                        ZStack {
                            Circle()
                                .fill(Color.white.opacity(0.15))
                                .frame(width: 44, height: 44)

                            Image(systemName: "plus")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(.white)
                        }
                        .padding(.trailing, 24)
                        .onTapGesture {
                            showAddSession = true
                        }
                    }
                    .padding(.top, 170)
                    .padding(.bottom, 16)

                    // Scrollable content
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {
                        CalendarView(sessionDates: $sessionDates, therapyType: $therapyTypeSelection.selectedTherapyType)
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.white.opacity(0.08))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                    )
                            )
                            .cornerRadius(16)
                            .frame(maxWidth: .infinity)

                        // Stats Dashboard
                        if !sessionDates.isEmpty {
                            VStack(spacing: 12) {
                                HStack {
                                    Image(systemName: "chart.bar.fill")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundColor(therapyTypeSelection.selectedTherapyType.color)

                                    Text("Statistics")
                                        .font(.system(size: 16, weight: .bold))
                                        .foregroundColor(.white)

                                    Spacer()
                                }

                                // Top Row - Current Streak & Longest Streak
                                HStack(spacing: 12) {
                                    // Current Streak
                                    HabitsStatCard(
                                        icon: "flame.fill",
                                        title: "Current Streak",
                                        value: "\(currentStreak)",
                                        unit: currentStreak == 1 ? "day" : "days",
                                        color: currentStreak > 0 ? .orange : .white.opacity(0.3),
                                        accentColor: therapyTypeSelection.selectedTherapyType.color
                                    )

                                    // Longest Streak
                                    HabitsStatCard(
                                        icon: "trophy.fill",
                                        title: "Best Streak",
                                        value: "\(longestStreak)",
                                        unit: longestStreak == 1 ? "day" : "days",
                                        color: .yellow,
                                        accentColor: therapyTypeSelection.selectedTherapyType.color
                                    )
                                }

                                // Bottom Row - This Week & This Month
                                HStack(spacing: 12) {
                                    // This Week
                                    HabitsStatCard(
                                        icon: "calendar",
                                        title: "This Week",
                                        value: "\(thisWeekCount)",
                                        unit: thisWeekCount == 1 ? "session" : "sessions",
                                        color: .cyan,
                                        accentColor: therapyTypeSelection.selectedTherapyType.color
                                    )

                                    // This Month
                                    HabitsStatCard(
                                        icon: "calendar.badge.clock",
                                        title: "This Month",
                                        value: "\(thisMonthCount)",
                                        unit: thisMonthCount == 1 ? "session" : "sessions",
                                        color: .green,
                                        accentColor: therapyTypeSelection.selectedTherapyType.color
                                    )
                                }
                            }
                        }

                        // Session History Header
                        if !sortedSessions.isEmpty {
                            HStack {
                                Image(systemName: "clock.fill")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(therapyTypeSelection.selectedTherapyType.color)

                                Text("Recent Sessions")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)

                                Spacer()

                                Text("\(sortedSessions.count)")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(therapyTypeSelection.selectedTherapyType.color)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(
                                        Capsule()
                                            .fill(therapyTypeSelection.selectedTherapyType.color.opacity(0.2))
                                    )
                            }
                            .padding(.vertical, 8)
                        }

                        if sortedSessions.isEmpty {
                            Text("Begin recording sessions to see data here")
                                .foregroundColor(.white.opacity(0.7))
                                .font(.system(size: 16, weight: .medium))
                                .padding()
                        } else {
                            // Iterate over the sorted sessions
                            ForEach(sortedSessions, id: \.self) { session in
                                SessionRow(session: session, therapyTypeSelection: therapyTypeSelection, therapyTypeName: therapyTypeSelection.selectedTherapyType.displayName(viewContext))
                                    .foregroundColor(.white)
                            }
                        }
                        }
                        .padding(.horizontal)
                        .padding(.bottom, 100)
                    }
                }
                .onAppear {
                    updateSessionDates()
                }
                .onChange(of: therapyTypeSelection.selectedTherapyType) { _ in
                    updateSessionDates()
                }
            }
        }
    }
}

// MARK: - Stat Card Component

struct HabitsStatCard: View {
    let icon: String
    let title: String
    let value: String
    let unit: String
    let color: Color
    let accentColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Icon and Title
            HStack(spacing: 8) {
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 32, height: 32)

                    Image(systemName: icon)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundColor(color)
                }

                Text(title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.white.opacity(0.8))
                    .textCase(.uppercase)
                    .tracking(0.5)
            }

            // Value and Unit
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)
                    .monospacedDigit()

                Text(unit)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.6))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            ZStack {
                // Base background
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.08))

                // Gradient overlay
                LinearGradient(
                    gradient: Gradient(colors: [
                        accentColor.opacity(0.15),
                        Color.clear
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Border
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                accentColor.opacity(0.3),
                                accentColor.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
        )
        .shadow(color: accentColor.opacity(0.1), radius: 8, x: 0, y: 4)
    }
}
