import SwiftUI
import HealthKit

class ExertionModel: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var exertionScore: Double = 0.0
    @Published var zoneTimes: [Double] = []
    
    
    init() {
        fetchExertionScore()
    }
    
    func fetchExertionScore() {
        // Fetch the user's age from HealthKit or default to 30 if unavailable
        HealthKitManager.shared.fetchUserAge { [weak self] (age: Int?, error: Error?) in
            let userAge = age ?? 30 // Use the fetched age or default to 30
            
            // Set startDate to the beginning of the current day
            let startDate = Calendar.current.startOfDay(for: Date())
            let endDate = Date()
            
            HealthKitManager.shared.fetchHeartRateData(from: startDate, to: endDate) { (results, error) in
                // ... existing implementation ...
                if let error = error {
                    print("Error fetching heart rate data: \(error)")
                    return
                }
                guard let results = results else { return }
                
                DispatchQueue.global().async {
                    do {
                        let score = try self?.calculateExertionScore(userAge: userAge, heartRateData: results)
                        DispatchQueue.main.async {
                            self?.exertionScore = score ?? 0.0
                        }
                    } catch {
                        print("Error calculating exertion score: \(error)")
                    }
                }
            }
        }
    }
    
    
    private func calculateExertionScore(userAge: Int, heartRateData: [HKQuantitySample]) throws -> Double {
        let zoneMultipliers: [Double] = [0.0668, 0.1198, 0.13175, 0.1581, 0.18975]
        let zoneUpperBoundaries: [Double] = [0.6, 0.7, 0.8, 0.9, 1.1]  // Assuming these are the correct percentages of max HR
        
        var exertionScore = 0.0
        
        // Reset zoneTimes on the main thread
        DispatchQueue.main.async {
            self.zoneTimes = []
        }
        
        for (index, upperBoundary) in zoneUpperBoundaries.enumerated() {
            let lowerBoundary = index == 0 ? 0.5 : zoneUpperBoundaries[index - 1]
            let timeInZone = calculateTimeInZone(for: heartRateData, userAge: userAge, lowerBoundMultiplier: lowerBoundary, upperBoundMultiplier: upperBoundary)
            exertionScore += timeInZone * zoneMultipliers[index]
            
            // Append to zoneTimes on the main thread
            DispatchQueue.main.async {
                self.zoneTimes.append(timeInZone)
            }
        }
        
        return exertionScore
    }
    
    private func calculateTimeInZone(for samples: [HKQuantitySample], userAge: Int, lowerBoundMultiplier: Double, upperBoundMultiplier: Double) -> Double {
        var zoneTime: TimeInterval = 0
        var previousSample: HKQuantitySample?
        
        let maxHeartRate = Double(220 - userAge)
        let lowerBoundHeartRate = lowerBoundMultiplier * maxHeartRate
        let upperBoundHeartRate = upperBoundMultiplier * maxHeartRate
        
        for sample in samples {
            let heartRateUnit = HKUnit.count().unitDivided(by: HKUnit.minute())
            let heartRate = sample.quantity.doubleValue(for: heartRateUnit)
            
            if heartRate >= lowerBoundHeartRate && heartRate < upperBoundHeartRate {
                if let previousSample = previousSample {
                    let timeDifference = sample.startDate.timeIntervalSince(previousSample.endDate)
                    zoneTime += timeDifference
                }
                previousSample = sample
            } else {
                previousSample = nil
            }
        }
        
        let minutesInZone = zoneTime / 60
        // Make sure to print on the main thread if you're updating the UI
        DispatchQueue.main.async {
            print("Time in Zone [\(lowerBoundHeartRate)-\(upperBoundHeartRate)]: \(minutesInZone) minutes")
        }
        return minutesInZone
    }
}


func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
    return min(max(range.lowerBound, value), range.upperBound)
}


struct ExertionView: View {
    @ObservedObject var model: ExertionModel

    var body: some View {
        ScrollView {
            VStack {
                HStack {
                    Text("Daily Exertion")
                        .font(.title2) // Adjusted font size
                        .fontWeight(.semibold) // Adjusted font weight
                        .foregroundColor(.white)
                        .padding(.leading)

                    Spacer()

                    ExertionRingView(exertionScore: model.exertionScore)
                        .frame(width: 120, height: 120)
                }
                .padding(.vertical, 20)

                // Dynamically create zoneInfos from model.zoneTimes
                let maxTime = model.zoneTimes.max() ?? 1
                let zoneInfos = model.zoneTimes.enumerated().map { (index, timeInMinutes) -> ZoneInfo in
                    // Define your color array matching the zones
                    let colors: [Color] = [.blue, .cyan, .green, .orange, .pink]
                    let timeSpentString = formatTime(timeInMinutes: timeInMinutes)
                    
                    return ZoneInfo(
                        zoneNumber: index + 1,
                        timeSpent: timeSpentString,
                        color: colors[index % colors.count],
                        timeInMinutes: timeInMinutes
                    )
                }

                ForEach(zoneInfos, id: \.zoneNumber) { zoneInfo in
                    ZoneItemView(zoneInfo: zoneInfo, maxTime: maxTime)
                }
            }
            .padding(.horizontal)
        }
        .background(Color.black.edgesIgnoringSafeArea(.all))
    }
    
    // Helper function to format the time from minutes to a string
    func formatTime(timeInMinutes: Double) -> String {
        let totalSeconds = Int(timeInMinutes * 60)
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}




struct ExertionRingView: View {
    var exertionScore: Double
    let maxExertionScore = 12.0  // Adjust this maximum score as needed

    var body: some View {
        let progress = clamp(exertionScore / maxExertionScore, to: 0...1)

        ZStack {
                  Circle()
                      .stroke(lineWidth: 8)
                      .foregroundColor(Color.gray.opacity(0.5))
                      .frame(width: 120, height: 120) // Set frame size to match Ready to Train circle

                  Circle()
                      .trim(from: 0, to: CGFloat(progress))
                      .stroke(style: StrokeStyle(lineWidth: 8, lineCap: .round))
                      .foregroundColor(Color.orange)
                      .rotationEffect(.degrees(-90))
                      .frame(width: 120, height: 120) // Set frame size to match Ready to Train circle

                  Text("\(exertionScore, specifier: "%.2f")")
                      .font(.title3)
                      .fontWeight(.bold)
                      .multilineTextAlignment(.center)
                      .foregroundColor(.white)
              }
          }
      }

struct ZoneInfo {
    var zoneNumber: Int
    var timeSpent: String
    var color: Color
    var timeInMinutes: Double  // Add this property to store the time in minutes
}


struct ZoneItemView: View {
    var zoneInfo: ZoneInfo
    var maxTime: Double

    var body: some View {
        HStack {
            Circle()
                .fill(zoneInfo.color)
                .frame(width: 10, height: 10)
            Text("Zone \(zoneInfo.zoneNumber)")
                .foregroundColor(.white)
                .padding(.leading, 5)
            
            Spacer()

            // Foreground of the progress bar
            GeometryReader { geometry in
                ZStack(alignment: .leading) {
                    Rectangle()
                        .frame(width: geometry.size.width, height: 5)
                        .foregroundColor(Color.gray.opacity(0.3))
                        .cornerRadius(2.5)

                    if zoneInfo.timeInMinutes > 0 {
                        Rectangle()
                            .frame(width: geometry.size.width * CGFloat(zoneInfo.timeInMinutes / maxTime), height: 5)
                            .foregroundColor(zoneInfo.color)
                            .cornerRadius(2.5)
                    }
                }
            }
            .frame(height: 5)

            Text(zoneInfo.timeSpent)
                .foregroundColor(.white)
                .padding(.leading, 5)
        }
        .padding()
        .background(Color.black.opacity(0.8))
        .cornerRadius(5)
    }
}
