import Foundation
import HealthKit

class HealthKitManager {
    static let shared = HealthKitManager()
    
    private let healthStore = HKHealthStore()
    private let heartRateType = HKObjectType.quantityType(forIdentifier: .heartRate)!
    private let respirationRateType = HKObjectType.quantityType(forIdentifier: .respiratoryRate)!
    private let spo2Type = HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!
    private let bodyMassType = HKObjectType.quantityType(forIdentifier: .bodyMass)!
    private let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
    private let activeEnergyType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
    private let restingEnergyType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned)!
    private let dateOfBirthType = HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!
    
    private init() {}
    
    func requestAuthorization(completion: @escaping (Bool, Error?) -> Void) {
        // Define the types for heart rate, body mass, sleep analysis, HRV, respiration rate, SpO2, Active Energy, and Resting Energy
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let restingHeartRateType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
        let bodyMassType = HKQuantityType.quantityType(forIdentifier: .bodyMass)!
        let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        let respirationRateType = HKObjectType.quantityType(forIdentifier: .respiratoryRate)!
        let spo2Type = HKObjectType.quantityType(forIdentifier: .oxygenSaturation)!
        let activeEnergyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        let restingEnergyType = HKQuantityType.quantityType(forIdentifier: .basalEnergyBurned)!
        let dateOfBirthType = HKObjectType.characteristicType(forIdentifier: .dateOfBirth)!

        // Add new types to the typesToRead set
        let typesToRead: Set<HKObjectType> = [
            heartRateType,
            restingHeartRateType,
            bodyMassType,
            sleepAnalysisType,
            hrvType,
            respirationRateType,
            spo2Type,
            activeEnergyType,
            restingEnergyType,
            dateOfBirthType
        ]

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
    
    func fetchUserAge(completion: @escaping (Int?, Error?) -> Void) {
          do {
              let dateOfBirthComponents = try healthStore.dateOfBirthComponents()
              guard let dateOfBirth = dateOfBirthComponents.date else {
                  // Date of birth is not available
                  completion(nil, nil)
                  return
              }
              
              let age = Calendar.current.dateComponents([.year], from: dateOfBirth, to: Date()).year
              completion(age, nil)
          } catch {
              completion(nil, error)
          }
      }
    
    
    func fetchMostRecentRestingEnergy(completion: @escaping (Double?) -> Void) {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictEndDate)

        guard let restingEnergyType = HKObjectType.quantityType(forIdentifier: .basalEnergyBurned) else {
            completion(nil)
            return
        }

        let query = HKStatisticsQuery(quantityType: restingEnergyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
            if let error = error {
                completion(nil)
                return
            }

            guard let sum = statistics?.sumQuantity() else {
                completion(nil)
                return
            }

            let totalRestingEnergy = sum.doubleValue(for: HKUnit.kilocalorie())
            completion(totalRestingEnergy)
        }
        healthStore.execute(query)
    }


    
    func fetchMostRecentActiveEnergy(completion: @escaping (Double?) -> Void) {
        let now = Date()
           let startOfDay = Calendar.current.startOfDay(for: now)
           let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: now, options: .strictEndDate)

           let query = HKStatisticsQuery(quantityType: activeEnergyType, quantitySamplePredicate: predicate, options: .cumulativeSum) { _, statistics, error in
               guard let statistics = statistics, let sum = statistics.sumQuantity() else {
                   completion(nil)
                   return
               }
               let totalActiveEnergy = sum.doubleValue(for: HKUnit.kilocalorie())
               completion(totalActiveEnergy)
           }
           healthStore.execute(query)
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
    
    func fetchNDayAvgOverallHeartRate(numDays: Int, completion: @escaping (Int?) -> Void) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        let calendar = Calendar.current
        
        // Set the start date to 'numDays' days before today
        guard let startDate = calendar.date(byAdding: .day, value: -numDays, to: Date()) else {
            completion(nil)
            return
        }
        
        // Create a predicate to fetch heart rate samples from the last 'numDays' days
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        // Query for overall heart rate samples
        let heartRateQuery = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            guard let samples = samples as? [HKQuantitySample], !samples.isEmpty else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // Calculate the total heart rate and count the number of samples
            let totalHeartRate = samples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: HKUnit(from: "count/min")) }
            let averageHeartRate = totalHeartRate / Double(samples.count)
            
            // Complete with the calculated average
            DispatchQueue.main.async {
                completion(Int(averageHeartRate))
            }
        }
        healthStore.execute(heartRateQuery)
    }
    
    
    func fetchNDayAvgRestingHeartRate(numDays: Int, completion: @escaping (Int?) -> Void) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
        let calendar = Calendar.current
        
        // Set the start date to 60 days before today
        guard let startDate = calendar.date(byAdding: .day, value: -numDays, to: Date()) else {
            completion(nil)
            return
        }
        
        // Create a predicate to fetch heart rate samples from the last 60 days
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: Date(), options: .strictStartDate)
        
        // Query for resting heart rate samples
        let heartRateQuery = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            
            guard let samples = samples as? [HKQuantitySample], !samples.isEmpty else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // Calculate the total heart rate and count the number of samples
            let totalHeartRate = samples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: HKUnit(from: "count/min")) }
            let averageHeartRate = totalHeartRate / Double(samples.count)
            
            // Complete with the calculated average
            DispatchQueue.main.async {
                completion(Int(averageHeartRate))
                
            }
        }
        healthStore.execute(heartRateQuery)
    }
    
    public func fetchHeartRateData(from startDate: Date, to endDate: Date, completion: @escaping ([HKQuantitySample]?, Error?) -> Void) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        // Create a predicate to fetch heart rate data within the specified date range
        let datePredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        // Sort descriptor to fetch the samples in ascending order
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        
        // Create a query to fetch heart rate samples
        let heartRateQuery = HKSampleQuery(sampleType: heartRateType, predicate: datePredicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            guard let samples = samples as? [HKQuantitySample] else {
                DispatchQueue.main.async {
                    print("Error or no samples found: \(String(describing: error))")
                    completion(nil, error)
                }
                return
            }
            completion(samples, nil)
        }
        healthStore.execute(heartRateQuery)
    }


    
    func fetchMostRecentRestingHeartRate(completion: @escaping (Int?) -> Void) {
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
        
        // Sort descriptor to fetch the most recent sample
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        // Create a query to fetch resting heart rate samples
        let heartRateQuery = HKSampleQuery(sampleType: heartRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            
            guard let samples = samples as? [HKQuantitySample], let mostRecentSample = samples.first else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // Extracting heart rate value from the most recent sample
            let heartRateValue = mostRecentSample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            
            // Convert to Int and complete
            DispatchQueue.main.async {
                completion(Int(heartRateValue))
            }
        }
        
        healthStore.execute(heartRateQuery)
    }
    
    
    func fetchMostRecentRespiratoryRate(completion: @escaping (Double?) -> Void) {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: respirationRateType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard let samples = samples, let sample = samples.first as? HKQuantitySample else {
                completion(nil)
                return
            }
            let respiratoryRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
            completion(respiratoryRate)
        }
        healthStore.execute(query)
    }

    
    func fetchMostRecentSPO2(completion: @escaping (Double?) -> Void) {
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        let query = HKSampleQuery(sampleType: spo2Type, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard let samples = samples, let sample = samples.first as? HKQuantitySample else {
                completion(nil)
                return
            }
            let spo2 = sample.quantity.doubleValue(for: HKUnit.percent())
            completion(spo2)
        }
        healthStore.execute(query)
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
        
        // Create a predicate to fetch heart rate samples within the range of the earliest and latest dates
        let predicate = HKQuery.predicateForSamples(withStart: earliestDate, end: Date(), options: .strictStartDate)
        
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
        
        // Create a predicate to fetch heart rate samples within the range of the earliest and latest dates
        let predicate = HKQuery.predicateForSamples(withStart: earliestDate, end: Date(), options: .strictStartDate)
        
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
    
    func fetchAvgHeartRateDuringSleepForLastNDays(numDays: Int, completion: @escaping (Double?) -> Void) {
        let calendar = Calendar.current
        let endDate = Date() // Today
        guard let startDate = calendar.date(byAdding: .day, value: -numDays, to: endDate) else {
            completion(nil)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!
        
        // Query the sleep analysis samples
        let sleepQuery = HKSampleQuery(sampleType: sleepAnalysisType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            
            guard let sleepSamples = samples as? [HKCategorySample], !sleepSamples.isEmpty else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            var totalHeartRate = 0.0
            var count = 0.0
            let dispatchGroup = DispatchGroup()
            
            // For each sleep sample
            for sleepSample in sleepSamples {
                let sleepStartDate = sleepSample.startDate
                let sleepEndDate = sleepSample.endDate
                
                // Create a predicate to fetch heart rate samples that fall within the sleep period
                let heartRatePredicate = HKQuery.predicateForSamples(withStart: sleepStartDate, end: sleepEndDate, options: .strictStartDate)
                
                // Query the heart rate samples
                dispatchGroup.enter()
                let heartRateQuery = HKSampleQuery(sampleType: self.heartRateType, predicate: heartRatePredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, heartRateSamples, error) in
                    
                    guard let heartRateSamples = heartRateSamples as? [HKQuantitySample] else {
                        dispatchGroup.leave()
                        return
                    }
                    
                    // For each heart rate sample, add the heart rate to the total and increment the count
                    for sample in heartRateSamples {
                        totalHeartRate += sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                        count += 1
                    }
                    dispatchGroup.leave()
                }
                self.healthStore.execute(heartRateQuery)
            }
            
            // Wait for all heart rate queries to complete
            dispatchGroup.notify(queue: DispatchQueue.main) {
                if count != 0 {
                    let avgHeartRate = totalHeartRate / count
                    completion(avgHeartRate)
                } else {
                    completion(nil)
                }
            }
        }
        
        healthStore.execute(sleepQuery)
    }
    
    
    func fetchAvgHeartRateDuringSleepForDays(days: [Date], completion: @escaping (Double?) -> Void) {
        let calendar = Calendar.current
        
        // Convert dates into just the day component
        var includedDays: [Set<Int>] = []
        for date in days {
            let components = calendar.dateComponents([.year, .month, .day], from: date)
            if let dayStart = calendar.date(from: components) {
                let set = Set([components.year!, components.month!, components.day!])
                includedDays.append(set)
            }
        }
        
        // Calculate earliest and latest date in the days array
        let earliestDate = days.min() ?? Date.distantPast
        
        // Create a predicate to fetch sleep samples within the range of the earliest and latest dates
        let predicate = HKQuery.predicateForSamples(withStart: earliestDate, end: Date(), options: .strictStartDate)
        
        let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!
        
        // Query the sleep analysis samples
        let sleepQuery = HKSampleQuery(sampleType: sleepAnalysisType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            
            guard let sleepSamples = samples else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            var totalHeartRate = 0.0
            var count = 0.0
            
            let dispatchGroup = DispatchGroup()
            
            // For each sleep sample
            for sleepSample in sleepSamples {
                let sleepStartDate = sleepSample.startDate
                let sleepEndDate = sleepSample.endDate
                let sleepStartComponents = calendar.dateComponents([.year, .month, .day], from: sleepStartDate)
                
                let sleepStartSet = Set([sleepStartComponents.year!, sleepStartComponents.month!, sleepStartComponents.day!])
                
                // Only proceed if the sleepSample is in includedDays
                if includedDays.contains(sleepStartSet) {
                    
                    // Create a predicate to fetch heart rate samples that fall within the sleep period
                    let heartRatePredicate = HKQuery.predicateForSamples(withStart: sleepStartDate, end: sleepEndDate, options: .strictStartDate)
                    
                    // Query the heart rate samples
                    dispatchGroup.enter()
                    let heartRateQuery = HKSampleQuery(sampleType: self.heartRateType, predicate: heartRatePredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, heartRateSamples, error) in
                        
                        guard let heartRateSamples = heartRateSamples as? [HKQuantitySample] else {
                            dispatchGroup.leave()
                            return
                        }
                        
                        // For each heart rate sample, add the heart rate to the total and increment the count
                        for sample in heartRateSamples {
                            totalHeartRate += sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                            count += 1
                        }
                        dispatchGroup.leave()
                    }
                    self.healthStore.execute(heartRateQuery)
                }
            }
            
            // Wait for all heart rate queries to complete
            dispatchGroup.notify(queue: DispatchQueue.main) {
                if count != 0 {
                    let avgHeartRate = totalHeartRate / count
                    completion(avgHeartRate)
                } else {
                    completion(nil)
                }
            }
        }
        
        healthStore.execute(sleepQuery)
    }
    
    func fetchAvgSleepDurationForLastNDays(numDays: Int, completion: @escaping (Double?) -> Void) {
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -numDays, to: endDate) else {
            completion(nil)
            return
        }
        
        // Create a predicate to fetch heart rate samples within the range of the last N days
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!
        
        let sleepQuery = HKSampleQuery(sampleType: sleepAnalysisType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            
            guard let sleepSamples = samples as? [HKCategorySample] else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // Sum up all of the time the user spent asleep during the time frame.
            var totalDuration = 0.0
            var sampleDays = Set<Date>()
            for sleepSample in sleepSamples {
                if sleepSample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue || sleepSample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue || sleepSample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue {
                    let duration = sleepSample.endDate.timeIntervalSince(sleepSample.startDate)
                    totalDuration += duration
                    let sampleDayStart = calendar.startOfDay(for: sleepSample.startDate)
                    sampleDays.insert(sampleDayStart)
                }
            }
            
            DispatchQueue.main.async {
                if !sampleDays.isEmpty {
                    let avgDuration = totalDuration / Double(sampleDays.count)
                    completion(avgDuration)
                } else {
                    completion(nil)
                }
            }
        }
        
        healthStore.execute(sleepQuery)
    }
    
    
    
    // Duration in Seconds
    func fetchAvgSleepDurationForDays(days: [Date], completion: @escaping (Double?) -> Void) {
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
        
        // Create a predicate to fetch heart rate samples within the range of the earliest and latest dates
        let predicate = HKQuery.predicateForSamples(withStart: earliestDate, end: Date(), options: .strictStartDate)
        
        let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!
        
        let sleepQuery = HKSampleQuery(sampleType: sleepAnalysisType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            
            guard let sleepSamples = samples as? [HKCategorySample] else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            // Sum up all of the time the user spent asleep during the time frame.
            var totalDuration = 0.0
            var sampleDays = Set<Date>()
            for sleepSample in sleepSamples {
                if let sampleDayStart = calendar.date(from: calendar.dateComponents([.year, .month, .day], from: sleepSample.endDate)), includedDays.contains(sampleDayStart) {
                    let duration = sleepSample.endDate.timeIntervalSince(sleepSample.startDate)
                    
                    if sleepSample.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue || sleepSample.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue || sleepSample.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue {
                        totalDuration += duration
                        sampleDays.insert(sampleDayStart)
                    }
                }
            }
            
            DispatchQueue.main.async {
                if !sampleDays.isEmpty {
                    let avgDuration = totalDuration / Double(sampleDays.count)
                    completion(avgDuration)
                } else {
                    completion(nil)
                }
            }
        }
        
        healthStore.execute(sleepQuery)
    }
    
    func fetchAvgHRVForLastDays(numberOfDays: Int, completion: @escaping (Double?) -> Void) {
        let calendar = Calendar.current
        let endDate = Date() // Today
        guard let startDate = calendar.date(byAdding: .day, value: -numberOfDays, to: endDate) else {
            completion(nil)
            return
        }
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        
        let hrvQuery = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
            guard let samples = samples as? [HKQuantitySample], !samples.isEmpty else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }
            
            let totalHRV = samples.reduce(0.0) { $0 + $1.quantity.doubleValue(for: HKUnit(from: "ms")) }
            let avgHRV = totalHRV / Double(samples.count)
            
            DispatchQueue.main.async {
                completion(avgHRV)
            }
        }
        
        healthStore.execute(hrvQuery)
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
    
    // Rob -- Fetches the total sleep duration for the previous night
    func fetchSleepDurationForPreviousNight(completion: @escaping (Double?) -> Void) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Calculate 7 PM yesterday
        guard let yesterday7PM = calendar.date(byAdding: .hour, value: -5, to: today) else {
            completion(nil)
            return
        }

        // Calculate 2 PM today
        guard let today2PM = calendar.date(byAdding: .hour, value: 14, to: today) else {
            completion(nil)
            return
        }

        let predicate = HKQuery.predicateForSamples(withStart: yesterday7PM, end: today2PM, options: .strictStartDate)

        guard let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis) else {
            completion(nil)
            return
        }

        let sleepQuery = HKSampleQuery(sampleType: sleepAnalysisType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)]) { (query, samples, error) in
            guard error == nil, let sleepSamples = samples as? [HKCategorySample] else {
                DispatchQueue.main.async {
                    completion(nil)
                }
                return
            }

            var totalSleepTime: TimeInterval = 0
            var lastEndDate: Date? = yesterday7PM

            for sample in sleepSamples {
                // Check if the sample represents actual sleep (using the updated enumeration case)
                if sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue {

                    // If there's an overlap, adjust the start date
                    let adjustedStartDate = max(sample.startDate, lastEndDate ?? sample.startDate)
                    if adjustedStartDate < sample.endDate {
                        totalSleepTime += sample.endDate.timeIntervalSince(adjustedStartDate)
                        lastEndDate = max(lastEndDate ?? sample.startDate, sample.endDate)
                    }
                }
            }

            DispatchQueue.main.async {
                completion(totalSleepTime)
            }
        }



        healthStore.execute(sleepQuery)
    }


    
    
    
    // MARK -- HRV METHODS
    
    // TODO: UPDATE THIS TO GET THE LAST HRV READING FOR THE NIGHT.
    func fetchAvgHRVDuringSleepForNightEndingOn(date: Date, completion: @escaping (Double?) -> Void) {
        let calendar = Calendar.current
        
        var endOfNightComponents = calendar.dateComponents([.year, .month, .day], from: date)
        endOfNightComponents.hour = 14 // 2 PM, assuming this is the end of the sleep period
        
        // Creating endOfNight for 2 PM of the passed-in date
        let endOfNight = calendar.date(from: endOfNightComponents)!
        
        let previousDay = calendar.date(byAdding: .day, value: -1, to: endOfNight)!
        let startOfPreviousDay = calendar.startOfDay(for: previousDay)
        let startOfNight = calendar.date(byAdding: .hour, value: 21, to: startOfPreviousDay)! // Assuming 9 PM is the start of the sleep period
        
        // Create a predicate for sleep analysis in the time range
        let sleepPredicate = HKQuery.predicateForSamples(withStart: startOfNight, end: endOfNight, options: .strictStartDate)
        let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!
        
        // Query sleep analysis data
        let sleepQuery = HKSampleQuery(sampleType: sleepAnalysisType, predicate: sleepPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, sleepSamples, error in
            guard let sleepSamples = sleepSamples as? [HKCategorySample], !sleepSamples.isEmpty else {
                completion(nil)
                return
            }
            
            // Assuming sleepSamples are sorted by start date, get the first and last sample to determine the sleep period
            let sleepStart = sleepSamples.first!.startDate
            let sleepEnd = sleepSamples.last!.endDate
            
            // Create a predicate for HRV data during the sleep period
            let hrvPredicate = HKQuery.predicateForSamples(withStart: sleepStart, end: sleepEnd, options: .strictStartDate)
            
            // Query HRV data
            let hrvQuery = HKSampleQuery(sampleType: self.hrvType, predicate: hrvPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, hrvSamples, error in
                guard let hrvSamples = hrvSamples as? [HKQuantitySample], !hrvSamples.isEmpty else {
                    completion(nil)
                    return
                }
                // Calculate average HRV
                let totalHRV = hrvSamples.reduce(0) { $0 + $1.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)) }
                let averageHRV = totalHRV / Double(hrvSamples.count)
                
                completion(averageHRV)
            }
            self.healthStore.execute(hrvQuery)
        }
        self.healthStore.execute(sleepQuery)
    }

    func fetchLastKnownHRV(before date: Date, completion: @escaping (Double?) -> Void) {
        let hrvPredicate = HKQuery.predicateForSamples(withStart: nil, end: date, options: .strictEndDate)

        let hrvQuery = HKSampleQuery(sampleType: self.hrvType, predicate: hrvPredicate, limit: 1, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: false)]) { _, hrvSamples, error in
            guard let lastHrvSample = hrvSamples?.first as? HKQuantitySample else {
                completion(nil)
                return
            }
            let lastHrvValue = lastHrvSample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
            completion(lastHrvValue)
        }
        self.healthStore.execute(hrvQuery)
    }
    
    func fetchAvgHRVDuringSleepForPreviousNight(completion: @escaping (Double?) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        
        var endOfPreviousNightComponents = calendar.dateComponents([.year, .month, .day], from: now)
        endOfPreviousNightComponents.hour = 14 // 2 PM
        
        // Creating startOfToday for 2 PM of the current day
        let endOfPreviousNight = calendar.date(from: endOfPreviousNightComponents)!
        
        let previousDay = calendar.date(byAdding: .day, value: -1, to: endOfPreviousNight)!
        let startOfPreviousDay = calendar.startOfDay(for: previousDay)
        let startOfPreviousNight = calendar.date(byAdding: .hour, value: 21, to: startOfPreviousDay)!
        
        // Create a predicate for sleep analysis in the time range
        let sleepPredicate = HKQuery.predicateForSamples(withStart: startOfPreviousNight, end: endOfPreviousNight, options: .strictStartDate)
        let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!
        
        // Query sleep analysis data
        let sleepQuery = HKSampleQuery(sampleType: sleepAnalysisType, predicate: sleepPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, sleepSamples, error in
            guard let sleepSamples = sleepSamples as? [HKCategorySample], !sleepSamples.isEmpty else {
                completion(nil)
                return
            }
            
            // Assuming sleepSamples are sorted by start date, get the first and last sample to determine the sleep period
            let sleepStart = sleepSamples.first!.startDate
            let sleepEnd = sleepSamples.last!.endDate
            
            // Create a predicate for HRV data during the sleep period
            let hrvPredicate = HKQuery.predicateForSamples(withStart: sleepStart, end: sleepEnd, options: .strictStartDate)
            
            // Query HRV data
            let hrvQuery = HKSampleQuery(sampleType: self.hrvType, predicate: hrvPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, hrvSamples, error in
                guard let hrvSamples = hrvSamples as? [HKQuantitySample], !hrvSamples.isEmpty else {
                    completion(nil)
                    return
                }
                // Calculate average HRV
                let totalHRV = hrvSamples.reduce(0) { $0 + $1.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)) }
                let averageHRV = totalHRV / Double(hrvSamples.count)
                
                completion(averageHRV)
            }
            self.healthStore.execute(hrvQuery)
        }
        self.healthStore.execute(sleepQuery)
    }
    
    func fetchAvgHRVDuring60DaysSleep(completion: @escaping (Double?) -> Void) {
        let calendar = Calendar.current
        let now = Date()
        
        // Set the end date to 2 PM today
        var endDateComponents = calendar.dateComponents([.year, .month, .day], from: now)
        endDateComponents.hour = 14 // 2 PM
        let endDate = calendar.date(from: endDateComponents)!
        
        // Set the start date to 60 days before
        let startDate = calendar.date(byAdding: .day, value: -60, to: endDate)!
        
        // Create a predicate for sleep analysis in the 60-day range
        let sleepPredicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictStartDate)
        let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!
        
        // Query sleep analysis data
        let sleepQuery = HKSampleQuery(sampleType: sleepAnalysisType, predicate: sleepPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, sleepSamples, error in
            guard let sleepSamples = sleepSamples as? [HKCategorySample], !sleepSamples.isEmpty else {
                completion(nil)
                return
            }
            
            // Extract all sleep periods
            let sleepPeriods = sleepSamples.map { ($0.startDate, $0.endDate) }
            
            // Fetch HRV data for each sleep period
            let group = DispatchGroup()
            var totalHRV: Double = 0
            var totalCount: Int = 0
            
            for (sleepStart, sleepEnd) in sleepPeriods {
                group.enter()
                let hrvPredicate = HKQuery.predicateForSamples(withStart: sleepStart, end: sleepEnd, options: .strictStartDate)
                
                // Query HRV data
                let hrvQuery = HKSampleQuery(sampleType: self.hrvType, predicate: hrvPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, hrvSamples, error in
                    if let hrvSamples = hrvSamples as? [HKQuantitySample], !hrvSamples.isEmpty {
                        // Calculate total HRV for this sleep period
                        let periodHRV = hrvSamples.reduce(0) { $0 + $1.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli)) }
                        totalHRV += periodHRV
                        totalCount += hrvSamples.count
                    }
                    group.leave()
                }
                self.healthStore.execute(hrvQuery)
            }
            
            // Calculate average after all queries complete
            group.notify(queue: DispatchQueue.main) {
                let averageHRV = totalCount > 0 ? totalHRV / Double(totalCount) : nil
                completion(averageHRV)
            }
        }
        self.healthStore.execute(sleepQuery)
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
