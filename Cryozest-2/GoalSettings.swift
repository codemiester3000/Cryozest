//
//  GoalSettings.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//  Goal storage and management using UserDefaults
//

import Foundation
import Combine

class GoalManager: ObservableObject {
    static let shared = GoalManager()

    // Per-therapy goal storage
    @Published var weeklyGoals: [String: Int] = [:] {
        didSet {
            saveWeeklyGoals()
        }
    }

    @Published var monthlyGoals: [String: Int] = [:] {
        didSet {
            saveMonthlyGoals()
        }
    }

    @Published var yearlyGoals: [String: Int] = [:] {
        didSet {
            saveYearlyGoals()
        }
    }

    private init() {
        loadGoals()
    }

    // Get weekly goal for a therapy type (default: 3)
    func getWeeklyGoal(for therapyType: TherapyType) -> Int {
        return weeklyGoals[therapyType.rawValue] ?? 3
    }

    // Get monthly goal for a therapy type (default: 12)
    func getMonthlyGoal(for therapyType: TherapyType) -> Int {
        return monthlyGoals[therapyType.rawValue] ?? 12
    }

    // Get yearly goal for a therapy type (default: 150)
    func getYearlyGoal(for therapyType: TherapyType) -> Int {
        return yearlyGoals[therapyType.rawValue] ?? 150
    }

    // Set goals
    func setWeeklyGoal(_ goal: Int, for therapyType: TherapyType) {
        weeklyGoals[therapyType.rawValue] = goal
    }

    func setMonthlyGoal(_ goal: Int, for therapyType: TherapyType) {
        monthlyGoals[therapyType.rawValue] = goal
    }

    func setYearlyGoal(_ goal: Int, for therapyType: TherapyType) {
        yearlyGoals[therapyType.rawValue] = goal
    }

    // Persistence
    private func saveWeeklyGoals() {
        if let encoded = try? JSONEncoder().encode(weeklyGoals) {
            UserDefaults.standard.set(encoded, forKey: "weeklyGoals")
        }
    }

    private func saveMonthlyGoals() {
        if let encoded = try? JSONEncoder().encode(monthlyGoals) {
            UserDefaults.standard.set(encoded, forKey: "monthlyGoals")
        }
    }

    private func saveYearlyGoals() {
        if let encoded = try? JSONEncoder().encode(yearlyGoals) {
            UserDefaults.standard.set(encoded, forKey: "yearlyGoals")
        }
    }

    private func loadGoals() {
        if let weeklyData = UserDefaults.standard.data(forKey: "weeklyGoals"),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: weeklyData) {
            weeklyGoals = decoded
        }

        if let monthlyData = UserDefaults.standard.data(forKey: "monthlyGoals"),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: monthlyData) {
            monthlyGoals = decoded
        }

        if let yearlyData = UserDefaults.standard.data(forKey: "yearlyGoals"),
           let decoded = try? JSONDecoder().decode([String: Int].self, from: yearlyData) {
            yearlyGoals = decoded
        }
    }
}
