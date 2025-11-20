import SwiftUI
import CoreData

struct DailyView: View {
    // Environment
    @Environment(\.scenePhase) private var scenePhase

    // Data Models
    @ObservedObject var recoveryModel: RecoveryGraphModel
    @ObservedObject var exertionModel: ExertionModel
    @ObservedObject var sleepModel: DailySleepViewModel

    var appleWorkoutsService: AppleWorkoutsService

    @State private var selectedDate: Date = Calendar.current.startOfDay(for: Date())
    @State private var dragOffset: CGFloat = 0

    @State private var showingRecoveryPopover = false
    @State private var showingSleepPopover = false
    @State private var showingMetricConfig = false
    @State private var calculatedUpperBound: Double = 8.0
    @ObservedObject var metricConfig = MetricConfigurationManager.shared

    // Metric expansion state
    @State private var expandedMetric: MetricType? = nil
    @Namespace private var metricAnimation

    // Onboarding state
    @State private var showOnboarding = false
    @State private var showMetricTooltip = false
    @State private var showCustomizeTooltip = false

    // Widget reordering
    @StateObject private var widgetOrderManager = WidgetOrderManager.shared
    @State private var isReorderMode = false
    @State private var draggedWidget: DailyWidgetSection?
    @State private var lastMoveTimestamp: Date = Date()

    // Heart rate polling timer
    @State private var heartRateTimer: Timer?

    private var visibleWidgets: [DailyWidgetSection] {
        widgetOrderManager.widgetOrder.filter { shouldShowWidget($0) }
    }

    private func supportsInlineExpansion(_ section: DailyWidgetSection) -> Bool {
        section == .largeHeartRate || section == .largeSteps
    }

    private func isInlineExpanded(_ section: DailyWidgetSection) -> Bool {
        (section == .largeHeartRate && expandedMetric == .rhr) ||
        (section == .largeSteps && expandedMetric == .steps)
    }

    private func shouldHideWidget(_ section: DailyWidgetSection) -> Bool {
        guard let metric = expandedMetric else { return false }
        // Don't hide if this widget is expanded or if the expanded metric supports inline expansion
        return !isInlineExpanded(section) && (metric != .rhr && metric != .steps)
    }

    private func moveWidget(from: DailyWidgetSection, to: DailyWidgetSection) {
        // Throttle rapid moves
        let now = Date()
        if now.timeIntervalSince(lastMoveTimestamp) < 0.1 {
            return
        }
        lastMoveTimestamp = now


        guard let fromIndex = widgetOrderManager.widgetOrder.firstIndex(of: from),
              let toIndex = widgetOrderManager.widgetOrder.firstIndex(of: to) else {
            return
        }

        guard fromIndex != toIndex else {
            return
        }

        // Update immediately for live feedback
        var newOrder = widgetOrderManager.widgetOrder
        let movedWidget = newOrder.remove(at: fromIndex)

        // Adjust insertion index
        let adjustedToIndex = fromIndex < toIndex ? toIndex - 1 : toIndex
        newOrder.insert(movedWidget, at: adjustedToIndex)


        // Update without animation for smoother drag experience
        widgetOrderManager.widgetOrder = newOrder
    }

    init(
        recoveryModel: RecoveryGraphModel,
        exertionModel: ExertionModel,
        sleepModel: DailySleepViewModel,
        context: NSManagedObjectContext
    ) {
        self.recoveryModel = recoveryModel
        self.exertionModel = exertionModel
        self.sleepModel = sleepModel
        
        appleWorkoutsService = AppleWorkoutsService(context: context)
    }
    
    var calculatedUpperBoundDailyView: Double {
        let recoveryScore = recoveryModel.recoveryScores.last ?? 8
        let upperBound = ceil(Double(recoveryScore) / 10.0)
        let calculatedUpperBound = max(upperBound, 1.0)
        return calculatedUpperBound
    }
    
    func triggerHapticFeedback() {
        let generator = UIImpactFeedbackGenerator(style: .heavy)
        generator.impactOccurred()
    }

    private func goToPreviousDay() {
        let calendar = Calendar.current
        if let previousDay = calendar.date(byAdding: .day, value: -1, to: selectedDate) {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                selectedDate = calendar.startOfDay(for: previousDay)
            }
            triggerHapticFeedback()
        }
    }

    private func goToNextDay() {
        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)
        let currentDay = calendar.startOfDay(for: selectedDate)

        // Only navigate forward if not already at today
        if currentDay < today {
            // Check if next day would be today - if so, use current time instead of start of day
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: selectedDate) {
                let nextDayStart = calendar.startOfDay(for: nextDay)

                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    // If navigating to today, use startOfDay for consistency
                    // (The heart rate widget and other widgets will fetch up to current time anyway)
                    selectedDate = nextDayStart
                }
                triggerHapticFeedback()
            }
        }
    }

    private var isToday: Bool {
        Calendar.current.isDate(selectedDate, inSameDayAs: Date())
    }

    private func shouldShowWidget(_ section: DailyWidgetSection) -> Bool {
        switch section {
        case .medications:
            return metricConfig.isEnabled(.medications)
        case .largeSteps:
            return metricConfig.isEnabled(.steps)
        case .largeHeartRate:
            return metricConfig.isEnabled(.heartRate)
        default:
            return true
        }
    }

    private func startHeartRatePolling() {
        // Stop existing timer if any
        stopHeartRatePolling()

        // Create a new timer that fires every 60 seconds
        heartRateTimer = Timer.scheduledTimer(withTimeInterval: 60.0, repeats: true) { _ in
            // Fetch heart rate data for current selected date
            recoveryModel.refreshHeartRateData(forDate: selectedDate)
        }
    }

    private func stopHeartRatePolling() {
        heartRateTimer?.invalidate()
        heartRateTimer = nil
    }

    @ViewBuilder
    private func widgetView(for section: DailyWidgetSection) -> some View {
        switch section {
        case .wellnessCheckIn:
            WellnessCheckInCard(selectedDate: $selectedDate)
                .modifier(ReorderableWidgetModifier(
                    section: section,
                    isReorderMode: isReorderMode,
                    draggedWidget: $draggedWidget,
                ))

        case .completedHabits:
            CompletedHabitsCard(selectedDate: $selectedDate)
                .modifier(ReorderableWidgetModifier(
                    section: section,
                    isReorderMode: isReorderMode,
                    draggedWidget: $draggedWidget,
                ))

        case .medications:
            if metricConfig.isEnabled(.medications) {
                MedicationsCard(selectedDate: $selectedDate)
                    .modifier(ReorderableWidgetModifier(
                        section: section,
                        isReorderMode: isReorderMode,
                        draggedWidget: $draggedWidget,
                    ))
            }

        case .heroScores:
            HeroScoresView(
                exertionScore: exertionModel.exertionScore,
                readinessScore: recoveryModel.recoveryScores.last ?? 0,
                sleepDuration: recoveryModel.previousNightSleepDuration,
                calculatedUpperBound: calculatedUpperBoundDailyView,
                onExertionTap: {
                    // Exertion now uses dedicated widget, not hero card
                },
                onReadinessTap: {
                    triggerHapticFeedback()
                    showingRecoveryPopover = true
                },
                onSleepTap: {
                    triggerHapticFeedback()
                    showingSleepPopover = true
                },
                recoveryMinutes: exertionModel.recoveryMinutes,
                conditioningMinutes: exertionModel.conditioningMinutes,
                overloadMinutes: exertionModel.overloadMinutes
            )
            .modifier(ReorderableWidgetModifier(
                section: section,
                isReorderMode: isReorderMode,
                draggedWidget: $draggedWidget,
            ))

        case .largeSteps:
            if metricConfig.isEnabled(.steps) {
                LargeStepsWidget(
                    model: recoveryModel,
                    expandedMetric: $expandedMetric,
                    namespace: metricAnimation
                )
                .modifier(ReorderableWidgetModifier(
                    section: section,
                    isReorderMode: isReorderMode,
                    draggedWidget: $draggedWidget,
                ))
            }

        case .largeHeartRate:
            if metricConfig.isEnabled(.heartRate) {
                LargeHeartRateWidget(
                    model: recoveryModel,
                    expandedMetric: $expandedMetric,
                    selectedDate: selectedDate,
                    namespace: metricAnimation
                )
                .modifier(ReorderableWidgetModifier(
                    section: section,
                    isReorderMode: isReorderMode,
                    draggedWidget: $draggedWidget,
                ))
            }

        case .exertion:
            if metricConfig.isEnabled(.exertion) {
                ExertionWidget(
                    exertionModel: exertionModel,
                    recoveryModel: recoveryModel,
                    expandedMetric: $expandedMetric,
                    namespace: metricAnimation
                )
                .modifier(ReorderableWidgetModifier(
                    section: section,
                    isReorderMode: isReorderMode,
                    draggedWidget: $draggedWidget,
                ))
            }

        case .metricsGrid:
            MetricsGridSection(
                model: recoveryModel,
                sleepModel: sleepModel,
                configManager: metricConfig,
                expandedMetric: $expandedMetric
            )
            .modifier(ReorderableWidgetModifier(
                section: section,
                isReorderMode: isReorderMode,
                draggedWidget: $draggedWidget,
            ))
        }
    }

    var body: some View {
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

            // Show onboarding or content
            if showOnboarding {
                OnboardingFlowView(onComplete: {
                    showOnboarding = false

                    // Load health data
                    recoveryModel.pullAllRecoveryData(forDate: selectedDate)
                    exertionModel.fetchExertionScoreAndTimes(forDate: selectedDate)
                    sleepModel.fetchSleepData(forDate: selectedDate)

                    // Show metric tooltip after onboarding
                    if OnboardingManager.shared.shouldShowMetricTooltip {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            showMetricTooltip = true
                        }
                    }
                })
            } else {
                ZStack(alignment: .topTrailing) {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Fixed header (title, customize, date selector)
                            DailyHeaderSection(
                                selectedDate: $selectedDate,
                                showingMetricConfig: $showingMetricConfig,
                                showCustomizeTooltip: $showCustomizeTooltip,
                                isToday: isToday
                            )
                            .padding(.top)
                            .padding(.bottom, 12)

                            // Reorderable widgets with inline expansion
                            VStack(spacing: 12) {
                                ForEach(visibleWidgets) { section in
                                    // For heart rate and steps widgets, expansion happens inline
                                    if shouldHideWidget(section) {
                                        // Hide widgets when a different widget is expanded (overlay behavior)
                                        EmptyView()
                                    } else if isInlineExpanded(section) {
                                        widgetView(for: section)
                                            .padding(.horizontal)
                                            .transition(.scale(scale: 0.95).combined(with: .opacity))
                                    } else {
                                        widgetView(for: section)
                                            .padding(.horizontal)
                                            .simultaneousGesture(
                                                LongPressGesture(minimumDuration: 0.6)
                                                    .onEnded { _ in
                                                        let generator = UIImpactFeedbackGenerator(style: .medium)
                                                        generator.impactOccurred()
                                                        withAnimation(.spring(response: 0.3)) {
                                                            isReorderMode = true
                                                        }
                                                    }
                                            )
                                            .onDrag {
                                                // Enter reorder mode if not already in it
                                                if !isReorderMode {
                                                    withAnimation(.spring(response: 0.3)) {
                                                        isReorderMode = true
                                                    }
                                                    let generator = UIImpactFeedbackGenerator(style: .medium)
                                                    generator.impactOccurred()
                                                }

                                                self.draggedWidget = section
                                                triggerHapticFeedback()
                                                return NSItemProvider(object: section.rawValue as NSString)
                                            }
                                            .onDrop(of: [.text], delegate: WidgetDropDelegate(
                                                draggedWidget: $draggedWidget,
                                                currentWidget: section,
                                                onMove: { from, to in
                                                    moveWidget(from: from, to: to)
                                                }
                                            ))
                                    }
                                }

                                // Show expanded overlay for widgets that don't support inline expansion (old behavior)
                                if let metric = expandedMetric, metric != .rhr && metric != .steps {
                                    Group {
                                        if metric == .exertion {
                                            ExpandedExertionWidget(
                                                exertionModel: exertionModel,
                                                recoveryModel: recoveryModel,
                                                expandedMetric: $expandedMetric,
                                                namespace: metricAnimation
                                            )
                                            .padding(.horizontal)
                                        } else {
                                            // Other metrics handled by ExpandedMetricView
                                            ExpandedMetricView(
                                                metricType: metric,
                                                model: recoveryModel,
                                                isPresented: Binding(
                                                    get: { expandedMetric != nil },
                                                    set: { if !$0 { expandedMetric = nil } }
                                                )
                                            )
                                            .padding(.horizontal)
                                        }
                                    }
                                }
                            }
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: expandedMetric)
                            .padding(.bottom, 12)

                            // Bottom spacer to prevent tab bar overlap
                            Color.clear
                                .frame(height: 100)
                        }
                    }

                    // Done button when in reorder mode
                    if isReorderMode {
                        Button(action: {
                            withAnimation(.spring(response: 0.3)) {
                                isReorderMode = false
                            }
                            // Save the final order
                            widgetOrderManager.saveOrder()
                            triggerHapticFeedback()
                        }) {
                            HStack(spacing: 6) {
                                Image(systemName: "checkmark.circle.fill")
                                    .font(.system(size: 18, weight: .semibold))
                                Text("Done")
                                    .font(.system(size: 16, weight: .semibold))
                            }
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(
                                Capsule()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.cyan, Color.cyan.opacity(0.8)],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .shadow(color: Color.cyan.opacity(0.5), radius: 10, x: 0, y: 5)
                            )
                        }
                        .padding(.top, 60)
                        .padding(.trailing, 20)
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .simultaneousGesture(
                    DragGesture(minimumDistance: 30)
                        .onEnded { value in
                            let horizontalAmount = value.translation.width
                            let verticalAmount = value.translation.height

                            // Only process horizontal swipes (not vertical scrolling)
                            if abs(horizontalAmount) > abs(verticalAmount) * 2 {
                                if horizontalAmount < 0 {
                                    // Swipe left - go to next day (if not today)
                                    goToNextDay()
                                } else {
                                    // Swipe right - go to previous day
                                    goToPreviousDay()
                                }
                            }
                        }
                )
            .refreshable {
                recoveryModel.pullAllRecoveryData(forDate: selectedDate)
                exertionModel.fetchExertionScoreAndTimes(forDate: selectedDate)
                sleepModel.fetchSleepData(forDate: selectedDate)
            }
            .sheet(isPresented: $showingSleepPopover) {
                DailySleepView(dailySleepModel: sleepModel)
            }
            .sheet(isPresented: $showingRecoveryPopover) {
                RecoveryCardView(model: recoveryModel)
            }
            .sheet(isPresented: $showingMetricConfig) {
                MetricConfigurationView()
            }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear() {
            // Check if should show onboarding
            if OnboardingManager.shared.shouldShowDailyEmptyState {
                showOnboarding = true
            } else {
                // User has already seen the onboarding, check if they granted HealthKit permissions
                HealthKitManager.shared.areHealthMetricsAuthorized() { isAuthorized in
                    if isAuthorized {
                        recoveryModel.pullAllRecoveryData(forDate: selectedDate)
                        exertionModel.fetchExertionScoreAndTimes(forDate: selectedDate)
                        sleepModel.fetchSleepData(forDate: selectedDate)
                        appleWorkoutsService.fetchAndSaveWorkouts()
                    }
                }

                // Show metric tooltip if not shown before
                if OnboardingManager.shared.shouldShowMetricTooltip {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        showMetricTooltip = true
                    }
                }

                // Show customize tooltip if not shown before
                if OnboardingManager.shared.shouldShowCustomizeTooltip {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                        showCustomizeTooltip = true
                    }
                }
            }
        }
        .onChange(of: selectedDate) { newValue in
            // CRITICAL: Update model selectedDate properties first
            recoveryModel.selectedDate = selectedDate
            exertionModel.selectedDate = selectedDate
            sleepModel.selectedDate = selectedDate

            // Then fetch data with the updated date
            recoveryModel.pullAllRecoveryData(forDate: selectedDate)
            exertionModel.fetchExertionScoreAndTimes(forDate: selectedDate)
            sleepModel.fetchSleepData(forDate: selectedDate)

            // Restart polling with new date if app is active
            if scenePhase == .active {
                startHeartRatePolling()
            }
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                // Check if the calendar day has changed since last view
                let calendar = Calendar.current
                let now = Date()
                let yesterday = calendar.date(byAdding: .day, value: -1, to: now) ?? now

                // If selectedDate is yesterday, automatically move to today
                if calendar.isDate(selectedDate, inSameDayAs: yesterday) {
                    selectedDate = calendar.startOfDay(for: now)
                } else {
                    // Otherwise update model dates and refresh data for current selectedDate
                    recoveryModel.selectedDate = selectedDate
                    exertionModel.selectedDate = selectedDate
                    sleepModel.selectedDate = selectedDate

                    recoveryModel.pullAllRecoveryData(forDate: selectedDate)
                    exertionModel.fetchExertionScoreAndTimes(forDate: selectedDate)
                    sleepModel.fetchSleepData(forDate: selectedDate)
                }

                // Start polling for heart rate every minute
                startHeartRatePolling()
            } else {
                // Stop polling when app becomes inactive
                stopHeartRatePolling()
            }
        }
        .onDisappear {
            // Clean up timer when view disappears
            stopHeartRatePolling()
        }
    }
}

struct HeaderView: View {
    @ObservedObject var model: RecoveryGraphModel
    @Binding var selectedDate: Date
    @Binding var showingMetricConfig: Bool
    let isToday: Bool

    @State private var showingDatePicker = false
    @ObservedObject var configManager = MetricConfigurationManager.shared

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                Text("Daily Health")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Spacer()
            }

            HStack(spacing: 12) {
                Button(action: {
                    showingMetricConfig = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Customize")
                            .font(.system(size: 13, weight: .medium))
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.cyan.opacity(0.15))
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                            )
                    )
                }

                Spacer()

                // Date indicator with swipe hint
                Button(action: {
                    showingDatePicker = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))

                        Text(dateFormatter.string(from: selectedDate))
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))

                        if isToday {
                            Text("Today")
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(.cyan)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    Capsule()
                                        .fill(Color.cyan.opacity(0.15))
                                )
                        }

                        Image(systemName: "chevron.right")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(isToday ? .white.opacity(0.2) : .white.opacity(0.5))
                    }
                    .padding(.vertical, 8)
                    .padding(.horizontal, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color.white.opacity(0.08))
                            .overlay(
                                RoundedRectangle(cornerRadius: 10)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerSheet(selectedDate: $selectedDate)
            }

            // Wellness Check-In Card
            WellnessCheckInCard(selectedDate: $selectedDate)

            // Completed Habits Card
            CompletedHabitsCard(selectedDate: $selectedDate)

            // Medications Card
            if configManager.isEnabled(.medications) {
                MedicationsCard(selectedDate: $selectedDate)
            }
        }
        .padding(.horizontal)
    }
}

struct PrimaryButtonStyle: ButtonStyle {
    var backgroundColor: Color
    
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .padding()
            .background(backgroundColor)
            .foregroundColor(.black)
            .clipShape(RoundedRectangle(cornerRadius: 10))
            .shadow(color: backgroundColor.opacity(0.4), radius: 10, x: 0, y: 10)
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
            )
            .scaleEffect(configuration.isPressed ? 0.96 : 1)
            .animation(.spring(), value: configuration.isPressed)
    }
}

// Function to get color based on percentage
func getColor(forPercentage percentage: Int) -> Color {
    switch percentage {
    case let x where x > 50:
        return .green
    case let x where x > 30:
        return .yellow
    default:
        return .red
    }
}



private func formatTotalCaloriesValue(_ activeCalories: Double?, _ restingCalories: Double?) -> String {
    let totalCalories = (activeCalories ?? 0) + (restingCalories ?? 0)
    return String(format: "%.0f", totalCalories)
}

private func formatVO2MaxValue(_ vo2Max: Double?) -> String {
    // If vo2Max is nil, return "0"
    return vo2Max != nil ? String(format: "%.1f", vo2Max!) : "0"
}

private func formatSPO2Value(_ spo2: Double?) -> String {
    guard let spo2 = spo2 else { return "N/A" }
    return String(format: "%.0f", spo2 * 100) // Convert to percentage
}
private func formatActiveCaloriesValue(_ calories: Double?) -> String {
    guard let calories = calories else { return "N/A" }
    return String(format: "%.0f", calories) // Rounded to the nearest integer
}

private func formatRespRateValue(_ respRate: Double?) -> String {
    guard let respRate = respRate else { return "N/A" }
    return String(format: "%.1f", respRate) // One decimal place
}

struct DailyGridMetrics: View {
    @ObservedObject var model: RecoveryGraphModel
    @ObservedObject var sleepModel: DailySleepViewModel
    @ObservedObject var exertionModel: ExertionModel
    @ObservedObject var configManager: MetricConfigurationManager
    @Binding var expandedMetric: MetricType?
    var selectedDate: Date
    @Namespace private var animation

    var body: some View {
        ZStack {
            if expandedMetric == nil {
                // Layout when nothing is expanded
                VStack(spacing: 12) {
                    // Large Steps Widget (full width)
                    if configManager.isEnabled(.steps) {
                        LargeStepsWidget(
                            model: model,
                            expandedMetric: $expandedMetric,
                            namespace: animation
                        )
                    }

                    // Large Heart Rate Widget (full width)
                    if configManager.isEnabled(.heartRate) {
                        LargeHeartRateWidget(
                            model: model,
                            expandedMetric: $expandedMetric,
                            selectedDate: selectedDate,
                            namespace: animation
                        )
                    }

                    // Exertion Widget (full width)
                    if configManager.isEnabled(.exertion) {
                        ExertionWidget(
                            exertionModel: exertionModel,
                            recoveryModel: model,
                            expandedMetric: $expandedMetric,
                            namespace: animation
                        )
                    }

                    // Grid layout for other metrics
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 12) {
                        if configManager.isEnabled(.hrv) {
                            GridItemView(
                                symbolName: "waveform.path.ecg",
                                title: "Avg HRV",
                                value: "\(model.lastKnownHRV)",
                                unit: "ms",
                                metricType: .hrv,
                                model: model,
                                expandedMetric: $expandedMetric,
                                namespace: animation
                            )
                        }

                        if configManager.isEnabled(.spo2) {
                            GridItemView(
                                symbolName: "drop",
                                title: "Blood Oxygen",
                                value: formatSPO2Value(model.mostRecentSPO2),
                                unit: "%",
                                metricType: .spo2,
                                model: model,
                                expandedMetric: $expandedMetric,
                                namespace: animation
                            )
                        }

                        if configManager.isEnabled(.respiratoryRate) {
                            GridItemView(
                                symbolName: "lungs",
                                title: "Respiratory Rate",
                                value: formatRespRateValue(model.mostRecentRespiratoryRate),
                                unit: "BrPM",
                                metricType: .respiratoryRate,
                                model: model,
                                expandedMetric: $expandedMetric,
                                namespace: animation
                            )
                        }

                        if configManager.isEnabled(.calories) {
                            GridItemView(
                                symbolName: "flame",
                                title: "Calories Burned",
                                value: formatTotalCaloriesValue(model.mostRecentActiveCalories, model.mostRecentRestingCalories),
                                unit: "kcal",
                                metricType: .calories,
                                model: model,
                                expandedMetric: $expandedMetric,
                                namespace: animation
                            )
                        }

                        if configManager.isEnabled(.vo2Max) {
                            GridItemView(
                                symbolName: "lungs",
                                title: "VO2 Max",
                                value: String(format: "%.1f", model.mostRecentVO2Max ?? 0.0),
                                unit: "ml/kg/min",
                                metricType: .vo2Max,
                                model: model,
                                expandedMetric: $expandedMetric,
                                namespace: animation
                            )
                        }

                        if configManager.isEnabled(.deepSleep) {
                            GridItemView(
                                symbolName: "bed.double.fill",
                                title: "Deep Sleep",
                                value: sleepModel.totalDeepSleep,
                                unit: "hrs",
                                metricType: .deepSleep,
                                model: model,
                                expandedMetric: $expandedMetric,
                                namespace: animation
                            )
                        }

                        if configManager.isEnabled(.remSleep) {
                            GridItemView(
                                symbolName: "moon.stars.fill",
                                title: "REM Sleep",
                                value: sleepModel.totalRemSleep,
                                unit: "hrs",
                                metricType: .remSleep,
                                model: model,
                                expandedMetric: $expandedMetric,
                                namespace: animation
                            )
                        }

                        if configManager.isEnabled(.coreSleep) {
                            GridItemView(
                                symbolName: "moon.fill",
                                title: "Core Sleep",
                                value: sleepModel.totalCoreSleep,
                                unit: "hrs",
                                metricType: .coreSleep,
                                model: model,
                                expandedMetric: $expandedMetric,
                                namespace: animation
                            )
                        }
                    }
                }
                .transition(.opacity)
            }

            // Expanded single tile view
            if let metric = expandedMetric {
                if metric == .steps {
                    ExpandedStepsWidget(
                        model: model,
                        expandedMetric: $expandedMetric,
                        namespace: animation
                    )
                    .transition(.asymmetric(
                        insertion: .identity,
                        removal: .identity
                    ))
                    .zIndex(1)
                } else {
                    ExpandedGridItemView(
                        symbolName: iconFor(metric),
                        title: titleFor(metric),
                        value: valueFor(metric),
                        unit: unitFor(metric),
                        metricType: metric,
                        model: model,
                        expandedMetric: $expandedMetric,
                        namespace: animation
                    )
                    .transition(.asymmetric(
                        insertion: .identity,
                        removal: .identity
                    ))
                    .zIndex(1)
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 12)
        .animation(.spring(response: 0.6, dampingFraction: 0.85), value: expandedMetric)
    }
    
    private func formatSPO2Value(_ spo2: Double?) -> String {
        guard let spo2 = spo2 else { return "N/A" }
        return String(format: "%.0f", spo2 * 100) // Convert to percentage
    }
    
    private func formatTotalCaloriesValue(_ activeCalories: Double?, _ restingCalories: Double?) -> String {
        let totalCalories = (activeCalories ?? 0) + (restingCalories ?? 0)
        return totalCalories > 0 ? String(format: "%.0f", totalCalories) : "0"
    }
    
    private func formatRespRateValue(_ respRate: Double?) -> String {
        guard let respRate = respRate else { return "N/A" }
        return String(format: "%.1f", respRate) // One decimal place
    }

    private func iconFor(_ metric: MetricType) -> String {
        switch metric {
        case .hrv: return "waveform.path.ecg"
        case .rhr: return "arrow.down.heart"
        case .spo2: return "drop"
        case .respiratoryRate: return "lungs"
        case .calories: return "flame"
        case .steps: return "figure.walk"
        case .vo2Max: return "lungs"
        case .deepSleep: return "bed.double.fill"
        case .remSleep: return "moon.stars.fill"
        case .coreSleep: return "moon.fill"
        case .exertion: return "flame.fill"
        }
    }

    private func titleFor(_ metric: MetricType) -> String {
        switch metric {
        case .hrv: return "Avg HRV"
        case .rhr: return "Avg RHR"
        case .spo2: return "Blood Oxygen"
        case .respiratoryRate: return "Respiratory Rate"
        case .calories: return "Calories Burned"
        case .steps: return "Steps"
        case .vo2Max: return "VO2 Max"
        case .deepSleep: return "Deep Sleep"
        case .remSleep: return "REM Sleep"
        case .coreSleep: return "Core Sleep"
        case .exertion: return "Exertion"
        }
    }

    private func valueFor(_ metric: MetricType) -> String {
        switch metric {
        case .hrv: return "\(model.lastKnownHRV)"
        case .rhr: return "\(model.mostRecentRestingHeartRate ?? 0)"
        case .spo2: return formatSPO2Value(model.mostRecentSPO2)
        case .respiratoryRate: return formatRespRateValue(model.mostRecentRespiratoryRate)
        case .calories: return formatTotalCaloriesValue(model.mostRecentActiveCalories, model.mostRecentRestingCalories)
        case .steps: return "\(model.mostRecentSteps.map(Int.init) ?? 0)"
        case .vo2Max: return String(format: "%.1f", model.mostRecentVO2Max ?? 0.0)
        case .deepSleep: return sleepModel.totalDeepSleep
        case .remSleep: return sleepModel.totalRemSleep
        case .coreSleep: return sleepModel.totalCoreSleep
        case .exertion: return "N/A" // Exertion uses dedicated widget
        }
    }

    private func unitFor(_ metric: MetricType) -> String {
        switch metric {
        case .hrv: return "ms"
        case .rhr: return "bpm"
        case .spo2: return "%"
        case .respiratoryRate: return "BrPM"
        case .calories: return "kcal"
        case .steps: return "steps"
        case .vo2Max: return "ml/kg/min"
        case .deepSleep: return "hrs"
        case .remSleep: return "hrs"
        case .coreSleep: return "hrs"
        case .exertion: return ""
        }
    }
}

struct GridItemView: View {
    var symbolName: String
    var title: String
    var value: String
    var unit: String
    var metricType: MetricType
    var model: RecoveryGraphModel
    @Binding var expandedMetric: MetricType?
    var namespace: Namespace.ID

    @State private var animate = true
    @State private var cachedValue: String
    @State private var isPressed = false

    init(symbolName: String, title: String, value: String, unit: String, metricType: MetricType, model: RecoveryGraphModel, expandedMetric: Binding<MetricType?>, namespace: Namespace.ID) {
        self.symbolName = symbolName
        self.title = title
        _cachedValue = State(initialValue: value)
        self.value = value
        self.unit = unit
        self.metricType = metricType
        self.model = model
        self._expandedMetric = expandedMetric
        self.namespace = namespace
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: symbolName)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(.cyan)
                    .frame(width: 24, height: 24)
                    .background(
                        Circle()
                            .fill(Color.cyan.opacity(0.15))
                    )

                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                Spacer()
            }

            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(animate ? Color.cyan : .white)
                Text(unit)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundColor(.white.opacity(0.5))
                    .padding(.bottom, 1)
            }
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2)) {
                animate = false
            }
        }
        .onChange(of: value) { newValue in
            if newValue != cachedValue {
                cachedValue = newValue
                animate = true
                withAnimation(.easeInOut(duration: 2)) {
                    animate = false
                }
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
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
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(animate ? Color.cyan.opacity(0.5) : Color.white.opacity(0.12), lineWidth: 1)
                )
        )
        .shadow(color: animate ? Color.cyan.opacity(0.25) : Color.black.opacity(0.05), radius: 6, x: 0, y: 3)
        .scaleEffect(isPressed ? 0.95 : 1.0)
        .matchedGeometryEffect(id: "metric-\(metricType.rawValue)", in: namespace, properties: .frame)
        .onTapGesture {
            expandedMetric = metricType
        }
        .onLongPressGesture(minimumDuration: 0.0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct ExpandedGridItemView: View {
    var symbolName: String
    var title: String
    var value: String
    var unit: String
    var metricType: MetricType
    var model: RecoveryGraphModel
    @Binding var expandedMetric: MetricType?
    var namespace: Namespace.ID

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                // Header section (similar to collapsed)
                HStack {
                    HStack(spacing: 10) {
                        Image(systemName: symbolName)
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(metricType.color)
                            .frame(width: 36, height: 36)
                            .background(
                                Circle()
                                    .fill(metricType.color.opacity(0.15))
                            )

                        VStack(alignment: .leading, spacing: 2) {
                            Text(title)
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))

                            HStack(alignment: .lastTextBaseline, spacing: 3) {
                                Text(value)
                                    .font(.system(size: 28, weight: .bold))
                                    .foregroundColor(.white)
                                Text(unit)
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }

                    Spacer()

                    Button(action: {
                        expandedMetric = nil
                    }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }

                // Chart section
                detailView
                    .opacity(expandedMetric != nil ? 1 : 0)
                    .animation(.easeInOut(duration: 0.2).delay(0.15), value: expandedMetric)
            }
            .padding(16)
        }
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(
                    LinearGradient(
                        gradient: Gradient(colors: [
                            Color.white.opacity(0.12),
                            Color.white.opacity(0.08)
                        ]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(metricType.color.opacity(0.3), lineWidth: 1.5)
                )
        )
        .shadow(color: metricType.color.opacity(0.3), radius: 12, x: 0, y: 6)
        .matchedGeometryEffect(id: "metric-\(metricType.rawValue)", in: namespace, properties: .frame)
    }

    @ViewBuilder
    private var detailView: some View {
        switch metricType {
        case .hrv:
            HRVDetailView(model: model)
        case .rhr:
            HeartRateDetailView(model: model)
        case .spo2:
            SpO2DetailView(model: model)
        case .respiratoryRate:
            RespiratoryRateDetailView(model: model)
        case .calories:
            CaloriesDetailView(model: model)
        case .steps:
            StepsDetailView(model: model)
        case .vo2Max:
            VO2MaxDetailView(model: model)
        case .deepSleep, .remSleep, .coreSleep:
            VStack(alignment: .leading, spacing: 16) {
                Text("Sleep stage data")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))

                Text("Tap on the Sleep hero card or visit the Sleep tab for detailed sleep analysis and trends.")
                    .font(.system(size: 14, weight: .regular))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        case .exertion:
            // Exertion has its own dedicated widget with expanded state
            EmptyView()
        }
    }
}

struct HeroScoresView: View {
    let exertionScore: Double
    let readinessScore: Int
    let sleepDuration: String?
    let calculatedUpperBound: Double
    let onExertionTap: () -> Void
    let onReadinessTap: () -> Void
    let onSleepTap: () -> Void

    @ObservedObject var configManager = MetricConfigurationManager.shared

    // Additional data for expanded cards (optional, provide defaults)
    var recoveryMinutes: Double = 0
    var conditioningMinutes: Double = 0
    var overloadMinutes: Double = 0

    private var enabledScores: [HeroScore] {
        HeroScore.allCases.filter { configManager.isEnabled($0) }
    }

    private var sleepDurationScore: Int {
        guard let durationString = sleepDuration,
              let duration = Double(durationString) else {
            return 0
        }
        // 8 hours = 100%, scale linearly
        let score = (duration / 8.0) * 100
        return min(Int(score), 100)
    }

    var body: some View {
        if enabledScores.isEmpty {
            EmptyView()
        } else {
            // All scores stacked vertically (full width)
            VStack(spacing: 12) {
                ForEach(enabledScores) { heroScore in
                    scoreCard(for: heroScore)
                }
            }
        }
    }

    @ViewBuilder
    private func scoreCard(for heroScore: HeroScore) -> some View {
        switch heroScore {
        case .exertion:
            // Exertion now uses dedicated widget in metrics section, not hero card
            EmptyView()
        case .readiness:
            if configManager.isEnabled(.readiness) {
                ReadinessWidget(
                    readinessScore: readinessScore,
                    action: onReadinessTap
                )
            }
        case .sleep:
            if configManager.isEnabled(.sleep) {
                SleepWidget(
                    sleepDuration: sleepDuration,
                    action: onSleepTap
                )
            }
        }
    }
}

struct ScoreCardView: View {
    let title: String
    let score: Int
    let icon: String
    let color: Color
    let requiresAppleWatch: Bool
    let action: () -> Void

    @State private var isPressed = false
    @State private var showAppleWatchNotice = false

    var body: some View {
        Button(action: {
            if requiresAppleWatch && score == 0 {
                showAppleWatchNotice = true
            }
            action()
        }) {
            VStack(spacing: 10) {
                // Icon
                ZStack {
                    Circle()
                        .fill(color.opacity(0.2))
                        .frame(width: 44, height: 44)

                    Image(systemName: icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(color)
                }

                // Score
                Text("\(score)")
                    .font(.system(size: 32, weight: .bold))
                    .foregroundColor(.white)

                // Title
                Text(title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.white.opacity(0.12),
                                Color.white.opacity(0.08)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.3), lineWidth: 1)
                    )
            )
            .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.95 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct ExpandedHeroCard: View {
    let title: String
    let score: Int
    let icon: String
    let color: Color
    let subtitle: String
    let details: [(label: String, value: String, color: Color)]
    let requiresAppleWatch: Bool
    let action: () -> Void

    @State private var isPressed = false

    private var scoreColor: Color {
        if score >= 80 {
            return color
        } else if score >= 60 {
            return .yellow
        } else if score >= 40 {
            return .orange
        } else {
            return .red
        }
    }

    private var statusText: String {
        if score == 0 {
            return "No data"
        } else if score >= 80 {
            return "Excellent"
        } else if score >= 60 {
            return "Good"
        } else if score >= 40 {
            return "Fair"
        } else {
            return "Low"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                // Header with icon and score
                HStack(alignment: .center, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(scoreColor.opacity(0.2))
                            .frame(width: 40, height: 40)

                        Image(systemName: icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(scoreColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(title)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))

                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text("\(score)")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)

                            if score > 0 {
                                Text("/ 100")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }

                    Spacer()

                    // Status badge
                    if score > 0 {
                        VStack(alignment: .trailing, spacing: 4) {
                            Text(statusText)
                                .font(.system(size: 11, weight: .bold))
                                .foregroundColor(scoreColor)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 5)
                                .background(
                                    Capsule()
                                        .fill(scoreColor.opacity(0.15))
                                        .overlay(
                                            Capsule()
                                                .stroke(scoreColor.opacity(0.3), lineWidth: 1)
                                        )
                                )
                        }
                    }
                }

                // Subtitle
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background(
                ZStack {
                    // Decorative icon pattern
                    GeometryReader { geo in
                        Image(systemName: icon)
                            .font(.system(size: 60, weight: .ultraLight))
                            .foregroundColor(scoreColor.opacity(0.04))
                            .rotationEffect(.degrees(-15))
                            .offset(x: geo.size.width - 50, y: 10)
                    }
                }
            )
            .modernWidgetCard(style: .hero)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

struct ProgressButtonView: View {
    let title: String
    let progress: Float
    let color: Color
    let action: () -> Void

    @State private var cachedProgress: Float
    @State private var hasNewData = false
    @State private var isPressed = false

    init(title: String, progress: Float, color: Color, action: @escaping () -> Void) {
        self.title = title
        self.progress = progress
        self.color = color
        self.action = action
        _cachedProgress = State(initialValue: progress)
    }

    private var iconName: String {
        switch title {
        case "Daily Exertion": return "flame.fill"
        case "Sleep Quality": return "moon.fill"
        default: return "bolt.fill"
        }
    }

    var body: some View {
        Button(action: {
            action()
            hasNewData = false
        }) {
            VStack(alignment: .leading, spacing: 10) {
                HStack(spacing: 10) {
                    // Icon with gradient background
                    Image(systemName: iconName)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            color.opacity(0.8),
                                            color.opacity(0.6)
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                        )

                    Text(title)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)

                    Spacer()

                    if hasNewData {
                        Circle()
                            .fill(color)
                            .frame(width: 8, height: 8)
                    }

                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(color)
                }

                // Progress bar
                GeometryReader { geometry in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.white.opacity(0.08))
                            .frame(height: 6)

                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [color, color.opacity(0.7)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: geometry.size.width * CGFloat(progress), height: 6)
                            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: progress)
                    }
                }
                .frame(height: 6)
            }
            .padding(14)
            .background(
                RoundedRectangle(cornerRadius: 16)
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
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(color.opacity(0.4), lineWidth: 1)
                    )
            )
            .shadow(color: color.opacity(0.2), radius: 8, x: 0, y: 4)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
        .onChange(of: progress) { newValue in
            if newValue > cachedProgress {
                withAnimation {
                    cachedProgress = newValue
                    hasNewData = true
                }
            }
        }
    }
}

struct DatePickerSheet: View {
    @Binding var selectedDate: Date
    @Environment(\.dismiss) var dismiss

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

                VStack(spacing: 24) {
                    // Calendar icon
                    Image(systemName: "calendar")
                        .font(.system(size: 48, weight: .semibold))
                        .foregroundColor(.cyan)
                        .padding(20)
                        .background(
                            Circle()
                                .fill(Color.cyan.opacity(0.15))
                        )
                        .padding(.top, 40)

                    Text("Select Date")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)

                    // Date Picker
                    DatePicker(
                        "Date",
                        selection: $selectedDate,
                        in: ...Date(),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.graphical)
                    .colorScheme(.dark)
                    .padding()
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.white.opacity(0.1))
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.cyan.opacity(0.3), lineWidth: 1)
                            )
                    )
                    .padding(.horizontal, 24)

                    Spacer()

                    // Done button
                    Button(action: {
                        dismiss()
                    }) {
                        Text("Done")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(Color.cyan)
                            )
                            .shadow(color: Color.cyan.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { dismiss() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
        }
    }
}

// MARK: - Reorderable Widget Modifier

struct ReorderableWidgetModifier: ViewModifier {
    let section: DailyWidgetSection
    let isReorderMode: Bool
    @Binding var draggedWidget: DailyWidgetSection?

    @State private var wiggleRotation: Double = 0
    @State private var wiggleX: CGFloat = 0

    func body(content: Content) -> some View {
        ZStack(alignment: .topTrailing) {
            content
                .opacity(isReorderMode && draggedWidget == section ? 0.5 : 1.0)
                .scaleEffect(isReorderMode && draggedWidget == section ? 0.95 : 1.0)
                .rotationEffect(.degrees(isReorderMode && draggedWidget != section ? wiggleRotation : 0))
                .offset(x: isReorderMode && draggedWidget != section ? wiggleX : 0)
                .animation(.spring(response: 0.3), value: isReorderMode)
                .animation(.spring(response: 0.3), value: draggedWidget)
                .onChange(of: isReorderMode) { newValue in
                    if newValue {
                        startWiggling()
                    } else {
                        stopWiggling()
                    }
                }
                .onAppear {
                }

            // Drag handle indicator when in reorder mode
            if isReorderMode {
                Image(systemName: "line.3.horizontal")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white.opacity(0.6))
                    .padding(12)
                    .background(
                        Circle()
                            .fill(Color.white.opacity(0.15))
                    )
                    .padding(8)
                    .transition(.scale.combined(with: .opacity))
            }
        }
    }

    private func startWiggling() {
        // Random offset for more natural look
        let randomDelay = Double.random(in: 0...0.3)
        let randomRotation = Double.random(in: 0.3...0.6) // Very subtle rotation
        let randomX = CGFloat.random(in: 0.2...0.5) // Tiny horizontal movement

        // Rotation wiggle
        withAnimation(
            Animation.easeInOut(duration: 0.12)
                .repeatForever(autoreverses: true)
                .delay(randomDelay)
        ) {
            wiggleRotation = randomRotation
        }

        // Horizontal wiggle (slightly different timing for natural feel)
        withAnimation(
            Animation.easeInOut(duration: 0.14)
                .repeatForever(autoreverses: true)
                .delay(randomDelay + 0.05)
        ) {
            wiggleX = randomX
        }
    }

    private func stopWiggling() {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            wiggleRotation = 0
            wiggleX = 0
        }
    }
}

// MARK: - Widget Drop Delegate

struct WidgetDropDelegate: DropDelegate {
    @Binding var draggedWidget: DailyWidgetSection?
    let currentWidget: DailyWidgetSection
    let onMove: (DailyWidgetSection, DailyWidgetSection) -> Void

    func performDrop(info: DropInfo) -> Bool {
        guard draggedWidget != nil else {
            return false
        }
        draggedWidget = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedWidget = draggedWidget else {
            return
        }
        guard draggedWidget != currentWidget else {
            return
        }

        onMove(draggedWidget, currentWidget)
    }

    func dropUpdated(info: DropInfo) -> DropProposal? {
        return DropProposal(operation: .move)
    }
}

// MARK: - Daily Header Section

struct DailyHeaderSection: View {
    @Binding var selectedDate: Date
    @Binding var showingMetricConfig: Bool
    @Binding var showCustomizeTooltip: Bool
    let isToday: Bool

    @State private var showingDatePicker = false

    private var compactDateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        return formatter
    }

    var body: some View {
        VStack(spacing: 10) {
            // Title and date selector on same line
            HStack(alignment: .center, spacing: 12) {
                Text("Daily Health")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)

                Spacer()

                // Ultra-compact date selector pill
                Button(action: {
                    showingDatePicker = true
                }) {
                    HStack(spacing: 6) {
                        // Today badge when applicable
                        if isToday {
                            HStack(spacing: 4) {
                                Circle()
                                    .fill(Color.cyan)
                                    .frame(width: 6, height: 6)

                                Text("Today")
                                    .font(.system(size: 11, weight: .bold))
                                    .foregroundColor(.cyan)
                            }
                            .padding(.trailing, 2)
                        } else {
                            Image(systemName: "calendar")
                                .font(.system(size: 11, weight: .semibold))
                                .foregroundColor(.white.opacity(0.6))
                        }

                        Text(compactDateFormatter.string(from: selectedDate))
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white)

                        Image(systemName: "chevron.down")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .background(
                        Capsule()
                            .fill(
                                LinearGradient(
                                    colors: isToday ? [
                                        Color.cyan.opacity(0.25),
                                        Color.cyan.opacity(0.15)
                                    ] : [
                                        Color.white.opacity(0.12),
                                        Color.white.opacity(0.08)
                                    ],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .overlay(
                                Capsule()
                                    .stroke(
                                        LinearGradient(
                                            colors: isToday ? [
                                                Color.cyan.opacity(0.4),
                                                Color.cyan.opacity(0.2)
                                            ] : [
                                                Color.white.opacity(0.25),
                                                Color.white.opacity(0.1)
                                            ],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: isToday ? Color.cyan.opacity(0.2) : Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
                    )
                }
                .buttonStyle(PlainButtonStyle())
            }

            // Compact customize button
            HStack(spacing: 12) {
                Button(action: {
                    showingMetricConfig = true
                }) {
                    HStack(spacing: 6) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 11, weight: .semibold))
                        Text("Customize")
                            .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(.cyan)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 7)
                    .background(
                        Capsule()
                            .fill(Color.cyan.opacity(0.12))
                            .overlay(
                                Capsule()
                                    .stroke(Color.cyan.opacity(0.25), lineWidth: 1)
                            )
                    )
                }
                .contextualTooltip(
                    message: "Tap here to customize your widgets",
                    isShowing: showCustomizeTooltip,
                    arrowPosition: .top,
                    accentColor: .cyan,
                    onDismiss: {
                        showCustomizeTooltip = false
                        OnboardingManager.shared.markCustomizeTooltipSeen()
                    }
                )

                Spacer()
            }
            .sheet(isPresented: $showingDatePicker) {
                DatePickerSheet(selectedDate: $selectedDate)
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Metrics Grid Section

struct MetricsGridSection: View {
    @ObservedObject var model: RecoveryGraphModel
    @ObservedObject var sleepModel: DailySleepViewModel
    @ObservedObject var configManager: MetricConfigurationManager
    @Binding var expandedMetric: MetricType?
    @Namespace private var animation

    var body: some View {
        ZStack {
            if expandedMetric == nil {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], alignment: .leading, spacing: 12) {
            if configManager.isEnabled(.hrv) {
                GridItemView(
                    symbolName: "waveform.path.ecg",
                    title: "Avg HRV",
                    value: "\(model.lastKnownHRV)",
                    unit: "ms",
                    metricType: .hrv,
                    model: model,
                    expandedMetric: $expandedMetric,
                    namespace: animation
                )
            }

            if configManager.isEnabled(.spo2) {
                GridItemView(
                    symbolName: "drop",
                    title: "Blood Oxygen",
                    value: formatSPO2Value(model.mostRecentSPO2),
                    unit: "%",
                    metricType: .spo2,
                    model: model,
                    expandedMetric: $expandedMetric,
                    namespace: animation
                )
            }

            if configManager.isEnabled(.respiratoryRate) {
                GridItemView(
                    symbolName: "lungs",
                    title: "Respiratory Rate",
                    value: formatRespRateValue(model.mostRecentRespiratoryRate),
                    unit: "BrPM",
                    metricType: .respiratoryRate,
                    model: model,
                    expandedMetric: $expandedMetric,
                    namespace: animation
                )
            }

            if configManager.isEnabled(.calories) {
                GridItemView(
                    symbolName: "flame",
                    title: "Calories Burned",
                    value: formatTotalCaloriesValue(model.mostRecentActiveCalories, model.mostRecentRestingCalories),
                    unit: "kcal",
                    metricType: .calories,
                    model: model,
                    expandedMetric: $expandedMetric,
                    namespace: animation
                )
            }

            if configManager.isEnabled(.vo2Max) {
                GridItemView(
                    symbolName: "lungs",
                    title: "VO2 Max",
                    value: String(format: "%.1f", model.mostRecentVO2Max ?? 0.0),
                    unit: "ml/kg/min",
                    metricType: .vo2Max,
                    model: model,
                    expandedMetric: $expandedMetric,
                    namespace: animation
                )
            }

            if configManager.isEnabled(.deepSleep) {
                GridItemView(
                    symbolName: "bed.double.fill",
                    title: "Deep Sleep",
                    value: sleepModel.totalDeepSleep,
                    unit: "hrs",
                    metricType: .deepSleep,
                    model: model,
                    expandedMetric: $expandedMetric,
                    namespace: animation
                )
            }

            if configManager.isEnabled(.remSleep) {
                GridItemView(
                    symbolName: "moon.stars.fill",
                    title: "REM Sleep",
                    value: sleepModel.totalRemSleep,
                    unit: "hrs",
                    metricType: .remSleep,
                    model: model,
                    expandedMetric: $expandedMetric,
                    namespace: animation
                )
            }

            if configManager.isEnabled(.coreSleep) {
                GridItemView(
                    symbolName: "moon.fill",
                    title: "Core Sleep",
                    value: sleepModel.totalCoreSleep,
                    unit: "hrs",
                    metricType: .coreSleep,
                    model: model,
                    expandedMetric: $expandedMetric,
                    namespace: animation
                )
            }
        }
            }  // Close expandedMetric == nil

            // Show expanded view when a metric is tapped
            if let metric = expandedMetric {
                ExpandedGridItemView(
                    symbolName: iconFor(metric),
                    title: titleFor(metric),
                    value: valueFor(metric),
                    unit: unitFor(metric),
                    metricType: metric,
                    model: model,
                    expandedMetric: $expandedMetric,
                    namespace: animation
                )
                .transition(.asymmetric(
                    insertion: .identity,
                    removal: .identity
                ))
                .zIndex(1)
            }
        }  // Close ZStack
        .animation(.spring(response: 0.6, dampingFraction: 0.85), value: expandedMetric)
    }

    private func formatSPO2Value(_ spo2: Double?) -> String {
        guard let spo2 = spo2 else { return "N/A" }
        return String(format: "%.0f", spo2 * 100)
    }

    private func formatTotalCaloriesValue(_ activeCalories: Double?, _ restingCalories: Double?) -> String {
        let totalCalories = (activeCalories ?? 0) + (restingCalories ?? 0)
        return totalCalories > 0 ? String(format: "%.0f", totalCalories) : "0"
    }

    private func formatRespRateValue(_ respRate: Double?) -> String {
        guard let respRate = respRate else { return "N/A" }
        return String(format: "%.1f", respRate)
    }

    private func iconFor(_ metric: MetricType) -> String {
        switch metric {
        case .hrv: return "waveform.path.ecg"
        case .rhr: return "arrow.down.heart"
        case .spo2: return "drop"
        case .respiratoryRate: return "lungs"
        case .calories: return "flame"
        case .steps: return "figure.walk"
        case .vo2Max: return "lungs"
        case .deepSleep: return "bed.double.fill"
        case .remSleep: return "moon.stars.fill"
        case .coreSleep: return "moon.fill"
        case .exertion: return "flame.fill"
        }
    }

    private func titleFor(_ metric: MetricType) -> String {
        switch metric {
        case .hrv: return "Avg HRV"
        case .rhr: return "Avg RHR"
        case .spo2: return "Blood Oxygen"
        case .respiratoryRate: return "Respiratory Rate"
        case .calories: return "Calories Burned"
        case .steps: return "Steps"
        case .vo2Max: return "VO2 Max"
        case .deepSleep: return "Deep Sleep"
        case .remSleep: return "REM Sleep"
        case .coreSleep: return "Core Sleep"
        case .exertion: return "Exertion"
        }
    }

    private func valueFor(_ metric: MetricType) -> String {
        switch metric {
        case .hrv: return "\(model.lastKnownHRV)"
        case .rhr: return "\(model.mostRecentRestingHeartRate ?? 0)"
        case .spo2: return formatSPO2Value(model.mostRecentSPO2)
        case .respiratoryRate: return formatRespRateValue(model.mostRecentRespiratoryRate)
        case .calories: return formatTotalCaloriesValue(model.mostRecentActiveCalories, model.mostRecentRestingCalories)
        case .steps: return "\(model.mostRecentSteps.map(Int.init) ?? 0)"
        case .vo2Max: return String(format: "%.1f", model.mostRecentVO2Max ?? 0.0)
        case .deepSleep: return sleepModel.totalDeepSleep
        case .remSleep: return sleepModel.totalRemSleep
        case .coreSleep: return sleepModel.totalCoreSleep
        case .exertion: return "N/A" // Exertion uses dedicated widget
        }
    }

    private func unitFor(_ metric: MetricType) -> String {
        switch metric {
        case .hrv: return "ms"
        case .rhr: return "bpm"
        case .spo2: return "%"
        case .respiratoryRate: return "BrPM"
        case .calories: return "kcal"
        case .steps: return "steps"
        case .vo2Max: return "ml/kg/min"
        case .deepSleep: return "hrs"
        case .remSleep: return "hrs"
        case .coreSleep: return "hrs"
        case .exertion: return ""
        }
    }
}

// MARK: - Expanded Metric Overlay

struct ExpandedMetricOverlay: View {
    let metric: MetricType
    @Binding var expandedMetric: MetricType?
    @ObservedObject var recoveryModel: RecoveryGraphModel
    @ObservedObject var sleepModel: DailySleepViewModel
    @Namespace private var animation

    var body: some View {
        VStack {
            switch metric {
            case .steps:
                StepsDetailView(model: recoveryModel)
            case .hrv:
                HRVDetailView(model: recoveryModel)
            case .rhr:
                RHRDetailView(model: recoveryModel)
            case .spo2:
                SpO2DetailView(model: recoveryModel)
            case .respiratoryRate:
                RespiratoryRateDetailView(model: recoveryModel)
            case .calories:
                CaloriesDetailView(model: recoveryModel)
            case .vo2Max:
                VO2MaxDetailView(model: recoveryModel)
            case .deepSleep, .remSleep, .coreSleep:
                VStack(alignment: .leading, spacing: 16) {
                    Text("Sleep stage data")
                        .font(.title2)
                        .bold()
                        .foregroundColor(.white)

                    Text("View detailed sleep analysis in the Sleep section")
                        .foregroundColor(.white.opacity(0.7))
                }
                .padding()
            case .exertion:
                // Exertion has its own dedicated widget with expanded state
                EmptyView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(red: 0.08, green: 0.18, blue: 0.28))
        .overlay(alignment: .topTrailing) {
            // Close button
            Button(action: {
                withAnimation(.spring(response: 0.6, dampingFraction: 0.85)) {
                    expandedMetric = nil
                }
            }) {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 32))
                    .foregroundColor(.white.opacity(0.8))
                    .padding()
            }
        }
        .transition(.asymmetric(
            insertion: .opacity.combined(with: .scale(scale: 0.95)),
            removal: .opacity
        ))
    }
}

// MARK: - Modern Widget Card Styling System
// Based on 2024-2025 UX trends: Glassmorphism, Bento Box, Material You, Variable Hierarchy

enum WidgetCardStyle {
    case hero           // Primary interactive widget (Wellness)
    case success        // Achievement/completion widget (Completed Habits)
    case medical        // Health tracking widget (Medications)
    case healthData     // Biometric data widget (Heart Rate)
    case activity       // Movement data widget (Steps)

    var cornerRadius: CGFloat {
        switch self {
        case .hero: return 22
        case .success: return 18
        case .medical: return 16
        case .healthData: return 20  // Larger, softer for biometric data
        case .activity: return 14     // Tighter, more energetic
        }
    }

    var backgroundGradient: LinearGradient {
        switch self {
        case .hero:
            return LinearGradient(
                colors: [
                    Color.white.opacity(0.14),
                    Color.white.opacity(0.08),
                    Color.cyan.opacity(0.06)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .success:
            return LinearGradient(
                colors: [
                    Color.green.opacity(0.12),
                    Color.white.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .medical:
            return LinearGradient(
                colors: [
                    Color.blue.opacity(0.08),
                    Color.white.opacity(0.07)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .healthData:
            // Diagonal gradient with red accent for vital signs
            return LinearGradient(
                colors: [
                    Color.red.opacity(0.12),
                    Color.white.opacity(0.10),
                    Color.red.opacity(0.06),
                    Color.white.opacity(0.08)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .activity:
            // Dual-tone split background for dynamic movement feel
            return LinearGradient(
                colors: [
                    Color.cyan.opacity(0.14),
                    Color.cyan.opacity(0.10),
                    Color.green.opacity(0.08),
                    Color.white.opacity(0.08)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
    }

    var borderGradient: LinearGradient {
        switch self {
        case .hero:
            return LinearGradient(
                colors: [
                    Color.cyan.opacity(0.4),
                    Color.purple.opacity(0.25),
                    Color.white.opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .success:
            return LinearGradient(
                colors: [
                    Color.green.opacity(0.35),
                    Color.green.opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .medical:
            return LinearGradient(
                colors: [
                    Color.blue.opacity(0.25),
                    Color.cyan.opacity(0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .healthData:
            // Thin, vibrant red border for vital signs emphasis
            return LinearGradient(
                colors: [
                    Color.red.opacity(0.6),
                    Color.red.opacity(0.45),
                    Color.red.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        case .activity:
            // Energetic cyan-to-green gradient border
            return LinearGradient(
                colors: [
                    Color.cyan.opacity(0.5),
                    Color.green.opacity(0.4),
                    Color.cyan.opacity(0.3)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        }
    }

    var borderWidth: CGFloat {
        switch self {
        case .hero: return 1.5
        case .success: return 1.3
        case .medical: return 1.0
        case .healthData: return 1.8  // Thin but vibrant red border
        case .activity: return 2.0     // Bolder border for energy
        }
    }

    var shadowConfiguration: (color: Color, radius: CGFloat, y: CGFloat) {
        switch self {
        case .hero:
            return (Color.cyan.opacity(0.25), 12, 6)
        case .success:
            return (Color.green.opacity(0.15), 8, 4)
        case .medical:
            return (Color.blue.opacity(0.10), 6, 3)
        case .healthData:
            // Subtle red glow for vital signs
            return (Color.red.opacity(0.20), 10, 5)
        case .activity:
            // Energetic cyan-green glow
            return (Color.cyan.opacity(0.18), 12, 5)
        }
    }

    var innerShadow: Bool {
        switch self {
        case .hero: return true
        default: return false
        }
    }

    // Accent decorations for visual distinction
    var hasAccentBar: Bool {
        switch self {
        default: return false
        }
    }

    var accentBarColor: LinearGradient {
        switch self {
        case .healthData:
            return LinearGradient(
                colors: [
                    Color.red.opacity(0.7),
                    Color.red.opacity(0.4)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        case .activity:
            return LinearGradient(
                colors: [
                    Color.cyan.opacity(0.6),
                    Color.green.opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        default:
            return LinearGradient(colors: [.clear], startPoint: .top, endPoint: .bottom)
        }
    }
}

struct ModernWidgetCardStyle: ViewModifier {
    let style: WidgetCardStyle

    func body(content: Content) -> some View {
        content
            .background(
                ZStack {
                    // Main background with gradient
                    RoundedRectangle(cornerRadius: style.cornerRadius)
                        .fill(style.backgroundGradient)

                    // Inner glow for hero cards
                    if style.innerShadow {
                        RoundedRectangle(cornerRadius: style.cornerRadius)
                            .fill(
                                RadialGradient(
                                    colors: [
                                        Color.white.opacity(0.08),
                                        Color.clear
                                    ],
                                    center: .topLeading,
                                    startRadius: 0,
                                    endRadius: 200
                                )
                            )
                    }

                    // Accent bar for distinctive widgets
                    if style.hasAccentBar {
                        HStack(spacing: 0) {
                            RoundedRectangle(cornerRadius: style.cornerRadius)
                                .fill(style.accentBarColor)
                                .frame(width: 4)

                            Spacer()
                        }
                    }
                }
                .overlay(
                    RoundedRectangle(cornerRadius: style.cornerRadius)
                        .stroke(style.borderGradient, lineWidth: style.borderWidth)
                )
                .shadow(
                    color: style.shadowConfiguration.color,
                    radius: style.shadowConfiguration.radius,
                    x: 0,
                    y: style.shadowConfiguration.y
                )
            )
    }
}

// MARK: - Readiness Widget

struct ReadinessWidget: View {
    let readinessScore: Int
    let action: () -> Void

    @State private var isPressed = false

    private var scoreColor: Color {
        if readinessScore >= 80 {
            return .green
        } else if readinessScore >= 60 {
            return .yellow
        } else if readinessScore >= 40 {
            return .orange
        } else if readinessScore > 0 {
            return .red
        } else {
            return .gray
        }
    }

    private var statusText: String {
        if readinessScore == 0 {
            return "No data"
        } else if readinessScore >= 80 {
            return "Prime condition"
        } else if readinessScore >= 60 {
            return "Ready to train"
        } else if readinessScore >= 40 {
            return "Take it easy"
        } else {
            return "Prioritize recovery"
        }
    }

    private var actionableMessage: String {
        if readinessScore == 0 {
            return "Connect Apple Watch to track recovery metrics"
        } else if readinessScore >= 80 {
            return "Your body is fully recovered - perfect for intense training"
        } else if readinessScore >= 60 {
            return "Good recovery - you can handle moderate to high intensity"
        } else if readinessScore >= 40 {
            return "Partial recovery - stick to light to moderate activity"
        } else {
            return "Low recovery - focus on rest and light movement only"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack(alignment: .center, spacing: 12) {
                    ZStack {
                        // Pulse effect when ready
                        if readinessScore >= 80 {
                            Circle()
                                .stroke(scoreColor.opacity(0.3), lineWidth: 2)
                                .frame(width: 40, height: 40)
                        }

                        Circle()
                            .fill(scoreColor.opacity(0.2))
                            .frame(width: 40, height: 40)

                        Image(systemName: readinessScore >= 80 ? "bolt.circle.fill" : "bolt.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(scoreColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Readiness")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))

                        HStack(alignment: .firstTextBaseline, spacing: 6) {
                            Text(readinessScore > 0 ? "\(readinessScore)" : "--")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)

                            if readinessScore > 0 {
                                Text("/ 100")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }

                    Spacer()

                    // Status badge
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(statusText)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(scoreColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(scoreColor.opacity(0.15))
                                    .overlay(
                                        Capsule()
                                            .stroke(scoreColor.opacity(0.3), lineWidth: 1)
                                    )
                            )
                    }
                }

                // Recommendation card
                HStack(spacing: 10) {
                    Image(systemName: readinessScore == 0 ? "applewatch" : "lightbulb.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(readinessScore == 0 ? .gray : .cyan)

                    Text(actionableMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    readinessScore == 0 ? Color.gray.opacity(0.3) : Color.cyan.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                )

                // Contributing factors (if we have data)
                if readinessScore > 0 {
                    VStack(spacing: 6) {
                        Text("Based on:")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 12) {
                            FactorPill(icon: "waveform.path.ecg", label: "HRV", color: .cyan)
                            FactorPill(icon: "heart.fill", label: "RHR", color: .red)
                            FactorPill(icon: "bed.double.fill", label: "Sleep", color: .purple)
                        }
                    }
                }
            }
            .padding(16)
            .background(
                ZStack {
                    GeometryReader { geo in
                        Image(systemName: "bolt.fill")
                            .font(.system(size: 60, weight: .ultraLight))
                            .foregroundColor(scoreColor.opacity(0.04))
                            .rotationEffect(.degrees(-15))
                            .offset(x: geo.size.width - 50, y: 10)
                    }
                }
            )
            .modernWidgetCard(style: .hero)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Sleep Widget

struct SleepWidget: View {
    let sleepDuration: String?
    let action: () -> Void

    @State private var isPressed = false

    private var sleepHours: Double {
        guard let duration = sleepDuration,
              let hours = Double(duration) else {
            return 0
        }
        return hours
    }

    private var scoreColor: Color {
        if sleepHours >= 7.5 {
            return .purple
        } else if sleepHours >= 6.5 {
            return .blue
        } else if sleepHours >= 5.5 {
            return .yellow
        } else if sleepHours > 0 {
            return .orange
        } else {
            return .gray
        }
    }

    private var statusText: String {
        if sleepHours == 0 {
            return "No data"
        } else if sleepHours >= 7.5 {
            return "Excellent"
        } else if sleepHours >= 6.5 {
            return "Good"
        } else if sleepHours >= 5.5 {
            return "Fair"
        } else {
            return "Poor"
        }
    }

    private var actionableMessage: String {
        if sleepHours == 0 {
            return "Wear Apple Watch to bed to track sleep stages and quality"
        } else if sleepHours >= 7.5 {
            return "Great sleep duration - your body is well-rested"
        } else if sleepHours >= 6.5 {
            return "Decent sleep - try to add 30-60 more minutes tonight"
        } else if sleepHours >= 5.5 {
            return "Below optimal - prioritize getting more sleep tonight"
        } else {
            return "Insufficient sleep - recovery will be impacted"
        }
    }

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 14) {
                // Header
                HStack(alignment: .center, spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(scoreColor.opacity(0.2))
                            .frame(width: 40, height: 40)

                        Image(systemName: sleepHours >= 7.5 ? "bed.double.circle.fill" : "bed.double.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(scoreColor)
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sleep")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.7))

                        HStack(alignment: .firstTextBaseline, spacing: 4) {
                            Text(sleepHours > 0 ? String(format: "%.1f", sleepHours) : "--")
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)

                            if sleepHours > 0 {
                                Text("hours")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.5))
                            }
                        }
                    }

                    Spacer()

                    // Status badge
                    VStack(alignment: .trailing, spacing: 4) {
                        Text(statusText)
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(scoreColor)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 5)
                            .background(
                                Capsule()
                                    .fill(scoreColor.opacity(0.15))
                                    .overlay(
                                        Capsule()
                                            .stroke(scoreColor.opacity(0.3), lineWidth: 1)
                                    )
                            )

                        if sleepHours > 0 {
                            Text("of 8h goal")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.white.opacity(0.5))
                        }
                    }
                }

                // Progress bar showing sleep vs goal
                if sleepHours > 0 {
                    GeometryReader { geometry in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(Color.white.opacity(0.1))
                                .frame(height: 10)

                            RoundedRectangle(cornerRadius: 6)
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            scoreColor,
                                            scoreColor.opacity(0.7)
                                        ]),
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .frame(width: geometry.size.width * min(sleepHours / 8.0, 1.0), height: 10)
                        }
                    }
                    .frame(height: 10)
                }

                // Recommendation card
                HStack(spacing: 10) {
                    Image(systemName: sleepHours == 0 ? "applewatch" : "moon.stars.fill")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(sleepHours == 0 ? .gray : .indigo)

                    Text(actionableMessage)
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.white.opacity(0.9))
                        .lineLimit(2)
                        .fixedSize(horizontal: false, vertical: true)
                }
                .padding(12)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 10)
                                .stroke(
                                    sleepHours == 0 ? Color.gray.opacity(0.3) : Color.indigo.opacity(0.3),
                                    lineWidth: 1
                                )
                        )
                )

                // Sleep stages preview (if we have data)
                if sleepHours > 0 {
                    VStack(spacing: 6) {
                        Text("Tap to view sleep stages:")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))
                            .frame(maxWidth: .infinity, alignment: .leading)

                        HStack(spacing: 12) {
                            FactorPill(icon: "bed.double.fill", label: "Deep", color: .indigo)
                            FactorPill(icon: "moon.stars.fill", label: "REM", color: .purple)
                            FactorPill(icon: "moon.fill", label: "Core", color: .blue)
                        }
                    }
                }
            }
            .padding(16)
            .background(
                ZStack {
                    GeometryReader { geo in
                        Image(systemName: "moon.stars.fill")
                            .font(.system(size: 60, weight: .ultraLight))
                            .foregroundColor(scoreColor.opacity(0.04))
                            .rotationEffect(.degrees(-15))
                            .offset(x: geo.size.width - 50, y: 10)
                    }
                }
            )
            .modernWidgetCard(style: .hero)
            .scaleEffect(isPressed ? 0.98 : 1.0)
        }
        .buttonStyle(PlainButtonStyle())
        .onLongPressGesture(minimumDuration: 0.0, maximumDistance: .infinity, pressing: { pressing in
            withAnimation(.easeInOut(duration: 0.1)) {
                isPressed = pressing
            }
        }, perform: {})
    }
}

// MARK: - Helper Views

struct FactorPill: View {
    let icon: String
    let label: String
    let color: Color

    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(color)

            Text(label)
                .font(.system(size: 11, weight: .medium))
                .foregroundColor(.white.opacity(0.8))
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(
            Capsule()
                .fill(Color.white.opacity(0.08))
                .overlay(
                    Capsule()
                        .stroke(color.opacity(0.3), lineWidth: 1)
                )
        )
    }
}

extension View {
    func modernWidgetCard(style: WidgetCardStyle) -> some View {
        self.modifier(ModernWidgetCardStyle(style: style))
    }
}
