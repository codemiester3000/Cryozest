//
//  UserGoals.swift
//  Cryozest-2
//
//  Created by Robert Amarin on 1/21/24.
//

import Foundation

class UserGoals: ObservableObject {
    @Published var recoveryMinutesGoal: Int
    @Published var conditioningMinutesGoal: Int
    @Published var highIntensityMinutesGoal: Int
    @Published var stepsGoal: Int
    @Published var remSleepGoal: Int
    @Published var deepSleepGoal: Int
    @Published var coreSleepGoal: Int
    @Published var totalSleepGoal: Int

    init(recoveryMinutesGoal: Int = 30,
         conditioningMinutesGoal: Int = 30,
         highIntensityMinutesGoal: Int = 30,
         stepsGoal: Int = 10000,
         remSleepGoal: Int = 90,
         deepSleepGoal: Int = 90,
         coreSleepGoal: Int = 90,
         totalSleepGoal: Int = 8) {
        self.recoveryMinutesGoal = recoveryMinutesGoal
        self.conditioningMinutesGoal = conditioningMinutesGoal
        self.highIntensityMinutesGoal = highIntensityMinutesGoal
        self.stepsGoal = stepsGoal
        self.remSleepGoal = remSleepGoal
        self.deepSleepGoal = deepSleepGoal
        self.coreSleepGoal = coreSleepGoal
        self.totalSleepGoal = totalSleepGoal
    }
}
