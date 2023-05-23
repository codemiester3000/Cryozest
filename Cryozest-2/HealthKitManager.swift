import Foundation
import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()

    private let healthStore = HKHealthStore()
    private let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
    private let respirationRateType = HKObjectType.quantityType(forIdentifier: .respiratoryRate)!
    private let spo2Type = HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!

    private init() {}

    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        let typesToRead: Set<HKObjectType> = [heartRateType, respirationRateType, spo2Type]

        healthStore.requestAuthorization(toShare: [], read: typesToRead) { success, error in
            print("Authorization status: \(success), error: \(String(describing: error))")
            completion(success, error)
        }
    }

    func fetchHealthData(from startDate: Date, to endDate: Date, completion: @escaping ((avgHeartRate: Double, avgSpo2: Double, avgRespirationRate: Double)?) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)

        var avgHeartRate: Double = 0
        var avgSpo2: Double = 0
        var avgRespirationRate: Double = 0

        let group = DispatchGroup()

        group.enter()
        let heartRateQuery = createAvgStatisticsQuery(for: heartRateType, with: predicate) { statistics in
            if let statistics = statistics, let heartRate = statistics.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min")) {
                print("Fetched average heart rate: \(heartRate)")
                avgHeartRate = heartRate
            } else {
                print("Failed to fetch average heart rate or no heart rate data available")
            }
            group.leave()
        }
        healthStore.execute(heartRateQuery)

        group.enter()
        let spo2Query = createAvgStatisticsQuery(for: spo2Type, with: predicate) { statistics in
            if let statistics = statistics, let spo2 = statistics.averageQuantity()?.doubleValue(for: HKUnit.percent()) {
                print("Fetched average SpO2: \(spo2)")
                avgSpo2 = spo2
            } else {
                print("Failed to fetch average SpO2 or no SpO2 data available")
            }
            group.leave()
        }
        healthStore.execute(spo2Query)

        group.enter()
        let respirationRateQuery = createAvgStatisticsQuery(for: respirationRateType, with: predicate) { statistics in
            if let statistics = statistics, let respirationRate = statistics.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min")) {
                print("Fetched average respiration rate: \(respirationRate)")
                avgRespirationRate = respirationRate
            } else {
                print("Failed to fetch average respiration rate or no respiration rate data available")
            }
            group.leave()
        }
        healthStore.execute(respirationRateQuery)

        group.notify(queue: .main) {
            print("All queries completed. Average Heart Rate: \(avgHeartRate), Average SpO2: \(avgSpo2), Average Respiration Rate: \(avgRespirationRate)")
            completion((avgHeartRate, avgSpo2, avgRespirationRate))
        }
    }

    private func createAvgStatisticsQuery(for type: HKQuantityType, with predicate: NSPredicate, completion: @escaping (HKStatistics?) -> Void) -> HKStatisticsQuery {
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteAverage) { _, statistics, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error during \(type.identifier) query: \(error)")
                }
                completion(statistics)
            }
        }
        return query
    }
}
