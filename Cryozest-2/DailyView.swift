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
    // @State private var dailySleepViewModel = DailySleepViewModel()
    @State private var calculatedUpperBound: Double = 8.0
    
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
        ScrollView {
            HeaderView(model: recoveryModel, selectedDate: $selectedDate)
                .padding(.top)
                .padding(.bottom, 5)
                .padding(.leading,10)
            
            DailyGridMetrics(model: recoveryModel)
            
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
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
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
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Daily Summary")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .padding(.top)
                
                if let lastRefreshDate = model.lastDataRefresh {
                    HStack(spacing: 2) { // Adjust the spacing as needed
                        Text("Updated HealthKit data:")
                            .font(.caption)
                            .foregroundColor(.gray)
                        
                        Text("\(lastRefreshDate, formatter: dateFormatter)")
                            .font(.caption)
                            .foregroundColor(.green)
                    }
                    .padding(.top, 0)
                    
                }
            }
            
            Spacer()
            
            DatePicker("", selection: $selectedDate, displayedComponents: .date)
                .labelsHidden()
                .colorScheme(.dark)
                .onChange(of: selectedDate) { newValue in
                    // Code to handle the date change if necessary
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
    
    let columns: [GridItem] = Array(repeating: .init(.flexible(minimum: 150)), count: 2) // Ensure minimum width for items
    
    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 17) { // Increased spacing between items
            GridItemView(
                symbolName: "waveform.path.ecg",
                title: "Avg HRV",
                value: "\(model.lastKnownHRV)",
                unit: "ms"
            )
            
            GridItemView(
                symbolName: "arrow.down.heart",
                title: "Avg RHR",
                value: "\(model.mostRecentRestingHeartRate ?? 0)", // Use averageDailyRHR here
                unit: "bpm"
            )
            
            GridItemView(
                symbolName: "drop",
                title: "Blood Oxygen",
                value: formatSPO2Value(model.mostRecentSPO2),
                unit: "%"
            )
            
            GridItemView(
                symbolName: "lungs",
                title: "Respiratory Rate",
                value: formatRespRateValue(model.mostRecentRespiratoryRate),
                unit: "BrPM"
            )
            
            GridItemView(
                symbolName: "flame",
                title: "Calories Burned",
                value: formatTotalCaloriesValue(model.mostRecentActiveCalories, model.mostRecentRestingCalories),
                unit: "kcal"
            )
            GridItemView(
                symbolName: "figure.walk",
                title: "Steps",
                value: "\(model.mostRecentSteps.map(Int.init) ?? 0)",
                unit: "steps"
            )
            
            GridItemView(
                symbolName: "lungs",
                title: "VO2 Max",
                value: String(format: "%.1f", model.mostRecentVO2Max ?? 0.0),
                unit: "ml/kg/min"
            )
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
    
    // Add state to manage the animation trigger
    @State private var animate = true
    @State private var cachedValue: String
    
    init(symbolName: String, title: String, value: String, unit: String) {
        self.symbolName = symbolName
        self.title = title
        // Directly use _cachedValue to initialize the State variable
        _cachedValue = State(initialValue: value)
        self.value = value
        self.unit = unit
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: symbolName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 15, height: 15)
                    .foregroundColor(.gray)
                Text(title)
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .lineLimit(1)
            }
            
            HStack(alignment: .lastTextBaseline) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                // Apply the animation color based on `animate` state
                    .foregroundColor(animate ? Color.orange : .white)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .onAppear {
            // Trigger the animation when the view appears
            withAnimation(.easeInOut(duration: 2)) {
                animate = false
            }
        }
        .onChange(of: value) { newValue in
            // Trigger the animation whenever the value changes
            
            if newValue != cachedValue {
                cachedValue = newValue
                
                animate = true // Reset animation state
                withAnimation(.easeInOut(duration: 2)) {
                    animate = false
                }
            }
        }
        .padding()
        .background(Color.black)
        .cornerRadius(8)
        .shadow(radius: 3)
    }
}

struct ProgressButtonView: View {
    let title: String
    let progress: Float
    let color: Color
    let action: () -> Void
    
    @State private var cachedProgress: Float
    @State private var hasNewData = false
    @State private var animateIcon = false // State to control the icon animation
    
    init(title: String, progress: Float, color: Color, action: @escaping () -> Void) {
        self.title = title
        self.progress = progress
        self.color = color
        self.action = action
        _cachedProgress = State(initialValue: progress)
    }
    
    var body: some View {
        Button(action: {
            action()
            hasNewData = false // Reset the new data indicator on button press
        }) {
            HStack {
                VStack(alignment: .leading) {
                    HStack {
                        Text(title)
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                            .padding(.bottom, 5)
                        
                        if hasNewData {
                            // Animated icon next to "Data Available"
                            HStack {
                                Image(systemName: "bell.fill") // Example icon
                                    .foregroundColor(.green)
                                    .font(.system(size: 14))
                                
                                Text("New data!")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.green)
                                    .transition(.scale.combined(with: .opacity))
                                    .padding(.leading, -1)
                            }
                            .padding(.leading, 4)
                        }
                    }
                    
                    HStack {
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: color))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                            .frame(height: 20)
                        
                        Text("\(Int(progress * 100))%")
                            .font(.headline)
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(hasNewData ? Color.green.opacity(0.3) : Color.gray.opacity(0.2))
                .cornerRadius(10)
                
                Spacer()
            }
        }
        .background(
            Image(systemName: "chevron.right")
                .foregroundColor(.gray)
                .font(Font.system(size: 12).weight(.semibold))
                .padding(.trailing, 20)
                .padding(.top, 10),
            alignment: .topTrailing
        )
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
