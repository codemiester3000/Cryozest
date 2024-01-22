//
//  UserSettings.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 1/21/24.
//

import SwiftUI

class UserSettings: ObservableObject {
    @Published var recoveryMinutesGoal: Int {
        didSet {
            UserDefaults.standard.set(recoveryMinutesGoal, forKey: UserDefaultsKeys.recoveryMinutesGoal)
        }
    }
    
    init() {
        let value = UserDefaults.standard.integer(forKey: UserDefaultsKeys.recoveryMinutesGoal)
        recoveryMinutesGoal = value != 0 ? value : 30
    }
}
