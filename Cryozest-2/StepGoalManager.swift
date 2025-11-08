//
//  StepGoalManager.swift
//  Cryozest-2
//
//  Step goal configuration manager with persistent storage
//

import Foundation

class StepGoalManager: ObservableObject {
    static let shared = StepGoalManager()

    @Published var dailyStepGoal: Int {
        didSet {
            UserDefaults.standard.set(dailyStepGoal, forKey: "dailyStepGoal")
        }
    }

    private init() {
        // Load saved goal or use default of 10,000 steps
        self.dailyStepGoal = UserDefaults.standard.object(forKey: "dailyStepGoal") as? Int ?? 10000
    }

    func updateGoal(_ newGoal: Int) {
        dailyStepGoal = max(1000, min(newGoal, 50000)) // Clamp between 1,000 and 50,000
    }
}
