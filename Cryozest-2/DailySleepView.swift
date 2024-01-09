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


struct DailySleepView: View {
    @ObservedObject var dailySleepModel = DailySleepViewModel()

    var body: some View {
        VStack {
//            Text("Total Time Asleep: \(dailySleepModel.totalTimeAsleep)")
//            Text("Total Deep Sleep: \(dailySleepModel.totalDeepSleep)")
//            Text("Total Core Sleep: \(dailySleepModel.totalCoreSleep)")
//            Text("Total REM Sleep: \(dailySleepModel.totalRemSleep)")
//            Text("Total Time Awake: \(dailySleepModel.totalTimeAwake)")
//            
            if let sleepData = dailySleepModel.sleepData {
                         SleepGraphView(sleepData: sleepData)
                             .frame(height: 200) // This is important
            } else {
                Text("Sleep data is not available yet.")
            }
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
            Text("Sleep Stages")
                .font(.title2)
                .fontWeight(.semibold)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
            
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
        .background(Color(.secondarySystemBackground))
        .cornerRadius(20)
        .shadow(color: Color.black.opacity(0.1), radius: 10, x: 0, y: 5)
        .padding(.horizontal)
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
