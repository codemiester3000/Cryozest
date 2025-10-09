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

            ScrollView {
                HeaderView(model: recoveryModel, selectedDate: $selectedDate, showingMetricConfig: $showingMetricConfig)
                    .padding(.top)
                    .padding(.bottom, 5)
                    .padding(.leading,10)

                DailyGridMetrics(model: recoveryModel, configManager: metricConfig)
            
            VStack(alignment: .leading, spacing: 10) {
                ProgressButtonView(
                    title: "Daily Exertion",
                    progress: Float(exertionModel.exertionScore / calculatedUpperBoundDailyView),
                    color: Color.orange,
                    action: {
                        triggerHapticFeedback()
                        showingExertionPopover = true
                    }
                )
                .popover(isPresented: $showingExertionPopover) {
                    ExertionView(exertionModel: exertionModel, recoveryModel: recoveryModel)
                }
                
                ProgressButtonView(
                    title: "Sleep Quality",
                    progress: Float(sleepModel.sleepScore / 100),
                    color: Color.yellow,
                    action: {
                        triggerHapticFeedback()
                        showingSleepPopover = true
                    }
                )
                .popover(isPresented: $showingSleepPopover) {
                    DailySleepView(dailySleepModel: sleepModel)
                }
                
                // TODO: (owen) THIS ONE isn't updating automatically
                // TODO: instead of checking .last get the index based on the selected day
                ProgressButtonView(
                    title: "Readiness to Train",
                    progress: Float(recoveryModel.recoveryScores.last ?? 0) / 100.0,
                    color: Color.green,
                    action: {
                        triggerHapticFeedback()
                        showingRecoveryPopover = true
                    }
                )
                .popover(isPresented: $showingRecoveryPopover) {
                    RecoveryCardView(model: recoveryModel)
                }
            }
            .padding(.horizontal,22)
            .padding(.top, 10)
            }
            .refreshable {
                recoveryModel.pullAllRecoveryData(forDate: selectedDate)
                exertionModel.fetchExertionScoreAndTimes(forDate: selectedDate)
                sleepModel.fetchSleepData(forDate: selectedDate)
            }
            .sheet(isPresented: $showingMetricConfig) {
                MetricConfigurationView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear() {
            HealthKitManager.shared.requestAuthorization { success, error in
                if success {
                    HealthKitManager.shared.areHealthMetricsAuthorized() { isAuthorized in
                        recoveryModel.pullAllRecoveryData(forDate: selectedDate)
                        exertionModel.fetchExertionScoreAndTimes(forDate: selectedDate)
                        sleepModel.fetchSleepData(forDate: selectedDate)
                        
                        appleWorkoutsService.fetchAndSaveWorkouts()
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
            HStack {
                VStack(alignment: .leading) {
                    Text("Daily Summary")
                        .font(.title2)
                        .fontWeight(.semibold)
                        .foregroundColor(.white)

                    if let lastRefreshDate = model.lastDataRefresh {
                        HStack(spacing: 2) {
                            Text("Updated HealthKit data:")
                                .font(.caption)
                                .foregroundColor(.gray)

                            Text("\(lastRefreshDate, formatter: dateFormatter)")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                }

                Spacer()

                DatePicker("", selection: $selectedDate, displayedComponents: .date)
                    .labelsHidden()
                    .colorScheme(.dark)
            }

            // Settings button for metric configuration
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

    let columns: [GridItem] = Array(repeating: .init(.flexible(minimum: 150)), count: 2)

    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 12) {
            if configManager.isEnabled(.hrv) {
                GridItemView(
                    symbolName: "waveform.path.ecg",
                    title: "Avg HRV",
                    value: "\(model.lastKnownHRV)",
                    unit: "ms"
                )
            }

            if configManager.isEnabled(.rhr) {
                GridItemView(
                    symbolName: "arrow.down.heart",
                    title: "Avg RHR",
                    value: "\(model.mostRecentRestingHeartRate ?? 0)",
                    unit: "bpm"
                )
            }

            if configManager.isEnabled(.spo2) {
                GridItemView(
                    symbolName: "drop",
                    title: "Blood Oxygen",
                    value: formatSPO2Value(model.mostRecentSPO2),
                    unit: "%"
                )
            }

            if configManager.isEnabled(.respiratoryRate) {
                GridItemView(
                    symbolName: "lungs",
                    title: "Respiratory Rate",
                    value: formatRespRateValue(model.mostRecentRespiratoryRate),
                    unit: "BrPM"
                )
            }

            if configManager.isEnabled(.calories) {
                GridItemView(
                    symbolName: "flame",
                    title: "Calories Burned",
                    value: formatTotalCaloriesValue(model.mostRecentActiveCalories, model.mostRecentRestingCalories),
                    unit: "kcal"
                )
            }

            if configManager.isEnabled(.steps) {
                GridItemView(
                    symbolName: "figure.walk",
                    title: "Steps",
                    value: "\(model.mostRecentSteps.map(Int.init) ?? 0)",
                    unit: "steps"
                )
            }

            if configManager.isEnabled(.vo2Max) {
                GridItemView(
                    symbolName: "lungs",
                    title: "VO2 Max",
                    value: String(format: "%.1f", model.mostRecentVO2Max ?? 0.0),
                    unit: "ml/kg/min"
                )
            }
        }
        .padding([.horizontal, .top])
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
}

struct GridItemView: View {
    var symbolName: String
    var title: String
    var value: String
    var unit: String

    @State private var animate = true
    @State private var cachedValue: String

    init(symbolName: String, title: String, value: String, unit: String) {
        self.symbolName = symbolName
        self.title = title
        _cachedValue = State(initialValue: value)
        self.value = value
        self.unit = unit
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
