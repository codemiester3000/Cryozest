import SwiftUI

class UserSettings: ObservableObject {
    let recoveryMinutesDefault = 30
    @Published var recoveryMinutesGoal: Int {
        didSet {
            UserDefaults.standard.set(recoveryMinutesGoal, forKey: UserDefaultsKeys.recoveryMinutesGoal)
        }
    }
    
    let conditioningMinutesDefault = 45
    @Published var conditioningMinutesGoal: Int {
        didSet {
            UserDefaults.standard.set(conditioningMinutesGoal, forKey: UserDefaultsKeys.conditioningMinutesGoal)
        }
    }
    
    let highIntensityMinutesDefault = 20
    @Published var highIntensityMinutesGoal: Int {
        didSet {
            UserDefaults.standard.set(highIntensityMinutesGoal, forKey: UserDefaultsKeys.highIntensityMinutesGoal)
        }
    }
    
    let trainingIntensityDefault = "Maintaining"
    @Published var trainingIntensity: String {
        didSet {
            UserDefaults.standard.set(trainingIntensity, forKey: UserDefaultsKeys.trainingIntensity)
        }
    }
    
    let stepsGoalDefault = 10000
    @Published var stepsGoal: Int {
        didSet {
            UserDefaults.standard.set(stepsGoal, forKey: UserDefaultsKeys.stepsGoal)
        }
    }
    
    let remSleepGoalDefault = 90
    @Published var remSleepGoal: Int {
        didSet {
            UserDefaults.standard.set(remSleepGoal, forKey: UserDefaultsKeys.remSleepGoal)
        }
    }
    
    let deepSleepGoalDefault = 90
    @Published var deepSleepGoal: Int {
        didSet {
            UserDefaults.standard.set(deepSleepGoal, forKey: UserDefaultsKeys.deepSleepGoal)
        }
    }
    
    let coreSleepGoalDefault = 90
    @Published var coreSleepGoal: Int {
        didSet {
            UserDefaults.standard.set(coreSleepGoal, forKey: UserDefaultsKeys.coreSleepGoal)
        }
    }
    
    let totalSleepGoalDefault = 8
    @Published var totalSleepGoal: Int {
        didSet {
            UserDefaults.standard.set(totalSleepGoal, forKey: UserDefaultsKeys.totalSleepGoal)
        }
    }
    
    
    
    init() {
        // Initialize the default values first
        recoveryMinutesGoal = UserDefaults.standard.integer(forKey: UserDefaultsKeys.recoveryMinutesGoal)
        conditioningMinutesGoal = UserDefaults.standard.integer(forKey: UserDefaultsKeys.conditioningMinutesGoal)
        highIntensityMinutesGoal = UserDefaults.standard.integer(forKey: UserDefaultsKeys.highIntensityMinutesGoal)
        trainingIntensity = UserDefaults.standard.string(forKey: UserDefaultsKeys.trainingIntensity) ?? trainingIntensityDefault
        stepsGoal = UserDefaults.standard.integer(forKey: UserDefaultsKeys.stepsGoal)
        remSleepGoal = UserDefaults.standard.integer(forKey: UserDefaultsKeys.remSleepGoal)
        deepSleepGoal = UserDefaults.standard.integer(forKey: UserDefaultsKeys.deepSleepGoal)
        coreSleepGoal = UserDefaults.standard.integer(forKey: UserDefaultsKeys.coreSleepGoal)
        totalSleepGoal = UserDefaults.standard.integer(forKey: UserDefaultsKeys.totalSleepGoal)
        
        // Now check if they should be replaced with user-specified values
        recoveryMinutesGoal = recoveryMinutesGoal != 0 ? recoveryMinutesGoal : recoveryMinutesDefault
        conditioningMinutesGoal = conditioningMinutesGoal != 0 ? conditioningMinutesGoal : conditioningMinutesDefault
        highIntensityMinutesGoal = highIntensityMinutesGoal != 0 ? highIntensityMinutesGoal : highIntensityMinutesDefault
        stepsGoal = stepsGoal != 0 ? stepsGoal : stepsGoalDefault
        remSleepGoal = remSleepGoal != 0 ? remSleepGoal : remSleepGoalDefault
        deepSleepGoal = deepSleepGoal != 0 ? deepSleepGoal : deepSleepGoalDefault
        coreSleepGoal = coreSleepGoal != 0 ? coreSleepGoal : coreSleepGoalDefault
        totalSleepGoal = totalSleepGoal != 0 ? totalSleepGoal : totalSleepGoalDefault
    }
}
