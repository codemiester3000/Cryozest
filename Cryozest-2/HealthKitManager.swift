import HealthKit

class HealthKitManager {
    static let healthStore = HKHealthStore()
    
    static let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        static let respirationRateType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!
        static let sleepAnalysisType = HKCategoryType.categoryType(forIdentifier: .sleepAnalysis)!
        static let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
    
    static func fetchBodyWeightfromHealthKit(completion: @escaping (Double?) -> Void) {
        let type = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let query = HKSampleQuery(sampleType: type, predicate: nil, limit: 1, sortDescriptors: nil) { query, results, error in
            guard let results = results as? [HKQuantitySample], let weight = results.first?.quantity.doubleValue(for: .pound()) else {
                // Handle error here
                completion(nil)
                return
            }
            DispatchQueue.main.async {
                completion(weight)
            }
        }
        healthStore.execute(query)
    }
    
    static func fetchHRV() {
        let query = HKSampleQuery(sampleType: hrvType, predicate: nil, limit: 1, sortDescriptors: nil) { query, results, error in
            guard let results = results as? [HKQuantitySample], let hrvSample = results.first else {
                // Handle error here
                return
            }
            
            let hrv = hrvSample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
            
            // Process hrv here
        }
        healthStore.execute(query)
    }
    
    static func fetchRespirationRate() {
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
    
    static func fetchSleepAnalysis() {
        let query = HKSampleQuery(sampleType: sleepAnalysisType, predicate: nil, limit: 1, sortDescriptors: nil) { query, results, error in
            guard let results = results as? [HKCategorySample], let sleepSample = results.first else {
                // Handle error here
                return
            }
            
            // Process sleepSample here
        }
        healthStore.execute(query)
    }
    
    static func fetchHeartRate() {
        let query = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: nil) { query, results, error in
            guard let results = results as? [HKQuantitySample], let heartRateSample = results.first else {
                // Handle error here
                return
            }
            
            let heartRate = heartRateSample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            
            // Process heartRate here
        }
        healthStore.execute(query)
    }
    
//    static  func fetchBodyWeight() {
//        let weightType = HKSampleType.quantityType(forIdentifier: .bodyMass)!
//        let query = HKSampleQuery(sampleType: weightType, predicate: nil, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
//            DispatchQueue.main.async {
//                guard let samples = samples as? [HKQuantitySample], let quantity = samples.first?.quantity else {
//                    return
//                }
//                let weight = quantity.doubleValue(for: HKUnit.pound())
//                bodyWeight = String(weight)
//            }
//        }
//        healthStore.execute(query)
//    }
}
