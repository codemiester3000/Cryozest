import Foundation
import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    private let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
    // private let respirationRateType = HKObjectType.quantityType(forIdentifier: .respiratoryRate)!
    // private let spo2Type = HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!
    private let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
    
    private let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
    
    private init() {}
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        // Define the types
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let restingHeartRateType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
        let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        
        let typesToRead: Set<HKObjectType> = [heartRateType, restingHeartRateType, bodyMassType, sleepAnalysisType, hrvType]
        
        healthStore.requestAuthorization(toShare: [], read: typesToRead) { success, error in
            completion(success, error)
        }
    }
    
    func areHealthMetricsAuthorized(completion: @escaping (Bool) -> Void) {
        let typesToRead: Set<HKObjectType> = [heartRateType]
        healthStore.getRequestStatusForAuthorization(toShare: [], read: typesToRead) { (status, error) in
            if let error = error {
                
                completion(false)
                return
            }
            switch status {
            case .unnecessary:
                // The system doesn't need to request authorization because the user has already granted access.
                completion(true)
            case .shouldRequest:
                // The system needs to request authorization.
                completion(false)
            case .unknown:
                
                // The system can't determine whether it needs to request authorization.
                completion(false)
            @unknown default:
                
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
                
                completion(nil)
                return
            }
            
            let bodyMass = sample.quantity.doubleValue(for: HKUnit.pound())
            
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
                
                avgHeartRate = heartRate
            } else {
                
            }
            group.leave()
        }
        healthStore.execute(heartRateQuery)
        
        group.enter()
        fetchMinimumHeartRate(from: startDate, to: endDate) { heartRate in
            if let heartRate = heartRate {
                minHeartRate = heartRate
            } else {
                print("Failed to fetch minimum heart rate")
            }
            group.leave()
        }
        
        group.enter()
        fetchMaximumHeartRate(from: startDate, to: endDate) { heartRate in
            if let heartRate = heartRate {
                maxHeartRate = heartRate
            } else {
                print("Failed to fetch maximum heart rate")
            }
            group.leave()
        }
        
        group.notify(queue: .main) {
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
    
    func fetchMinimumHeartRate(from startDate: Date, to endDate: Date, completion: @escaping (Double?) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let minHeartRateQuery = createMinStatisticsQuery(for: heartRateType, with: predicate) { statistics in
            if let statistics = statistics, let heartRate = statistics.minimumQuantity()?.doubleValue(for: HKUnit(from: "count/min")) {
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
    
    func fetchAvgRestingHeartRateForDays(days: [Date], completion: @escaping (Double?) -> Void) {
        guard !days.isEmpty else {
            completion(nil)
            return
        }
        
        let calendar = Calendar.current
        
        // Convert dates into just the day component
        var includedDays: [Date] = []
        for date in days {
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            if let dayStart = calendar.date(from: components) {
                includedDays.append(dayStart)
            }
        }
        
        // Calculate earliest and latest date in the days array
        let earliestDate = includedDays.min() ?? Date.distantPast
        let latestDate = includedDays.max() ?? Date.distantFuture
        
        // Create a predicate to fetch heart rate samples within the range of the earliest and latest dates
        let predicate = HKQuery.predicateForSamples(withStart: earliestDate, end: latestDate, options: .strictStartDate)
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
        
        let heartRateQuery = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            
            guard let samples = samples as? [HKQuantitySample] else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            var totalHeartRate = 0.0
            var count = 0.0
            
            for sample in samples {
                let sampleDayStart = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: sample.endDate))
                
                // Only include the sample if its day component is in the includedDays array
                if includedDays.contains(sampleDayStart!) {
                    totalHeartRate += sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                    count += 1
                }
            }
            
            DispatchQueue.main.async {
                if count != 0 {
                    let avgHeartRate = totalHeartRate / count
                    completion(avgHeartRate)
                } else {
                    // print("No resting heart rate samples found for the specified days.")
                    completion(nil)
                }
            }
        }
        
        healthStore.execute(heartRateQuery)
    }
    
    func fetchAvgHeartRateForDays(days: [Date], completion: @escaping (Double?) -> Void) {
        guard !days.isEmpty else {
            completion(nil)
            return
        }
        
        let calendar = Calendar.current
        
        // Convert dates into just the day component
        var includedDays: [Date] = []
        for date in days {
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            if let dayStart = calendar.date(from: components) {
                includedDays.append(dayStart)
            }
        }
        
        // Calculate earliest and latest date in the days array
        let earliestDate = includedDays.min() ?? Date.distantPast
        let latestDate = includedDays.max() ?? Date.distantFuture
        
        // Create a predicate to fetch heart rate samples within the range of the earliest and latest dates
        let predicate = HKQuery.predicateForSamples(withStart: earliestDate, end: latestDate, options: .strictStartDate)
        
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        let heartRateQuery = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            
            guard let samples = samples as? [HKQuantitySample] else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            var totalHeartRate = 0.0
            var count = 0.0
            
            for sample in samples {
                let sampleDayStart = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: sample.endDate))
                
                // Only include the sample if its day component is in the includedDays array
                if includedDays.contains(sampleDayStart!) {
                    totalHeartRate += sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                    count += 1
                }
            }
            
            DispatchQueue.main.async {
                if count != 0 {
                    let avgHeartRate = totalHeartRate / count
                    completion(avgHeartRate)
                } else {
                    // print("No heart rate samples found for the specified days.")
                    completion(nil)
                }
            }
        }
        
        healthStore.execute(heartRateQuery)
    }
    
    
    func fetchAvgHeartRateDuringSleepForDays(days: [Date], completion: @escaping (Double?) -> Void) {
        let calendar = Calendar.current
        
        // Convert dates into just the day component
        var includedDays: [Int] = []
        for date in days {
            let dayComponent = calendar.component(.day, from: date)
            includedDays.append(dayComponent)
        }
        
        // Define the sleep analysis type
        let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!
        
        // Create a predicate to fetch all sleep analysis samples
        let sleepPredicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictStartDate)
        
        // Query the sleep analysis samples
        let sleepQuery = HKSampleQuery(sampleType: sleepAnalysisType, predicate: sleepPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            
            guard let sleepSamples = samples else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            var totalHeartRate = 0.0
            var count = 0.0
            
            // For each sleep sample
            for sleepSample in sleepSamples {
                let sleepStartDate = sleepSample.startDate
                let sleepEndDate = sleepSample.endDate
                
                // Create a predicate to fetch heart rate samples that fall within the sleep period
                let heartRatePredicate = HKQuery.predicateForSamples(withStart: sleepStartDate, end: sleepEndDate, options: .strictStartDate)
                
                // Query the heart rate samples
                let heartRateQuery = HKSampleQuery(sampleType: self.heartRateType, predicate: heartRatePredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, heartRateSamples, error) in
                    
                    guard let heartRateSamples = heartRateSamples as? [HKQuantitySample] else {
                        DispatchQueue.main.async {
                            completion(nil)
                        }
                        return
                    }
                    
                    // For each heart rate sample, add the heart rate to the total and increment the count
                    for sample in heartRateSamples {
                        totalHeartRate += sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                        count += 1
                    }
                }
                
                self.healthStore.execute(heartRateQuery)
            }
            
            DispatchQueue.main.async {
                if count != 0 {
                    let avgHeartRate = totalHeartRate / count
                    completion(avgHeartRate)
                } else {
                    // print("No heart rate samples found for the specified days during sleep hours.")
                    completion(nil)
                }
            }
        }
        
        healthStore.execute(sleepQuery)
    }
    
    // Duration in Seconds
    func fetchAvgSleepDurationForDays(days: [Date], completion: @escaping (Double?) -> Void) {
        let calendar = Calendar.current
        var includedDays: [Int] = []
        for date in days {
            let dayComponent = calendar.component(.day, from: date)
            includedDays.append(dayComponent)
        }
        
        let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!
        let sleepPredicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictStartDate)
        
        let sleepQuery = HKSampleQuery(sampleType: sleepAnalysisType, predicate: sleepPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            
            guard let sleepSamples = samples as? [HKCategorySample] else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            var totalDuration = 0.0
            var count = 0.0
            
            for sleepSample in sleepSamples {
                let sampleDayComponent = calendar.component(.day, from: sleepSample.endDate)
                if includedDays.contains(sampleDayComponent) && sleepSample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue {
                    let duration = sleepSample.endDate.timeIntervalSince(sleepSample.startDate)
                    totalDuration += duration
                    
                    print("inside the sleep method: ", duration)
                    
                    if (duration > 0) {
                        count += 1
                    }
                }
            }
            
            DispatchQueue.main.async {
                if count != 0 {
                    let avgDuration = totalDuration / count
                    completion(avgDuration)
                } else {
                    print("No sleep duration samples found for the specified days.")
                    completion(nil)
                }
            }
        }
        
        healthStore.execute(sleepQuery)
    }
    
    
    func fetchAvgHRVForDays(days: [Date], completion: @escaping (Double?) -> Void) {
        let calendar = Calendar.current
        var includedDays: [Int] = []
        for date in days {
            let dayComponent = calendar.component(.day, from: date)
            includedDays.append(dayComponent)
        }
        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictStartDate)
        let hrvQuery = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            guard let samples = samples as? [HKQuantitySample] else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            var totalHRV = 0.0
            var count = 0.0
            for sample in samples {
                let sampleDayComponent = calendar.component(.day, from: sample.endDate)
                if includedDays.contains(sampleDayComponent) {
                    totalHRV += sample.quantity.doubleValue(for: HKUnit(from: "ms"))
                    count += 1
                }
            }
            DispatchQueue.main.async {
                if count != 0 {
                    let avgHRV = totalHRV / count
                    completion(avgHRV)
                } else {
                    // print("No HRV samples found for the specified days.")
                    completion(nil)
                }
            }
        }
        healthStore.execute(hrvQuery)
    }
    
    func fetchMaxHRVForDays(days: [Date], completion: @escaping (Double?) -> Void) {
        let calendar = Calendar.current
        
        // Convert dates into just the day component
        var includedDays: [Int] = []
        for date in days {
            let dayComponent = calendar.component(.day, from: date)
            includedDays.append(dayComponent)
        }
        
        // Create a predicate to fetch all HRV samples
        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictStartDate)
        
        let hrvQuery = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            
            guard let samples = samples as? [HKQuantitySample] else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            var hrvValues: [Double] = []
            
            for sample in samples {
                let sampleDayComponent = calendar.component(.day, from: sample.endDate)
                
                // Only include the sample if its day component is in the includedDays array
                if includedDays.contains(sampleDayComponent) {
                    let hrvValue = sample.quantity.doubleValue(for: HKUnit(from: "ms"))
                    hrvValues.append(hrvValue)
                }
            }
            
            DispatchQueue.main.async {
                let maxHRV = hrvValues.max()
                completion(maxHRV)
            }
        }
        
        healthStore.execute(hrvQuery)
    }
    
    func fetchMinHRVForDays(days: [Date], completion: @escaping (Double?) -> Void) {
        let calendar = Calendar.current
        
        // Convert dates into just the day component
        var includedDays: [Int] = []
        for date in days {
            let dayComponent = calendar.component(.day, from: date)
            includedDays.append(dayComponent)
        }
        
        // Create a predicate to fetch all HRV samples
        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictStartDate)
        
        let hrvQuery = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            
            guard let samples = samples as? [HKQuantitySample] else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            var hrvValues: [Double] = []
            
            for sample in samples {
                let sampleDayComponent = calendar.component(.day, from: sample.endDate)
                
                // Only include the sample if its day component is in the includedDays array
                if includedDays.contains(sampleDayComponent) {
                    let hrvValue = sample.quantity.doubleValue(for: HKUnit(from: "ms"))
                    hrvValues.append(hrvValue)
                }
            }
            
            DispatchQueue.main.async {
                let minHRV = hrvValues.min()
                completion(minHRV)
            }
        }
        
        healthStore.execute(hrvQuery)
    }
    
    func fetchHRVTrendForDays(days: [Date], completion: @escaping (Trend?) -> Void) {
        let calendar = Calendar.current
        var includedDays: [Int] = []
        for date in days {
            let dayComponent = calendar.component(.day, from: date)
            includedDays.append(dayComponent)
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: Date.distantPast, end: Date(), options: .strictStartDate)
        let query = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            guard let samples = samples as? [HKQuantitySample] else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            var hrvValuesForIncludedDays: [Double] = []
            for sample in samples {
                let sampleDayComponent = calendar.component(.day, from: sample.endDate)
                if includedDays.contains(sampleDayComponent) {
                    let hrvValue = sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                    hrvValuesForIncludedDays.append(hrvValue)
                }
            }
            
            DispatchQueue.main.async {
                guard let firstValue = hrvValuesForIncludedDays.first, let lastValue = hrvValuesForIncludedDays.last else {
                    completion(nil)
                    return
                }
                completion(firstValue < lastValue ? .increasing : .decreasing)
            }
        }
        healthStore.execute(query)
    }
}

enum Trend: CustomStringConvertible {
    case increasing
    case decreasing
    
    var description: String {
        switch self {
        case .increasing: return "Increasing"
        case .decreasing: return "Decreasing"
        }
    }
}
