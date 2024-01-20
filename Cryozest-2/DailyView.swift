import SwiftUI

struct DailyView: View {
    @ObservedObject var model: RecoveryGraphModel
    @ObservedObject var exertionModel: ExertionModel
    
    
    @State private var showingExertionPopover = false
    @State private var showingRecoveryPopover = false
    @State private var showingSleepPopover = false
    @State private var dailySleepViewModel = DailySleepViewModel()
    @State private var calculatedUpperBound: Double = 8.0
    
    
    var calculatedUpperBoundDailyView: Double {
        let recoveryScore = model.recoveryScores.last ?? 8
        let upperBound = ceil(Double(recoveryScore) / 10.0) + 1
        let calculatedUpperBound = max(upperBound, 1.0)
        return calculatedUpperBound
    }
    
    var body: some View {
        ScrollView {
            
            HeaderView(model: model)
                .padding(.top)
                .padding(.bottom, 5)
                .padding(.leading,10)
            
            DailyGridMetrics(model: model)
            
            VStack(alignment: .leading, spacing: 10) {
                ProgressButtonView(
                    title: "Readiness to Train",
                    progress: Float(model.recoveryScores.last ?? 0) / 100.0,
                    color: Color.green,
                    action: { showingRecoveryPopover = true }
                )
                .popover(isPresented: $showingRecoveryPopover) {
                    RecoveryCardView(model: model)
//                    RecoveryGraphView(model: model)
                }
                
                
                ProgressButtonView(
                       title: "Daily Exertion",
                       progress: Float(exertionModel.exertionScore / calculatedUpperBoundDailyView),
                       color: Color.orange,
                       action: { showingExertionPopover = true }
                   )
                   .popover(isPresented: $showingExertionPopover) {
                       ExertionView(exertionModel: exertionModel, recoveryModel: model)
                   }
                   .onAppear {
                       print("Exertion Score: \(exertionModel.exertionScore)")
                   }
                
                ProgressButtonView(
                    title: "Sleep Quality",
                    progress: Float(dailySleepViewModel.sleepScore / 100), // Divide by 100 to scale it correctly
                    color: Color.yellow,
                    action: { showingSleepPopover = true }
                )
                .popover(isPresented: $showingSleepPopover) {
                    DailySleepView(dailySleepModel: DailySleepViewModel())
                }
            }
            .padding(.horizontal,22)
            .padding(.top, 10)
        }
        .refreshable {
                 model.pullAllData()
                 exertionModel.fetchExertionScoreAndTimes()
                 dailySleepViewModel.refreshData() 
             }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.black)
        .onAppear() {
            HealthKitManager.shared.requestAuthorization { success, error in
                if success {
                    HealthKitManager.shared.areHealthMetricsAuthorized() { isAuthorized in
                    }
                }
            }
        }
    }
}

struct HeaderView: View {
    @ObservedObject var model: RecoveryGraphModel
    
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
        }
        .padding(.horizontal, 22)
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


class RecoveryGraphModel: ObservableObject {
    
    @Published var lastDataRefresh: Date?
    
    @Published var previousNightSleepDuration: String? = nil {
        didSet {
            calculateSleepScorePercentage()
        }
    }
    
    // MARK -- HRV variables
    @Published var avgHrvDuringSleep: Int? {
        didSet {
            calculateHrvPercentage()
        }
    }
    @Published var avgHrvDuringSleep60Days: Int? {
        didSet {
            calculateHrvPercentage()
        }
    }
    @Published var hrvSleepPercentage: Int?
    
    // MARK -- Heart Rate variables
    @Published var mostRecentRestingHeartRate: Int? {
        didSet {
            calculateRestingHeartRatePercentage()
        }
    }
    @Published var avgRestingHeartRate60Days: Int? {
        didSet {
            calculateRestingHeartRatePercentage()
        }
    }
    @Published var restingHeartRatePercentage: Int?
    
    @Published var recoveryScores = [Int]() {
        didSet {
            let sum = self.recoveryScores.reduce(0, +) // Sums up all elements in the array
            self.weeklyAverage = self.recoveryScores.isEmpty ? 0 : sum / self.recoveryScores.count
        }
    }
    
    @Published var weeklyAverage: Int = 0
    @Published var lastKnownHRV: Int = 0  // Add a default value or make it optional
    @Published var lastKnownHRVTime: String? = nil // Add this property
    @Published var mostRecentSPO2: Double? = nil
    @Published var mostRecentRespiratoryRate: Double? = nil
    @Published var mostRecentActiveCalories: Double? = nil
    @Published var mostRecentRestingCalories: Double? = nil
    @Published var sleepScorePercentage: Int?
    @Published var mostRecentSteps: Double? = nil
    @Published var mostRecentVO2Max: Double? = nil
    
    private var dailySleepViewModel = DailySleepViewModel()
    
    var hrvReadings: [Date: Int] = [:]
    
    func getClosestHRVReading(for date: Date) -> Int? {
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: date) // Start of the given date
        let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)! // Start of the next day
        
        let sortedDates = hrvReadings.keys.filter { $0 >= startDate && $0 < endDate }.sorted().reversed()
        for readingDate in sortedDates {
            return hrvReadings[readingDate]
        }
        return nil
    }
    
    func generateUserStatement() -> String {
        guard let recoveryScore = recoveryScores.last else {
            return "Data not available."
        }
        
        // Fetch the sleep score from DailySleepViewModel
        let sleepScore = dailySleepViewModel.sleepScore
        
        switch (recoveryScore, sleepScore) {
        case (80...100, 80...100):
            return "Hello! Your Recovery and Sleep are both at peak levels today. You're well-rested and ready to tackle any challenge. Aim high for your exertion targets, but remember to stay attuned to your body's signals."
        case (80...100, 70..<80):
            return "Great job! Your Recovery is high, showing you're in excellent shape. Your Sleep was decent, so you might want to focus a bit more on rest tonight. Feel confident to push your limits today, but keep an eye on your body's needs."
        case (80...100, 60..<70):
            return "You're showing high recovery levels, which is fantastic! Your sleep was not optimal, though. Today, you can aim high but also consider some extra rest to improve your sleep quality."
        case (80...100, ..<60):
            return "Although your Sleep was low, your Recovery is high. You might still feel ready for challenges, but remember, consistent good sleep is key for sustained well-being. Balance is essential."
        case (70..<80, 80...100):
            return "Nice work! Your Recovery is decent and your Sleep was impressive. You're well-equipped for today's activities. Aim for your exertion goals while ensuring you maintain this great sleep pattern."
        case (70..<80, 70..<80):
            return "Good going! You're showing decent levels in both Recovery and Sleep. You're on the right track. Today is a good day to work towards your goals at a steady pace, keeping a balance between activity and rest."
        case (70..<80, 60..<70):
            return "Your recovery is decent, but your sleep wasn't quite optimal. While you can still be active, try to prioritize improving your sleep tonight for a better balance."
        case (70..<80, ..<60):
            return "You have a decent recovery score, but your sleep is low. Be mindful of your energy levels today and focus on getting more restful sleep tonight."
        case (60..<70, 80...100):
            return "Your sleep quality is high, which is great, but your recovery isn't optimal. You can be moderately active today, but don't forget to listen to your body and take it easy if needed."
        case (60..<70, 70..<80):
            return "With not optimal recovery and decent sleep, today might be a day for moderate activities. Focus on maintaining your good sleep habits and giving your body time to recover."
        case (60..<70, 60..<70):
            return "Both your recovery and sleep are not optimal. It's a signal to take things slow today. Focus on self-care and try to improve both your sleep and recovery."
        case (60..<70, ..<60),
            (50..<60, 60..<70):
            return "Your Sleep wasn't optimal and Recovery is a bit low. It might be a sign to take it easier today. Focus on activities that are less strenuous and prioritize rest to bounce back stronger."
        case (50..<60, 80...100):
            return "Your sleep is excellent, but your recovery is low. This contrast suggests you might want to take a lighter approach to activities today, despite the good sleep."
        case (50..<60, 70..<80):
            return "Your Recovery is on the lower side, but your Sleep was decent. Consider lighter activities today and continue focusing on good sleep habits. Your body will thank you for the balanced approach."
        case (50..<60, 60..<70):
            return "With low recovery and not optimal sleep, it's crucial to prioritize rest and recovery today. Engage in light, restorative activities and focus on improving your sleep tonight."
        case (50..<60, ..<60):
            return "Both your recovery and sleep are low, indicating a need for rest and recuperation. Today should be about restful activities and aiming for better sleep."
        default:
            return "Wear your Apple Watch for personalized insights."
        }
    }
    
    private func formatSleepDuration(_ duration: TimeInterval) -> String {
        let hours = duration / 3600  // Convert seconds to hours
        return String(format: "%.1f", hours)
    }
    
    init() {
        pullAllData()
    }
    
    func pullAllData() {
        lastDataRefresh = Date()
        
        self.getLastSevenDaysOfRecoveryScores()
        
        HealthKitManager.shared.fetchAvgHRVDuringSleepForPreviousNight() { hrv in
            DispatchQueue.main.async {
                if let hrv = hrv {
                    self.avgHrvDuringSleep = Int(hrv)
                } else {
                    self.avgHrvDuringSleep = nil
                }
            }
        }
        
        
        HealthKitManager.shared.fetchMostRecentHRVForToday(before: Date()) { lastHrv in
            DispatchQueue.main.async {
                if let lastHrv = lastHrv {
                    self.lastKnownHRV = Int(lastHrv)
                } else {
                    // Handle the case where the last known HRV is not available
                    self.lastKnownHRV = 0  // or handle it differently
                }
            }
        }
        
        HealthKitManager.shared.fetchMostRecentSPO2 { spo2 in
            DispatchQueue.main.async {
                self.mostRecentSPO2 = spo2
            }
        }
        
        HealthKitManager.shared.fetchMostRecentRespiratoryRate { respRate in
            DispatchQueue.main.async {
                self.mostRecentRespiratoryRate = respRate
            }
        }
        
        HealthKitManager.shared.fetchMostRecentActiveEnergy { activeCalories in
            DispatchQueue.main.async {
                self.mostRecentActiveCalories = activeCalories
            }
        }
        
        HealthKitManager.shared.fetchSleepDurationForPreviousNight() { sleepDuration in
            DispatchQueue.main.async {
                if let sleepDuration = sleepDuration {
                    self.previousNightSleepDuration = self.formatSleepDuration(sleepDuration)
                } else {
                    self.previousNightSleepDuration = nil
                }
            }
        }
        
        HealthKitManager.shared.fetchAvgHRVDuring60DaysSleep() { hrv in
            DispatchQueue.main.async {
                if let hrv = hrv {
                    self.avgHrvDuringSleep60Days = Int(hrv)
                } else {
                    self.avgHrvDuringSleep60Days = nil
                }
            }
        }
        
        HealthKitManager.shared.fetchMostRecentRestingHeartRate() { restingHeartRate in
            DispatchQueue.main.async {
                if let restingHeartRate = restingHeartRate {
                    self.mostRecentRestingHeartRate = restingHeartRate
                } else {
                    self.mostRecentRestingHeartRate = nil
                }
            }
        }
        
        HealthKitManager.shared.fetchMostRecentRestingEnergy { restingCalories in
            DispatchQueue.main.async {
                self.mostRecentRestingCalories = restingCalories
            }
        }
        
        HealthKitManager.shared.fetchNDayAvgRestingHeartRate(numDays: 60) { restingHeartRate60days in
            DispatchQueue.main.async {
                if let restingHeartRate = restingHeartRate60days {
                    self.avgRestingHeartRate60Days = restingHeartRate
                } else {
                    self.avgRestingHeartRate60Days = nil
                }
            }
        }
        
        HealthKitManager.shared.fetchStepsToday { steps, error in
            DispatchQueue.main.async {
                if let error = error {
                    // Handle the error here
                    print("Error fetching steps: \(error.localizedDescription)")
                    return
                }
                self.mostRecentSteps = steps
            }
        }

        HealthKitManager.shared.fetchMostRecentVO2Max { vo2Max, error in
            DispatchQueue.main.async {
                if let error = error {
                    // Handle the error here
                    print("Error fetching VO2 Max: \(error.localizedDescription)")
                    return
                }
                self.mostRecentVO2Max = vo2Max
            }
        }

        
        
    }
    
    private func calculateSleepScorePercentage() {
        guard let sleepDurationString = previousNightSleepDuration,
              let sleepDuration = Double(sleepDurationString) else {
            print("calculateSleepScorePercentage: No sleep duration data available or conversion to Double failed")
            sleepScorePercentage = nil
            return
        }
        
        let idealSleepDuration: Double = 8 // 8 hours for 100% score
        let sleepScore = (sleepDuration / idealSleepDuration) * 100
        sleepScorePercentage = Int(sleepScore.rounded())
    }
    
    
    
    
    private func calculateHrvPercentage() {
        if let avgSleep = avgHrvDuringSleep, let avg60Days = avgHrvDuringSleep60Days, avg60Days > 0 {
            let percentage = Double(avgSleep - avg60Days) / Double(avg60Days) * 100
            hrvSleepPercentage = Int(percentage.rounded())
        } else {
            hrvSleepPercentage = nil
        }
    }
    
    private func calculateRestingHeartRatePercentage() {
        if let mostRecentHr = mostRecentRestingHeartRate, let avg60Days = avgRestingHeartRate60Days, avg60Days > 0 {
            let percentage = Double(mostRecentHr - avg60Days) / Double(avg60Days) * 100
            restingHeartRatePercentage = Int(percentage.rounded())
        } else {
            restingHeartRatePercentage = nil
        }
    }
    
    func getLastSevenDaysDates() -> [Date] {
        var dates = [Date]()
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        for i in 0..<7 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                dates.insert(date, at: 0) // Insert at the beginning to reverse the order
            }
        }
        // At this point, 'dates' contains the last seven days including today,
        // each normalized to start at midnight
        return dates
    }
    
    func getLastSevenDays() -> [String] {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "EEE" // Format for day of the week
        
        var daysArray = [String]()
        
        // Generate days from today to the past six days
        for i in 0..<7 {
            if let date = Calendar.current.date(byAdding: .day, value: -i, to: Date()) {
                let day = dateFormatter.string(from: date).uppercased()
                daysArray.insert(day, at: 0) // Insert at the beginning to reverse the order
            }
        }
        return daysArray
    }
    
    func calculateRecoveryScore(hrvPercentage: Int, restingHRPercentage: Int) -> Int {
        var score = 0
        
        score += max(0, hrvPercentage)
        
        score += max(0, -restingHRPercentage)
        
        let normalizedScore = min(max(score, 0), 100)
        
        return normalizedScore
    }
    
    func performMultipleHealthKitOperations(date: Date, completion: @escaping (Int?, Int?, Int?, Int?) -> Void) {
        let group = DispatchGroup()
        
        var avgHrvLast10days: Int? = nil
        var avgHrvForDate: Int? = nil
        var avgHeartRate30day: Int? = nil
        var avgRestingHeartRateForDay: Int? = nil
        
        group.enter()
        HealthKitManager.shared.fetchAvgHRVForLastDays(numberOfDays: 10) { avgHrv in
            if let avgHrv = avgHrv {
                avgHrvLast10days = Int(avgHrv)
            }
            group.leave()
        }
        
        group.enter()
        HealthKitManager.shared.fetchAvgHRVDuringSleepForNightEndingOn(date: date) { avgHrv in
            DispatchQueue.main.async {
                if let avgHrv = avgHrv {
                    self.hrvReadings[date] = Int(avgHrv)
                }
                group.leave()
            }
        }
        
        group.enter()
        HealthKitManager.shared.fetchNDayAvgRestingHeartRate(numDays: 30) { restingHeartRate in
            if let restingHeartRate = restingHeartRate {
                avgHeartRate30day = restingHeartRate
            }
            group.leave()
        }
        
        group.enter()
        HealthKitManager.shared.fetchAvgRestingHeartRateForDays(days: [date]) { restingHeartRate in
            if let heartRate = restingHeartRate {
                avgRestingHeartRateForDay = Int(heartRate)
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
            // All tasks are complete, call completion with the fetched data
            completion(avgHrvLast10days, avgHrvForDate, avgHeartRate30day, avgRestingHeartRateForDay)
        }
    }
    
    func getLastSevenDaysOfRecoveryScores() {
        let last7Days = getLastSevenDaysDates()  // Assuming this returns [Date]
        var temporaryScores: [Date: Int] = [:]
        let group = DispatchGroup()
        
        for date in last7Days {
            group.enter()
            
            performMultipleHealthKitOperations(date: date) { avgHrvLast10days, avgHrvForDate, avgHeartRate30day, avgRestingHeartRateForDay in
                
                // Now calling calculateRecoveryScore with the correct parameters
                let score = self.calculateRecoveryScore(
                    date: date,
                    avgHrvLast10days: avgHrvLast10days,
                    avgHrvForDate: avgHrvForDate,
                    avgHeartRate30day: avgHeartRate30day,
                    avgRestingHeartRateForDay: avgRestingHeartRateForDay
                )
                
                DispatchQueue.main.async {
                    temporaryScores[date] = score
                    group.leave()
                }
            }
        }
        
        group.notify(queue: .main) {
            // Once all data is fetched and processed, update recoveryScores
            self.recoveryScores = last7Days.compactMap { temporaryScores[$0] }
            let sortedDates = self.getLastSevenDaysDates().sorted()
            self.recoveryScores = sortedDates.compactMap { temporaryScores[$0] }
        }
    }
    
    func calculateRecoveryScore(date: Date, avgHrvLast10days: Int?, avgHrvForDate: Int?, avgHeartRate30day: Int?, avgRestingHeartRateForDay: Int?) -> Int {
        guard let avgHrvLast10days = avgHrvLast10days, avgHrvLast10days > 0,
              let avgHeartRate30day = avgHeartRate30day, avgHeartRate30day > 0,
              let avgRestingHeartRateForDay = avgRestingHeartRateForDay else {
            return 0
        }
        
        // Use avgHrvForDate if available; otherwise, use the closest available HRV reading
        let effectiveAvgHrv = avgHrvForDate ?? getClosestHRVReading(for: date)
        
        guard let safeAvgHrvForDate = effectiveAvgHrv else {
            return 0
        }
        
        let scaledHrvRatio = (Double(safeAvgHrvForDate) / Double(avgHrvLast10days)) / 1.33
        let scaledHeartRateRatio = (Double(avgRestingHeartRateForDay) / Double(avgHeartRate30day)) / 1.25
        
        let recoveryScore = 0.8 * scaledHrvRatio + 0.2 * scaledHeartRateRatio
        let normalizedScore = min(max(Int(recoveryScore * 100), 0), 100)
        
        return normalizedScore
    }
}

struct RecoveryGraphView: View {
    @ObservedObject var model: RecoveryGraphModel
    
    var body: some View {
        VStack(spacing: 20) {
            HStack {
                Text("Recovery Per Day")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
            }
            .padding(.horizontal)
            
            HStack(alignment: .bottom, spacing: 10) {
                ForEach(Array(zip(model.getLastSevenDays(), model.recoveryScores)), id: \.0) { (day, percentage) in
                    VStack {
                        Text("\(percentage)%")
                            .font(.caption)
                            .foregroundColor(.white)
                        Rectangle()
                            .fill(getColor(forPercentage: percentage))
                            .frame(width: 40, height: CGFloat(percentage))
                            .cornerRadius(5)
                        Text(day)
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
            }
            
            HStack {
                Text("Weekly Average: \(model.weeklyAverage)%")
                    .font(.caption)
                    .foregroundColor(.green)
                    .padding(.leading, 18)
                Spacer()
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 32)
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


struct RecoveryCardView: View {
    @ObservedObject var model: RecoveryGraphModel
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }
    
    var body: some View {
        ScrollView {
             Spacer(minLength: 20)

             VStack(alignment: .leading) {
               
                 HStack {
                     VStack(alignment: .leading) {
                         Text("Recovery")
                             .font(.title2)
                             .fontWeight(.semibold)
                             .foregroundColor(.white)
                        
//                        if let lastRefreshDate = model.lastDataRefresh {
//                            Text("Updated HealthKit data:")
//                                .font(.caption)
//                                .foregroundColor(.gray)
//                                .padding(.top, 0)
//                            Text("\(lastRefreshDate, formatter: dateFormatter)")
//                                .font(.caption)
//                                .foregroundColor(.green)
//                        }
                    }
                    
                    Spacer()
                    
                    
                    ZStack {
                        Circle()
                            .stroke(lineWidth: 8)
                            .foregroundColor(Color(.systemGreen).opacity(0.5))
                        let progress = Double(model.recoveryScores.last ?? 0) / 100.0
                        let progressColor = Color(red: 1.0 - progress, green: progress, blue: 0)
                        
                        Circle()
                            .trim(from: 0, to: CGFloat(progress)) // Use the progress value here
                            .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                            .foregroundColor(progressColor)
                            .rotationEffect(.degrees(-90))
                        
                        VStack {
                            Text("Ready to Train")
                                .font(.system(size: 10))
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                            
                            Text("\(model.recoveryScores.last ?? 0)%")
                                .font(.title3)
                                .fontWeight(.bold)
                                .multilineTextAlignment(.center)
                                .foregroundColor(.white)
                        }
                    }
                    .frame(width: 120, height: 120)
                    
                }
                .padding(.horizontal, 22)
                
                // Metrics and paragraph
                 VStack {
                     HStack {
                         MetricView(
                             label: model.avgHrvDuringSleep != nil ? "\(model.avgHrvDuringSleep!) ms" : "N/A",
                             symbolName: "heart.fill",
                             change: "\(model.hrvSleepPercentage ?? 0)% (\(model.avgHrvDuringSleep60Days ?? 0))",
                             arrowUp: model.avgHrvDuringSleep ?? 0 > model.avgHrvDuringSleep60Days ?? 0,
                             isGreen: model.avgHrvDuringSleep ?? 0 > model.avgHrvDuringSleep60Days ?? 0
                         )

                         Spacer()

                         MetricView(
                             label: "\(model.mostRecentRestingHeartRate ?? 0) bpm",
                             symbolName: "waveform.path.ecg",
                             change: "\(model.restingHeartRatePercentage ?? 0)% (\(model.avgRestingHeartRate60Days ?? 0))",
                             arrowUp: model.mostRecentRestingHeartRate ?? 0 > model.avgRestingHeartRate60Days ?? 0,
                             isGreen: model.mostRecentRestingHeartRate ?? 0 < model.avgRestingHeartRate60Days ?? 0
                         )
                        
                    }
                    .padding(.bottom, 5)
                    
                    RecoveryExplanation(model: model)
                                       .padding(.horizontal, 4)
                                       .padding(.vertical, 32)

                                   Spacer() // Add a Spacer between RecoveryExplanation and RecoveryGraphView

                                   RecoveryGraphView(model: model)
                                       .padding(.horizontal, 4)
                                       .padding(.vertical, 32)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 32)
            }
            
            //            DailyGridMetrics(model: model)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
                .padding(.horizontal)
                .background(Color.black)
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

struct RecoveryExplanation: View {
    @ObservedObject var model: RecoveryGraphModel
    
    var body: some View {
        VStack {
            if (model.avgHrvDuringSleep ?? 0) == 0 || (model.mostRecentRestingHeartRate ?? 0) == 0 {
                Text("Wear your Apple Watch to get recovery information")
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            else {
                Text("Recovery is based on your average HRV during sleep of ")
                    .font(.system(size: 16))
                    .foregroundColor(.white) +
                Text("\(model.avgHrvDuringSleep ?? 0) ms ")
                    .font(.system(size: 17))
                    .foregroundColor(.green)
                    .fontWeight(.bold) +
                Text("which is \(abs(model.hrvSleepPercentage ?? 0))% \(model.hrvSleepPercentage ?? 0 < 0 ? "lower" : "higher") than your 60 day average of \(model.avgHrvDuringSleep60Days ?? 0) ms and your most recent resting heart rate of ")
                    .font(.system(size: 16))
                    .foregroundColor(.white) +
                Text("\(model.mostRecentRestingHeartRate ?? 0) bpm ")
                    .font(.system(size: 17))
                    .foregroundColor(.green)
                    .fontWeight(.bold) +
                Text("which is \(abs(model.restingHeartRatePercentage ?? 0))% \(model.restingHeartRatePercentage ?? 0 < 0 ? "lower" : "higher") than your 60 day average of \(model.avgRestingHeartRate60Days ?? 0) bpm.")
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct DailyGridMetrics: View {
    @ObservedObject var model: RecoveryGraphModel
    
    let columns: [GridItem] = Array(repeating: .init(.flexible(minimum: 150)), count: 2) // Ensure minimum width for items
    
    var body: some View {
        LazyVGrid(columns: columns, alignment: .leading, spacing: 17) { // Increased spacing between items
            GridItemView(
                symbolName: "waveform.path.ecg",
                title: "HRV",
                value: "\(model.lastKnownHRV)",
                unit: "ms"
            )
            
            GridItemView(
                symbolName: "arrow.down.heart",
                title: "RHR",
                value: "\(model.mostRecentRestingHeartRate ?? 0)",
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
        return totalCalories > 0 ? String(format: "%.0f", totalCalories) : "N/A"
    }
    
    private func formatRespRateValue(_ respRate: Double?) -> String {
        guard let respRate = respRate else { return "N/A" }
        return String(format: "%.1f", respRate) // One decimal place
    }
}



struct MetricView: View {
    let label: String
    let symbolName: String
    let change: String
    let arrowUp: Bool
    let isGreen: Bool
    
    var body: some View {
        VStack {
            HStack {
                Image(systemName: symbolName)
                    .foregroundColor(.gray)
                Text(label)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            HStack {
                Text(change)
                    .font(.caption)
                    .foregroundColor(.white)
                    .opacity(0.7)
                Text(arrowUp ? "↑" : "↓")
                    .font(.footnote)
                    .foregroundColor(isGreen ? .green : .red)
            }
            .padding(.leading, 4)
        }
    }
}

struct GridItemView: View {
    var symbolName: String
    var title: String
    var value: String
    var unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                Image(systemName: symbolName)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 15, height: 15)
                    .foregroundColor(.gray)
                Text(title)
                    .font(.system(size: 16)) // Adjust the size as needed
                    .foregroundColor(.white)
                    .lineLimit(1)
                    .layoutPriority(1) // This tells SwiftUI to give priority to this text view to use available space
            }
            
            HStack(alignment: .lastTextBaseline) {
                Text(value)
                    .font(.title)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                Text(unit)
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.top,6)
        .padding(.bottom,6)
        .padding(.leading, 22) // Apply padding only to the leading (left
        .background(Color.black)
        .cornerRadius(8)
        .shadow(radius: 3)
    }
}


struct ProgressButtonView: View {
    let title: String
    let progress: Float // A value between 0.0 and 1.0
    let color: Color
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                VStack(alignment: .leading) {
                    // Title Text
                    Text(title)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(.white)
                        .fontWeight(.semibold)
                        .padding(.bottom, 5) // Adjust padding for spacing between title and progress bar
                    
                    // Horizontal Stack for progress bar and percentage
                    HStack {
                        ProgressView(value: progress)
                            .progressViewStyle(LinearProgressViewStyle(tint: color))
                            .scaleEffect(x: 1, y: 2, anchor: .center)
                            .frame(height: 20)
                        
                        Text("\(Int(progress * 100))%") // Shows the percentage
                            .font(.headline)
                            .foregroundColor(.white)
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.gray.opacity(0.2)) // Button fill
                .cornerRadius(10)
                
                Spacer() // Push '>' to the right
            }
        }
        .background(
            Image(systemName: "chevron.right") // System name for '>'
                .foregroundColor(.gray)
                .font(Font.system(size: 12).weight(.semibold))
                .padding(.trailing, 20)
                .padding(.top, 10),
            alignment: .topTrailing
        )
    }
}
