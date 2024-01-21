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
        let stepCountType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        let vo2MaxType = HKQuantityType.quantityType(forIdentifier: .vo2Max)!
        
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
               dateOfBirthType,
               stepCountType,
               vo2MaxType
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
    
    func fetchAvgRestingHeartRate(numDays: Int, completion: @escaping (Double?) -> Void) {
        let now = Date()
        let startOfDay = Calendar.current.startOfDay(for: now)
        let startDate = Calendar.current.date(byAdding: .day, value: -numDays, to: startOfDay)
        
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: now, options: .strictEndDate)
        
        guard let restingHeartRateType = HKObjectType.quantityType(forIdentifier: .restingHeartRate) else {
            completion(nil)
            return
        }
        
        let query = HKStatisticsQuery(quantityType: restingHeartRateType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, statistics, error in
            if let error = error {
                print("Error fetching average resting heart rate: \(error.localizedDescription)")
                completion(nil)
                return
            }
            
            guard let avgQuantity = statistics?.averageQuantity() else {
                completion(nil)
                return
            }
            
            let avgRestingHeartRate = avgQuantity.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute()))
            completion(avgRestingHeartRate)
        }
        
        healthStore.execute(query)
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
    
    public func fetchMostRecentVO2Max(completion: @escaping (Double?, Error?) -> Void) {
        let vo2MaxType = HKQuantityType.quantityType(forIdentifier: .vo2Max)!
        
        // Create a sort descriptor to fetch the most recent sample
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        // Create a query to fetch the most recent VO2 max sample
        let vo2MaxQuery = HKSampleQuery(sampleType: vo2MaxType, predicate: nil, limit: 1, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            guard let vo2MaxSample = samples?.first as? HKQuantitySample else {
                DispatchQueue.main.async {
                    print("Error or no VO2 max sample found: \(String(describing: error))")
                    completion(nil, error)
                }
                return
            }
            // Extract the VO2 max value from the sample
            let vo2MaxUnit = HKUnit(from: "ml/(kg*min)")
            let vo2MaxValue = vo2MaxSample.quantity.doubleValue(for: vo2MaxUnit)
            completion(vo2MaxValue, nil)
        }
        
        healthStore.execute(vo2MaxQuery)
    }

    func fetchStepsToday(completion: @escaping (Double?, Error?) -> Void) {
         // Check if step count data is available on the device
         guard HKHealthStore.isHealthDataAvailable() else {
             completion(nil, NSError(domain: "com.yourapp.HealthKitManager", code: 1, userInfo: [NSLocalizedDescriptionKey: "Health data is not available on this device."]))
             return
         }
         
         // Define the type for step count
         let stepType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
         
         // Set the start and end date to represent today
         let calendar = Calendar.current
         let now = Date()
         let startOfDay = calendar.startOfDay(for: now)
         let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
         
         // Create a predicate to fetch step count data for today
         let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
         
         // Create a query to fetch step count samples
         let query = HKStatisticsQuery(quantityType: stepType, quantitySamplePredicate: predicate, options: .cumulativeSum) { (_, result, error) in
             guard let result = result, let sum = result.sumQuantity() else {
                 completion(nil, error)
                 return
             }
             
             let stepCount = sum.doubleValue(for: HKUnit.count())
             completion(stepCount, nil)
         }
         
         healthStore.execute(query)
     }
    
    
    //THIS iS NOT MOST RECENT, IT IS
    func fetchMostRecentRestingHeartRate(completion: @escaping (Int?) -> Void) {
        // First, get the sleep times
        getSleepTimes(for: Date()) { sleepStart, sleepEnd in
            guard let sleepStart = sleepStart, let sleepEnd = sleepEnd else {
                completion(nil)
                return
            }

            // Create a predicate to fetch heart rate samples during sleep time
            let predicate = HKQuery.predicateForSamples(withStart: sleepStart, end: sleepEnd, options: .strictEndDate)
            let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!

            // Create a statistics query to calculate the average heart rate during sleep
            let heartRateQuery = HKStatisticsQuery(quantityType: heartRateType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, error in
                guard error == nil else {
                    completion(nil)
                    return
                }

                if let avgQuantity = result?.averageQuantity() {
                    let averageHeartRate = avgQuantity.doubleValue(for: HKUnit(from: "count/min"))
                    DispatchQueue.main.async {
                        // Convert the average from Double to Int
                        completion(Int(averageHeartRate.rounded()))
                    }
                } else {
                    // Return nil if there are no heart rate readings for the sleep period
                    completion(nil)
                }
            }

            HKHealthStore().execute(heartRateQuery)
        }
    }
    
    
    func fetchAverageDailyRHR(completion: @escaping (Int?) -> Void) {
        let calendar = Calendar.current
          let startOfToday = calendar.startOfDay(for: Date())
          let endOfToday = Date() // Current moment

          // Create a predicate to fetch resting heart rate samples for the current day
          let predicate = HKQuery.predicateForSamples(withStart: startOfToday, end: endOfToday, options: .strictEndDate)
          let heartRateType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!

          // Create a statistics query to calculate the average resting heart rate
          let heartRateQuery = HKStatisticsQuery(quantityType: heartRateType, quantitySamplePredicate: predicate, options: .discreteAverage) { _, result, error in
              guard error == nil else {
                  completion(nil)
                  return
              }

              if let avgQuantity = result?.averageQuantity() {
                  let averageHeartRate = avgQuantity.doubleValue(for: HKUnit(from: "count/min"))
                  DispatchQueue.main.async {
                      // Convert the average from Double to Int
                      completion(Int(averageHeartRate.rounded()))
                  }
              } else {
                  // Return nil if there are no resting heart rate readings for the current day
                  completion(nil)
              }
          }

          healthStore.execute(heartRateQuery)
      }

    
    
    
    func fetchMostRecentRespiratoryRate(completion: @escaping (Double?) -> Void) {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let endOfToday = Date() // Current moment
        
        // Create a predicate to fetch respiratory rate samples for the current day
        let predicate = HKQuery.predicateForSamples(withStart: startOfToday, end: endOfToday, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: respirationRateType, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard error == nil else {
                completion(nil)
                return
            }
            
            if let sample = samples?.first as? HKQuantitySample {
                let respiratoryRate = sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                completion(respiratoryRate)
            } else {
                // Return 0 if there are no respiratory rate readings for the current day
                completion(0)
            }
        }
        healthStore.execute(query)
    }
    
    
    
    func fetchMostRecentSPO2(completion: @escaping (Double?) -> Void) {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let endOfToday = Date() // Current moment
        
        // Create a predicate to fetch SpO2 samples for the current day
        let predicate = HKQuery.predicateForSamples(withStart: startOfToday, end: endOfToday, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)
        
        let query = HKSampleQuery(sampleType: spo2Type, predicate: predicate, limit: 1, sortDescriptors: [sortDescriptor]) { _, samples, error in
            guard error == nil else {
                completion(nil)
                return
            }
            
            if let sample = samples?.first as? HKQuantitySample {
                let spo2 = sample.quantity.doubleValue(for: HKUnit.percent())
                completion(spo2)
            } else {
                // Return 0 if there are no SpO2 readings for the current day
                completion(0)
            }
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
    
    struct SleepSession {
        var start: Date
        var end: Date

        var duration: TimeInterval {
            return end.timeIntervalSince(start)
        }

        func overlaps(with other: SleepSession) -> Bool {
            return (start < other.end) && (end > other.start)
        }

        func merge(with other: SleepSession) -> SleepSession {
            // Merge overlapping sessions by taking the earliest start time and the latest end time
            return SleepSession(start: min(start, other.start), end: max(end, other.end))
            
        }
    }
    
    private func getSleepTimes(for date: Date, completion: @escaping (Date?, Date?) -> Void) {
        let calendar = Calendar.current
        
        // Set search window from 7 PM the day before to 2 PM on the date
        let startOfCurrentDay = calendar.startOfDay(for: date)
        let sleepSearchStartTime = calendar.date(bySettingHour: 19, minute: 0, second: 0, of: startOfCurrentDay.addingTimeInterval(-24 * 60 * 60))!
        let sleepSearchEndTime = calendar.date(bySettingHour: 14, minute: 0, second: 0, of: startOfCurrentDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: sleepSearchStartTime, end: sleepSearchEndTime, options: .strictEndDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: true)
        let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [sortDescriptor]) { (query, samples, error) in
            guard error == nil, let sleepSamples = samples as? [HKCategorySample] else {
                print("Error fetching sleep data: \(String(describing: error))")
                completion(nil, nil)
                return
            }
            
            // Filter 'asleep' samples and ignore very short sessions
            let asleepSamples = sleepSamples.filter { $0.value == HKCategoryValueSleepAnalysis.asleep.rawValue && $0.endDate.timeIntervalSince($0.startDate) >= 15 * 60 }
            
            // Identify the primary sleep session by finding the longest session
            guard let primarySleepSession = asleepSamples.max(by: { $0.endDate.timeIntervalSince($0.startDate) < $1.endDate.timeIntervalSince($1.startDate) }) else {
                print("No significant sleep session found.")
                completion(nil, nil)
                return
            }
            
            // Initial sleep period
            var sleepStart = primarySleepSession.startDate
            var sleepEnd = primarySleepSession.endDate
            
            // Check for additional sleep sessions after the primary session
            let additionalSleepSessions = asleepSamples.filter { $0.startDate > sleepEnd }
            if let lastAdditionalSleep = additionalSleepSessions.last {
                sleepEnd = lastAdditionalSleep.endDate
            }
            
            DispatchQueue.main.async {
                completion(sleepStart, sleepEnd)
            }
        }
        
        HKHealthStore().execute(query)
    }

    
    func fetchAverageRHRDuringSleep(for date: Date, completion: @escaping (Double?) -> Void) {
        getSleepTimes(for: date) { sleepStart, sleepEnd in
            guard let sleepStart = sleepStart, let sleepEnd = sleepEnd else {
                completion(nil)
                return
            }

            let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
            let predicate = HKQuery.predicateForSamples(withStart: sleepStart, end: sleepEnd, options: .strictEndDate)
            let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
                
                guard error == nil, let heartRateSamples = samples as? [HKQuantitySample] else {
                    print("Error fetching heart rate data: \(String(describing: error))")
                    completion(nil)
                    return
                }

                let heartRates = heartRateSamples.map { $0.quantity.doubleValue(for: HKUnit(from: "count/min")) }
                let totalHeartRate = heartRates.reduce(0, +)
                let averageHeartRate = heartRates.isEmpty ? nil : totalHeartRate / Double(heartRates.count)

                DispatchQueue.main.async {
                    completion(averageHeartRate)
                }
            }
            
            HKHealthStore().execute(query)
        }
    }

//    func fetchAverageRHRDuringSleep(for date: Date, completion: @escaping (Double?) -> Void) {
//        getSleepTimes(for: date) { sleepStart, sleepEnd in
//            guard let sleepStart = sleepStart, let sleepEnd = sleepEnd else {
//                completion(nil)
//                return
//            }
//
//            let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
//            let predicate = HKQuery.predicateForSamples(withStart: sleepStart, end: sleepEnd, options: .strictEndDate)
//            let query = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, samples, error) in
//                
//                guard error == nil, let heartRateSamples = samples as? [HKQuantitySample] else {
//                    print("Error fetching heart rate data: \(String(describing: error))")
//                    completion(nil)
//                    return
//                }
//
//                let heartRates = heartRateSamples.map { $0.quantity.doubleValue(for: HKUnit(from: "count/min")) }
//                let totalHeartRate = heartRates.reduce(0, +)
//                let averageHeartRate = heartRates.isEmpty ? nil : totalHeartRate / Double(heartRates.count)
//
//                DispatchQueue.main.async {
//                    completion(averageHeartRate)
//                }
//            }
//            
//            HKHealthStore().execute(query)
//        }
//    }


    func fetchAverageSleepVitalsForDays(days: [Date], completion: @escaping (Double, Double) -> Void) {
        let calendar = Calendar.current
        let healthStore = HKHealthStore()
        let group = DispatchGroup()

        var dailyVitalsResults: [(averageHeartRate: Double, averageHRV: Double)] = []

        for date in days {
            group.enter()

            getSleepTimes(for: date) { sleepStart, sleepEnd in
                guard let sleepStart = sleepStart, let sleepEnd = sleepEnd else {
                    print("Error getting sleep times.")
                    group.leave()
                    return
                }

                let predicate = HKQuery.predicateForSamples(withStart: sleepStart, end: sleepEnd, options: .strictEndDate)
                let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
                let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!

                let heartRateQuery = HKSampleQuery(sampleType: heartRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { (query, samples, error) in

                    guard let heartRateSamples = samples as? [HKQuantitySample], error == nil else {
                        print("Error fetching heart rate data: \(String(describing: error))")
                        group.leave()
                        return
                    }

                    let totalHeartRate = heartRateSamples.reduce(0.0) { (acc, sample) -> Double in
                        return acc + sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                    }
                    let averageHeartRate = heartRateSamples.isEmpty ? 0.0 : totalHeartRate / Double(heartRateSamples.count)

                    let hrvQuery = HKSampleQuery(sampleType: hrvType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { (query, samples, error) in

                        guard let hrvSamples = samples as? [HKQuantitySample], error == nil else {
                            print("Error fetching HRV data: \(String(describing: error))")
                            group.leave()
                            return
                        }

                        let totalHRV = hrvSamples.reduce(0.0) { (acc, sample) -> Double in
                            return acc + sample.quantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                        }
                        let averageHRV = hrvSamples.isEmpty ? 0.0 : totalHRV / Double(hrvSamples.count)

                        dailyVitalsResults.append((averageHeartRate: averageHeartRate, averageHRV: averageHRV))
                        group.leave()
                    }

                    healthStore.execute(hrvQuery)
                }

                healthStore.execute(heartRateQuery)
            }
        }

        group.notify(queue: .main) {
            let totalDays = Double(dailyVitalsResults.count)
            let averageHeartRate = dailyVitalsResults.map { $0.averageHeartRate }.reduce(0, +) / totalDays
            let averageHRV = dailyVitalsResults.map { $0.averageHRV }.reduce(0, +) / totalDays

            completion(averageHeartRate, averageHRV)
        }
    }

    func fetchAverageRespiratoryRateAndSPO2ForDays(days: [Date], completion: @escaping (Double, Double) -> Void) {
        let healthStore = HKHealthStore()
        let group = DispatchGroup()

        var dailyVitalsResults: [(averageRespiratoryRate: Double, averageSPO2: Double)] = []

        for date in days {
            group.enter()

            getSleepTimes(for: date) { sleepStart, sleepEnd in
                guard let sleepStart = sleepStart, let sleepEnd = sleepEnd else {
                    print("Error getting sleep times for date: \(date)")
                    group.leave()
                    return
                }

                let predicate = HKQuery.predicateForSamples(withStart: sleepStart, end: sleepEnd, options: .strictEndDate)
                let respiratoryRateType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!
                let spo2Type = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!

                let respiratoryRateQuery = HKSampleQuery(sampleType: respiratoryRateType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { (query, samples, error) in

                    guard let respiratoryRateSamples = samples as? [HKQuantitySample], error == nil else {
                        print("Error fetching respiratory rate data for date: \(date), Error: \(String(describing: error))")
                        group.leave()
                        return
                    }

                    let totalRespiratoryRate = respiratoryRateSamples.reduce(0.0) { (acc, sample) -> Double in
                        return acc + sample.quantity.doubleValue(for: HKUnit(from: "count/min"))
                    }
                    let averageRespiratoryRate = respiratoryRateSamples.isEmpty ? 0.0 : totalRespiratoryRate / Double(respiratoryRateSamples.count)

                    let spo2Query = HKSampleQuery(sampleType: spo2Type, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { (query, samples, error) in

                        guard let spo2Samples = samples as? [HKQuantitySample], error == nil else {
                            print("Error fetching SPO2 data for date: \(date), Error: \(String(describing: error))")
                            group.leave()
                            return
                        }

                        let totalSPO2 = spo2Samples.reduce(0.0) { (acc, sample) -> Double in
                            return acc + sample.quantity.doubleValue (for: HKUnit.percent())
                        }
                        let averageSPO2 = spo2Samples.isEmpty ? 0.0 : totalSPO2 / Double(spo2Samples.count)

                        // Append the results for this day to the daily vitals results array
                        dailyVitalsResults.append((averageRespiratoryRate: averageRespiratoryRate, averageSPO2: averageSPO2))
                        group.leave()
                    }

                    // Execute the SPO2 Query
                    healthStore.execute(spo2Query)
                }

                // Execute the Respiratory Rate Query
                healthStore.execute(respiratoryRateQuery)
            }
        }

        group.notify(queue: .main) {
            // Calculate the overall averages
            let totalRespiratoryRate = dailyVitalsResults.reduce(0.0) { $0 + $1.averageRespiratoryRate }
            let totalSPO2 = dailyVitalsResults.reduce(0.0) { $0 + $1.averageSPO2 }
            let averageRespiratoryRate = !dailyVitalsResults.isEmpty ? totalRespiratoryRate / Double(dailyVitalsResults.count) : 0.0
            let averageSPO2 = !dailyVitalsResults.isEmpty ? totalSPO2 / Double(dailyVitalsResults.count) : 0.0

            // Call the completion handler with the overall average values
            completion(averageRespiratoryRate, averageSPO2)
        }
    }

    func fetchWakingStatisticsForDays(days: [Date], completion: @escaping (Double, Double, Double) -> Void) {
        let healthStore = HKHealthStore()
        let group = DispatchGroup()

        var totalRestingHeartRate = 0.0
        var totalCaloriesBurned = 0.0
        var totalStepsTaken = 0.0
        
        var count = 0.0
        
        var heartRateCount = 0.0

        for date in days {
            count += 1

            // Resting Heart Rate Query
            group.enter()
            let restingHeartRateType = HKObjectType.quantityType(forIdentifier: .restingHeartRate)!
            let heartRatePredicate = HKQuery.predicateForSamples(withStart: date, end: Calendar.current.startOfDay(for: date).addingTimeInterval(24 * 3600), options: [])
            let heartRateQuery = HKStatisticsQuery(quantityType: restingHeartRateType, quantitySamplePredicate: heartRatePredicate, options: .discreteAverage) { _, result, _ in
                defer { group.leave() }

                if let result = result, let avgQuantity = result.averageQuantity() {
                    var hrvalue = avgQuantity.doubleValue(for: HKUnit(from: "count/min"))
                    totalRestingHeartRate += avgQuantity.doubleValue(for: HKUnit(from: "count/min"))
                    
                    if (hrvalue != 0) {
                        heartRateCount += 1
                    }
                }
            }
            healthStore.execute(heartRateQuery)

            // Total Calories Burned Query
            group.enter()
            let caloriesType = HKObjectType.quantityType(forIdentifier: .activeEnergyBurned)!
            let caloriesPredicate = HKQuery.predicateForSamples(withStart: date, end: Calendar.current.startOfDay(for: date).addingTimeInterval(24 * 3600), options: [])
            let caloriesQuery = HKStatisticsQuery(quantityType: caloriesType, quantitySamplePredicate: caloriesPredicate, options: .cumulativeSum) { _, result, _ in
                defer { group.leave() }

                if let result = result, let sumQuantity = result.sumQuantity() {
                    totalCaloriesBurned += sumQuantity.doubleValue(for: HKUnit.kilocalorie())
                }
            }
            healthStore.execute(caloriesQuery)

            // Steps Taken Query
            group.enter()
            let stepsType = HKObjectType.quantityType(forIdentifier: .stepCount)!
            let stepsPredicate = HKQuery.predicateForSamples(withStart: date, end: Calendar.current.startOfDay(for: date).addingTimeInterval(24 * 3600), options: [])
            let stepsQuery = HKStatisticsQuery(quantityType: stepsType, quantitySamplePredicate: stepsPredicate, options: .cumulativeSum) { _, result, _ in
                defer { group.leave() }

                if let result = result, let sumQuantity = result.sumQuantity() {
                    totalStepsTaken += sumQuantity.doubleValue(for: HKUnit.count())
                }
            }
            healthStore.execute(stepsQuery)
        }

        group.notify(queue: .main) {
            let averageRestingHeartRate = totalRestingHeartRate / heartRateCount
            let averageCaloriesBurned = totalCaloriesBurned / count
            let averageStepsTaken = totalStepsTaken / count

            completion(averageRestingHeartRate, averageCaloriesBurned, averageStepsTaken)
        }
    }



    // Return averageTotalSleep, averageREMSleep, averageDeepSleep, averageCoreSleep
    func fetchAverageSleepStatisticsForDays(days: [Date], completion: @escaping (Double, Double, Double, Double) -> Void) {
        let calendar = Calendar.current
        let healthStore = HKHealthStore()
        let group = DispatchGroup()

        var dailySleepResults: [(totalSleep: Double, remSleep: Double, deepSleep: Double, coreSleep: Double)] = []

        for date in days {
            group.enter()

            let sleepStartTime = calendar.startOfDay(for: date).addingTimeInterval(19 * 3600) // 7 PM
            let sleepEndTime = calendar.startOfDay(for: date).addingTimeInterval((24 + 14) * 3600) // 2 PM next day

            let predicate = HKQuery.predicateForSamples(withStart: sleepStartTime, end: sleepEndTime, options: .strictEndDate)
            let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis)!

            let sleepQuery = HKSampleQuery(sampleType: sleepAnalysisType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]) { (query, samples, error) in
                defer { group.leave() }

                guard let sleepSamples = samples as? [HKCategorySample], error == nil else {
                    print("Error fetching sleep data: \(String(describing: error))")
                    return
                }

                if sleepSamples.isEmpty {
                    // No sleep data available for this day, skip it
                    return
                }

                var totalREMSleepDurationForDay = 0.0
                var totalDeepSleepDurationForDay = 0.0
                var totalCoreSleepDurationForDay = 0.0

                for sleepSample in sleepSamples {
                    let duration = sleepSample.endDate.timeIntervalSince(sleepSample.startDate)
                    
                    switch sleepSample.value {
                    case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                        totalREMSleepDurationForDay += duration
                    case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                        totalDeepSleepDurationForDay += duration
                    case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                        totalCoreSleepDurationForDay += duration
                    default:
                        break
                    }
                }

                let totalSleepDurationForDay = totalCoreSleepDurationForDay + totalREMSleepDurationForDay + totalDeepSleepDurationForDay
                dailySleepResults.append((totalSleep: totalSleepDurationForDay, remSleep: totalREMSleepDurationForDay, deepSleep: totalDeepSleepDurationForDay, coreSleep: totalCoreSleepDurationForDay))

                // Debugging statement to print total sleep duration for the current day
            }

            healthStore.execute(sleepQuery)
        }

        group.notify(queue: .main) {
            // Filter out days with no sleep data
            let filteredDailySleepResults = dailySleepResults.filter { $0.totalSleep > 0 }

            let totalDays = Double(filteredDailySleepResults.count)
            let averageTotalSleep = filteredDailySleepResults.map { $0.totalSleep }.reduce(0, +) / (totalDays * 3600)
            let averageREMSleep = filteredDailySleepResults.map { $0.remSleep }.reduce(0, +) / (totalDays * 3600)
            let averageDeepSleep = filteredDailySleepResults.map { $0.deepSleep }.reduce(0, +) / (totalDays * 3600)
            let averageCoreSleep = filteredDailySleepResults.map { $0.coreSleep }.reduce(0, +) / (totalDays * 3600)

            completion(averageTotalSleep, averageREMSleep, averageDeepSleep, averageCoreSleep)
        }
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
                    completion(nil)
                }
            }
        }
        healthStore.execute(hrvQuery)
    }
    
    func fetchSleepDurationForPreviousNight(completion: @escaping (Double?) -> Void) {
        let calendar = Calendar.current
        
        // Calculate the start of the current day
        let startOfCurrentDay = calendar.startOfDay(for: Date())
        
        // Calculate the end of the sleep period, which is 2 PM today
        guard let endOfSleepPeriod = calendar.date(byAdding: .hour, value: 14, to: startOfCurrentDay) else {
            completion(nil)
            return
        }
        
        // Calculate the start of the sleep period, which is 7 PM yesterday
        let startOfPreviousDay = calendar.date(byAdding: .day, value: -1, to: startOfCurrentDay)!
        guard let startOfSleepPeriod = calendar.date(byAdding: .hour, value: 19, to: startOfPreviousDay) else {
            completion(nil)
            return
        }
        
        // Create a predicate for querying sleep analysis data
        let sleepPeriodPredicate = HKQuery.predicateForSamples(withStart: startOfSleepPeriod, end: endOfSleepPeriod, options: .strictStartDate)
        guard let sleepAnalysisType = HKObjectType.categoryType(forIdentifier: HKCategoryTypeIdentifier.sleepAnalysis) else {
            completion(nil)
            return
        }
        
        // Query sleep analysis data
        let sleepQuery = HKSampleQuery(sampleType: sleepAnalysisType, predicate: sleepPeriodPredicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, sleepSamples, error in
            guard error == nil, let sleepSamples = sleepSamples as? [HKCategorySample], !sleepSamples.isEmpty else {
                completion(nil)
                return
            }
            
            var totalSleepTime: TimeInterval = 0
            var lastSleepSampleEndDate: Date? = startOfSleepPeriod
            
            for sample in sleepSamples {
                // Check if the sample represents actual sleep
                if sample.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue {
                    
                    // Adjust for overlapping sleep periods
                    let adjustedStartDate = max(sample.startDate, lastSleepSampleEndDate ?? sample.startDate)
                    if adjustedStartDate < sample.endDate {
                        totalSleepTime += sample.endDate.timeIntervalSince(adjustedStartDate)
                        lastSleepSampleEndDate = max(lastSleepSampleEndDate ?? sample.startDate, sample.endDate)
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
    
    
    //This is actually average HRV for the Day
    func fetchMostRecentHRVForToday(before date: Date, completion: @escaping (Double?) -> Void) {
        let calendar = Calendar.current
           let startOfDay = calendar.startOfDay(for: date)
           let hrvPredicate = HKQuery.predicateForSamples(withStart: startOfDay, end: date, options: .strictEndDate)

           let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
           let hrvQuery = HKStatisticsQuery(quantityType: hrvType, quantitySamplePredicate: hrvPredicate, options: .discreteAverage) { _, result, error in
               guard error == nil else {
                   completion(nil)
                   return
               }

               if let avgQuantity = result?.averageQuantity() {
                   let avgHrvValue = avgQuantity.doubleValue(for: HKUnit.secondUnit(with: .milli))
                   completion(avgHrvValue)
               } else {
                   // Return nil if there are no HRV readings for the current day
                   completion(nil)
               }
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
    
    
    func fetchSleepData(completion: @escaping ([HKCategorySample]?, Error?) -> Void) {
        guard let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else {
            completion(nil, nil)
            return
        }
        
        let calendar = Calendar.current
        
        // Get 7 PM of the previous day
        let startOfToday = calendar.startOfDay(for: Date())
        guard let startOfSleepPeriod = calendar.date(byAdding: .hour, value: -5, to: startOfToday) else {
            completion(nil,nil)
            return
        }
        
        // Get 2 PM of the current day
        guard let endOfSleepPeriod = calendar.date(byAdding: .hour, value: 14, to: startOfToday) else {
            completion(nil, nil)
            return
        }
        
        // Create predicate for the specified time period
        let predicate = HKQuery.predicateForSamples(withStart: startOfSleepPeriod, end: endOfSleepPeriod, options: .strictStartDate)
        
        let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { _, samples, error in
            guard let samples = samples as? [HKCategorySample], error == nil else {
                completion(nil, error)
                return
            }
            completion(samples, nil)
        }
        
        healthStore.execute(query)
    }
    
    func processSleepData(samples: [HKCategorySample]) -> [String: TimeInterval] {
        let deepSleepSamples = samples.filter { $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue }
        let coreSleepSamples = samples.filter { $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue }
        let remSleepSamples = samples.filter { $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue }
        let unspecifiedSleepSamples = samples.filter { $0.value == HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue }
        let awakeSamples = samples.filter { $0.value == HKCategoryValueSleepAnalysis.awake.rawValue }
        
        let totalDeepSleepTime = deepSleepSamples.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
        let totalCoreSleepTime = coreSleepSamples.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
        let totalRemSleepTime = remSleepSamples.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
        let totalUnspecifiedSleepTime = unspecifiedSleepSamples.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
        let totalAwakeTime = awakeSamples.reduce(0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
        
        var sleepDataResults: [String: TimeInterval] = [:]
        sleepDataResults["Deep Sleep"] = totalDeepSleepTime
        sleepDataResults["Core Sleep"] = totalCoreSleepTime
        sleepDataResults["REM Sleep"] = totalRemSleepTime
        sleepDataResults["Unspecified Sleep"] = totalUnspecifiedSleepTime
        sleepDataResults["Awake"] = totalAwakeTime
        
        return sleepDataResults
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

