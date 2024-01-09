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

    init() {
        fetchSleepData()
    }

    private func fetchSleepData() {
        HealthKitManager.shared.requestAuthorization { [weak self] authorized, error in
            if authorized {
                HealthKitManager.shared.fetchSleepData { samples, error in
                    guard let self = self, let sleepSamples = samples as? [HKCategorySample], error == nil else { return }

                    // Now we call updateSleepData to process the fetched samples.
                    self.updateSleepData(with: sleepSamples)
                    
                    // Then we can update the string properties for display.
                    self.totalTimeAsleep = self.formatTimeInterval(self.calculateTotalDuration(samples: sleepSamples, for: .asleepUnspecified))
                    self.totalDeepSleep = self.formatTimeInterval(self.calculateTotalDuration(samples: sleepSamples, for: .asleepDeep))
                    self.totalCoreSleep = self.formatTimeInterval(self.calculateTotalDuration(samples: sleepSamples, for: .asleepCore))
                    self.totalRemSleep = self.formatTimeInterval(self.calculateTotalDuration(samples: sleepSamples, for: .asleepREM))
                    self.totalTimeAwake = self.formatTimeInterval(self.calculateTotalDuration(samples: sleepSamples, for: .awake))
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

func calculateSleepScore(totalSleep: TimeInterval, deepSleep: TimeInterval, remSleep: TimeInterval, coreSleep: TimeInterval) -> Double {
    let totalSleepTarget: TimeInterval = 420 * 60 // 7 hours in seconds
    let deepSleepTarget: TimeInterval = 60 * 60  // 1 hour in seconds
    let remSleepTarget: TimeInterval = 120 * 60  // 2 hours in seconds

    let totalSleepScore = min(totalSleep / totalSleepTarget, 1.0) * 50
    let deepSleepScore = min(deepSleep / deepSleepTarget, 1.0) * 20
    let remSleepScore = min(remSleep / remSleepTarget, 1.0) * 20
    let coreSleepScore = min(coreSleep / (totalSleepTarget - remSleepTarget - deepSleepTarget), 1.0) * 10

    return totalSleepScore + deepSleepScore + remSleepScore + coreSleepScore
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
        let coreSleep = sleepData["Core Sleep"] ?? 0

        let sleepScore = calculateSleepScore(totalSleep: totalSleep, deepSleep: deepSleep, remSleep: remSleep, coreSleep: coreSleep)
        completion(sleepScore)
    }
}


struct DailySleepView: View {
    @ObservedObject var dailySleepModel = DailySleepViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("Daily Sleep")
                    .font(.title2)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity, alignment: .leading) // Align text to the left
                    .padding(.horizontal, 22) // Horizontal padding of 22
                    .padding(.top, 16) // Top padding

                if let sleepData = dailySleepModel.sleepData {
                    Spacer(minLength: 20) // Add space between text and graph
                    SleepGraphView(sleepData: sleepData)
                        .frame(height: 200) // Graph height
                } else {
                    Spacer(minLength: 20) // Add space between text and placeholder
                    Text("Sleep data is not available yet.")
                }
            }
            .padding([.horizontal, .bottom])
        }
    }
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
