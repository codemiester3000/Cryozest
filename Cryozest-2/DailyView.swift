import SwiftUI
import CoreData

struct DailyView: View {
    // Data Models
    @ObservedObject var recoveryModel: RecoveryGraphModel
    @ObservedObject var exertionModel: ExertionModel
    @ObservedObject var sleepModel: DailySleepViewModel

    var appleWorkoutsService: AppleWorkoutsService

    @State private var selectedDate: Date = Date()
    @State private var dragOffset: CGFloat = 0

    @State private var showingExertionPopover = false
    @State private var showingRecoveryPopover = false
    @State private var showingSleepPopover = false
    @State private var showingMetricConfig = false
    @State private var calculatedUpperBound: Double = 8.0
    @ObservedObject var metricConfig = MetricConfigurationManager.shared

    // Metric expansion state
    @State private var expandedMetric: MetricType? = nil

    // Onboarding state
    @State private var showEmptyState = false
    @State private var showMetricTooltip = false

    // Widget reordering
    @StateObject private var widgetOrderManager = WidgetOrderManager.shared
    @State private var isReorderMode = false
    @State private var draggedWidget: DailyWidgetSection?
    @State private var lastMoveTimestamp: Date = Date()

    private var visibleWidgets: [DailyWidgetSection] {
        widgetOrderManager.widgetOrder.filter { shouldShowWidget($0) }
    }

    private func moveWidget(from: DailyWidgetSection, to: DailyWidgetSection) {
        // Throttle rapid moves
        let now = Date()
        if now.timeIntervalSince(lastMoveTimestamp) < 0.1 {
            return
        }
        lastMoveTimestamp = now

        print("🔄 moveWidget called: \(from.rawValue) → \(to.rawValue)")

        guard let fromIndex = widgetOrderManager.widgetOrder.firstIndex(of: from),
              let toIndex = widgetOrderManager.widgetOrder.firstIndex(of: to) else {
            print("❌ Could not find indices")
            return
        }

        print("📍 Indices: from=\(fromIndex), to=\(toIndex)")
        guard fromIndex != toIndex else {
            print("⚠️ Same position, skipping")
            return
        }

        // Update immediately for live feedback
        var newOrder = widgetOrderManager.widgetOrder
        let movedWidget = newOrder.remove(at: fromIndex)

        // Adjust insertion index
        let adjustedToIndex = fromIndex < toIndex ? toIndex - 1 : toIndex
        print("📌 Inserting at adjusted index: \(adjustedToIndex)")
        newOrder.insert(movedWidget, at: adjustedToIndex)

        print("🔢 New order: \(newOrder.map { $0.rawValue })")

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
                selectedDate = previousDay
            }
            triggerHapticFeedback()
        }
    }

    private func goToNextDay() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let currentDay = calendar.startOfDay(for: selectedDate)

        // Only navigate forward if not already at today
        if currentDay < today {
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: selectedDate) {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                    selectedDate = nextDay
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

    @ViewBuilder
    private func widgetView(for section: DailyWidgetSection) -> some View {
        switch section {
        case .wellnessCheckIn:
            WellnessCheckInCard(selectedDate: $selectedDate)
                .modifier(ReorderableWidgetModifier(
                    section: section,
                    isReorderMode: isReorderMode,
                    draggedWidget: $draggedWidget,
                    onLongPress: { isReorderMode = true }
                ))

        case .completedHabits:
            CompletedHabitsCard(selectedDate: $selectedDate)
                .modifier(ReorderableWidgetModifier(
                    section: section,
                    isReorderMode: isReorderMode,
                    draggedWidget: $draggedWidget,
                    onLongPress: { isReorderMode = true }
                ))

        case .medications:
            if metricConfig.isEnabled(.medications) {
                MedicationsCard(selectedDate: $selectedDate)
                    .modifier(ReorderableWidgetModifier(
                        section: section,
                        isReorderMode: isReorderMode,
                        draggedWidget: $draggedWidget,
                        onLongPress: { isReorderMode = true }
                    ))
            }

        case .heroScores:
            HeroScoresView(
                exertionScore: exertionModel.exertionScore,
                readinessScore: recoveryModel.recoveryScores.last ?? 0,
                sleepDuration: recoveryModel.previousNightSleepDuration,
                calculatedUpperBound: calculatedUpperBoundDailyView,
                onExertionTap: {
                    triggerHapticFeedback()
                    showingExertionPopover = true
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
                onLongPress: { isReorderMode = true }
            ))

        case .largeSteps:
            if metricConfig.isEnabled(.steps) {
                LargeStepsWidget(
                    model: recoveryModel,
                    expandedMetric: $expandedMetric
                )
                .modifier(ReorderableWidgetModifier(
                    section: section,
                    isReorderMode: isReorderMode,
                    draggedWidget: $draggedWidget,
                    onLongPress: { isReorderMode = true }
                ))
            }

        case .largeHeartRate:
            if metricConfig.isEnabled(.heartRate) {
                LargeHeartRateWidget(
                    model: recoveryModel,
                    expandedMetric: $expandedMetric
                )
                .modifier(ReorderableWidgetModifier(
                    section: section,
                    isReorderMode: isReorderMode,
                    draggedWidget: $draggedWidget,
                    onLongPress: { isReorderMode = true }
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
                onLongPress: { isReorderMode = true }
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

            // Show empty state or content
            if showEmptyState {
                DailyEmptyStateView(
                    onEnableHealthKit: {
                        HealthKitManager.shared.requestAuthorization { success, error in
                            // Always mark as seen and hide empty state after permission request
                            showEmptyState = false
                            OnboardingManager.shared.markDailyTabSeen()

                            if success {
                                recoveryModel.pullAllRecoveryData(forDate: selectedDate)
                                exertionModel.fetchExertionScoreAndTimes(forDate: selectedDate)
                                sleepModel.fetchSleepData(forDate: selectedDate)
                            } else {
                                showMetricTooltip = true
                            }
                        }
                    }
                )
            } else {
                ZStack(alignment: .topTrailing) {
                    ScrollView {
                        VStack(spacing: 0) {
                            // Fixed header (title, customize, date selector)
                            DailyHeaderSection(
                                selectedDate: $selectedDate,
                                showingMetricConfig: $showingMetricConfig,
                                isToday: isToday
                            )
                            .padding(.top)
                            .padding(.leading, 10)
                            .padding(.bottom, 12)

                            // Reorderable widgets
                            VStack(spacing: 12) {
                                ForEach(visibleWidgets) { section in
                                    widgetView(for: section)
                                        .padding(.horizontal)
                                        .padding(.leading, 10)
                                        .onDrag {
                                            guard isReorderMode else { return NSItemProvider() }
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
                            .padding(.bottom, 12)
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
                                    .font(.system(size: 16, weight: .semibold, design: .rounded))
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
            .sheet(isPresented: $showingExertionPopover) {
                ExertionView(exertionModel: exertionModel, recoveryModel: recoveryModel)
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
                showEmptyState = true
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
            }
        }
        .onChange(of: selectedDate) { newValue in
            print("updated date: ", selectedDate)
            recoveryModel.pullAllRecoveryData(forDate: selectedDate)
            exertionModel.fetchExertionScoreAndTimes(forDate: selectedDate)
            sleepModel.fetchSleepData(forDate: selectedDate)
            // Any other actions needed when the date changes
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
                            .font(.system(size: 13, weight: .medium, design: .rounded))
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
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))

                        if isToday {
                            Text("Today")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
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
    @ObservedObject var configManager: MetricConfigurationManager
    @Binding var expandedMetric: MetricType?
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
                            expandedMetric: $expandedMetric
                        )
                    }

                    // Large Heart Rate Widget (full width)
                    if configManager.isEnabled(.heartRate) {
                        LargeHeartRateWidget(
                            model: model,
                            expandedMetric: $expandedMetric
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
        .padding(.horizontal)
        .padding(.top, 12)
        .padding(.leading, 10)
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
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .lineLimit(1)
                Spacer()
            }

            HStack(alignment: .lastTextBaseline, spacing: 3) {
                Text(value)
                    .font(.system(size: 24, weight: .bold, design: .rounded))
                    .foregroundColor(animate ? Color.cyan : .white)
                Text(unit)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
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
                                .font(.system(size: 14, weight: .medium, design: .rounded))
                                .foregroundColor(.white.opacity(0.7))

                            HStack(alignment: .lastTextBaseline, spacing: 3) {
                                Text(value)
                                    .font(.system(size: 28, weight: .bold, design: .rounded))
                                    .foregroundColor(.white)
                                Text(unit)
                                    .font(.system(size: 13, weight: .medium, design: .rounded))
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
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundColor(.white.opacity(0.9))

                Text("Tap on the Sleep hero card or visit the Sleep tab for detailed sleep analysis and trends.")
                    .font(.system(size: 14, weight: .regular, design: .rounded))
                    .foregroundColor(.white.opacity(0.7))
                    .lineSpacing(4)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
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
            if configManager.isEnabled(.exertion) {
                ExpandedHeroCard(
                    title: "Exertion",
                    score: Int((exertionScore / calculatedUpperBound) * 100),
                    icon: "flame.fill",
                    color: .orange,
                    subtitle: exertionScore > 0 ? String(format: "%.1f of %.1f target", exertionScore, calculatedUpperBound) : "No data today",
                    details: exertionScore > 0 ? [
                        ("Light", "\(Int(recoveryMinutes)) min", Color.teal),
                        ("Moderate", "\(Int(conditioningMinutes)) min", Color.green),
                        ("Intense", "\(Int(overloadMinutes)) min", Color.red)
                    ] : [],
                    requiresAppleWatch: true,
                    action: onExertionTap
                )
            }
        case .readiness:
            if configManager.isEnabled(.readiness) {
                ExpandedHeroCard(
                    title: "Readiness",
                    score: readinessScore,
                    icon: "bolt.fill",
                    color: .green,
                    subtitle: readinessScore > 0 ? "Ready to train" : "No data today",
                    details: [],
                    requiresAppleWatch: true,
                    action: onReadinessTap
                )
            }
        case .sleep:
            if configManager.isEnabled(.sleep) {
                ExpandedHeroCard(
                    title: "Sleep",
                    score: sleepDurationScore,
                    icon: "bed.double.fill",
                    color: .purple,
                    subtitle: sleepDuration != nil ? "\(sleepDuration!) hours" : "No data today",
                    details: [],
                    requiresAppleWatch: true,
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
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                // Title
                Text(title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
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

    var body: some View {
        Button(action: action) {
            HStack(spacing: 16) {
                // Left side: Icon and score
                VStack(spacing: 8) {
                    ZStack {
                        Circle()
                            .fill(color.opacity(0.2))
                            .frame(width: 56, height: 56)

                        Image(systemName: icon)
                            .font(.system(size: 24, weight: .semibold))
                            .foregroundColor(color)
                    }

                    Text("\(score)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .frame(width: 80)

                // Right side: Title, subtitle, and details
                VStack(alignment: .leading, spacing: 8) {
                    Text(title)
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Text(subtitle)
                        .font(.system(size: 13, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.6))

                    if !details.isEmpty {
                        HStack(spacing: 12) {
                            ForEach(details.indices, id: \.self) { index in
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(details[index].color)
                                        .frame(width: 6, height: 6)

                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(details[index].label)
                                            .font(.system(size: 10, weight: .medium, design: .rounded))
                                            .foregroundColor(.white.opacity(0.5))

                                        Text(details[index].value)
                                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }

                Spacer()

                // Chevron
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
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
                        .font(.system(size: 15, weight: .semibold, design: .rounded))
                        .foregroundColor(.white)

                    Spacer()

                    if hasNewData {
                        Circle()
                            .fill(color)
                            .frame(width: 8, height: 8)
                    }

                    Text("\(Int(progress * 100))%")
                        .font(.system(size: 16, weight: .bold, design: .rounded))
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
                        .font(.system(size: 24, weight: .bold, design: .rounded))
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
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
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
    let onLongPress: () -> Void

    @State private var wiggleOffset: CGFloat = 0

    func body(content: Content) -> some View {
        ZStack(alignment: .topTrailing) {
            content
                .opacity(isReorderMode && draggedWidget == section ? 0.5 : 1.0)
                .scaleEffect(isReorderMode && draggedWidget == section ? 0.95 : 1.0)
                .rotationEffect(.degrees(isReorderMode && draggedWidget != section ? wiggleOffset : 0))
                .animation(.spring(response: 0.3), value: isReorderMode)
                .animation(.spring(response: 0.3), value: draggedWidget)
                .onLongPressGesture(minimumDuration: 0.5) {
                    let generator = UIImpactFeedbackGenerator(style: .medium)
                    generator.impactOccurred()
                    onLongPress()
                }
                .onChange(of: isReorderMode) { newValue in
                    if newValue {
                        startWiggling()
                    } else {
                        stopWiggling()
                    }
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
        let randomOffset = Double.random(in: 0...0.5)

        withAnimation(
            Animation.easeInOut(duration: 0.15)
                .repeatForever(autoreverses: true)
                .delay(randomOffset)
        ) {
            wiggleOffset = 1.5
        }
    }

    private func stopWiggling() {
        withAnimation(.spring(response: 0.3)) {
            wiggleOffset = 0
        }
    }
}

// MARK: - Widget Drop Delegate

struct WidgetDropDelegate: DropDelegate {
    @Binding var draggedWidget: DailyWidgetSection?
    let currentWidget: DailyWidgetSection
    let onMove: (DailyWidgetSection, DailyWidgetSection) -> Void

    func performDrop(info: DropInfo) -> Bool {
        guard draggedWidget != nil else { return false }
        draggedWidget = nil
        return true
    }

    func dropEntered(info: DropInfo) {
        guard let draggedWidget = draggedWidget else { return }
        guard draggedWidget != currentWidget else { return }

        onMove(draggedWidget, currentWidget)
    }
}

// MARK: - Daily Header Section

struct DailyHeaderSection: View {
    @Binding var selectedDate: Date
    @Binding var showingMetricConfig: Bool
    let isToday: Bool

    @State private var showingDatePicker = false

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
                            .font(.system(size: 13, weight: .medium, design: .rounded))
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

                // Date indicator
                Button(action: {
                    showingDatePicker = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white.opacity(0.5))

                        Text(dateFormatter.string(from: selectedDate))
                            .font(.system(size: 14, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))

                        if isToday {
                            Text("Today")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
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
}
