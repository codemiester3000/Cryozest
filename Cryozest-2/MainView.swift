import SwiftUI
import HealthKit
import CoreData

struct MainView: View {

    @ObservedObject var therapyTypeSelection: TherapyTypeSelection

    @Environment(\.scenePhase) private var scenePhase

    @Environment(\.managedObjectContext) private var viewContext

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

    @State private var showAlert: Bool = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""
    @State private var isHealthDataAvailable: Bool = false

    @State private var showAddSession = false

    @State private var sessionDates = [Date]()

    // Onboarding state
    @State private var showEmptyState = false
    @State private var showTherapySelectorTooltip = false
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
    private var habitCompletionSection: some View {
        if isSessionCompleteForToday {
            completedStateView
        } else {
            incompleteStateView
        }
    }

    private var completedStateView: some View {
        ZStack(alignment: .topTrailing) {
            HStack(spacing: 16) {
                // Minimalist checkmark
                ZStack {
                    Circle()
                        .fill(Color.white.opacity(0.08))
                        .frame(width: 52, height: 52)

                    Circle()
                        .stroke(Color.green.opacity(0.3), lineWidth: 1.5)
                        .frame(width: 52, height: 52)

                    Image(systemName: "checkmark")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.green)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Completed")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text(formattedDate(Date()))
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)

            // Undo button - positioned in upper right
            Button(action: {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                    deleteSessionForToday()
                }
            }) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.uturn.backward")
                        .font(.system(size: 13, weight: .semibold))
                    Text("Undo")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                }
                .foregroundColor(.white.opacity(0.7))
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(Color.white.opacity(0.15), lineWidth: 1)
                        )
                )
            }
            .buttonStyle(ElegantPressStyle())
            .padding(.trailing, 16)
            .padding(.top, 16)
        }
    }

    private var incompleteStateView: some View {
        Button(action: {
            withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                logSession()
            }
        }) {
            HStack(spacing: 16) {
                // Elegant circle checkbox
                ZStack {
                    Circle()
                        .stroke(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    therapyTypeSelection.selectedTherapyType.color.opacity(0.6),
                                    therapyTypeSelection.selectedTherapyType.color.opacity(0.3)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 2.5
                        )
                        .frame(width: 52, height: 52)

                    Circle()
                        .fill(therapyTypeSelection.selectedTherapyType.color.opacity(0.12))
                        .frame(width: 48, height: 48)

                    Image(systemName: "plus")
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(therapyTypeSelection.selectedTherapyType.color)
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text("Mark as Complete")
                        .font(.system(size: 17, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text(formattedDate(Date()))
                        .font(.system(size: 14, weight: .regular, design: .rounded))
                        .foregroundColor(.white.opacity(0.5))
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 18)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color.white.opacity(0.03))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        therapyTypeSelection.selectedTherapyType.color.opacity(0.3),
                                        therapyTypeSelection.selectedTherapyType.color.opacity(0.1)
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1.5
                            )
                    )
            )
        }
        .buttonStyle(ElegantPressStyle())
    }

    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
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
                        }
                    )

                Spacer()

                // Habit Completion Section
                VStack(spacing: 0) {
                    habitCompletionSection
                }
                .padding(20)
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

                // Health status - below completion area
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
                                    .frame(height: 240)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, 12)
                                
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
                }

                // Make NavigationView background transparent
                let appearance = UINavigationBarAppearance()
                appearance.configureWithTransparentBackground()
                appearance.backgroundColor = .clear
                UINavigationBar.appearance().standardAppearance = appearance
                UINavigationBar.appearance().scrollEdgeAppearance = appearance

                // Make ScrollView background transparent
                UIScrollView.appearance().backgroundColor = .clear

                // Check HealthKit authorization status without prompting
                HealthKitManager.shared.areHealthMetricsAuthorized() { isAuthorized in
                    isHealthDataAvailable = isAuthorized
                }
        }
    }  // Close var body

    private func logSession() {
        let newSession = TherapySessionEntity(context: viewContext)
        newSession.date = Date()
        newSession.therapyType = therapyTypeSelection.selectedTherapyType.rawValue
        newSession.id = UUID()

        do {
            try viewContext.save()
            // Mark first session completed for onboarding
            OnboardingManager.shared.markFirstSessionCompleted()
        } catch {
            // Handle the error here, e.g., display an error message or log the error
            print("Failed to save session: \(error.localizedDescription)")
        }
    }

    private func deleteSessionForToday() {
        // Find today's session for the current therapy type
        if let sessionToDelete = sessions.first(where: { session in
            let calendar = Calendar.current
            let isSameDay = calendar.isDateInToday(session.date ?? Date())
            let isSameTherapyType = session.therapyType == therapyTypeSelection.selectedTherapyType.rawValue
            return isSameDay && isSameTherapyType
        }) {
            viewContext.delete(sessionToDelete)

            do {
                try viewContext.save()
                updateSessionDates()
            } catch {
                print("Failed to delete session: \(error.localizedDescription)")
            }
        }
    }

    func presentAlert(title: String, message: String) {
        alertTitle = title
        alertMessage = message
        showAlert = true
    }
}

extension Color {
    static let darkBackground = Color(red: 26 / 255, green: 32 / 255, blue: 44 / 255)
    static let customBlue = Color(red: 30 / 255, green: 144 / 255, blue: 255 / 255)
}

struct HealthDataStatusView: View {
    var isHealthDataAvailable: Bool

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: isHealthDataAvailable ? "checkmark.circle.fill" : "info.circle.fill")
                .font(.system(size: 16))
                .foregroundColor(isHealthDataAvailable ? .green : .cyan)

            Text(isHealthDataAvailable ? "Health data from sessions is available only with an Apple Watch" : "HealthKit permissions are needed for the full health tracking experience. Visit Settings → Privacy → Health to manage access.")
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

// Elegant press style for modern button interactions
struct ElegantPressStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.85 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// Scale button style for press animation (used by other views)
struct ScaleButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.spring(response: 0.2, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
