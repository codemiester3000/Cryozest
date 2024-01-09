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
    
    
    init() {
        fetchSleepData()
    }
    
    private func fetchSleepData() {
        HealthKitManager.shared.requestAuthorization { [weak self] authorized, error in
            if authorized {
                HealthKitManager.shared.fetchSleepData { samples, error in
                    guard let self = self, let sleepSamples = samples as? [HKCategorySample], error == nil else { return }
                    
                    self.updateSleepData(with: sleepSamples)
                    
                    // Calculate and update sleep score
                    let totalSleep = self.calculateTotalDuration(samples: sleepSamples, for: .asleepUnspecified)
                    let deepSleep = self.calculateTotalDuration(samples: sleepSamples, for: .asleepDeep)
                    let remSleep = self.calculateTotalDuration(samples: sleepSamples, for: .asleepREM)
                    
                    DispatchQueue.main.async {
                        self.sleepScore = calculateSleepScore(totalSleep: totalSleep, deepSleep: deepSleep, remSleep: remSleep)
                    }
                }
            } else {
                // Handle errors or lack of authorization
            }
        }
    }

    
    
    private func updateSleepData(with samples: [HKCategorySample]) {
        let awakeDuration = calculateTotalDuration(samples: samples, for: .awake)
        let remDuration = calculateTotalDuration(samples: samples, for: .asleepREM)
        let coreDuration = calculateTotalDuration(samples: samples, for: .asleepCore)
        let deepDuration = calculateTotalDuration(samples: samples, for: .asleepDeep)
        
        // Assuming 'light' sleep is 'unspecified' in this context
        let lightDuration = calculateTotalDuration(samples: samples, for: .asleepUnspecified)
        
        DispatchQueue.main.async {
            self.sleepData = SleepData(awake: awakeDuration, rem: remDuration, core: coreDuration, deep: deepDuration)
        }
    }
    
    private func calculateTotalDuration(samples: [HKCategorySample], for sleepStage: HKCategoryValueSleepAnalysis) -> TimeInterval {
        return samples.filter { $0.categoryType.identifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue && $0.value == sleepStage.rawValue }
            .reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
        
    }
    
    private func calculateTotalTime(samples: [HKCategorySample], for sleepStage: HKCategoryValueSleepAnalysis) -> String {
        let totalSeconds = samples.filter { $0.categoryType.identifier == HKCategoryTypeIdentifier.sleepAnalysis.rawValue && $0.value == sleepStage.rawValue }
            .reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
        return formatTimeInterval(totalSeconds)
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
}

func calculateSleepScore(totalSleep: TimeInterval, deepSleep: TimeInterval, remSleep: TimeInterval) -> Double {
    let totalSleepTarget: TimeInterval = 420 * 60 // 7 hours in seconds
    let deepSleepTarget: TimeInterval = 60 * 60  // 1 hour in seconds
    let remSleepTarget: TimeInterval = 120 * 60  // 2 hours in seconds

    let totalSleepScore = min(totalSleep / totalSleepTarget, 1.0) * 40 // 40% of the score
    let deepSleepScore = min(deepSleep / deepSleepTarget, 1.0) * 40 // 40% of the score
    let remSleepScore = min(remSleep / remSleepTarget, 1.0) * 20 // 20% of the score

    return totalSleepScore + deepSleepScore + remSleepScore // Total score
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
                    VStack(alignment: .leading, spacing: 4) { // VStack for title and sleep time
                        Text("Sleep Performance")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                        
                        Text("\(sleepStartTime) to \(sleepEndTime)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 22)
                    .padding(.top, 16)

                    Spacer() // This will push the ProgressRingView to the right
                    
                    ProgressRingView(progress: dailySleepModel.sleepScore / 100, progressColor: .blue)
                        .frame(width: 100, height: 100)
                        .padding()
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
            }
            .onAppear {
                // Fetch and update sleep start and end times
                fetchSleepTimes()
            }
        }
    }

    private func fetchSleepTimes() {
                      // Use your own logic to fetch the sleep start and end times here
                      // You can update the sleepStartTime and sleepEndTime properties accordingly
                      // For example, you can call the getSleepTimesYesterday function mentioned earlier
                      
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
    // Define the date range for "last night"
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date())
        let startDate = calendar.date(byAdding: .day, value: -1, to: endDate)

        // Create the predicate for the query
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        // Define the sleep analysis query
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
                                  predicate: predicate,
                                  limit: HKObjectQueryNoLimit,
                                  sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            
            guard error == nil, let sleepSamples = samples as? [HKCategorySample], let lastSleep = sleepSamples.first else {
                completion(nil, nil)
                return
            }

            // Extract start and end times
            let sleepStart = lastSleep.startDate
            let sleepEnd = lastSleep.endDate

            // Call completion handler
            completion(sleepStart, sleepEnd)
        }

        // Execute the query
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
        max(sleepData.awake + sleepData.rem + sleepData.core + sleepData.deep, 1) // Avoid division by zero
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
    
    
    
    var body: some View {
        VStack(spacing: 16) {
            //            Text("Sleep Stages")
            //                .font(.title2)
            //                .fontWeight(.semibold)
            //                .frame(maxWidth: .infinity, alignment: .leading)
            //                .padding(.horizontal, 16)
            
            HStack(alignment: .bottom, spacing: 12) {
                GraphBarView(color: .red, heightFraction: sleepData.awake / totalSleepTime, label: "Awake", value: sleepData.awake)
                GraphBarView(color: .purple, heightFraction: sleepData.rem / totalSleepTime, label: "REM", value: sleepData.rem)
                GraphBarView(color: .yellow, heightFraction: sleepData.core / totalSleepTime, label: "Core", value: sleepData.core)
                GraphBarView(color: .blue, heightFraction: sleepData.deep / totalSleepTime, label: "Deep", value: sleepData.deep)
            }
            .frame(height: 150)
            .padding(.horizontal, 16)
            
            Text("Total Sleep Time: \(formatTimeInterval(totalSleepTime))")
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
        }
        .padding(.vertical, 20)
        .background(Color(.black))
        .padding([.horizontal, .bottom])
    }
}

struct GraphBarView: View {
    var color: Color
    var heightFraction: CGFloat // fraction of the total height
    var label: String
    var value: TimeInterval
    
    private var barHeight: CGFloat {
        max(150 * heightFraction, 10) // Ensure a minimum height of 10 for visibility
    }
    
    private func formatTimeInterval(_ interval: TimeInterval) -> String {
        let hours = Int(interval) / 3600
        let minutes = Int(interval) % 3600 / 60
        return "\(hours)h \(minutes)m"
    }
    
    var body: some View {
        VStack {
            Spacer()
            Rectangle()
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
    var progress: Double // The progress value, between 0 and 1
    var progressColor: Color // The color of the progress ring
    var thickness: CGFloat = 8

    var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: thickness)
                .foregroundColor(Color.gray.opacity(0.5))
                .frame(width: 120, height: 120)

            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(style: StrokeStyle(lineWidth: thickness, lineCap: .round))
                .foregroundColor(progressColor)
                .rotationEffect(.degrees(-90))
                .frame(width: 120, height: 120)

            Text(String(format: "%.0f%%", min(progress, 1.0) * 100))
                .font(.title2)
                .bold()
        }
    }
}


struct RestorativeSleepView: View {
    var deepSleep: TimeInterval
    var remSleep: TimeInterval
    var totalSleep: TimeInterval
    
    private var restorativePercentage: Double {
        let totalRestorative = deepSleep + remSleep
        return totalRestorative / totalSleep
    }

    var body: some View {
        VStack {
            Text("Restorative Sleep")
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
            
            ZStack {
                Circle()
                    .stroke(lineWidth: 8)
                    .foregroundColor(Color.gray.opacity(0.5))
                    .frame(width: 120, height: 120)
                
                Circle()
                    .trim(from: 0, to: CGFloat(min(restorativePercentage, 1.0)))
                    .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .foregroundColor(Color.green) // You can change the color to your preference
                    .rotationEffect(.degrees(-90))
                    .frame(width: 120, height: 120)
                
                Text(String(format: "%.0f%%", min(restorativePercentage, 1.0) * 100))
                    .font(.title2)
                    .bold()
            }
        }
    }
}
