import SwiftUI
import CoreData

class RecoveryGraphModel: ObservableObject {
    
    @Published var selectedDate: Date
    
    @Published var lastDataRefresh: Date?
    
    @Published var previousNightSleepDuration: String? = nil {
        didSet {
            self.calculateSleepScorePercentage()
        }
    }
    
    // MARK -- HRV variables
    @Published var avgHrvDuringSleep: Int? {
        didSet {
            self.calculateHrvPercentage()
        }
    }
    @Published var avgHrvDuringSleep60Days: Int? {
        didSet {
            self.calculateHrvPercentage()
        }
    }
    @Published var hrvSleepPercentage: Int?
    
    // MARK -- Heart Rate variables
    @Published var mostRecentRestingHeartRate: Int? {
        didSet {
            self.calculateRestingHeartRatePercentage()
        }
    }
    @Published var mostRecentRestingHeartRateTime: Date?
    @Published var avgRestingHeartRate60Days: Int? {
        didSet {
            self.calculateRestingHeartRatePercentage()
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
    @Published var averageDailyRHR: Int?
    
    private var dailySleepViewModel: DailySleepViewModel
    
    var hrvReadings: [Date: Int] = [:]
    
    init(selectedDate: Date) {
        self.selectedDate = selectedDate
        self.dailySleepViewModel = DailySleepViewModel(selectedDate: selectedDate)

        if ScreenshotDataManager.isScreenshotMode {
            injectMockData()
        } else {
            pullAllRecoveryData(forDate: selectedDate)
        }
    }

    // MARK: - Mock Data for Screenshots
    private func injectMockData() {
        let mock = ScreenshotDataManager.mockHeartRate
        let mockHRV = ScreenshotDataManager.mockHRV
        let mockSleep = ScreenshotDataManager.mockSleep
        let mockScores = ScreenshotDataManager.mockScores

        // Heart rate
        self.mostRecentRestingHeartRate = mock.restingHeartRate
        self.mostRecentRestingHeartRateTime = mock.lastReadingTime
        self.avgRestingHeartRate60Days = mock.weeklyAverage
        self.averageDailyRHR = mock.lastHourAverage

        // HRV
        self.avgHrvDuringSleep = mockHRV.currentHRV
        self.avgHrvDuringSleep60Days = mockHRV.weeklyAverage
        self.lastKnownHRV = mockHRV.currentHRV

        // Sleep
        let hours = mockSleep.totalSleep / 3600
        self.previousNightSleepDuration = String(format: "%.1f", hours)

        // Other metrics
        self.mostRecentSPO2 = 98.0
        self.mostRecentRespiratoryRate = 14.5
        self.mostRecentActiveCalories = 485.0
        self.mostRecentRestingCalories = 1650.0
        self.mostRecentSteps = Double(ScreenshotDataManager.mockSteps.todaySteps)
        self.mostRecentVO2Max = 42.5

        // Recovery scores (last 7 days)
        self.recoveryScores = [72, 78, 75, 82, 80, 85, mockScores.recoveryScore]

        self.lastDataRefresh = Date()
    }
    
    
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
    
    func refreshHeartRateData(forDate date: Date) {
        // Quick refresh of just heart rate data (for polling)
        HealthKitManager.shared.fetchMostRecentRestingHeartRate(for: date) { restingHeartRate, timestamp in
            DispatchQueue.main.async {
                if let restingHeartRate = restingHeartRate {
                    self.mostRecentRestingHeartRate = restingHeartRate
                    self.mostRecentRestingHeartRateTime = timestamp
                } else {
                    self.mostRecentRestingHeartRate = nil
                    self.mostRecentRestingHeartRateTime = nil
                }

                // Notify widgets to refresh their graph data
                NotificationCenter.default.post(name: NSNotification.Name("HeartRateDataRefreshed"), object: nil)
            }
        }
    }

    func pullAllRecoveryData(forDate date: Date) {
        print("pull all recovery data for: ", date)

        DispatchQueue.main.async {
            self.lastDataRefresh = Date()
        }
        self.getLastSevenDaysOfRecoveryScores()
        
        // HealthKitManager.shared.fetchAvgHRVDuringSleepForPreviousNight() { hrv in
        HealthKitManager.shared.fetchAvgHRVDuringSleepForNightEndingOn(date: date) { hrv in
            DispatchQueue.main.async {
                if let hrv = hrv {
                    self.avgHrvDuringSleep = Int(hrv)
                } else {
                    self.avgHrvDuringSleep = nil
                }
            }
        }
        // HealthKitManager.shared.fetchMostRecentHRVForToday(before: Date()) { lastHrv in
        HealthKitManager.shared.fetchAvgHRVForDay(date: date) { lastHrv in
            DispatchQueue.main.async {
                if let lastHrv = lastHrv {
                    self.lastKnownHRV = Int(lastHrv)
                } else {
                    // Handle the case where the last known HRV is not available
                    self.lastKnownHRV = 0  // or handle it differently
                }
            }
        }
        HealthKitManager.shared.fetchSPO2(for: date) { spo2 in
            DispatchQueue.main.async {
                self.mostRecentSPO2 = spo2
            }
        }
        HealthKitManager.shared.fetchRespiratoryRate(for: date) { respRate in
            DispatchQueue.main.async {
                self.mostRecentRespiratoryRate = respRate
            }
        }

        HealthKitManager.shared.fetchAverageActiveEnergy(for: date) { activeCalories in
            DispatchQueue.main.async {
                self.mostRecentActiveCalories = activeCalories
            }
        }
        
        // TODO: UPDATE THIS ONE WITH DATE
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
        HealthKitManager.shared.fetchMostRecentRestingHeartRate(for: date) { restingHeartRate, timestamp in
            DispatchQueue.main.async {
                if let restingHeartRate = restingHeartRate {
                    self.mostRecentRestingHeartRate = restingHeartRate
                    self.mostRecentRestingHeartRateTime = timestamp
                } else {
                    self.mostRecentRestingHeartRate = nil
                    self.mostRecentRestingHeartRateTime = nil
                }
            }
        }
        //TODO: UPDATE THIS ONE WITH DATE
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
        HealthKitManager.shared.fetchSteps(for: date) { steps, error in
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
        HealthKitManager.shared.fetchAverageDailyRHR { averageRHR in
            DispatchQueue.main.async {
                // Assuming you have a property in your DailyView to store the average RHR
                self.averageDailyRHR = averageRHR // Update your property with the fetched value
            }
        }
    }
    
    private func calculateSleepScorePercentage() {
        guard let sleepDurationString = previousNightSleepDuration,
              let sleepDuration = Double(sleepDurationString) else {
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
            if let avgHrv = avgHrv {
                DispatchQueue.main.async {
                    self.hrvReadings[date] = Int(avgHrv)
                }
                avgHrvForDate = Int(avgHrv)
            }
            group.leave()
        }
        
        if avgHrvForDate == nil {
            group.enter()
            HealthKitManager.shared.fetchMostRecentHRVForToday(before: Date()) { avgHrv in
                if let avgHrv = avgHrv {
                    DispatchQueue.main.async {
                        self.hrvReadings[date] = Int(avgHrv)
                    }
                    avgHrvForDate = Int(avgHrv)
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
        HealthKitManager.shared.fetchAverageDailyRHR { restingHeartRate in
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
        let last7Days = getLastSevenDaysDates()
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
