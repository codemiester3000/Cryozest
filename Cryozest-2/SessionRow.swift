import SwiftUI
import HealthKit

struct SessionRow: View {
    var session: TherapySessionEntity
    var therapyTypeSelection: TherapyTypeSelection
    var therapyTypeName: String

    @State private var averageHeartRateForDay: Double? = nil
    @State private var averageHRVForDay: Double? = nil

    var body: some View {
            VStack(alignment: .leading, spacing: 16) {
                // Date and Therapy Type
                HStack {
                    Text(formattedDate)
                        .font(.headline)
                        .foregroundColor(.white)
                    Spacer()
                    Text(therapyTypeName)
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(therapyTypeSelection.selectedTherapyType.color)
                }

                Divider().background(Color.white.opacity(0.8))

                // Session Metrics
                HStack {
                    Label("\(formattedDuration)", systemImage: "clock")
                        .foregroundColor(.white)
                    Spacer()
                    Text("\(Int(session.temperature))°F")
                        .font(.subheadline)
                        .fontWeight(.medium)
                        .foregroundColor(.white)
                }

                HeartRateView(title: "Average Heart Rate", value: session.averageHeartRate)
                HeartRateView(title: "Min Heart Rate", value: session.minHeartRate, maxValue: 1000)
                HeartRateView(title: "Max Heart Rate", value: session.maxHeartRate)

                Divider().background(Color.white.opacity(0.8))

                // Daily Metrics
                VStack(alignment: .leading, spacing: 8) {
                    if averageHeartRateForDay != nil || averageHRVForDay != nil {
                        Text("Daily Metrics")
                            .font(.headline)
                            .foregroundColor(.white)
                    }

                    if let avgHeartRate = averageHeartRateForDay {
                        Text("Average Heart Rate for the Day: \(Int(avgHeartRate)) bpm")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }

                    if let avgHRV = averageHRVForDay {
                        Text("Average HRV for the Day: \(String(format: "%.2f", avgHRV)) ms")
                            .font(.subheadline)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding()
            //.background(Color(.darkGray))
            .cornerRadius(16)
            .shadow(radius: 5)
            .onAppear {
                loadAverageHeartRate()
                loadAverageHRV()
            }
        }

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .long
        return formatter.string(from: session.date ?? Date())
    }

    private var formattedDuration: String {
        let minutes = Int(session.duration) / 60
        let seconds = Int(session.duration) % 60
        return minutes == 0 ? "\(seconds) secs" : "\(minutes) mins \(seconds) secs"
    }

    private func HeartRateView(title: String, value: Double, maxValue: Double = 0) -> some View {
        let roundedValue = Int((value * 10).rounded() / 10)
        return Group {
            if Double(roundedValue) != maxValue {
                HStack {
                    Image(systemName: "heart.fill")
                        .foregroundColor(therapyTypeSelection.selectedTherapyType.color)
                        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                    Text("\(title): \(roundedValue) bpm")
                        .font(.system(size: 16, design: .monospaced))
                        .foregroundColor(.white)
                        .shadow(color: .black.opacity(0.1), radius: 1, x: 0, y: 1)
                }
            }
        }
    }


    private func loadAverageHeartRate() {
        guard let sessionDate = session.date else { return }
        HealthKitManager.shared.fetchAvgHeartRateForDays(days: [sessionDate]) { averageHeartRate in
            self.averageHeartRateForDay = averageHeartRate
        }
    }

    private func loadAverageHRV() {
        guard let sessionDate = session.date else { return }
        
        HealthKitManager.shared.fetchAvgHRVForDays(days: [sessionDate]) { averageHRV in
            self.averageHRVForDay = averageHRV
        }
    }
}

