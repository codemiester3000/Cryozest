import SwiftUI
import HealthKit

class ExertionModel: ObservableObject {
    
    @Published var selectedDate: Date
    
    let healthStore = HKHealthStore()
    
    @Published var exertionScore: Double = 0.0
    @Published var zoneTimes: [Double] = []
    @Published var recoveryMinutes: Double = 0
    @Published var conditioningMinutes: Double = 0
    @Published var overloadMinutes: Double = 0
    @Published var avgRestingHeartRate: Double = 0
    @Published var heartRateZoneRanges: [(lowerBound: Double, upperBound: Double)] = []
    
    var maxExertionTime: Double {
        let maxTime = max(recoveryMinutes, conditioningMinutes, overloadMinutes)
        return maxTime == 0 ? 1 : maxTime
    }

    init(selectedDate: Date) {
        self.selectedDate = selectedDate
        fetchExertionScoreAndTimes(forDate: selectedDate)
    }
    
    func fetchExertionScoreAndTimes(forDate date: Date) {
        // Fetch the user's age
        HealthKitManager.shared.fetchUserAge { [weak self] (age: Int?, error: Error?) in
            guard let self = self else { return }
            let userAge = age ?? 30 // Use the fetched age or default to 30
            
            // Fetch the average resting heart rate
            HealthKitManager.shared.fetchAvgRestingHeartRate(numDays: 30) { [weak self] avgRestingHeartRate in
                guard let self = self, let avgRestingHeartRate = avgRestingHeartRate else {
                    return
                }
                
                DispatchQueue.main.async {
                    self.avgRestingHeartRate = avgRestingHeartRate
                }
                
                self.calculateHeartRateZoneRanges(userAge: userAge, avgRestingHeartRate: avgRestingHeartRate)
                
//                let startDate = Calendar.current.startOfDay(for: Date())
//                let endDate = Date()
                
                // TODO: ADDED THIS INSTEAD OF THE TWO LINES ABOVE
                let calendar = Calendar.current
                let startDate = calendar.startOfDay(for: date) // Now uses 'date' parameter
                let endDate = calendar.date(byAdding: .day, value: 1, to: startDate)! // End of the 'date' parameter's day
                
                // Fetch heart rate data
                HealthKitManager.shared.fetchHeartRateData(from: startDate, to: endDate) { (results, error) in
                    guard let results = results else {
                        print("Error fetching heart rate data: \(error?.localizedDescription ?? "Unknown error")")
                        return
                    }
                    
                    // Calculate exertion score
                    DispatchQueue.global().async {
                        do {
                            let score = try self.calculateExertionScore(
                                userAge: userAge,
                                heartRateData: results,
                                avgRestingHeartRate: self.avgRestingHeartRate
                            )
                            DispatchQueue.main.async {
                                self.exertionScore = score
                                self.updateExertionCategories()
                            }
                        } catch {
                            print("Error calculating exertion score: \(error)")
                        }
                    }
                }
            }
        }
    }
    
    func updateExertionCategories() {
        // This function will be called once the zoneTimes are updated
        if zoneTimes.count >= 3 {
            let recoveryTime = zoneTimes[0]
            let conditioningTime = zoneTimes[1] + zoneTimes[2]
            let overloadTime = zoneTimes.count > 3 ? zoneTimes.dropFirst(3).reduce(0, +) : 0
            
            DispatchQueue.main.async {
                self.recoveryMinutes = recoveryTime
                self.conditioningMinutes = conditioningTime
                self.overloadMinutes = overloadTime
            }
        }
    }
    
    private func calculateExertionScore(userAge: Int, heartRateData: [HKQuantitySample], avgRestingHeartRate: Double) throws -> Double {
        let zoneMultipliers: [Double] = [0.0668, 0.1198, 0.13175, 0.1581, 0.18975].map { $0 * 1 } // ROB: Working on scaling exertion score
        let zoneUpperBoundaries: [Double] = [0.6, 0.7, 0.8, 0.9, 1.1]

        var exertionScore = 0.0
        var tempZoneTimes: [Double] = []

        for (index, upperBoundary) in zoneUpperBoundaries.enumerated() {
            let lowerBoundary = index == 0 ? 0.4 : zoneUpperBoundaries[index - 1]
            let timeInZone = calculateTimeInZone(
                for: heartRateData,
                userAge: userAge,
                lowerBoundMultiplier: lowerBoundary,
                upperBoundMultiplier: upperBoundary,
                avgRestingHeartRate: avgRestingHeartRate
            )
            exertionScore += timeInZone * zoneMultipliers[index]
            tempZoneTimes.append(timeInZone)
        }

        DispatchQueue.main.async {
            self.zoneTimes = tempZoneTimes
        }

        return exertionScore
    }
    
    func calculateHeartRateZoneRanges(userAge: Int, avgRestingHeartRate: Double) {
        let maxHeartRate = 207 - (0.7 * Double(userAge))
        let heartRateReserve = maxHeartRate - avgRestingHeartRate
        let zoneMultipliers = [(0.4, 0.6), (0.6, 0.7), (0.7, 0.8), (0.8, 0.9), (0.9, 1.0)]
        
        heartRateZoneRanges = zoneMultipliers.map { (lowerMultiplier, upperMultiplier) in
            let lowerBoundHeartRate = (heartRateReserve * lowerMultiplier) + avgRestingHeartRate
            let upperBoundHeartRate = (heartRateReserve * upperMultiplier) + avgRestingHeartRate
            return (lowerBoundHeartRate, upperBoundHeartRate)
        }
    }
    
    
    private func calculateTimeInZone(for samples: [HKQuantitySample], userAge: Int, lowerBoundMultiplier: Double, upperBoundMultiplier: Double, avgRestingHeartRate: Double) -> Double {
        var zoneTime: TimeInterval = 0
        var previousSample: HKQuantitySample?
        
        let maxHeartRate = 207 - (0.7 * Double(userAge))
        let heartRateReserve = maxHeartRate - avgRestingHeartRate
        let lowerBoundHeartRate = (heartRateReserve * lowerBoundMultiplier) + avgRestingHeartRate
        let upperBoundHeartRate = (heartRateReserve * upperBoundMultiplier) + avgRestingHeartRate
        
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
        return minutesInZone
    }
    
    func clamp(_ value: Double, to range: ClosedRange<Double>) -> Double {
        return min(max(range.lowerBound, value), range.upperBound)
    }
}
