import Foundation
import SwiftUI
import HealthKit

class DailySleepViewModel: ObservableObject {
    @Published var totalTimeInBed: String = "N/A"
    @Published var totalTimeAsleep: String = "N/A"
    @Published var totalDeepSleep: String = "N/A"
    @Published var totalCoreSleep: String = "N/A"
    @Published var totalRemSleep: String = "N/A"
    @Published var totalTimeAwake: String = "N/A"
    @Published var sleepData: SleepData?
    @Published var sleepScore: Double = 0.0
    @Published var restorativeSleepPercentage: Double = 0.0
    @Published var averageWakingHeartRate: Double = 0.0
    @Published var averageHeartRateDuringSleep: Double = 0.0
    
    var heartRateDifferencePercentage: Double {
        let averageWakingHeartRate = self.averageWakingHeartRate
        let averageHeartRateDuringSleep = self.averageHeartRateDuringSleep
        
        // Check if averageWakingHeartRate is zero or a valid number
        if averageWakingHeartRate == 0 || !averageWakingHeartRate.isNormal {
            // Return a default value or handle accordingly if the waking heart rate is zero or invalid
            return 0.0
        } else {
            let difference = averageWakingHeartRate - averageHeartRateDuringSleep
            let percentageDifference = (difference / averageWakingHeartRate) * 100.0
            
            // Check for NaN or infinite result
            if percentageDifference.isFinite {
                return percentageDifference
            } else {
                // Return a default value or handle accordingly if the result is not finite
                return 0.0
            }
        }
    }
    
    
    //    var heartRateDifferencePercentage: Double {
    //        let averageWakingHeartRate = self.averageWakingHeartRate
    //        let averageHeartRateDuringSleep = self.averageHeartRateDuringSleep
    //
    //
    //        // Calculate the percentage difference
    //        if averageWakingHeartRate != 0 {
    //            let difference =  averageWakingHeartRate - averageHeartRateDuringSleep
    //            let percentageDifference = (difference / averageWakingHeartRate) * 100.0
    //
    //            // Additional debugging statement to check the final calculated value
    //
    //            return percentageDifference
    //        } else {
    //            // Handling the case where averageWakingHeartRate is zero
    //            return 0.0
    //        }
    //    }
    
    private var sleepSamples: [HKCategorySample] = []
    
    init() {
        fetchSleepData()
        fetchAverageWakingHeartRate { bpm, _ in
            if let bpm = bpm, bpm.isFinite {
                DispatchQueue.main.async {
                    self.averageWakingHeartRate = bpm
                }
            } else {
                DispatchQueue.main.async {
                    self.averageWakingHeartRate = 0.0
                }
            }
        }
        
        fetchAverageHeartRateDuringSleep { bpm, _ in
            if let bpm = bpm {
                DispatchQueue.main.async {
                    self.averageHeartRateDuringSleep = bpm
                }
            }
        }
    }
    
    private func fetchSleepData() {
        HealthKitManager.shared.requestAuthorization { [weak self] authorized, error in
            if authorized {
                HealthKitManager.shared.fetchSleepData { samples, error in
                    guard let self = self, let fetchedSamples = samples as? [HKCategorySample], error == nil else {
                        return
                    }
                    DispatchQueue.main.async {
                        self.sleepSamples = fetchedSamples
                        self.updateSleepData(with: self.sleepSamples)
                        
                        // Pass completion handlers to the functions
                        self.fetchAverageWakingHeartRate { bpm, error in
                            if let bpm = bpm, bpm.isFinite {
                                self.averageWakingHeartRate = bpm
                            } else {
                                self.averageWakingHeartRate = 0.0
                            }
                            
                        }
                        self.fetchAverageHeartRateDuringSleep { bpm, error in
                            if let bpm = bpm {
                                self.averageHeartRateDuringSleep = bpm
                            }
                            // Handle error if needed
                        }
                    }
                }
            } else {
                // Handle authorization error
            }
        }
    }
    
    
    
    private func fetchWakeUpTimePreviousDay(completion: @escaping (Date?) -> Void) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startOfPreviousDay = calendar.startOfDay(for: today.addingTimeInterval(-24*60*60))
        
        let earliestWakeUpTime = calendar.date(bySettingHour: 3, minute: 0, second: 0, of: startOfPreviousDay)!
        let latestWakeUpTime = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: startOfPreviousDay)!
        
        
        
        let predicate = HKQuery.predicateForSamples(withStart: earliestWakeUpTime, end: latestWakeUpTime, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            if let error = error {
                completion(nil)
                return
            }
            
            guard let sleepSamples = samples as? [HKCategorySample], let lastSleepSession = sleepSamples.first else {
                completion(nil)
                return
            }
            
            let wakeUpTime = lastSleepSession.endDate
            completion(wakeUpTime)
        }
        
        HKHealthStore().execute(query)
    }
    
    
    private func fetchSleepStartTimeCurrentDay(completion: @escaping (Date?) -> Void) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startOfSleepSearch = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today.addingTimeInterval(-24*60*60))! // 8 PM on Jan 8th
        let endOfSleepSearch = calendar.date(bySettingHour: 3, minute: 0, second: 0, of: today)! // 3 AM on Jan 9th
        
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfSleepSearch, end: endOfSleepSearch, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            if let error = error {
                completion(nil)
                return
            }
            
            guard let sleepSamples = samples as? [HKCategorySample], let firstSleepSession = sleepSamples.first else {
                completion(nil)
                return
            }
            
            let sleepStartTime = firstSleepSession.startDate
            completion(sleepStartTime)
        }
        
        HKHealthStore().execute(query)
    }
    
    
        private func fetchAverageWakingHeartRate(completion: @escaping (Double?, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(nil, NSError(domain: "com.yourapp.healthkit", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device."]))
            return
        }

        let healthStore = HKHealthStore()
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!

        let calendar = Calendar.current
        let yesterday = calendar.startOfDay(for: Date()).addingTimeInterval(-24 * 60 * 60)
        let startTime = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: yesterday)!
        let endTime = calendar.date(bySettingHour: 17, minute: 0, second: 0, of: yesterday)!

        let predicate = HKQuery.predicateForSamples(withStart: startTime, end: endTime, options: .strictEndDate)

        let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
            if let error = error {
                completion(nil, error)
                return
            }

            guard let heartRateSamples = results as? [HKQuantitySample], !heartRateSamples.isEmpty else {
                completion(0.0, nil)  // Return 0 if there are no samples
                return
            }

            let restingHeartRateSamples = heartRateSamples.filter { $0.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())) < 80 }
            
            // Check if there are filtered samples; if not, return 0
            if restingHeartRateSamples.isEmpty {
                completion(0.0, nil)
            } else {
                let averageHeartRate = restingHeartRateSamples.reduce(0.0) { sum, sample in
                    sum + sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                } / Double(restingHeartRateSamples.count)
                
                DispatchQueue.main.async {
                    completion(averageHeartRate, nil)
                }
            }
        }
        
        healthStore.execute(query)
    }

    private func getSleepStartTimeForNextDay(completion: @escaping (Date?) -> Void) {
        let healthStore = HKHealthStore()
        
        // Ensure sleep data is available
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(nil)
            return
        }
        
        // Set the query period (start of today to now)
        let calendar = Calendar.current
        let startDate = calendar.startOfDay(for: Date())
        let endDate = Date()
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        // Create the query for sleep analysis
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: 0, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { (query, results, error) in
            if let error = error {
                completion(nil)
                return
            }
            
            guard let sleepResults = results as? [HKCategorySample], let lastSleep = sleepResults.first else {
                completion(nil)
                return
            }
            
            // Assuming sleep data is recorded with the end date as the wake-up time and start date as sleep time
            let sleepStartTime = lastSleep.startDate
            completion(sleepStartTime)
        }
        
        healthStore.execute(query)
    }
    
    
    
    
    
    private func fetchAverageHeartRateDuringSleep(completion: @escaping (Double?, Error?) -> Void) {
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(nil, NSError(domain: "com.yourapp.healthkit", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device."]))
            return
        }
        
        let healthStore = HKHealthStore()
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        getSleepTimesYesterday { sleepStartTime, sleepEndTime in
            guard let sleepStartTime = sleepStartTime, let sleepEndTime = sleepEndTime else {
                completion(nil, nil)
                return
            }
            
            
            // Create a predicate for heart rate samples during sleep
            let predicate = HKQuery.predicateForSamples(withStart: sleepStartTime, end: sleepEndTime, options: .strictStartDate)
            
            // Create a query to fetch heart rate samples during sleep
            let query = HKStatisticsQuery(quantityType: heartRateType, quantitySamplePredicate: predicate, options: .discreteAverage) { (query, result, error) in
                if let error = error {
                    completion(nil, error)
                    print("Error fetching heart rate samples: \(error.localizedDescription)")
                    return
                }
                
                if let result = result, let averageHeartRate = result.averageQuantity() {
                    // Calculate the average heart rate during sleep
                    let bpm = averageHeartRate.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                    completion(bpm, nil)
                } else {
                    print("No heart rate samples found for the given period.")
                    completion(nil, nil)
                }
            }
            
            // Execute the query
            healthStore.execute(query)
        }
    }
 

    
    
    
    private func updateSleepData(with samples: [HKCategorySample]) {
        let awakeDuration = calculateTotalDuration(samples: samples, for: .awake)
        let remDuration = calculateTotalDuration(samples: samples, for: .asleepREM)
        let coreDuration = calculateTotalDuration(samples: samples, for: .asleepCore)
        let deepDuration = calculateTotalDuration(samples: samples, for: .asleepDeep)
        
        
        let restorativeSleep = remDuration + deepDuration
        let totalSleep = awakeDuration + remDuration + coreDuration + deepDuration // Include all sleep stages
        
        DispatchQueue.main.async {
            self.sleepData = SleepData(awake: awakeDuration, rem: remDuration, core: coreDuration, deep: deepDuration)
            self.restorativeSleepPercentage = totalSleep > 0 ? (restorativeSleep / totalSleep) * 100 : 0
            self.sleepScore = calculateSleepScore(totalSleep: totalSleep, deepSleep: deepDuration, remSleep: remDuration)
            
        }
    }
    
    private func calculateTotalDuration(samples: [HKCategorySample], for sleepStage: HKCategoryValueSleepAnalysis) -> TimeInterval {
        return samples.filter { $0.categoryType.identifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue && $0.value == sleepStage.rawValue }
            .reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
    
    // Computed property to get formatted restorative sleep time
    var formattedRestorativeSleepTime: String {
        formatTimeInterval(restorativeSleepTime)
    }
    
    // Computed property to get restorative sleep time
    var restorativeSleepTime: TimeInterval {
        calculateTotalDuration(samples: self.sleepSamples, for: .asleepDeep) +
        calculateTotalDuration(samples: self.sleepSamples, for: .asleepREM)
    }
    
    // Computed property to get formatted average restorative sleep
    // Update this to implement your logic for averaging
    var formattedAverageRestorativeSleep: String {
        formatTimeInterval(averageRestorativeSleep)
    }
    
    // Example computed property for average restorative sleep
    var averageRestorativeSleep: TimeInterval {
        // Dummy average calculation, replace with your logic
        restorativeSleepTime
    }
    
    // Computed property to get restorative sleep description
    var restorativeSleepDescription: String {
        "Your Restorative Sleep (Deep and REM) was greater than \(String(format: "%.0f%%", restorativeSleepPercentage)) of your total time asleep. This should help your body to repair itself and your mind to be refreshed."
    }
}



func calculateSleepScore(totalSleep: TimeInterval, deepSleep: TimeInterval, remSleep: TimeInterval) -> Double {
    let totalSleepTarget: TimeInterval = 420 * 60 // 7 hours in seconds
    let deepSleepTarget: TimeInterval = 60 * 60  // 1 hour in seconds
    let remSleepTarget: TimeInterval = 120 * 60  // 2 hours in seconds
    
    let totalSleepScore = min(totalSleep / totalSleepTarget, 1.0) * 40 // 40% of the score
    let deepSleepScore = min(deepSleep / deepSleepTarget, 1.0) * 40 // 40% of the score
    let remSleepScore = min(remSleep / remSleepTarget, 1.0) * 20 // 20% of the score
    
    return totalSleepScore + deepSleepScore + remSleepScore
}

func fetchAndCalculateSleepScore(completion: @escaping (Double) -> Void) {
    HealthKitManager.shared.fetchSleepData { samples, error in
        guard let samples = samples, error == nil else {
            completion(0)
            return
        }
        
        let sleepData = HealthKitManager.shared.processSleepData(samples: samples)
        let totalSleep = sleepData["Total Sleep"] ?? 0
        let deepSleep = sleepData["Deep Sleep"] ?? 0
        let remSleep = sleepData["REM Sleep"] ?? 0
        
        let sleepScore = calculateSleepScore(totalSleep: totalSleep, deepSleep: deepSleep, remSleep: remSleep)
        completion(sleepScore)
        
    }
}


struct DailySleepView: View {
    @ObservedObject var dailySleepModel = DailySleepViewModel()
    
    
    @State private var sleepStartTime: String = "N/A"
    @State private var sleepEndTime: String = "N/A"
    @State private var isPopoverVisible: Bool = false // State for showing the popover
    @State private var sleepScore: Double = 0.0
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                HStack {
                    // "Sleep Performance" Text and "?" Button
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            
                            Text("Sleep Quality")
                                .font(.title2)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                            
                            
                            Button(action: {
                                isPopoverVisible.toggle()
                            }) {
                                Image(systemName: "questionmark.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(Color.blue)
                            }
                            .padding(.leading, 8)
                            .popover(isPresented: $isPopoverVisible) {
                                SleepInfoPopoverView()
                                    .frame(width: UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
                            }
                        }
                        
                        // Conditional Display of Sleep Start and End Times
                                     if sleepStartTime != "N/A" && sleepEndTime != "N/A" {
                                         Text("\(sleepStartTime) to \(sleepEndTime)")
                                             .font(.footnote)
                                             .fontWeight(.medium)
                                             .foregroundColor(.gray)
                                     }
                                 }
                                 .padding(.horizontal, 22)
                                 .padding(.top, 16)
                                 
                                 Spacer()
                    
                    ProgressRingView(progress: dailySleepModel.sleepScore / 100, progressColor: .green,
                                     ringSize: 120)
                    .frame(width: 120, height: 120)
                    .padding(.top, 16)
                    .padding(.bottom, 16)
                    .padding(.horizontal, 22)
                }
                
                if let sleepData = dailySleepModel.sleepData {
                    Spacer(minLength: 20)
                    SleepGraphView(sleepData: sleepData)
                        .frame(height: 200)
                } else {
                    Spacer(minLength: 20)
                    Text("Sleep data is not available yet.")
                }
                
                Spacer(minLength: 20)
                
                RestorativeSleepView(viewModel: dailySleepModel)
                
                
                HeartRateDifferenceProgressCircle(heartRateDifferencePercentage: dailySleepModel.heartRateDifferencePercentage,
                                                  averageWakingHeartRate: dailySleepModel.averageWakingHeartRate,
                                                  averageHeartRateDuringSleep: dailySleepModel.averageHeartRateDuringSleep)
                .padding(.bottom,16)
                
            }
            
            
            .onAppear {
                fetchSleepTimes()
            }
        }
        .background(Color.black)
    } 

    
    private func fetchSleepTimes() {
        getSleepTimesYesterday { (start, end) in
            if let start = start, let end = end {
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "hh:mm a"
                
                self.sleepStartTime = dateFormatter.string(from: start)
                self.sleepEndTime = dateFormatter.string(from: end)
            } else {
                self.sleepStartTime = "N/A"
                self.sleepEndTime = "N/A"
            }
        }
    }
}
struct SleepSession {
    var start: Date
    var end: Date
}


private func getSleepTimesYesterday(completion: @escaping (Date?, Date?) -> Void) {
    let calendar = Calendar.current
    
    // Set search window from 7 PM previous day to 2 PM current day
    let startOfPreviousDay = calendar.startOfDay(for: Date())
    let sleepSearchStartTime = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: startOfPreviousDay.addingTimeInterval(-24 * 60 * 60))!
    let sleepSearchEndTime = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: startOfPreviousDay)!
    
    let predicate = HKQuery.predicateForSamples(withStart: sleepSearchStartTime, end: sleepSearchEndTime, options: .strictEndDate)
    
    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
    let query = HKSampleQuery(sampleType: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
        guard error == nil, let sleepSamples = samples as? [HKCategorySample] else {
            print("Error or no sleep samples found.")
            completion(nil, nil)
            return
        }
        
        // Filter 'asleep' samples and ignore very short sessions
        let asleepSamples = sleepSamples.filter { $0.value == HKCategoryValueSleepAnalysis.asleep.rawValue && $0.endDate.timeIntervalSince($0.startDate) >= 15 * 60 }
        
        // Identify the primary sleep session by finding the longest session
        guard let primarySleepSession = asleepSamples.max(by: { $0.endDate.timeIntervalSince($0.startDate) < $1.endDate.timeIntervalSince($1.startDate) }) else {
            DispatchQueue.main.async {
                completion(nil, nil)
            }
            return
        }
        
        // Initial sleep period
        var sleepStart = primarySleepSession.startDate
        var sleepEnd = primarySleepSession.endDate
        
        // Check for additional sleep sessions after the primary session
        let additionalSleepSessions = asleepSamples.filter { $0.startDate > sleepEnd }
        if let lastAdditionalSleep = additionalSleepSessions.last {
            sleepEnd = lastAdditionalSleep.endDate
        }
        
        DispatchQueue.main.async {
            completion(sleepStart, sleepEnd)
        }
    }
    HKHealthStore().execute(query)
}

struct SleepData {
    var awake: TimeInterval
    var rem: TimeInterval
    var core: TimeInterval
    var deep: TimeInterval
}

struct SleepGraphView: View {
    var sleepData: SleepData
    
    private var totalSleepTime: TimeInterval {
        max(sleepData.awake + sleepData.rem + sleepData.core + sleepData.deep, 1)
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
    
    var body: some View {
        VStack(spacing: 16) {
            HStack(alignment: .bottom, spacing: 12) {
                GraphBarView(color: Color(red: 0.90, green: 0.29, blue: 0.33), heightFraction: sleepData.awake / totalSleepTime, label: "Awake", value: sleepData.awake)
                GraphBarView(color: Color(red: 0.48, green: 0.60, blue: 0.48), heightFraction: sleepData.rem / totalSleepTime, label: "REM", value: sleepData.rem)
                GraphBarView(color: Color(red: 1.00, green: 0.70, blue: 0.00), heightFraction: sleepData.core / totalSleepTime, label: "Core", value: sleepData.core)
                GraphBarView(color: Color(red: 0.31, green: 0.61, blue: 0.87), heightFraction: sleepData.deep / totalSleepTime, label: "Deep", value: sleepData.deep)
            }
            .frame(height: 150)
            .padding(.horizontal, 16)
            
            Text("Total Sleep Time: \(formatTimeInterval(totalSleepTime))")
                .font(.footnote)
                .fontWeight(.medium)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
        }
        .padding(.vertical, 20)
        .background(Color(.black))
        .padding([.horizontal, .bottom])
    }
}

struct GraphBarView: View {
    var color: Color
    var heightFraction: CGFloat
    var label: String
    var value: TimeInterval
    
    private var barHeight: CGFloat {
        max(150 * heightFraction, 10)
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
    
    var body: some View {
        VStack(spacing: 4) {
            Spacer()
            RoundedRectangle(cornerRadius: 7)
                .fill(color)
                .frame(height: barHeight)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
            Text(formatTimeInterval(value))
                .font(.caption2)
                .foregroundColor(.gray)
        }
    }
}


struct ProgressRingView: View {
    var progress: Double
    var progressColor: Color
    var ringSize: CGFloat
    var thickness: CGFloat = 8
    
    var body: some View {
        ZStack {
            // Background Circle
            Circle()
                .stroke(lineWidth: thickness)
                .foregroundColor(Color.gray.opacity(0.5))
                .frame(width: ringSize, height: ringSize)
            
            // Progress Circle
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(style: StrokeStyle(lineWidth: thickness, lineCap: .round))
                .foregroundColor(progressColor)
                .rotationEffect(.degrees(-90))
                .frame(width: ringSize, height: ringSize)
            
            // Text for "Sleep Score" and Percentage
            VStack {
                Text("Sleep Score")
                    .font(.system(size: 10))
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white)
                Text(String(format: "%.0f%%", min(progress, 1.0) * 100))
                    .font(.title2)
                    .bold()
                    .foregroundColor(.white)
            }
        }
    }
}

struct RestorativeSleepView: View {
    @ObservedObject var viewModel: DailySleepViewModel
    
    var body: some View {
        HStack {
            // Full Stroke Blue Circle with Text Inside
            ZStack {
                Circle()
                    .stroke(Color.blue, lineWidth: 10)
                    .frame(width: 70, height: 70)
                
                Text(String(format: "%.0f%%", viewModel.restorativeSleepPercentage))
                    .font(.title3)
                    .bold()
                    .foregroundColor(.white)
            }
            .padding(.leading, 22)
            
            VStack(alignment: .leading) {
                HStack(spacing: 0) {
                    Text(viewModel.formattedRestorativeSleepTime)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text(" of Restorative Sleep")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Text(viewModel.restorativeSleepDescription)
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.leading, 10)
            
            
            Spacer()
        }
        .padding(.vertical, 10)
        .background(Color(.black))
        .cornerRadius(10)
    }
}

struct HeartRateDifferenceProgressCircle: View {
    var heartRateDifferencePercentage: Double
    var averageWakingHeartRate: Double
    var averageHeartRateDuringSleep: Double
    
    // Determine if the watch was worn based on averageHeartRateDuringSleep
    private var watchWasWorn: Bool {
        averageHeartRateDuringSleep != 0
    }
    
    // Computed property to get the title with the appropriate status and color
    private var heartRateDipTitle: (Text, Text) {
        if watchWasWorn {
            let titleText = Text("Heart Rate Dip is ")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            
            if heartRateDifferencePercentage > 20 {
                let statusText = Text("Good")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.green)
                return (titleText, statusText)
            } else if heartRateDifferencePercentage >= 10 {
                let statusText = Text("Average")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.yellow)
                return (titleText, statusText)
            } else {
                let statusText = Text("Suboptimal")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
                return (titleText, statusText)
            }
        } else {
            // When the watch was not worn, display "Heart Rate Dip" without a status
            let titleText = Text("Heart Rate Dip")
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundColor(.white)
            return (titleText, Text(""))
        }
    }
    
    var body: some View {
        HStack {
            ZStack {
                Circle()
                    .stroke(Color.red, lineWidth: 10)
                    .frame(width: 70, height: 70)
                
                // Adjust the display based on whether the watch was worn
                Text(watchWasWorn ? "\(Int(heartRateDifferencePercentage))%" : "0%")
                    .font(.title3)
                    .bold()
                    .foregroundColor(.white)
            }
            .padding(.leading, 22)
            
            VStack(alignment: .leading) {
                HStack {
                    heartRateDipTitle.0 + heartRateDipTitle.1
                }
                
                Text("Your Heart Rate Dip during sleep is the percentage difference between your waking non-active heart rate ")
                    .font(.caption)
                    .foregroundColor(.gray)
                +
                Text("\(Int(averageWakingHeartRate))")
                    .font(.caption)
                    .foregroundColor(.green)
                    .bold()
                +
                Text(" BPM versus your average heart rate during sleep for the night before ")
                    .font(.caption)
                    .foregroundColor(.gray)
                +
                Text("\(Int(averageHeartRateDuringSleep))")
                    .font(.caption)
                    .foregroundColor(.green)
                    .bold()
                +
                Text(" BPM.")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.leading, 10)
            .padding(.bottom, 10)
            .padding(.top,10)
            
            Spacer()
        }
    }
}

struct SleepInfoPopoverView: View {
    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    // First Paragraph with "Sleep Score:" in bold
                    Text("Sleep Score: ").font(.system(size: 18)).bold().foregroundColor(.green) +
                    Text("Your sleep score represents your sleep last night versus your target sleep goals. The target sleep is 7 hours of total sleep, 1 hour of deep sleep, and 2 hours of REM sleep, with deep sleep making up the largest portion of the score.")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                    
                    // Second Paragraph with "Restorative Sleep:" in bold
                    Text("Restorative Sleep: ").font(.system(size: 18)).bold().foregroundColor(.blue) +
                    Text("Restorative sleep consists of the last two stages of sleep: deep sleep and rapid eye movement (REM) sleep. During sleep, your body repairs itself, with REM sleep refreshing the brain. Studies have shown that deep sleep should ideally represent 13-23% of your total sleep, and 20-25% should be allocated to REM sleep for optimal restorative sleep.")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                    
                    // Third Paragraph with "Heart Rate Dip:" in bold
                    Text("Heart Rate Dip: ").font(.system(size: 18)).bold().foregroundColor(.red) +
                    Text("Heart rate dip is the percentage difference between your average non-active heart rate for the previous day and your average sleeping heart rate for the previous night. The goal is to achieve a high heart rate dip, with anything over 20% being considered good, anything between 10-20% being average, and under 10% being suboptimal.")
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }
                .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(VisualEffectBlur(blurStyle: .dark)) // Blur effect for the background
        .cornerRadius(20)
        .padding(.top, UIApplication.shared.windows.first?.safeAreaInsets.top)
    }
}

struct VisualEffectBlur: UIViewRepresentable {
    var blurStyle: UIBlurEffect.Style
    
    func makeUIView(context: Context) -> UIVisualEffectView {
        return UIVisualEffectView(effect: UIBlurEffect(style: blurStyle))
    }
    
    func updateUIView(_ uiView: UIVisualEffectView, context: Context) {}
}

