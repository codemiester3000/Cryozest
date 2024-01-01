import SwiftUI
import HealthKit

class ExertionModel: ObservableObject {
    let healthStore = HKHealthStore()
    
    @Published var exertionScore: Double = 0.0
    
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
        let zoneUpperBoundaries: [Double] = [0.6, 0.7, 0.8, 0.9, 1.0]
        
        var exertionScore = 0.0

        for (index, upperBoundary) in zoneUpperBoundaries.enumerated() {
            let lowerBoundary = index == 0 ? 0.5 : zoneUpperBoundaries[index - 1]
            let timeInZone = calculateTimeInZone(for: heartRateData, userAge: userAge, lowerBoundMultiplier: lowerBoundary, upperBoundMultiplier: upperBoundary)
            exertionScore += timeInZone * zoneMultipliers[index]
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
        print("Time in Zone [\(lowerBoundHeartRate)-\(upperBoundHeartRate)]: \(minutesInZone) minutes")
        return minutesInZone
    }
}


func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
    return min(max(range.lowerBound, value), range.upperBound)
}


struct ExertionView: View {
    @ObservedObject var model: ExertionModel
 
    var body: some View {
        VStack {
            Text("Exertion Score")
                .font(.headline)
                .padding()

            ExertionRingView(exertionScore: model.exertionScore)
                .frame(width: 120, height: 120)
        }
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













