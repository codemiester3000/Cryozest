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
    
    init() {
        let recoveryValue = UserDefaults.standard.integer(forKey: UserDefaultsKeys.recoveryMinutesGoal)
        recoveryMinutesGoal = recoveryValue != 0 ? recoveryValue : recoveryMinutesDefault
        
        let conditioningValue = UserDefaults.standard.integer(forKey: UserDefaultsKeys.conditioningMinutesGoal)
        conditioningMinutesGoal = conditioningValue != 0 ? conditioningValue : conditioningMinutesDefault
        
        let highIntensityValue = UserDefaults.standard.integer(forKey: UserDefaultsKeys.highIntensityMinutesGoal)
        highIntensityMinutesGoal = highIntensityValue != 0 ? highIntensityValue : highIntensityMinutesDefault
    }
}
