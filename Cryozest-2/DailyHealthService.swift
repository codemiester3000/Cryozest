import CoreData
import HealthKit

class DailyHealthService {
    private let managedContext: NSManagedObjectContext
    private let healthStore = HKHealthStore()
    
    init(managedContext: NSManagedObjectContext) {
        self.managedContext = managedContext
    }
    
    func saveDailyHealthData(date: Date, completion: @escaping (Bool) -> Void) {
           fetchSleepTimes(for: date) { sleepStart, sleepEnd in
               guard let sleepStart = sleepStart, let sleepEnd = sleepEnd else {
                   print("No sleep data available for date: \(date)")
                   completion(false)
                   return
               }
               
               self.fetchAverageHeartRate(from: sleepStart, to: sleepEnd) { averageHeartRate in
                   self.fetchDailyCalories(for: date) { calories in
                       self.fetchDailySteps(for: date) { steps in
                           self.fetchAverageWakingRespRate(from: sleepEnd, to: date) { averageWakingRespRate in
                               self.fetchAverageWakingHR(from: sleepEnd, to: date) { averageWakingHR in
                                   self.fetchAverageWakingRHR(from: sleepEnd, to: date) { averageWakingRHR in
                                       self.fetchAverageWakingHRV(from: sleepEnd, to: date) { averageWakingHRV in
                                           self.fetchAverageWakingSPO2(from: sleepEnd, to: date) { averageWakingSPO2 in
                                               self.saveDailyHealthEntity(date: date, sleepStart: sleepStart, sleepEnd: sleepEnd, averageHeartRate: averageHeartRate, calories: calories, steps: steps, averageWakingRespRate: averageWakingRespRate, averageWakingHR: averageWakingHR, averageWakingRHR: averageWakingRHR, averageWakingHRV: averageWakingHRV, averageWakingSPO2: averageWakingSPO2)
                                               completion(true)
                                           }
                                       }
                                   }
                               }
                           }
                       }
                   }
               }
           }
       }
    
    
    
    private func fetchSleepTimes(for date: Date, completion: @escaping (Date?, Date?) -> Void) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!
        
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        let sortDescriptor = NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)
        
        let query = HKSampleQuery(sampleType: HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!,
                                  predicate: predicate,
                                  limit: HKObjectQueryNoLimit,
                                  sortDescriptors: [sortDescriptor]) { (query, results, error) in
            guard let samples = results as? [HKCategorySample], error == nil else {
                print("Error fetching sleep times: \(error?.localizedDescription ?? "")")
                completion(nil, nil)
                return
            }
            
            let sleepSamples = samples.filter { $0.value == HKCategoryValueSleepAnalysis.asleep.rawValue }
            
            if sleepSamples.isEmpty {
                print("No sleep samples found for date: \(date)")
            } else {
                print("Found \(sleepSamples.count) sleep samples for date: \(date)")
            }
            
            let sleepStart = sleepSamples.first?.startDate
            let sleepEnd = sleepSamples.last?.endDate
            
            completion(sleepStart, sleepEnd)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchAverageHeartRate(from startDate: Date, to endDate: Date, completion: @escaping (Double) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        let query = HKStatisticsQuery(quantityType: heartRateType,
                                      quantitySamplePredicate: predicate,
                                      options: .discreteAverage) { (query, statistics, error) in
            guard let averageHeartRate = statistics?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())),
                  error == nil else {
                print("Error fetching average heart rate: \(error?.localizedDescription ?? "")")
                completion(0.0)
                return
            }
            
            print("Average heart rate: \(averageHeartRate) for date range: \(startDate) - \(endDate)")
            completion(averageHeartRate)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchDailyCalories(for date: Date, completion: @escaping (Double) -> Void) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        let energyType = HKQuantityType.quantityType(forIdentifier: .activeEnergyBurned)!
        
        let query = HKStatisticsQuery(quantityType: energyType,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { (query, statistics, error) in
            guard let calories = statistics?.sumQuantity()?.doubleValue(for: HKUnit.kilocalorie()),
                  error == nil else {
                print("Error fetching daily calories: \(error?.localizedDescription ?? "")")
                completion(0.0)
                return
            }
            
            print("Total calories burned: \(calories) for date: \(date)")
            completion(calories)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchDailySteps(for date: Date, completion: @escaping (Double) -> Void) {
        let startOfDay = Calendar.current.startOfDay(for: date)
        let endOfDay = Calendar.current.date(byAdding: .day, value: 1, to: startOfDay)!
        let predicate = HKQuery.predicateForSamples(withStart: startOfDay, end: endOfDay, options: .strictStartDate)
        let stepsType = HKQuantityType.quantityType(forIdentifier: .stepCount)!
        
        let query = HKStatisticsQuery(quantityType: stepsType,
                                      quantitySamplePredicate: predicate,
                                      options: .cumulativeSum) { (query, statistics, error) in
            guard let steps = statistics?.sumQuantity()?.doubleValue(for: HKUnit.count()),
                  error == nil else {
                print("Error fetching daily steps: \(error?.localizedDescription ?? "")")
                completion(0.0)
                return
            }
            
            print("Total steps: \(steps) for date: \(date)")
            completion(steps)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchAverageWakingRespRate(from startDate: Date, to endDate: Date, completion: @escaping (Double) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let respRateType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!
        
        let query = HKStatisticsQuery(quantityType: respRateType,
                                      quantitySamplePredicate: predicate,
                                      options: .discreteAverage) { (query, statistics, error) in
            guard let averageRespRate = statistics?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())),
                  error == nil else {
                print("Error fetching average waking respiratory rate: \(error?.localizedDescription ?? "")")
                completion(0.0)
                return
            }
            
            print("Average waking respiratory rate: \(averageRespRate) for date range: \(startDate) - \(endDate)")
            completion(averageRespRate)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchAverageWakingHR(from startDate: Date, to endDate: Date, completion: @escaping (Double) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
        
        let query = HKStatisticsQuery(quantityType: heartRateType,
                                      quantitySamplePredicate: predicate,
                                      options: .discreteAverage) { (query, statistics, error) in
            guard let averageWakingHR = statistics?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())),
                  error == nil else {
                print("Error fetching average waking heart rate: \(error?.localizedDescription ?? "")")
                completion(0.0)
                return
            }
            
            print("Average waking heart rate: \(averageWakingHR) for date range: \(startDate) - \(endDate)")
            completion(averageWakingHR)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchAverageWakingRHR(from startDate: Date, to endDate: Date, completion: @escaping (Double) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let restingHeartRateType = HKQuantityType.quantityType(forIdentifier: .restingHeartRate)!
        
        let query = HKStatisticsQuery(quantityType: restingHeartRateType,
                                      quantitySamplePredicate: predicate,
                                      options: .discreteAverage) { (query, statistics, error) in
            guard let averageWakingRHR = statistics?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())),
                  error == nil else {
                print("Error fetching average waking resting heart rate: \(error?.localizedDescription ?? "")")
                completion(0.0)
                return
            }
            
            print("Average waking resting heart rate: \(averageWakingRHR) for date range: \(startDate) - \(endDate)")
            completion(averageWakingRHR)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchAverageWakingHRV(from startDate: Date, to endDate: Date, completion: @escaping (Double) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
        
        let query = HKStatisticsQuery(quantityType: hrvType,
                                      quantitySamplePredicate: predicate,
                                      options: .discreteAverage) { (query, statistics, error) in
            guard let averageWakingHRV = statistics?.averageQuantity()?.doubleValue(for: HKUnit.secondUnit(with: .milli)),
                  error == nil else {
                print("Error fetching average waking HRV: \(error?.localizedDescription ?? "")")
                completion(0.0)
                return
            }
            
            print("Average waking HRV: \(averageWakingHRV) for date range: \(startDate) - \(endDate)")
            completion(averageWakingHRV)
        }
        
        healthStore.execute(query)
    }
    
    private func fetchAverageWakingSPO2(from startDate: Date, to endDate: Date, completion: @escaping (Double) -> Void) {
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
        let oxygenSatType = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!
        
        let query = HKStatisticsQuery(quantityType: oxygenSatType,
                                      quantitySamplePredicate: predicate,
                                      options: .discreteAverage) { (query, statistics, error) in
            guard let averageWakingSPO2 = statistics?.averageQuantity()?.doubleValue(for: HKUnit.percent()),
                  error == nil else {
                print("Error fetching average waking SPO2: \(error?.localizedDescription ?? "")")
                completion(0.0)
                return
            }
            
            print("Average waking SPO2: \(averageWakingSPO2) for date range: \(startDate) - \(endDate)")
            completion(averageWakingSPO2)
        }
        
        healthStore.execute(query)
    }
    
    private func saveDailyHealthEntity(date: Date, sleepStart: Date, sleepEnd: Date, averageHeartRate: Double, calories: Double, steps: Double, averageWakingRespRate: Double, averageWakingHR: Double, averageWakingRHR: Double, averageWakingHRV: Double, averageWakingSPO2: Double) {
        let newDailyHealth = DailyHealthEntity(context: managedContext)
        newDailyHealth.date = date
        newDailyHealth.sleepStart = sleepStart
        newDailyHealth.sleepEnd = sleepEnd
        newDailyHealth.averageSleepingRHR = averageHeartRate
        newDailyHealth.caloriesBurned = calories
        newDailyHealth.stepsTaken = steps
        newDailyHealth.averageWakingRespRate = averageWakingRespRate
        newDailyHealth.averageWakingHR = averageWakingHR
        newDailyHealth.averageWakingRHR = averageWakingRHR
        newDailyHealth.averageWakingHRV = averageWakingHRV
        newDailyHealth.averageWakingSPO2 = averageWakingSPO2
        
        do {
            try managedContext.save()
            print("Successfully saved daily health data for date: \(date)")
        } catch {
            print("Failed to save daily health data: \(error.localizedDescription)")
        }
    }
}
