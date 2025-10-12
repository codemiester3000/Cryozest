//
//  OnboardingManager.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//

import Foundation

class OnboardingManager {
    static let shared = OnboardingManager()

    private let defaults = UserDefaults.standard

    // Keys for tracking onboarding state
    private let hasSeenDailyTabKey = "hasSeenDailyTab"
    private let hasSeenHabitsTabKey = "hasSeenHabitsTab"
    private let hasSeenAnalysisTabKey = "hasSeenAnalysisTab"
    private let hasCompletedFirstSessionKey = "hasCompletedFirstSession"
    private let hasSelectedFirstTherapyKey = "hasSelectedFirstTherapy"
    private let hasSeenTherapySelectorTooltipKey = "hasSeenTherapySelectorTooltip"
    private let hasSeenStopwatchTooltipKey = "hasSeenStopwatchTooltip"
    private let hasSeenMetricTooltipKey = "hasSeenMetricTooltip"
    private let hasSeenSafetyWarningKey = "hasSeenSafetyWarning"

    private init() {}

    // MARK: - Tab Empty States

    var shouldShowDailyEmptyState: Bool {
        !defaults.bool(forKey: hasSeenDailyTabKey)
    }

    func markDailyTabSeen() {
        defaults.set(true, forKey: hasSeenDailyTabKey)
    }

    var shouldShowHabitsEmptyState: Bool {
        !defaults.bool(forKey: hasSeenHabitsTabKey)
    }

    func markHabitsTabSeen() {
        defaults.set(true, forKey: hasSeenHabitsTabKey)
    }

    var shouldShowAnalysisEmptyState: Bool {
        !defaults.bool(forKey: hasSeenAnalysisTabKey)
    }

    func markAnalysisTabSeen() {
        defaults.set(true, forKey: hasSeenAnalysisTabKey)
    }

    // MARK: - User Progress

    var hasCompletedFirstSession: Bool {
        defaults.bool(forKey: hasCompletedFirstSessionKey)
    }

    func markFirstSessionCompleted() {
        defaults.set(true, forKey: hasCompletedFirstSessionKey)
    }

    var hasSelectedFirstTherapy: Bool {
        defaults.bool(forKey: hasSelectedFirstTherapyKey)
    }

    func markFirstTherapySelected() {
        defaults.set(true, forKey: hasSelectedFirstTherapyKey)
    }

    // MARK: - Tooltips

    var shouldShowTherapySelectorTooltip: Bool {
        !defaults.bool(forKey: hasSeenTherapySelectorTooltipKey)
    }

    func markTherapySelectorTooltipSeen() {
        defaults.set(true, forKey: hasSeenTherapySelectorTooltipKey)
    }

    var shouldShowStopwatchTooltip: Bool {
        !defaults.bool(forKey: hasSeenStopwatchTooltipKey) && hasSelectedFirstTherapy
    }

    func markStopwatchTooltipSeen() {
        defaults.set(true, forKey: hasSeenStopwatchTooltipKey)
    }

    var shouldShowMetricTooltip: Bool {
        !defaults.bool(forKey: hasSeenMetricTooltipKey)
    }

    func markMetricTooltipSeen() {
        defaults.set(true, forKey: hasSeenMetricTooltipKey)
    }

    // MARK: - Safety Warning

    var shouldShowSafetyWarning: Bool {
        !defaults.bool(forKey: hasSeenSafetyWarningKey)
    }

    func markSafetyWarningSeen() {
        defaults.set(true, forKey: hasSeenSafetyWarningKey)
    }

    // MARK: - Reset (for testing)

    func resetOnboarding() {
        defaults.removeObject(forKey: hasSeenDailyTabKey)
        defaults.removeObject(forKey: hasSeenHabitsTabKey)
        defaults.removeObject(forKey: hasSeenAnalysisTabKey)
        defaults.removeObject(forKey: hasCompletedFirstSessionKey)
        defaults.removeObject(forKey: hasSelectedFirstTherapyKey)
        defaults.removeObject(forKey: hasSeenTherapySelectorTooltipKey)
        defaults.removeObject(forKey: hasSeenStopwatchTooltipKey)
        defaults.removeObject(forKey: hasSeenMetricTooltipKey)
        defaults.removeObject(forKey: hasSeenSafetyWarningKey)
    }
}
