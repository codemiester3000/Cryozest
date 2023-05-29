import Foundation
import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    private let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
    // private let respirationRateType = HKObjectType.quantityType(forIdentifier: .respiratoryRate)!
    // private let spo2Type = HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!
    private let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
    
    private init() {}
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        print("request authorization")
        let typesToRead: Set<HKObjectType> = [heartRateType, bodyMassType]
        
        healthStore.requestAuthorization(toShare: [], read: typesToRead) { success, error in
            print("Authorization status: \(success), error: \(String(describing: error))")
            completion(success, error)
        }
    }
    
    func areHealthMetricsAuthorized(completion: @escaping (Bool) -> Void) {
        let typesToRead: Set<HKObjectType> = [heartRateType]
        
        healthStore.getRequestStatusForAuthorization(toShare: [], read: typesToRead) { (status, error) in
            if let error = error {
                print("Error checking authorization status: \(error)")
                completion(false)
                return
            }
            
            print("owen here", status.rawValue)
            
            switch status {
            case .unnecessary:
                // The system doesn't need to request authorization because the user has already granted access.
                completion(true)
            case .shouldRequest:
                print("here 2")
                // The system needs to request authorization.
                completion(false)
            case .unknown:
                print("here")
                // The system can't determine whether it needs to request authorization.
                completion(false)
            @unknown default:
                print("here 1")
                // Handle potential future cases.
                completion(false)
            }
        }
    }
    
    func fetchMostRecentBodyMass(completion: @escaping (Double?) -> Void) {
        // Don't limit by start date.
        let predicate = HKQuery.predicateForSamples(withStart: nil, end: Date(), options: .strictEndDate)
        
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let bodyMassQuery = HKSampleQuery(sampleType: bodyMassType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            
            // Ensure the samples are not nil and get the first sample
            guard let samples = samples, let sample = samples.first as? HKQuantitySample else {
                print("Failed to fetch most recent body mass")
                completion(nil)
                return
            }
            
            let bodyMass = sample.quantity.doubleValue(for: HKUnit.pound())
            print("Fetched most recent body mass: \(bodyMass)")
            completion(bodyMass)
        }
        
        healthStore.execute(bodyMassQuery)
    }
    
    func fetchHealthData(from startDate: Date, to endDate: Date, completion: @escaping ((avgHeartRate: Double, mostRecentHeartRate: Double, avgSpo2: Double, avgRespirationRate: Double, minHeartRate: Double, maxHeartRate: Double)?) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        var avgHeartRate: Double = 0
        var mostRecentHeartRate: Double = 0
        var minHeartRate: Double = 0
        var maxHeartRate: Double = 0
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
        fetchMinimumHeartRate(from: startDate, to: endDate) { heartRate in
            if let heartRate = heartRate {
                print("Fetched minimum heart rate: \(heartRate)")
                minHeartRate = heartRate
            } else {
                print("Failed to fetch minimum heart rate")
            }
            group.leave()
        }
        
        group.enter()
        fetchMaximumHeartRate(from: startDate, to: endDate) { heartRate in
            if let heartRate = heartRate {
                print("Fetched maximum heart rate: \(heartRate)")
                maxHeartRate = heartRate
            } else {
                print("Failed to fetch maximum heart rate")
            }
            group.leave()
        }
        
//        group.enter()
//        let spo2Query = createAvgStatisticsQuery(for: spo2Type, with: predicate) { statistics in
//            if let statistics = statistics, let spo2 = statistics.averageQuantity()?.doubleValue(for: HKUnit.percent()) {
//                print("Fetched average SpO2: \(spo2)")
//                avgSpo2 = spo2
//            } else {
//                print("Failed to fetch average SpO2 or no SpO2 data available")
//            }
//            group.leave()
//        }
//        healthStore.execute(spo2Query)
//
//        group.enter()
//        let respirationRateQuery = createAvgStatisticsQuery(for: respirationRateType, with: predicate) { statistics in
//            if let statistics = statistics, let respirationRate = statistics.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min")) {
//                print("Fetched average respiration rate: \(respirationRate)")
//                avgRespirationRate = respirationRate
//            } else {
//                print("Failed to fetch average respiration rate or no respiration rate data available")
//            }
//            group.leave()
//        }
//        healthStore.execute(respirationRateQuery)
        
        group.notify(queue: .main) {
            print("All queries completed. Average Heart Rate: \(avgHeartRate), Most Recent Heart Rate: \(mostRecentHeartRate), Minimum Heart Rate: \(minHeartRate), Maximum Heart Rate: \(maxHeartRate), Average SpO2: \(avgSpo2), Average Respiration Rate: \(avgRespirationRate)")
            completion((avgHeartRate, mostRecentHeartRate, avgSpo2, avgRespirationRate, minHeartRate, maxHeartRate))
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
    
    func fetchMostRecentHeartRate(completion: @escaping (Double?) -> Void) {
        let endDate = Date()
        let startDate = endDate.addingTimeInterval(-10) // 10 seconds before the current date/time
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let heartRateQuery = createAvgStatisticsQuery(for: heartRateType, with: predicate) { statistics in
            if let statistics = statistics, let heartRate = statistics.averageQuantity()?.doubleValue(for: HKUnit(from: "count/min")) {
                print("Fetched most recent heart rate over past 10 seconds: \(heartRate)")
                completion(heartRate)
            } else {
                print("Failed to fetch most recent heart rate")
                completion(nil)
            }
        }
        
        healthStore.execute(heartRateQuery)
    }
    
    private func createMostRecentSampleQuery(for type: HKQuantityType, with predicate: NSPredicate, completion: @escaping (HKQuantitySample?) -> Void) -> HKSampleQuery {
        let query = HKSampleQuery(sampleType: type, predicate: predicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)]) { _, samples, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error during \(type.identifier) query: \(error)")
                }
                completion(samples?.first as? HKQuantitySample)
            }
        }
        return query
    }
    
    func fetchMinimumHeartRate(from startDate: Date, to endDate: Date, completion: @escaping (Double?) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let minHeartRateQuery = createMinStatisticsQuery(for: heartRateType, with: predicate) { statistics in
            if let statistics = statistics, let heartRate = statistics.minimumQuantity()?.doubleValue(for: HKUnit(from: "count/min")) {
                print("Fetched minimum heart rate: \(heartRate)")
                completion(heartRate)
            } else {
                print("Failed to fetch minimum heart rate")
                completion(nil)
            }
        }
        
        healthStore.execute(minHeartRateQuery)
    }
    
    func fetchMaximumHeartRate(from startDate: Date, to endDate: Date, completion: @escaping (Double?) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let maxHeartRateQuery = createMaxStatisticsQuery(for: heartRateType, with: predicate) { statistics in
            if let statistics = statistics, let heartRate = statistics.maximumQuantity()?.doubleValue(for: HKUnit(from: "count/min")) {
                print("Fetched maximum heart rate: \(heartRate)")
                completion(heartRate)
            } else {
                print("Failed to fetch maximum heart rate")
                completion(nil)
            }
        }
        
        healthStore.execute(maxHeartRateQuery)
    }
    
    private func createMinStatisticsQuery(for type: HKQuantityType, with predicate: NSPredicate, completion: @escaping (HKStatistics?) -> Void) -> HKStatisticsQuery {
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteMin) { _, statistics, error in
            DispatchQueue.main.async {
                if let error = error {
                    print("Error during \(type.identifier) query: \(error)")
                }
                completion(statistics)
            }
        }
        return query
    }
    
    private func createMaxStatisticsQuery(for type: HKQuantityType, with predicate: NSPredicate, completion: @escaping (HKStatistics?) -> Void) -> HKStatisticsQuery {
        let query = HKStatisticsQuery(quantityType: type, quantitySamplePredicate: predicate, options: .discreteMax) { _, statistics, error in
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
