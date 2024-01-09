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
            let averageWalkingHeartRate = self.averageWakingHeartRate
            let averageHeartRateDuringSleep = self.averageHeartRateDuringSleep

            // Calculate the percentage difference
            if averageWalkingHeartRate != 0 {
                let difference =  averageWakingHeartRate - averageHeartRateDuringSleep
                let percentageDifference = (difference / averageWakingHeartRate) * 100.0
                
                // Print statements to check the values
                print("Average Waking Heart Rate: \(averageWakingHeartRate)")
                print("Average Heart Rate During Sleep: \(averageHeartRateDuringSleep)")
                print("Heart Rate Difference Percentage: \(percentageDifference)%")
                
                return percentageDifference
            } else {
                return 0.0 // Handle the case where averageWalkingHeartRate is zero to avoid division by zero.
            }
        }
        
    
    private var sleepSamples: [HKCategorySample] = []
    
    init() {
        fetchSleepData()
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

//
//    private func fetchAverageWalkingHeartRate(completion: @escaping (Double?, Error?) -> Void) {
//        // Check if HealthKit is available on this device
//        guard HKHealthStore.isHealthDataAvailable() else {
//            completion(nil, NSError(domain: "com.yourapp.healthkit", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device."]))
//            return
//        }
//
//        // Create a HealthKit store instance
//        let healthStore = HKHealthStore()
//
//        // Define the type of data you want to fetch (heart rate)
//        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
//
//        // Create a predicate to filter the data (if needed)
//        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictStartDate)
//
//        // Create a query to fetch heart rate samples
//        let query = HKStatisticsQuery(quantityType: heartRateType,
//                                      quantitySamplePredicate: predicate,
//                                      options: .discreteAverage) { (query, result, error) in
//            if let result = result, let averageHeartRate = result.averageQuantity() {
//                // Calculate the average walking heart rate (e.g., for the past day)
//                let bpm = averageHeartRate.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
//                completion(bpm, nil)
//            } else {
//                completion(nil, error)
//            }
//        }
//
//        // Execute the query
//        healthStore.execute(query)
//    }


    private func fetchAverageWakingHeartRate(completion: @escaping (Double?, Error?) -> Void) {
        print("Fetching average waking heart rate, excluding readings above 70 BPM.")

        guard HKHealthStore.isHealthDataAvailable() else {
            completion(nil, NSError(domain: "com.yourapp.healthkit", code: 1, userInfo: [NSLocalizedDescriptionKey: "HealthKit is not available on this device."]))
            return
        }

        let healthStore = HKHealthStore()
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!

        // Fetch the sleep end time to determine waking time
        getSleepTimesYesterday { sleepStartTime, sleepEndTime in
            guard let sleepEndTime = sleepEndTime else {
                print("Unable to fetch sleep end time for yesterday.")
                completion(nil, NSError(domain: "com.yourapp.healthkit", code: 2, userInfo: [NSLocalizedDescriptionKey: "Unable to fetch sleep end time."]))
                return
            }

            let now = Date()
            let predicate = HKQuery.predicateForSamples(withStart: sleepEndTime, end: now, options: .strictStartDate)

            let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
                if let error = error {
                    print("Error fetching heart rate samples: \(error.localizedDescription)")
                    completion(nil, error)
                    return
                }

                guard let heartRateSamples = results as? [HKQuantitySample] else {
                    print("No heart rate data available.")
                    completion(nil, nil)
                    return
                }

                let filteredSamples = heartRateSamples.filter { $0.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())) <= 80 }
                let averageHeartRate = filteredSamples.reduce(0.0) { sum, sample in sum + sample.quantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())) } / Double(filteredSamples.count)

                print("Average Waking Heart Rate (excluding >100 BPM): \(averageHeartRate)")
                DispatchQueue.main.async {
                    completion(averageHeartRate, nil)
                }
            }

            healthStore.execute(query)
        }
    }


    
    
    private func fetchAverageHeartRateDuringSleep(completion: @escaping (Double?, Error?) -> Void) {
        print("Fetching average heart rate during sleep.")

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

            // Debugging output
            print("Sleep start time: \(sleepStartTime), Sleep end time: \(sleepEndTime)")

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
                    print("Average Heart Rate During Sleep: \(bpm)")
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
        print("Sleep Score: \(sleepScore)")
        
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
                    .padding()
                
                Text("Heart Rate Difference: \(dailySleepModel.heartRateDifferencePercentage, specifier: "%.2f")%")
                    .font(.caption)
                    .foregroundColor(.gray)

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
    let query = HKSampleQuery(sampleType: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
                              predicate: predicate,
                              limit: HKObjectQueryNoLimit,
                              sortDescriptors: [sortDescriptor]) { (query, samples, error) in
        
        guard error == nil, let sleepSamples = samples as? [HKCategorySample], let lastSleep = sleepSamples.first else {
            completion(nil, nil)
            return
        }
        
        let sleepStart = lastSleep.startDate
        let sleepEnd = lastSleep.endDate
        
        completion(sleepStart, sleepEnd)
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


