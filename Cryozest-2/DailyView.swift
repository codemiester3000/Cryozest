import SwiftUI

struct DailyView: View {
    @ObservedObject var model: RecoveryGraphModel
    
    var body: some View {
        ScrollView {
            DailyViewHeader(lastDataRefresh: model.lastDataRefresh)
            
            CaloriesBurnedGraphView()
            
            SleepBarGraphView()
            
            StepsBarGraphView()
            
            DailyGridMetrics(model: model)
                .padding(.top, 24)
            
//            StepsBarGraphView()
//            
//            StepsBarGraphView()
            
            Divider().background(Color.white.opacity(0.8)).padding(.vertical, 8)
            
            
            DailySleepView(dailySleepModel: DailySleepViewModel())
            
            Divider().background(Color.white.opacity(0.8)).padding(.vertical, 8)
            
            RecoveryCardView(model: model)
            
            RecoveryGraphView(model: model)
            
            Divider().background(Color.white.opacity(0.8)).padding(.vertical, 8)
            
            ExertionView(exertionModel: ExertionModel(), recoveryModel: model)
            
           // Divider().background(Color.white.opacity(0.8)).padding(.vertical, 8)
            
            //DailySleepView(dailySleepModel: DailySleepViewModel())
        }
        .refreshable {
            model.pullAllData()
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
        
        print("calculateSleepScorePercentage: Calculated sleep score percentage is \(sleepScorePercentage ?? 0)")
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

struct DailyViewHeader: View {
    
    var lastDataRefresh: Date?
    
    private var dateFormatter: DateFormatter {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .medium
        return formatter
    }
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading) {
                        Text("Daily Summary")
                            .font(.system(size: 24, weight: .regular, design: .default))
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        if let lastRefreshDate = lastDataRefresh {
                            Text("Updated HealthKit data:")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .padding(.top, 0)
                            Text("\(lastRefreshDate, formatter: dateFormatter)")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                    }
                    
                    
                    Spacer()
                    
//                    Button(action: {
//                        // Action for the button
//                    }) {
//                        Text("Record Data")
//                            .fontWeight(.semibold)
//                            .foregroundColor(.white)
//                            .padding()
//                            .background(Color.clear)
//                            .cornerRadius(8)
//                            .overlay(
//                                RoundedRectangle(cornerRadius: 8)
//                                    .stroke(Color.orange, lineWidth: 2)
//                            )
//                            .shadow(radius: 5)
//                    }
                }
            }
            .padding(.horizontal)
            .padding(.top, 36)
            Spacer()
        }
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
            VStack(alignment: .leading) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Recovery")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
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
                .padding(.horizontal, 6)
                .padding(.top)
                
                // Metrics and paragraph
                VStack {
                    HStack {
                        MetricView(
                            label: model.avgHrvDuringSleep != nil ? "\(model.avgHrvDuringSleep!) ms" : "N/A",
                            symbolName: "heart.fill",
                            change: "\(model.hrvSleepPercentage ?? 0)% (\(model.avgHrvDuringSleep60Days ?? 0)))",
                            arrowUp: model.hrvSleepPercentage ?? -1 > model.avgHrvDuringSleep60Days ?? -1,
                            isGreen: model.hrvSleepPercentage ?? -1 < model.avgHrvDuringSleep60Days ?? -1
                        )
                        
                        Spacer()
                        
                        MetricView(
                            label: "\(model.mostRecentRestingHeartRate ?? 0) bpm",
                            symbolName: "waveform.path.ecg",
                            change: "\(model.restingHeartRatePercentage ?? 0)% (\(model.avgRestingHeartRate60Days ?? 0)))",
                            arrowUp: model.restingHeartRatePercentage ?? -1 > model.avgRestingHeartRate60Days ?? -1,
                            isGreen: model.restingHeartRatePercentage ?? -1 < model.avgRestingHeartRate60Days ?? -1
                        )
                        
                    }
                    .padding(.bottom)
                    .padding(.horizontal, 6)
                    
                    RecoveryExplanation(model: model)
                }
                .padding(.horizontal, 4)
                .padding(.vertical, 32)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.horizontal)
    }
}

private func formatTotalCaloriesValue(_ activeCalories: Double?, _ restingCalories: Double?) -> String {
    let totalCalories = (activeCalories ?? 0) + (restingCalories ?? 0)
    return totalCalories > 0 ? String(format: "%.0f", totalCalories) : "N/A"
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
            Text("which is \(abs(model.restingHeartRatePercentage ?? 0))% lower than your 60 day average of \(model.avgRestingHeartRate60Days ?? 0) bpm.")
                .font(.system(size: 16))
                .foregroundColor(.white)
            
        }
        .frame(maxWidth: .infinity, alignment: .center)
    }
}

struct DailyGridMetrics: View {
    @ObservedObject var model: RecoveryGraphModel
    
    var body: some View {
        VStack {
            // First row of grid items
            HStack(spacing: 12) {
//                GridItemView(
//                    title: "Sleep",
//                    value: model.previousNightSleepDuration ?? "N/A",
//                    unit: "hrs"
//                )
                
                                GridItemView(
                                    title: "SPO2",
                                    value: formatSPO2Value(model.mostRecentSPO2),
                                    unit: "%"
                                )
                
//                GridItemView(
//                    title: "HRV",
//                    value: "\(model.lastKnownHRV)",
//                    unit: "ms"
//                )
                
                GridItemView(
                    title: "Resp Rate",
                    value: formatRespRateValue(model.mostRecentRespiratoryRate),
                    unit: "BrPM"
                )
                
                GridItemView(
                    title: "RHR",
                    value: "\(model.mostRecentRestingHeartRate ?? 0)",
                    unit: "bpm"
                )
            }

            // Second row of grid items
//            HStack(spacing: 12) {
//                GridItemView(
//                    title: "SPO2",
//                    value: formatSPO2Value(model.mostRecentSPO2),
//                    unit: "%"
//                )
//                GridItemView(
//                    title: "Resp Rate",
//                    value: formatRespRateValue(model.mostRecentRespiratoryRate),
//                    unit: "BrPM"
//                )
//                
//                GridItemView(
//                    title: "Cals Burned",
//                    value: formatTotalCaloriesValue(model.mostRecentActiveCalories, model.mostRecentRestingCalories),
//                    unit: "kcal"
//                )
//            }
//            .padding(.top, 10)

            HStack {
                Spacer()
                Text("Latest Daily Metrics")
                    .foregroundColor(.gray)
                    .font(.footnote)
                Spacer()
            }
            .padding(.top, 4)
            .padding(.bottom, 12)
        }
        .padding(.horizontal, 6)
    }
}

struct GridItemView: View {
    var title: String
    var value: String
    var unit: String
    
    var body: some View {
        VStack {
            Text(title)
                .font(.system(size: 15))
                .fontWeight(.bold)
                .foregroundColor(.white)
                .padding(.bottom, 2)
            
            HStack(alignment: .lastTextBaseline) {
                Text(value)
                    .font(.system(size: 22))
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Text(unit)
                    .font(.footnote)
                    .foregroundColor(.white.opacity(0.8))
                    .padding(.leading, 2)
            }
        }
        .padding(8)
        .frame(width: 115, height: 75)
        .background(Color.clear) // No background color
        .cornerRadius(10)
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(Color.red, lineWidth: 2) // Red border
        )
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


