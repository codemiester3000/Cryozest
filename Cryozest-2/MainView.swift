import SwiftUI
import HealthKit
import CoreData

enum SessionFeature {
    case STOPWATCH
    case QUICK_ADD

    func displayString() -> String {
        switch self {
        case .STOPWATCH:
            return "Stopwatch"
        case .QUICK_ADD:
            return "Quick Add"
        }
    }
}

struct MainView: View {

    @ObservedObject var therapyTypeSelection: TherapyTypeSelection

    @Environment(\.scenePhase) private var scenePhase
    
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: SelectedTherapy.entity(),
        sortDescriptors: []
    )
    private var selectedTherapies: FetchedResults<SelectedTherapy>
    
    @FetchRequest(
        entity: CustomTimer.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CustomTimer.duration, ascending: true)]
    )
    private var customTimers: FetchedResults<CustomTimer>
    
    var selectedTherapyTypes: [TherapyType] {
        // Convert the selected therapy types from strings to TherapyType values
        if selectedTherapies.isEmpty {
            return [.drySauna, .weightTraining, .coldPlunge, .meditation]
        } else {
            return selectedTherapies.compactMap { TherapyType(rawValue: $0.therapyType ?? "") }
        }
    }
    
    let healthStore = HKHealthStore()
    let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
    let respirationRateType = HKObjectType.quantityType(forIdentifier: .respiratoryRate)!
    let spo2Type = HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!
    let gridItems = [GridItem(.flexible()), GridItem(.flexible())]
    
    @FetchRequest(
        entity: TherapySessionEntity.entity(),
        sortDescriptors: [])
    private var sessions: FetchedResults<TherapySessionEntity>

    var isSessionCompleteForToday: Bool {
        sessions.contains { session in
            let calendar = Calendar.current
            let isSameDay = calendar.isDateInToday(session.date ?? Date())
            let isSameTherapyType = session.therapyType == therapyTypeSelection.selectedTherapyType.rawValue
            return isSameDay && isSameTherapyType
        }
    }

    @State private var timerLabel: String = "00:00"
    @State private var timer: Timer?
    @State private var healthDataTimer: Timer?
    @State private var timerDuration: TimeInterval = 0
    @State private var timerStartDate: Date?
    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var showLogbook: Bool = false
    @State private var showSessionSummary: Bool = false
    @State private var averageHeartRate: Double = 0.0
    @State private var minHeartRate: Double = 1000.0
    @State private var maxHeartRate: Double = 0.0
    @State private var averageSpo2: Double = 0.0
    @State private var averageRespirationRate: Double = 0.0
    @State private var isHealthDataAvailable: Bool = false
    @State private var acceptedHealthKitPermissions: Bool = false
    @State private var countDown: Bool = false
    @State private var initialTimerDuration: TimeInterval = 0
    @State private var showCreateTimer = false
    
    @State private var selectedMode = SessionFeature.STOPWATCH

    @State private var showAddSession = false

    @State private var sessionDates = [Date]()

    // Onboarding state
    @State private var showEmptyState = false
    @State private var showTherapySelectorTooltip = false
    @State private var showStopwatchTooltip = false
    @State private var showSafetyWarning = false

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
    
    @ViewBuilder
    private var timerSectionContent: some View {
        if selectedMode == SessionFeature.STOPWATCH {
            VStack(spacing: 12) {
                // Compact timer with controls side-by-side
                HStack(spacing: 16) {
                    // Timer display - more compact
                    VStack(spacing: 4) {
                        HStack(spacing: 6) {
                            Circle()
                                .fill(timer != nil ? therapyTypeSelection.selectedTherapyType.color : Color.white.opacity(0.3))
                                .frame(width: 6, height: 6)
                            Text(timer != nil ? "ACTIVE" : "READY")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(timer != nil ? therapyTypeSelection.selectedTherapyType.color : .white.opacity(0.5))
                                .tracking(1)
                        }

                        Text(timerLabel)
                            .font(.system(size: 48, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                            .monospacedDigit()
                    }
                    .frame(maxWidth: .infinity)

                    // Quick timer badges - vertical stack with customize button first
                    VStack(spacing: 8) {
                        compactAddButton
                        ForEach(customTimers.prefix(2), id: \.self) { timer in
                            compactTimerBadge(for: Int(timer.duration))
                        }
                    }
                }

                // Start/Stop button - full width but compact
                StartStopButtonView(isRunning: timer != nil, action: startStopButtonPressed, selectedColor: therapyTypeSelection.selectedTherapyType.color)
            }
        } else {
            quickAddContent
        }
    }

    private func compactTimerBadge(for duration: Int) -> some View {
        Button(action: {
            startCountdown(for: Double(duration) * 60)
        }) {
            HStack(spacing: 8) {
                Text("\(duration)")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("min")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.6))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.1))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(therapyTypeSelection.selectedTherapyType.color.opacity(0.4), lineWidth: 1)
                    )
            )
        }
        .disabled(self.timer != nil)
        .opacity(self.timer != nil ? 0.4 : 1)
    }

    private var compactAddButton: some View {
        Button(action: { showCreateTimer = true }) {
            HStack(spacing: 6) {
                Image(systemName: "slider.horizontal.3")
                    .font(.system(size: 14))
                    .foregroundColor(therapyTypeSelection.selectedTherapyType.color)
                Text("Custom")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white.opacity(0.05))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(therapyTypeSelection.selectedTherapyType.color.opacity(0.6), lineWidth: 1.5)
                    )
            )
        }
        .disabled(timer != nil)
        .opacity(timer != nil ? 0.4 : 1)
    }

    private var timerBadges: some View {
        HStack(spacing: 10) {
            ForEach(customTimers, id: \.self) { timer in
                timerBadge(for: timer)
            }
            addTimerButton
        }
        .padding(.horizontal, 20)
    }

    private func timerBadge(for timer: CustomTimer) -> some View {
        Button(action: {
            startCountdown(for: Double(timer.duration) * 60)
        }) {
            VStack(spacing: 6) {
                Text("\(timer.duration)")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .foregroundColor(.white)
                Text("min")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .textCase(.uppercase)
                    .tracking(1)
            }
            .frame(width: 70, height: 80)
            .background(timerBadgeBackground)
            .shadow(color: therapyTypeSelection.selectedTherapyType.color.opacity(0.25), radius: 8, x: 0, y: 4)
        }
        .disabled(self.timer != nil)
        .opacity(self.timer != nil ? 0.3 : 1)
    }

    private var timerBadgeBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.15),
                        Color.white.opacity(0.08)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        therapyTypeSelection.selectedTherapyType.color.opacity(0.5),
                        lineWidth: 1.5
                    )
            )
    }

    private var addTimerButton: some View {
        Button(action: { showCreateTimer = true }) {
            VStack(spacing: 6) {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(therapyTypeSelection.selectedTherapyType.color)
                Text("add")
                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .textCase(.uppercase)
                    .tracking(1)
            }
            .frame(width: 70, height: 80)
            .background(addTimerButtonBackground)
        }
        .disabled(timer != nil)
        .opacity(timer != nil ? 0.3 : 1)
    }

    private var addTimerButtonBackground: some View {
        RoundedRectangle(cornerRadius: 16)
            .fill(
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color.white.opacity(0.1),
                        Color.white.opacity(0.05)
                    ]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(therapyTypeSelection.selectedTherapyType.color.opacity(0.6), lineWidth: 2)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.white.opacity(0.1), lineWidth: 1)
                            .padding(1)
                    )
            )
    }

    @ViewBuilder
    private var quickAddContent: some View {
        if isSessionCompleteForToday {
            VStack(spacing: 16) {
                ZStack {
                    Circle()
                        .fill(Color.green.opacity(0.2))
                        .frame(width: 80, height: 80)
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green)
                }
                Text("Already Complete for Today!")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.white)
            }
            .padding()
        } else {
            markCompleteButton
        }
    }

    private var markCompleteButton: some View {
        Button(action: { logSession() }) {
            HStack(spacing: 12) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 22, weight: .semibold))
                Text("Mark today as complete")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 18)
            .background(
                ZStack {
                    // Gradient background
                    LinearGradient(
                        gradient: Gradient(colors: [
                            therapyTypeSelection.selectedTherapyType.color,
                            therapyTypeSelection.selectedTherapyType.color.opacity(0.8)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )

                    // Subtle shine overlay
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.2),
                            Color.clear
                        ]),
                        startPoint: .top,
                        endPoint: .center
                    )
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: therapyTypeSelection.selectedTherapyType.color.opacity(0.4), radius: 12, x: 0, y: 6)
            .shadow(color: therapyTypeSelection.selectedTherapyType.color.opacity(0.3), radius: 24, x: 0, y: 8)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.3),
                                Color.white.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            )
        }
        .buttonStyle(ScaleButtonStyle())
        .padding(.vertical, 20)
    }

    private var headerView: some View {
        HStack {
            Text("Sessions")
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)

            Spacer()

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
    }

    var body: some View {
        NavigationView {
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

                // Show empty state or content
                if showEmptyState {
                    HabitsEmptyStateView(
                        therapyColor: therapyTypeSelection.selectedTherapyType.color,
                        onDismiss: {
                            showEmptyState = false
                            OnboardingManager.shared.markHabitsTabSeen()
                            showTherapySelectorTooltip = true
                        }
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 0) {
                        headerView

                    // Horizontal scrolling habit selector
                    HorizontalHabitSelector(
                        therapyTypeSelection: therapyTypeSelection,
                        selectedTherapyTypes: selectedTherapies
                    )
                    .padding(.bottom, 16)
                    .contextualTooltip(
                        message: "Swipe to explore different wellness habits",
                        isShowing: showTherapySelectorTooltip,
                        arrowPosition: .top,
                        accentColor: therapyTypeSelection.selectedTherapyType.color,
                        onDismiss: {
                            showTherapySelectorTooltip = false
                            OnboardingManager.shared.markTherapySelectorTooltipSeen()
                            OnboardingManager.shared.markFirstTherapySelected()
                            showStopwatchTooltip = true
                        }
                    )

                Spacer()

                // Consolidated Timer Section
                VStack(spacing: 0) {
                    CustomSessionPicker(selectedFeature: $selectedMode, backgroundColor: therapyTypeSelection.selectedTherapyType.color)
                        .padding(.bottom, 12)

                    timerSectionContent
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white.opacity(0.05))
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                )
                .padding(.horizontal, 24)
                .padding(.bottom, 16)
                .contextualTooltip(
                    message: "Tap Start to begin tracking your first session",
                    isShowing: showStopwatchTooltip,
                    arrowPosition: .top,
                    accentColor: therapyTypeSelection.selectedTherapyType.color,
                    onDismiss: {
                        showStopwatchTooltip = false
                        OnboardingManager.shared.markStopwatchTooltipSeen()
                    }
                )

                // Health status - below timer area
                if !isHealthDataAvailable {
                    HealthDataStatusView(isHealthDataAvailable: isHealthDataAvailable)
                        .padding(.bottom, 16)
                }
                
                // LogbookView(therapyTypeSelection: self.therapyTypeSelection)
                
                //NavigationView {
                    VStack(alignment: .leading) {
                        NavigationLink(destination: ManuallyAddSession(), isActive: $showAddSession) {
                            EmptyView()
                        }
                        VStack {
                            HStack {
                                Text("\(therapyTypeSelection.selectedTherapyType.displayName(viewContext)) History")
                                    .font(.title2)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                    .padding(.leading)

                                Spacer()

                                Button(action: {
                                    showAddSession = true
                                }) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.15))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: "plus")
                                            .font(.system(size: 20, weight: .semibold))
                                            .foregroundColor(.white)
                                    }
                                }
                                .padding(.trailing, 24)
                            }
                            .padding(.top, 24)
                            
                            VStack(alignment: .leading, spacing: 16) {
                                CalendarView(sessionDates: $sessionDates, therapyType: $therapyTypeSelection.selectedTherapyType)
                                    .background(
                                        RoundedRectangle(cornerRadius: 16)
                                            .fill(Color.white.opacity(0.08))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 16)
                                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                                            )
                                    )
                                    .frame(height: 300)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical)
                                
                                if sortedSessions.isEmpty {
                                    VStack(spacing: 16) {
                                        ZStack {
                                            Circle()
                                                .fill(Color.cyan.opacity(0.15))
                                                .frame(width: 80, height: 80)
                                            Image(systemName: "clock.arrow.circlepath")
                                                .font(.system(size: 40, weight: .light))
                                                .foregroundColor(.cyan)
                                        }
                                        Text("Begin recording sessions to see data here")
                                            .foregroundColor(.white.opacity(0.8))
                                            .font(.system(size: 16, weight: .medium, design: .rounded))
                                            .multilineTextAlignment(.center)
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 40)
                                } else {
                                    // Iterate over the sorted sessions
                                    ForEach(sortedSessions, id: \.self) { session in
                                        SessionRow(session: session, therapyTypeSelection: therapyTypeSelection, therapyTypeName: therapyTypeSelection.selectedTherapyType.displayName(viewContext))
                                            .foregroundColor(.white)
                                            .padding(.bottom)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .padding(.bottom, 100)
                        }
                        .onAppear {
                            updateSessionDates()
                        }
                        .onChange(of: therapyTypeSelection.selectedTherapyType) { _ in
                            updateSessionDates()
                        }
                    }
                }  // Close VStack(spacing: 0)

                NavigationLink(destination: LogbookView(therapyTypeSelection: self.therapyTypeSelection), isActive: $showLogbook) {
                    EmptyView()
                }
                NavigationLink(
                    destination: SessionSummary(
                        duration: timerDuration <= 0 ? initialTimerDuration : timerDuration,
                        therapyType: $therapyTypeSelection.selectedTherapyType,
                        averageHeartRate: averageHeartRate,
                        averageSpo2: averageSpo2,
                        averageRespirationRate: averageRespirationRate,
                        minHeartRate: minHeartRate,
                        maxHeartRate: maxHeartRate
                    ),
                    isActive: $showSessionSummary
                ) {
                    EmptyView()
                }
                }  // Close ScrollView
                }  // Close else (empty state)

                // Safety warning overlay (highest priority, shows first)
                if showSafetyWarning {
                    SafetyWarningView(onDismiss: {
                        showSafetyWarning = false
                        OnboardingManager.shared.markSafetyWarningSeen()

                        // After dismissing safety warning, check for other onboarding
                        if OnboardingManager.shared.shouldShowHabitsEmptyState {
                            showEmptyState = true
                        }
                    })
                }
            }  // Close ZStack
            }  // Close NavigationView
        .navigationViewStyle(.stack)
        .onAppear() {
                // Check if should show safety warning first (highest priority)
                if OnboardingManager.shared.shouldShowSafetyWarning {
                    showSafetyWarning = true
                } else if OnboardingManager.shared.shouldShowHabitsEmptyState {
                    // Check if should show onboarding
                    showEmptyState = true
                } else {
                    // Show therapy selector tooltip if not shown before
                    if OnboardingManager.shared.shouldShowTherapySelectorTooltip {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            showTherapySelectorTooltip = true
                        }
                    }

                    // Show stopwatch tooltip if appropriate
                    if OnboardingManager.shared.shouldShowStopwatchTooltip {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                            showStopwatchTooltip = true
                        }
                    }
                }

                // Make NavigationView background transparent
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.backgroundColor = .clear
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance

                // Make ScrollView background transparent
                UIScrollView.appearance().backgroundColor = .clear

                // Add default timers if no custom ones are saved
                if customTimers.isEmpty {
                    let defaultDurations = [10, 15]
                    for duration in defaultDurations {
                        let newTimer = CustomTimer(context: viewContext)
                        newTimer.duration = Int32(duration)
                    }
                }

                do {
                    try viewContext.save()
                } catch {
                    // Handle the error appropriately
                    print("Failed to save new timers: \(error)")
                }

                // Check HealthKit authorization status without prompting
                HealthKitManager.shared.areHealthMetricsAuthorized() { isAuthorized in
                    isHealthDataAvailable = isAuthorized
                }
        }
        .sheet(isPresented: $showCreateTimer) {
            CreateTimerView()
                .environment(\.managedObjectContext, self.viewContext)
        }
        .onChange(of: scenePhase) { newScenePhase in
            switch newScenePhase {
            case .active:
                // App has returned to the foreground, load timer state
                let now = Date()
                let timerStartDate = UserDefaults.standard.object(forKey: "timerStartDate") as? Date ?? now
                let initialTimerDuration = UserDefaults.standard.double(forKey: "timerDuration")
                let elapsedTime = now.timeIntervalSince(timerStartDate)
                let remainingTime = max(0, initialTimerDuration - elapsedTime)

                if remainingTime > 0 {
                    // Timer was running when app went to background
                    self.timerStartDate = timerStartDate
                    self.timerDuration = remainingTime
                } else {
                    // Timer was not running
                    // self.timerStartDate = nil
                    self.timerDuration = 0
                }

            case .inactive, .background:
                // App has gone to the background, save timer state
                UserDefaults.standard.set(self.timerStartDate, forKey: "timerStartDate")
                UserDefaults.standard.set(self.initialTimerDuration, forKey: "timerDuration")

            @unknown default:
                // Future cases
                break
            }
        }  // Close .onChange
    }  // Close var body

    private func logSession() {
        let newSession = TherapySessionEntity(context: viewContext)
        newSession.date = Date()
        newSession.therapyType = therapyTypeSelection.selectedTherapyType.rawValue
        newSession.id = UUID()

        do {
            do {
                try viewContext.save()
                // Mark first session completed for onboarding
                OnboardingManager.shared.markFirstSessionCompleted()
            } catch {
                // Handle the error here, e.g., display an error message or log the error
                print("Failed to save session: \(error.localizedDescription)")
            }
        } catch {
            let nsError = error as NSError
            fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
        }
    }
    
    func startCountdown(for seconds: TimeInterval) {
        initialTimerDuration = seconds
        timerDuration = seconds
        countDown = true
        startStopButtonPressed()
    }
    
    func startStopButtonPressed() {
        // Timer has not started (shows 'start').
        if timer == nil {
            HealthKitManager.shared.requestAuthorization { success, error in
                DispatchQueue.main.async {
                    if success {
                        // pullHealthData()
                        self.acceptedHealthKitPermissions = true
                    } else {
                        self.acceptedHealthKitPermissions = false
                        presentAlert(title: "Authorization Failed", message: "Failed to authorize HealthKit access.")
                    }
                }
            }
            
            timerStartDate = Date()
            timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
                if self.countDown {
                    timerDuration -= 1
                    if timerDuration <= 0 {
                        timer?.invalidate()
                        timer = nil
                        countDown = false
                        showSummary()
                        timerLabel = "00:00"
                        return
                    }
                } else {
                    timerDuration = Date().timeIntervalSince(timerStartDate!)
                }
                let minutes = Int(timerDuration) / 60
                let seconds = Int(timerDuration) % 60
                timerLabel = String(format: "%02d:%02d", minutes, seconds)
            }
        } else { // Timer is running (shows 'stop').
            
            
            pullHealthData()
            
            
            timer?.invalidate()
            timer = nil
            healthDataTimer?.invalidate()
            healthDataTimer = nil
            showSummary()
            timerLabel = "00:00"
            
            // For stopwatch timers
            if countDown {
                timerDuration = initialTimerDuration - timerDuration
                countDown = false
            }
        }
    }
    
    func pullHealthData() {
        guard let startDate = timerStartDate else { return }
        let endDate = Date()
        
        HealthKitManager.shared.fetchHealthData(from: startDate, to: endDate) { healthData in
            if let healthData = healthData {
                averageHeartRate = healthData.avgHeartRate  // This line was changed
                averageSpo2 = healthData.avgSpo2
                averageRespirationRate = healthData.avgRespirationRate
                minHeartRate = healthData.minHeartRate
                maxHeartRate = healthData.maxHeartRate
            }
        }
    }
    
    func showSummary() {
        withAnimation {
            showSessionSummary = true
        }
    }
    
    func presentAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }

    func setupView() {
        // Add default timers if no custom ones are saved
        if customTimers.isEmpty {
            let defaultDurations = [5, 10, 15]
            for duration in defaultDurations {
                let newTimer = CustomTimer(context: viewContext)
                newTimer.duration = Int32(duration)
            }
            try? viewContext.save()
        }

        // Request authorization for HealthKit
        HealthKitManager.shared.requestAuthorization { success, _ in
            if success {
                HealthKitManager.shared.areHealthMetricsAuthorized() { isAuthorized in
                    isHealthDataAvailable = isAuthorized
                }
            } else {
                presentAlert(title: "Authorization Failed", message: "Failed to authorize HealthKit access.")
            }
        }
    }
}

extension Color {
    static let darkBackground = Color(red: 26 / 255, green: 32 / 255, blue: 44 / 255)
    static let customBlue = Color(red: 30 / 255, green: 144 / 255, blue: 255 / 255)
}

struct TimerDisplayView: View {
    @Binding var timerLabel: String
    var selectedColor: Color
    var isRunning: Bool

    @State private var glowAnimation = false

    var body: some View {
        VStack(spacing: 0) {
            // Status indicator
            HStack(spacing: 8) {
                Circle()
                    .fill(isRunning ? selectedColor : Color.white.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .scaleEffect(glowAnimation && isRunning ? 1.3 : 1.0)
                    .opacity(glowAnimation && isRunning ? 0.5 : 1.0)
                    .onAppear {
                        if isRunning {
                            withAnimation(.easeInOut(duration: 1.0).repeatForever(autoreverses: true)) {
                                glowAnimation = true
                            }
                        }
                    }

                Text(isRunning ? "ACTIVE SESSION" : "READY")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                    .foregroundColor(isRunning ? selectedColor : .white.opacity(0.5))
                    .tracking(1.5)
            }
            .padding(.bottom, 20)

            // Timer display
            Text(timerLabel)
                .font(.system(size: 72, weight: .bold, design: .rounded))
                .foregroundColor(.white)
                .monospacedDigit()
                .padding(.vertical, 32)
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 24)
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.white.opacity(0.12),
                                    Color.white.opacity(0.06)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: 24)
                                .stroke(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            selectedColor.opacity(isRunning ? 0.8 : 0.4),
                                            selectedColor.opacity(isRunning ? 0.4 : 0.2)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ),
                                    lineWidth: 2
                                )
                        )
                )
                .shadow(color: selectedColor.opacity(isRunning ? 0.4 : 0.2), radius: 20, x: 0, y: 10)
        }
        .padding(.horizontal, 32)
    }
}

struct StartStopButtonView: View {
    var isRunning: Bool
    var action: () -> Void
    var selectedColor: Color

    var body: some View {
        Button(action: action) {
            HStack(spacing: 10) {
                Image(systemName: isRunning ? "stop.fill" : "play.fill")
                    .font(.system(size: 20, weight: .semibold))
                Text(isRunning ? "Stop" : "Start")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 50)
            .padding(.vertical, 18)
            .background(
                LinearGradient(
                    gradient: Gradient(colors: [selectedColor, selectedColor.opacity(0.8)]),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(25)
            .shadow(color: selectedColor.opacity(0.4), radius: 12, x: 0, y: 6)
            .animation(.easeInOut, value: selectedColor)
        }
    }
}

struct HealthDataStatusView: View {
    var isHealthDataAvailable: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isHealthDataAvailable ? "checkmark.circle.fill" : "info.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(isHealthDataAvailable ? .green : .cyan)

            Text(isHealthDataAvailable ? "Health data from sessions is available only with an Apple Watch" : "Enable HealthKit permissions for CryoZest to give you the full health tracking experience. Visit Settings → Privacy → Health to grant access.")
                .foregroundColor(.white.opacity(0.8))
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .multilineTextAlignment(.leading)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
    }
}

struct CustomSessionPicker: View {
    @Binding var selectedFeature: SessionFeature
    let backgroundColor: Color

    var body: some View {
        HStack(spacing: 0) {
            SessionPickerItem(
                sessionFeature: SessionFeature.STOPWATCH,
                isSelected: selectedFeature == SessionFeature.STOPWATCH,
                backgroundColor: backgroundColor
            )
            .onTapGesture {
                self.selectedFeature = SessionFeature.STOPWATCH
            }

            SessionPickerItem(
                sessionFeature: SessionFeature.QUICK_ADD,
                isSelected: selectedFeature == SessionFeature.QUICK_ADD,
                backgroundColor: backgroundColor
            )
            .onTapGesture {
                self.selectedFeature = SessionFeature.QUICK_ADD
            }
        }
        .padding(4)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.08))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color.white.opacity(0.15), lineWidth: 1)
                )
        )
        .padding(.horizontal, 24)
    }
}

struct SessionPickerItem: View {
    let sessionFeature: SessionFeature
    let isSelected: Bool
    let backgroundColor: Color

    var body: some View {
        Text(sessionFeature.displayString())
            .font(.system(size: 15, weight: isSelected ? .semibold : .medium, design: .rounded))
            .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            .padding(.vertical, 10)
            .padding(.horizontal, 24)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? backgroundColor.opacity(0.3) : Color.clear)
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(isSelected ? backgroundColor.opacity(0.6) : Color.clear, lineWidth: isSelected ? 2 : 0)
            )
    }
}

// Scale button style for press animation
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
