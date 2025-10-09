import SwiftUI
import CoreData

struct DailyView: View {
    // Data Models
    @ObservedObject var recoveryModel: RecoveryGraphModel
    @ObservedObject var exertionModel: ExertionModel
    @ObservedObject var sleepModel: DailySleepViewModel

    var appleWorkoutsService: AppleWorkoutsService

    @State private var selectedDate: Date = Date()

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
                            if success {
                                showEmptyState = false
                                OnboardingManager.shared.markDailyTabSeen()
                                recoveryModel.pullAllRecoveryData(forDate: selectedDate)
                                exertionModel.fetchExertionScoreAndTimes(forDate: selectedDate)
                                sleepModel.fetchSleepData(forDate: selectedDate)
                            }
                        }
                    },
                    onDismiss: {
                        showEmptyState = false
                        OnboardingManager.shared.markDailyTabSeen()
                        showMetricTooltip = true
                    }
                )
            } else {
                ScrollView {
                HeaderView(model: recoveryModel, selectedDate: $selectedDate, showingMetricConfig: $showingMetricConfig)
                    .padding(.top)
                    .padding(.bottom, 5)
                    .padding(.leading,10)

                HeroScoresView(
                    exertionScore: exertionModel.exertionScore,
                    sleepScore: sleepModel.sleepScore,
                    readinessScore: recoveryModel.recoveryScores.last ?? 0,
                    calculatedUpperBound: calculatedUpperBoundDailyView,
                    onExertionTap: {
                        triggerHapticFeedback()
                        showingExertionPopover = true
                    },
                    onSleepTap: {
                        triggerHapticFeedback()
                        showingSleepPopover = true
                    },
                    onReadinessTap: {
                        triggerHapticFeedback()
                        showingRecoveryPopover = true
                    }
                )
                .padding(.horizontal)
                .padding(.bottom, 8)

                DailyGridMetrics(model: recoveryModel, configManager: metricConfig, expandedMetric: $expandedMetric)
                    .contextualTooltip(
                        message: "Tap any metric to see detailed history and trends",
                        isShowing: showMetricTooltip,
                        arrowPosition: .top,
                        accentColor: .cyan,
                        onDismiss: {
                            showMetricTooltip = false
                            OnboardingManager.shared.markMetricTooltipSeen()
                        }
                    )
                    .padding(.bottom, 20)
            }
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
                // Only request HealthKit if user has already dismissed the empty state
                // This means they've either granted permission or chosen to skip
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

    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(alignment: .top) {
                Text("Daily Summary")
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
                            .foregroundColor(.cyan)
                    }
                }
            }

            HStack {
                Button(action: {
                    showingMetricConfig = true
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 12, weight: .semibold))
                        Text("Customize Metrics")
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

                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .labelsHidden()
                    .colorScheme(.dark)
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
    @ObservedObject var configManager: MetricConfigurationManager
    @Binding var expandedMetric: MetricType?
    @Namespace private var animation

    var body: some View {
        ZStack {
            if expandedMetric == nil {
                // Grid layout when nothing is expanded
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

                    if configManager.isEnabled(.rhr) {
                        GridItemView(
                            symbolName: "arrow.down.heart",
                            title: "Avg RHR",
                            value: "\(model.mostRecentRestingHeartRate ?? 0)",
                            unit: "bpm",
                            metricType: .rhr,
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

                    if configManager.isEnabled(.steps) {
                        GridItemView(
                            symbolName: "figure.walk",
                            title: "Steps",
                            value: "\(model.mostRecentSteps.map(Int.init) ?? 0)",
                            unit: "steps",
                            metricType: .steps,
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
        .padding([.horizontal, .top])
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
            RHRDetailView(model: model)
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
        }
    }
}

struct HeroScoresView: View {
    let exertionScore: Double
    let sleepScore: Double
    let readinessScore: Int
    let calculatedUpperBound: Double
    let onExertionTap: () -> Void
    let onSleepTap: () -> Void
    let onReadinessTap: () -> Void

    @ObservedObject var configManager = MetricConfigurationManager.shared

    private var enabledScores: [HeroScore] {
        HeroScore.allCases.filter { configManager.isEnabled($0) }
    }

    var body: some View {
        if enabledScores.isEmpty {
            EmptyView()
        } else if enabledScores.count == 1 {
            // Single score: Full width card
            scoreCard(for: enabledScores[0])
                .frame(maxWidth: .infinity)
        } else {
            // Multiple scores: Horizontal layout
            HStack(spacing: 12) {
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
                ScoreCardView(
                    title: "Exertion",
                    score: Int((exertionScore / calculatedUpperBound) * 100),
                    icon: "flame.fill",
                    color: .orange,
                    requiresAppleWatch: true,
                    action: onExertionTap
                )
            }
        case .quality:
            if configManager.isEnabled(.quality) {
                ScoreCardView(
                    title: "Quality",
                    score: Int(sleepScore),
                    icon: "moon.fill",
                    color: .yellow,
                    requiresAppleWatch: true,
                    action: onSleepTap
                )
            }
        case .readiness:
            if configManager.isEnabled(.readiness) {
                ScoreCardView(
                    title: "Readiness",
                    score: readinessScore,
                    icon: "bolt.fill",
                    color: .green,
                    requiresAppleWatch: true,
                    action: onReadinessTap
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
