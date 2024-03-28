import CoreData
import HealthKit

class DailyHealthService {
    private let managedContext: NSManagedObjectContext
    private let healthStore = HKHealthStore()
    private let hrvType = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN)!
    
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
                                                self.fetchAvgHRVDuringSleepForNightEndingOn(date: date) { lastSleepingHRV in
                                                    self.fetchAverageSleepingHR(from: sleepStart, to: sleepEnd) { averageSleepingHR in
                                                        self.fetchLowestSleepHR(from: sleepStart, to: sleepEnd) { lowestSleepHR in
                                                            self.fetchDeepSleep(from: sleepStart, to: sleepEnd) { deepSleep in
                                                                self.fetchREMSleep(from: sleepStart, to: sleepEnd) { remSleep in
                                                                    self.fetchCoreSleep(from: sleepStart, to: sleepEnd) { coreSleep in
                                                                        self.fetchAverageSleepingRespRate(from: sleepStart, to: sleepEnd) { averageSleepingRespRate in
                                                                            self.fetchAverageSleepingSPO2(from: sleepStart, to: sleepEnd) { averageSleepingSPO2 in
                                                                                self.saveDailyHealthEntity(date: date, sleepStart: sleepStart, sleepEnd: sleepEnd, averageHeartRate: averageHeartRate, calories: calories, steps: steps, averageWakingRespRate: averageWakingRespRate, averageWakingHR: averageWakingHR, averageWakingRHR: averageWakingRHR, averageWakingHRV: averageWakingHRV, averageWakingSPO2: averageWakingSPO2, lastSleepingHRV: lastSleepingHRV, averageSleepingHR: averageSleepingHR, lowestSleepHR: lowestSleepHR, deepSleep: deepSleep, remSleep: remSleep, coreSleep: coreSleep, averageSleepingRespRate: averageSleepingRespRate, averageSleepingSPO2: averageSleepingSPO2)
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
    
    
    //This function finds the last HRV reading of your sleeep period
    private func fetchAvgHRVDuringSleepForNightEndingOn(date: Date, completion: @escaping (Double?) -> Void) {
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
      
    private func fetchAverageSleepingHR(from startDate: Date, to endDate: Date, completion: @escaping (Double) -> Void) {
         let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
         let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
         
         let query = HKStatisticsQuery(quantityType: heartRateType,
                                       quantitySamplePredicate: predicate,
                                       options: .discreteAverage) { (query, statistics, error) in
             guard let averageSleepingHR = statistics?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())),
                   error == nil else {
                 print("Error fetching average sleeping heart rate: \(error?.localizedDescription ?? "")")
                 completion(0.0)
                 return
             }
             
             print("Average sleeping heart rate: \(averageSleepingHR) for date range: \(startDate) - \(endDate)")
             completion(averageSleepingHR)
         }
         
         healthStore.execute(query)
     }
     
     private func fetchLowestSleepHR(from startDate: Date, to endDate: Date, completion: @escaping (Double) -> Void) {
         let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
         let heartRateType = HKQuantityType.quantityType(forIdentifier: .heartRate)!
         
         let query = HKStatisticsQuery(quantityType: heartRateType,
                                       quantitySamplePredicate: predicate,
                                       options: .discreteMin) { (query, statistics, error) in
             guard let lowestSleepHR = statistics?.minimumQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())),
                   error == nil else {
                 print("Error fetching lowest sleep heart rate: \(error?.localizedDescription ?? "")")
                 completion(0.0)
                 return
             }
             
             print("Lowest sleep heart rate: \(lowestSleepHR) for date range: \(startDate) - \(endDate)")
             completion(lowestSleepHR)
         }
         
         healthStore.execute(query)
     }
     
    private func fetchDeepSleep(from startDate: Date, to endDate: Date, completion: @escaping (TimeInterval) -> Void) {
          let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
          let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
          
          let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
              guard let samples = results as? [HKCategorySample], error == nil else {
                  completion(0)
                  return
              }
              
              let deepSleepSamples = samples.filter { $0.value == HKCategoryValueSleepAnalysis.asleepDeep.rawValue }
              let deepSleepDuration = deepSleepSamples.reduce(0) { (total, sample) -> TimeInterval in
                  total + sample.endDate.timeIntervalSince(sample.startDate)
              }
              
              completion(deepSleepDuration)
          }
          
          healthStore.execute(query)
      }
      
      private func fetchREMSleep(from startDate: Date, to endDate: Date, completion: @escaping (TimeInterval) -> Void) {
          let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
          let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
          
          let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
              guard let samples = results as? [HKCategorySample], error == nil else {
                  completion(0)
                  return
              }
              
              let remSleepSamples = samples.filter { $0.value == HKCategoryValueSleepAnalysis.asleepREM.rawValue }
              let remSleepDuration = remSleepSamples.reduce(0) { (total, sample) -> TimeInterval in
                  total + sample.endDate.timeIntervalSince(sample.startDate)
              }
              
              completion(remSleepDuration)
          }
          
          healthStore.execute(query)
      }
      
      private func fetchCoreSleep(from startDate: Date, to endDate: Date, completion: @escaping (TimeInterval) -> Void) {
          let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
          let sleepType = HKObjectType.categoryType(forIdentifier: .sleepAnalysis)!
          
          let query = HKSampleQuery(sampleType: sleepType, predicate: predicate, limit: HKObjectQueryNoLimit, sortDescriptors: nil) { (query, results, error) in
              guard let samples = results as? [HKCategorySample], error == nil else {
                  completion(0)
                  return
              }
              
              let coreSleepSamples = samples.filter { $0.value == HKCategoryValueSleepAnalysis.asleepCore.rawValue }
              let coreSleepDuration = coreSleepSamples.reduce(0) { (total, sample) -> TimeInterval in
                  total + sample.endDate.timeIntervalSince(sample.startDate)
              }
              
              completion(coreSleepDuration)
          }
          
          healthStore.execute(query)
      }
      
    private func fetchAverageSleepingRespRate(from startDate: Date, to endDate: Date, completion: @escaping (Double) -> Void) {
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
            let respiratoryRateType = HKQuantityType.quantityType(forIdentifier: .respiratoryRate)!
            
            let query = HKStatisticsQuery(quantityType: respiratoryRateType,
                                          quantitySamplePredicate: predicate,
                                          options: .discreteAverage) { (query, statistics, error) in
                guard let averageSleepingRespRate = statistics?.averageQuantity()?.doubleValue(for: HKUnit.count().unitDivided(by: HKUnit.minute())),
                      error == nil else {
                    print("Error fetching average sleeping respiratory rate: \(error?.localizedDescription ?? "")")
                    completion(0.0)
                    return
                }
                
                print("Average sleeping respiratory rate: \(averageSleepingRespRate) for date range: \(startDate) - \(endDate)")
                completion(averageSleepingRespRate)
            }
            
            healthStore.execute(query)
        }
        
        private func fetchAverageSleepingSPO2(from startDate: Date, to endDate: Date, completion: @escaping (Double) -> Void) {
            let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate, options: .strictEndDate)
            let oxygenSaturationtype = HKQuantityType.quantityType(forIdentifier: .oxygenSaturation)!
            
            let query = HKStatisticsQuery(quantityType: oxygenSaturationtype,
                                          quantitySamplePredicate: predicate,
                                          options: .discreteAverage) { (query, statistics, error) in
                guard let averageSleepingSPO2 = statistics?.averageQuantity()?.doubleValue(for: HKUnit.percent()),
                      error == nil else {
                    print("Error fetching average sleeping SpO2: \(error?.localizedDescription ?? "")")
                    completion(0.0)
                    return
                }
                
                print("Average sleeping SpO2: \(averageSleepingSPO2) for date range: \(startDate) - \(endDate)")
                completion(averageSleepingSPO2)
            }
            
            healthStore.execute(query)
        }
        
        private func saveDailyHealthEntity(date: Date, sleepStart: Date, sleepEnd: Date, averageHeartRate: Double, calories: Double, steps: Double, averageWakingRespRate: Double, averageWakingHR: Double, averageWakingRHR: Double, averageWakingHRV: Double, averageWakingSPO2: Double, lastSleepingHRV: Double?, averageSleepingHR: Double, lowestSleepHR: Double, deepSleep: TimeInterval, remSleep: TimeInterval, coreSleep: TimeInterval, averageSleepingRespRate: Double, averageSleepingSPO2: Double) {
            let newDailyHealth = DailyHealthEntity(context: managedContext)
            newDailyHealth.date = date
            newDailyHealth.sleepStart = sleepStart
            newDailyHealth.sleepEnd = sleepEnd
            newDailyHealth.averageSleepingHR = averageHeartRate
            newDailyHealth.caloriesBurned = calories
            newDailyHealth.stepsTaken = steps
            newDailyHealth.averageWakingRespRate = averageWakingRespRate
            newDailyHealth.averageWakingHR = averageWakingHR
            newDailyHealth.averageWakingRHR = averageWakingRHR
            newDailyHealth.averageWakingHRV = averageWakingHRV
            newDailyHealth.averageWakingSPO2 = averageWakingSPO2
            newDailyHealth.lastSleepingHRV = lastSleepingHRV ?? 0.0
            newDailyHealth.averageSleepingHR = averageSleepingHR
            newDailyHealth.lowestSleepHR = lowestSleepHR
            newDailyHealth.deepSleep = deepSleep
            newDailyHealth.remSleep = remSleep
            newDailyHealth.coreSleep = coreSleep
            newDailyHealth.averageSleepingRespRate = averageSleepingRespRate
            newDailyHealth.averageSleepingSPO2 = averageSleepingSPO2
            
            do {
                try managedContext.save()
                print("Successfully saved daily health data for date: \(date)")
            } catch {
                print("Failed to save daily health data: \(error.localizedDescription)")
            }
        }
    }
