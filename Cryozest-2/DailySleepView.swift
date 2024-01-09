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


        // Calculate the percentage difference
        if averageWakingHeartRate != 0 {
            let difference =  averageWakingHeartRate - averageHeartRateDuringSleep
            let percentageDifference = (difference / averageWakingHeartRate) * 100.0
            
            // Additional debugging statement to check the final calculated value
            
            return percentageDifference
        } else {
            // Handling the case where averageWakingHeartRate is zero
            print("Average Waking Heart Rate is zero, unable to calculate Heart Rate Difference Percentage.")
            return 0.0
        }
    }

        
    
    private var sleepSamples: [HKCategorySample] = []
    
    init() {
            fetchSleepData()
            fetchAverageWakingHeartRate { bpm, _ in
                if let bpm = bpm {
                    DispatchQueue.main.async {
                        self.averageWakingHeartRate = bpm
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
                            if let bpm = bpm {
                                self.averageWakingHeartRate = bpm
                            }
                            // Handle error if needed
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

        // Debugging: Print search period for wake-up time
        print("Searching for wake-up time between \(earliestWakeUpTime) and \(latestWakeUpTime)")

        let predicate = HKQuery.predicateForSamples(withStart: earliestWakeUpTime, end: latestWakeUpTime, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            if let error = error {
                print("Error fetching wake-up time: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let sleepSamples = samples as? [HKCategorySample], let lastSleepSession = sleepSamples.first else {
                print("No wake-up time found for the specified period.")
                completion(nil)
                return
            }

            let wakeUpTime = lastSleepSession.endDate
            print("Fetched wake-up time: \(wakeUpTime)")
            completion(wakeUpTime)
        }

        HKHealthStore().execute(query)
    }


    private func fetchSleepStartTimeCurrentDay(completion: @escaping (Date?) -> Void) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let startOfSleepSearch = calendar.date(bySettingHour: 20, minute: 0, second: 0, of: today.addingTimeInterval(-24*60*60))! // 8 PM on Jan 8th
        let endOfSleepSearch = calendar.date(bySettingHour: 3, minute: 0, second: 0, of: today)! // 3 AM on Jan 9th

        // Debugging: Print search period
        print("Searching for sleep start time between \(startOfSleepSearch) and \(endOfSleepSearch)")

        let predicate = HKQuery.predicateForSamples(withStart: startOfSleepSearch, end: endOfSleepSearch, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            if let error = error {
                print("Error fetching sleep start time: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let sleepSamples = samples as? [HKCategorySample], let firstSleepSession = sleepSamples.first else {
                print("No sleep start time found for the specified period.")
                completion(nil)
                return
            }

            let sleepStartTime = firstSleepSession.startDate
            print("Fetched sleep start time: \(sleepStartTime)")
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

        fetchWakeUpTimePreviousDay { wakeUpTimePreviousDay in
            guard let wakeUpTimePreviousDay = wakeUpTimePreviousDay else {
                print("Unable to fetch wake-up time for the previous day.")
                completion(nil, NSError(domain: "com.yourapp.healthkit", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch wake-up time for the previous day."]))
                return
            }

            self.fetchSleepStartTimeCurrentDay { sleepStartTimeCurrentDay in
                guard let sleepStartTimeCurrentDay = sleepStartTimeCurrentDay else {
                    print("Unable to fetch sleep start time for the current day.")
                    completion(nil, NSError(domain: "com.yourapp.healthkit", code: 3, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch sleep start time for the current day."]))
                    return
                }

                let predicate = HKQuery.predicateForSamples(withStart: wakeUpTimePreviousDay, end: sleepStartTimeCurrentDay, options: .strictStartDate)
                
                // Debugging: Convert dates to Pacific Time for readability
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                dateFormatter.timeZone = TimeZone(identifier: "America/Los_Angeles")
                let wakeUpTimeString = dateFormatter.string(from: wakeUpTimePreviousDay)
                let sleepStartTimeString = dateFormatter.string(from: sleepStartTimeCurrentDay)
                print("Fetching waking heart rate from \(wakeUpTimeString) to \(sleepStartTimeString) Pacific Time")

                let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
                    if let error = error {
                        completion(nil, error)
                        return
                    }

                    guard let heartRateSamples = results as? [HKQuantitySample] else {
                        completion(nil, nil)
                        return
                    }

                    let filteredSamples = heartRateSamples.filter { $0.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())) <= 80 }
                    let averageHeartRate = filteredSamples.reduce(0.0) { sum, sample in sum + sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())) } / Double(filteredSamples.count)

                    DispatchQueue.main.async {
                        completion(averageHeartRate, nil)
                    }
                }

                healthStore.execute(query)
            }
        }
    }


    private func getSleepStartTimeForNextDay(completion: @escaping (Date?) -> Void) {
        let healthStore = HKHealthStore()

        // Ensure sleep data is available
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            print("Sleep data is not available.")
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
                print("Error fetching sleep data: \(error.localizedDescription)")
                completion(nil)
                return
            }

            guard let sleepResults = results as? [HKCategorySample], let lastSleep = sleepResults.first else {
                print("No sleep data available for today.")
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

        // Check if HealthKit is available on this device
        guard HKHealthStore.isHealthDataAvailable() else {
            completion(nil, NSError(domain: "com.yourapp.healthkit", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device."]))
            return
        }

        // Create a HealthKit store instance
        let healthStore = HKHealthStore()

        // Define the type of data you want to fetch (heart rate and sleep)
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!

        // Fetch the sleep times for last night
        getSleepTimesYesterday { sleepStartTime, sleepEndTime in
            guard let sleepStartTime = sleepStartTime, let sleepEndTime = sleepEndTime else {
                print("No sleep times available for last night.")
                completion(nil, nil)
                return
            }


            // Create a predicate for heart rate samples during sleep
            let predicate = HKQuery.predicateForSamples(withStart: sleepStartTime, end: sleepEndTime, options: .strictStartDate)

            // Create a query to fetch heart rate samples during sleep
            let query = HKStatisticsQuery(quantityType: heartRateType, quantitySamplePredicate: predicate, options: .discreteAverage) { (query, result, error) in
                if let error = error {
                    print("Error fetching heart rate samples: \(error.localizedDescription)")
                    completion(nil, error)
                    return
                }

                if let result = result, let averageHeartRate = result.averageQuantity() {
                    // Calculate the average heart rate during sleep
                    let bpm = averageHeartRate.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
                    completion(bpm, nil)
                } else {
                    print("No average heart rate data available for sleep period.")
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
    
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Sleep Performance")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("\(sleepStartTime) to \(sleepEndTime)")
                            .font(.footnote)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
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
                
                
                RestorativeSleepView(viewModel: dailySleepModel)

                
                HeartRateDifferenceProgressCircle(heartRateDifferencePercentage: dailySleepModel.heartRateDifferencePercentage,
                                                  averageWakingHeartRate: dailySleepModel.averageWakingHeartRate,
                                                  averageHeartRateDuringSleep: dailySleepModel.averageHeartRateDuringSleep)

                    }
            
            
            .onAppear {
                
                fetchSleepTimes()
                
            }
        }
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

private func getSleepTimesYesterday(completion: @escaping (Date?, Date?) -> Void) {
    let calendar = Calendar.current
    let endDate = calendar.startOfDay(for: Date())
    let startDate = calendar.date(byAdding: .day, value: -1, to: endDate)

    let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

    let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
    let query = HKSampleQuery(sampleType: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
        guard error == nil, let sleepSamples = samples as? [HKCategorySample] else {
            completion(nil, nil)
            return
        }

        // Filter out 'inBed' samples and focus on 'asleep' samples
        let asleepSamples = sleepSamples.filter { $0.value == HKCategoryValueSleepAnalysis.asleep.rawValue }

        // Find the earliest sleep start time and latest sleep end time
        let sleepStart = asleepSamples.map { $0.startDate }.min()
        let sleepEnd = asleepSamples.map { $0.endDate }.max()

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
                .foregroundColor(.secondary)
            Text(formatTimeInterval(value))
                .font(.caption2)
                .foregroundColor(.secondary)
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
            Circle()
                .stroke(lineWidth: thickness)
                .foregroundColor(Color.gray.opacity(0.5))
                .frame(width: ringSize, height: ringSize)
            
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(style: StrokeStyle(lineWidth: thickness, lineCap: .round))
                .foregroundColor(progressColor)
                .rotationEffect(.degrees(-90))
                .frame(width: ringSize, height: ringSize)
            
            Text(String(format: "%.0f%%", min(progress, 1.0) * 100))
                .font(.title2)
                .bold()
        }
    }
}



struct RestorativeSleepView: View {
    @ObservedObject var viewModel: DailySleepViewModel
    
    var body: some View {
        HStack {
            VStack {
                ProgressRingView(progress: viewModel.restorativeSleepPercentage / 100,
                                 progressColor: .blue,
                                 ringSize: 70)
                .frame(width: 70, height: 70)
            }
            .padding(.leading, 22)
            
            VStack(alignment: .leading) {
                HStack(spacing: 2) {
                    Text(viewModel.formattedRestorativeSleepTime)
                        .font(.headline)
                        .fontWeight(.semibold)
                    Text("of Restorative Sleep")
                        .font(.headline)
                        .fontWeight(.semibold)
                }
                
                Text(viewModel.restorativeSleepDescription)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .padding(.top, 4)
            }
            .padding(.leading, 10)
            
            Spacer()
        }
        .padding(.vertical, 10)
        .background(Color(.systemBackground))
        .cornerRadius(10)
    }
}

struct HeartRateDifferenceProgressCircle: View {
    var heartRateDifferencePercentage: Double
    var averageWakingHeartRate: Double
    var averageHeartRateDuringSleep: Double

    var body: some View {
        HStack {
            // Progress Circle View
            VStack {
                ZStack {
                    Circle()
                        .stroke(Color.red.opacity(0.3), lineWidth: 10)
                        .frame(width: 70, height: 70)

                    Circle()
                        .trim(from: 0.0, to: CGFloat(min(self.heartRateDifferencePercentage / 100, 1.0)))
                        .stroke(Color.red, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                        .rotationEffect(Angle(degrees: -90))
                        .frame(width: 70, height: 70)
                        .animation(.linear(duration: 0.5))
                    

                    Text("\(Int(heartRateDifferencePercentage))%")
                        .font(.title3)
                        .bold()
                        .foregroundColor(.white)
                }
                .frame(width: 70, height: 70)
                .padding(.leading, 22)
            }
            
            
            // Text Section (Reduced left padding)
            VStack(alignment: .leading) {
                Text("Heart Rate Dip")
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
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
