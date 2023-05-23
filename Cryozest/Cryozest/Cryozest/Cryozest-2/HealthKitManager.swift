import Foundation
import HealthKit

class HealthKitManager {
    
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    private let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
    private let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
    private let hrvType = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
    private let respirationRateType = HKObjectType.quantityType(forIdentifier: .respiratoryRate)!
    
    private init() {}
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        healthStore.requestAuthorization(toShare: [], read: [HKObjectType.quantityType(forIdentifier: .bodyMass)!, sleepAnalysisType, heartRateType, hrvType, respirationRateType]) { success, error in
            completion(success, error)
        }
    }
    
    func fetchBodyWeight(completion: @escaping (Double?) -> Void) {
        let weightType = HKSampleType.quantityType(forIdentifier: .bodyMass)!
        let query = HKSampleQuery(sampleType: weightType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            DispatchQueue.main.async {
                guard let samples = samples as? [HKQuantitySample], let quantity = samples.first?.quantity else {
                    completion(nil)
                    return
                }
                let weight = quantity.doubleValue(for: HKUnit.pound())
                completion(weight)
            }
        }
        healthStore.execute(query)
    }
    
    func fetchSleepAnalysis(completion: @escaping ([HKCategorySample]?) -> Void) {
        let query = HKSampleQuery(sampleType: sleepAnalysisType, predicate: nil, limit: 1, sortDescriptors: nil) { query, results, error in
            guard let results = results as? [HKCategorySample] else {
                completion(nil)
                return
            }
            completion(results)
        }
        healthStore.execute(query)
    }
    
    func fetchHeartRate(completion: @escaping (Double?) -> Void) {
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: nil) { query, results, error in
            guard let results = results as? [HKQuantitySample], let heartRateSample = results.first else {
                completion(nil)
                return
            }
            let heartRate = heartRateSample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            completion(heartRate)
        }
        healthStore.execute(query)
    }
    
    func fetchHRV(completion: @escaping (Double?) -> Void) {
        let query = HKSampleQuery(sampleType: hrvType, predicate: nil, limit: 1, sortDescriptors: nil) { query, results, error in
            guard let results = results as? [HKQuantitySample], let hrvSample = results.first else {
                completion(nil)
                return
            }
            let hrv = hrvSample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
            completion(hrv)
        }
        healthStore.execute(query)
    }
    
    func fetchRespirationRate() {
        let query = HKSampleQuery(sampleType: respirationRateType, predicate: nil, limit: 1, sortDescriptors: nil) { query, results, error in
            guard let results = results as? [HKQuantitySample], let respirationRateSample = results.first else {
                // Handle error here
                return
            }
            
            let respirationRate = respirationRateSample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            
            // Process respirationRate here
        }
        healthStore.execute(query)
    }
}
