import SwiftUI
import CoreData

struct AnalysisView: View {

    @ObservedObject var therapyTypeSelection: TherapyTypeSelection
    @Binding var selectedTab: Int

    @Environment(\.managedObjectContext) private var viewContext
    @FetchRequest(
        entity: TherapySessionEntity.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \TherapySessionEntity.date, ascending: false)]
    )
    private var sessions: FetchedResults<TherapySessionEntity>
    
    @FetchRequest(
        entity: SelectedTherapy.entity(),
        sortDescriptors: []
    )
    private var selectedTherapies: FetchedResults<SelectedTherapy>
    
    var selectedTherapyTypes: [TherapyType] {
        // Convert the selected therapy types from strings to TherapyType values
        if selectedTherapies.isEmpty {
            return [.drySauna, .weightTraining, .coldPlunge, .meditation]
        } else {
            return selectedTherapies.compactMap { TherapyType(rawValue: $0.therapyType ?? "") }
        }
    }
    
    let healthKitManager = HealthKitManager.shared
    
    let gridItems = [GridItem(.flexible()), GridItem(.flexible())]
    
    @State private var selectedTimeFrame: TimeFrame = .week
    @State private var showingGoalConfiguration = false

    // Onboarding state
    @State private var showEmptyState = false

    private let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateFormat = "MM/dd/yyyy"
        return df
    }()

    init(therapyTypeSelection: TherapyTypeSelection, selectedTab: Binding<Int>) {
        self.therapyTypeSelection = therapyTypeSelection
        self._selectedTab = selectedTab
    }

    private var filteredSessions: [TherapySessionEntity] {
        sessions.filter { $0.therapyType == therapyTypeSelection.selectedTherapyType.rawValue }
    }

    private var hasEnoughData: Bool {
        filteredSessions.count >= 1
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

                // Show empty state if not enough data, otherwise show analytics
                if showEmptyState || (!OnboardingManager.shared.shouldShowAnalysisEmptyState && !hasEnoughData) {
                    AnalysisEmptyStateView(
                        therapyColor: therapyTypeSelection.selectedTherapyType.color,
                        onDismiss: {
                            showEmptyState = false
                            OnboardingManager.shared.markAnalysisTabSeen()
                            // Switch to Habits tab (tab index 1)
                            selectedTab = 1
                        }
                    )
                } else {
                    VStack {
                        ScrollView {
                            HStack {
                                Text("Analytics")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)

                                Spacer()

                                // Goal configuration button
                                Button(action: { showingGoalConfiguration = true }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.15))
                                            .frame(width: 44, height: 44)

                                        Image(systemName: "target")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(therapyTypeSelection.selectedTherapyType.color)
                                    }
                                }

                                NavigationLink(destination: TherapyTypeSelectionView()) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.15))
                                            .frame(width: 44, height: 44)

                                        Image(systemName: "gearshape.fill")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(therapyTypeSelection.selectedTherapyType.color)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.top, 16)

                        HorizontalHabitSelector(
                            therapyTypeSelection: therapyTypeSelection,
                            selectedTherapyTypes: selectedTherapies
                        )
                        .padding(.bottom, 16)
                    
                    CustomPicker(selectedTimeFrame: $selectedTimeFrame, backgroundColor: therapyTypeSelection.selectedTherapyType.color)

                    // Personal Bests
                    PersonalBestsView(sessions: Array(sessions), therapyType: therapyTypeSelection.selectedTherapyType)
                        .padding(.horizontal)
                        .padding(.top, 16)

                    // Consistency Score
                    ConsistencyScoreCard(sessions: Array(sessions), therapyType: therapyTypeSelection.selectedTherapyType, timeFrame: selectedTimeFrame)
                        .padding(.horizontal)
                        .padding(.top, 12)

                    // Monthly Projection
                    ProjectionWidget(sessions: Array(sessions), therapyType: therapyTypeSelection.selectedTherapyType)
                        .padding(.horizontal)
                        .padding(.top, 12)

                    // Duration Analysis with existing view
                    DurationAnalysisView(viewModel: DurationAnalysisViewModel(therapyType: therapyTypeSelection.selectedTherapyType, timeFrame: selectedTimeFrame, sessions: sessions))
                        .padding(.horizontal)
                        .padding(.top, 12)

                    // Average Duration Trend
                    AverageDurationTrendGraph(sessions: Array(sessions), therapyType: therapyTypeSelection.selectedTherapyType, timeframe: .month)
                        .padding(.horizontal)
                        .padding(.top, 12)

                    // Weekly Consistency Heatmap
                    WeeklyHeatmapView(sessions: Array(sessions), therapyType: therapyTypeSelection.selectedTherapyType)
                        .padding(.horizontal)
                        .padding(.top, 12)

                    // Session Frequency by Day
                    SessionFrequencyChart(sessions: Array(sessions), therapyType: therapyTypeSelection.selectedTherapyType)
                        .padding(.horizontal)
                        .padding(.top, 12)

                    // Time of Day Analysis
                    TimeOfDayAnalysisView(sessions: Array(sessions), therapyType: therapyTypeSelection.selectedTherapyType)
                        .padding(.horizontal)
                        .padding(.top, 12)

                    Divider().background(Color.white.opacity(0.8)).padding(.vertical, 16).padding(.horizontal)

                    RecoveryAnalysisView(viewModel: SleepViewModel(therapyType: therapyTypeSelection.selectedTherapyType, timeFrame: selectedTimeFrame, sessions: sessions))
                        .padding(.bottom)

                    Divider().background(Color.white.opacity(0.8)).padding(.vertical, 8)

                    WakingAnalysisView(model: WakingAnalysisDataModel(therapyType: therapyTypeSelection.selectedTherapyType, timeFrame: selectedTimeFrame, sessions: sessions))
                        .padding(.bottom, 20)
                    }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .sheet(isPresented: $showingGoalConfiguration) {
                GoalConfigurationView(selectedTherapyTypes: selectedTherapyTypes)
            }
            .onAppear {
                // Check if should show onboarding
                if OnboardingManager.shared.shouldShowAnalysisEmptyState {
                    showEmptyState = true
                }
            }
        }
    }
    
    func getCurrentStreak(for therapyType: TherapyType) -> Int {
        var currentStreak = 0
        let sortedSessions = sessions.filter { $0.therapyType == therapyType.rawValue }.sorted { $0.date! > $1.date! }
        var currentDate = Date()
        
        for session in sortedSessions {
            guard let date = session.date else {
                continue
            }
            if !Calendar.current.isDate(date, inSameDayAs: currentDate) {
                break
            }
            currentDate = Calendar.current.date(byAdding: .day, value: -1, to: currentDate)!
            currentStreak += 1
        }
        
        return currentStreak
    }
    
    func getLongestStreak(for therapyType: TherapyType) -> Int {
        var longestStreak = 0
        var currentStreak = 0
        var streakStarted = false
        
        for session in sessions {
            guard let date = session.date,
                  session.therapyType == therapyType.rawValue,
                  isWithinTimeFrame(date: date) else {
                continue
            }
            
            if streakStarted {
                currentStreak += 1
                if currentStreak > longestStreak {
                    longestStreak = currentStreak
                }
            } else {
                streakStarted = true
                currentStreak = 1
                longestStreak = 1
            }
        }
        
        return longestStreak
    }
    
    func getTotalTime(for therapyType: TherapyType) -> TimeInterval {
        return sessions.compactMap { session -> TimeInterval? in
            guard let date = session.date,
                  session.therapyType == therapyType.rawValue,
                  isWithinTimeFrame(date: date) else {
                return nil
            }
            return session.duration
        }.reduce(0, +)
    }
    
    func getTotalSessions(for therapyType: TherapyType) -> Int {
        return sessions.filter { session in
            guard let date = session.date else {
                return false
            }
            return session.therapyType == therapyType.rawValue && isWithinTimeFrame(date: date)
        }.count
    }
    
    func isWithinTimeFrame(date: Date) -> Bool {
        switch selectedTimeFrame {
        case .week:
            return Calendar.current.isDate(date, inSameDayAs: Date())
        case .month:
            guard let oneMonthAgo = Calendar.current.date(byAdding: .month, value: -1, to: Date()) else {
                return false
            }
            let dateInterval = DateInterval(start: oneMonthAgo, end: Date())
            return dateInterval.contains(date)
        case .allTime:
            return true
        }
    }
}

enum TimeFrame: CaseIterable {
    case week, month, allTime
    
    func displayString() -> String {
        switch self {
        case .week:
            return "Last Week"
        case .month:
            return "Last Month"
        case .allTime:
            return "Last Year"
        }
    }
    
    func presentDisplayString() -> String {
        switch self {
        case .week:
            return "this week"
        case .month:
            return "this month"
        case .allTime:
            return "this year"
        }
    }
    
    func numberOfDays() -> Int {
        switch self {
        case .week:
            return 7
        case .month:
            return 30
        case .allTime:
            return 365
        }
    }
}
