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
    /// Daily average RHR from HealthKit — matches the value used by the Z-score engine.
    /// Use this (not mostRecentRestingHeartRate) for recovery score driver comparisons.
    @Published var dailyAvgRestingHeartRate: Int? {
        didSet {
            self.calculateRestingHeartRatePercentage()
        }
    }
    @Published var avgRestingHeartRate60Days: Int? {
        didSet {
            self.calculateRestingHeartRatePercentage()
        }
    }
    @Published var restingHeartRatePercentage: Int?
    
    @Published var recoveryScores = [Int?]() {
        didSet {
            let validScores = self.recoveryScores.compactMap { $0 }
            self.weeklyAverage = validScores.isEmpty ? 0 : validScores.reduce(0, +) / validScores.count
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
    @Published var hasTemperatureData: Bool = false

    private var dailySleepViewModel: DailySleepViewModel
    
    var hrvReadings: [Date: Int] = [:]
    
    init(selectedDate: Date) {
        self.selectedDate = selectedDate
        self.dailySleepViewModel = DailySleepViewModel(selectedDate: selectedDate)

        pullAllRecoveryData(forDate: selectedDate)
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
        // Get the most recent non-nil recovery score
        guard let recoveryScore = recoveryScores.last ?? nil else {
            return "Wear your Apple Watch to sleep for personalized insights."
        }

        // Fetch the sleep score from DailySleepViewModel
        let sleepScore = dailySleepViewModel.sleepScore

        // Ranges aligned with the 5-metric Z-score engine output
        switch (recoveryScore, sleepScore) {
        case (85...100, 80...100):
            return "Your Recovery and Sleep are both at peak levels today. You're well-rested and ready to push hard. Aim high for your exertion targets."
        case (85...100, 60..<80):
            return "Your Recovery is excellent, but sleep could be better. You can train hard today, but prioritize better sleep tonight."
        case (85...100, ..<60):
            return "Peak recovery despite low sleep. You can perform well today, but sustained low sleep will catch up. Make tonight count."
        case (67..<85, 80...100):
            return "Good recovery and great sleep. You're well-equipped for a solid effort today."
        case (67..<85, 60..<80):
            return "Decent recovery and sleep. A good day for structured training at moderate intensity."
        case (67..<85, ..<60):
            return "Recovery is good but sleep was low. Be mindful of energy levels and consider lighter activity."
        case (50..<67, 80...100):
            return "Sleep was great but recovery is only moderate. Stick to moderate activity and let your body catch up."
        case (50..<67, 60..<80):
            return "Both recovery and sleep are moderate. A lighter training day with focus on technique or mobility."
        case (50..<67, ..<60):
            return "Recovery and sleep are both suboptimal. Focus on restorative activities and prioritize rest tonight."
        case (34..<50, _):
            return "Your body is showing accumulated stress. A light recovery day with walking or stretching is best."
        case (..<34, _):
            return "Your body needs rest. Skip intense training and focus on sleep, hydration, and nutrition today."
        default:
            return "Wear your Apple Watch to sleep for personalized insights."
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
            self.selectedDate = date
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
        
        HealthKitManager.shared.fetchTotalSleepForNight(date: date) { sleepDuration in
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
                let newRHR = restingHeartRate
                if self.mostRecentRestingHeartRate != newRHR {
                    self.mostRecentRestingHeartRate = newRHR
                }
                if self.mostRecentRestingHeartRateTime != timestamp {
                    self.mostRecentRestingHeartRateTime = timestamp
                }
            }
        }
        // Fetch daily average RHR (same source the Z-score engine uses)
        HealthKitManager.shared.fetchRestingHeartRateForDay(date: date) { rhr in
            DispatchQueue.main.async {
                let newVal = rhr.map { Int($0.rounded()) }
                if self.dailyAvgRestingHeartRate != newVal {
                    self.dailyAvgRestingHeartRate = newVal
                }
            }
        }
        HealthKitManager.shared.fetchRestingEnergy(for: date) { restingCalories in
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
                    print("Error fetching steps: \(error.localizedDescription)")
                    return
                }
                if self.mostRecentSteps != steps {
                    self.mostRecentSteps = steps
                }
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
        // Prefer daily average RHR (matches the Z-score engine); fall back to most recent sample
        let rhr = dailyAvgRestingHeartRate ?? mostRecentRestingHeartRate
        if let rhr = rhr, let avg60Days = avgRestingHeartRate60Days, avg60Days > 0 {
            let percentage = Double(rhr - avg60Days) / Double(avg60Days) * 100
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
    
    // MARK: - New 5-Metric Recovery Score (via StressScoreEngine)

    func fetchNightlyMetrics(for date: Date, completion: @escaping (NightlyMetrics?) -> Void) {
        let group = DispatchGroup()
        let hk = HealthKitManager.shared

        var hrv: Double?
        var rhr: Double?
        var respRate: Double?
        var wristTemp: Double?
        var sleepDuration: Double?

        group.enter()
        hk.fetchHRVDuringSleepForDate(date) { value in
            hrv = value
            group.leave()
        }

        group.enter()
        hk.fetchRestingHeartRateForDay(date: date) { value in
            rhr = value
            group.leave()
        }

        group.enter()
        hk.fetchRespiratoryRateDuringSleep(for: date) { value in
            respRate = value
            group.leave()
        }

        group.enter()
        hk.fetchSleepingWristTemperature(for: date) { value in
            wristTemp = value
            group.leave()
        }

        group.enter()
        hk.fetchTotalSleepForNight(date: date) { value in
            sleepDuration = value
            group.leave()
        }

        group.notify(queue: .main) {
            // Return nil if absolutely no data
            if hrv == nil && rhr == nil && sleepDuration == nil && respRate == nil && wristTemp == nil {
                completion(nil)
                return
            }
            completion(NightlyMetrics(
                date: date,
                hrv: hrv,
                rhr: rhr,
                respRate: respRate,
                wristTemp: wristTemp,
                sleepDuration: sleepDuration
            ))
        }
    }

    func getLastSevenDaysOfRecoveryScores() {
        let last7Days = getLastSevenDaysDates()
        var temporaryScores: [Date: Int] = [:]
        let group = DispatchGroup()
        let engine = StressScoreEngine.shared
        let baseline = engine.loadBaseline()

        for date in last7Days {
            group.enter()

            fetchNightlyMetrics(for: date) { metrics in
                // No data or insufficient data = no score for this day (gap in chart)
                guard let metrics = metrics, metrics.hasSufficientData else {
                    DispatchQueue.main.async {
                        // Don't set a score — leave this date absent from temporaryScores
                        group.leave()
                    }
                    return
                }

                guard let score = engine.computeScore(metrics: metrics, baseline: baseline) else {
                    DispatchQueue.main.async {
                        group.leave()
                    }
                    return
                }

                DispatchQueue.main.async {
                    temporaryScores[date] = score.recoveryScore
                    if let hrv = metrics.hrv {
                        self.hrvReadings[date] = Int(hrv)
                    }
                    // Track if the most recent day has temperature data (for weight display)
                    if date == last7Days.last {
                        self.hasTemperatureData = score.hasTemperatureData
                    }
                    group.leave()
                }
            }
        }

        group.notify(queue: .main) {
            let sortedDates = self.getLastSevenDaysDates().sorted()
            // nil = no data for that day (watch not worn or insufficient sleep)
            self.recoveryScores = sortedDates.map { temporaryScores[$0] }
        }
    }
}
