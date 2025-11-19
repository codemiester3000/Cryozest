//
//  MetricConfiguration.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/8/25.
//

import Foundation
import SwiftUI

enum HealthMetric: String, CaseIterable, Identifiable {
    case hrv = "Avg HRV"
    case rhr = "Avg RHR"
    case spo2 = "Blood Oxygen"
    case respiratoryRate = "Respiratory Rate"
    case calories = "Calories Burned"
    case steps = "Steps"
    case vo2Max = "VO2 Max"
    case deepSleep = "Deep Sleep"
    case remSleep = "REM Sleep"
    case coreSleep = "Core Sleep"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .hrv: return "waveform.path.ecg"
        case .rhr: return "arrow.down.heart"
        case .spo2: return "drop"
        case .respiratoryRate: return "lungs"
        case .calories: return "flame"
        case .steps: return "figure.walk"
        case .vo2Max: return "lungs"
        case .deepSleep: return "bed.double.fill"
        case .remSleep: return "moon.stars.fill"
        case .coreSleep: return "moon.fill"
        }
    }
}

enum DailyWidget: String, CaseIterable, Identifiable {
    case medications = "Medications"
    case heartRate = "Heart Rate"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .medications: return "pills.fill"
        case .heartRate: return "heart.fill"
        }
    }

    var color: Color {
        switch self {
        case .medications: return .green
        case .heartRate: return .red
        }
    }
}

enum HeroScore: String, CaseIterable, Identifiable {
    case exertion = "Exertion"
    case readiness = "Readiness"
    case sleep = "Sleep"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .exertion: return "flame.fill"
        case .readiness: return "bolt.fill"
        case .sleep: return "bed.double.fill"
        }
    }

    var color: Color {
        switch self {
        case .exertion: return .orange
        case .readiness: return .green
        case .sleep: return .purple
        }
    }
}

class MetricConfigurationManager: ObservableObject {
    static let shared = MetricConfigurationManager()

    @Published var enabledMetrics: Set<HealthMetric> {
        didSet {
            saveMetricConfiguration()
        }
    }

    @Published var enabledHeroScores: Set<HeroScore> {
        didSet {
            saveHeroScoreConfiguration()
        }
    }

    @Published var enabledWidgets: Set<DailyWidget> {
        didSet {
            saveWidgetConfiguration()
        }
    }

    private let metricConfigKey = "enabledHealthMetrics"
    private let heroScoreConfigKey = "enabledHeroScores"
    private let widgetConfigKey = "enabledDailyWidgets"

    private init() {
        // Load saved metric configuration or default to enabled (except sleep metrics)
        if let saved = UserDefaults.standard.stringArray(forKey: metricConfigKey) {
            self.enabledMetrics = Set(saved.compactMap { HealthMetric(rawValue: $0) })
        } else {
            // Default: enable all metrics except sleep metrics
            self.enabledMetrics = Set(HealthMetric.allCases.filter {
                $0 != .deepSleep && $0 != .remSleep && $0 != .coreSleep
            })
        }

        // Load saved hero score configuration or default to all enabled
        if let saved = UserDefaults.standard.stringArray(forKey: heroScoreConfigKey) {
            self.enabledHeroScores = Set(saved.compactMap { HeroScore(rawValue: $0) })
        } else {
            // Default: enable all hero scores
            self.enabledHeroScores = Set(HeroScore.allCases)
        }

        // Load saved widget configuration or default to all enabled
        if let saved = UserDefaults.standard.stringArray(forKey: widgetConfigKey) {
            self.enabledWidgets = Set(saved.compactMap { DailyWidget(rawValue: $0) })
        } else {
            // Default: enable all widgets
            self.enabledWidgets = Set(DailyWidget.allCases)
        }
    }

    private func saveMetricConfiguration() {
        let metricStrings = enabledMetrics.map { $0.rawValue }
        UserDefaults.standard.set(metricStrings, forKey: metricConfigKey)
    }

    private func saveHeroScoreConfiguration() {
        let heroScoreStrings = enabledHeroScores.map { $0.rawValue }
        UserDefaults.standard.set(heroScoreStrings, forKey: heroScoreConfigKey)
    }

    private func saveWidgetConfiguration() {
        let widgetStrings = enabledWidgets.map { $0.rawValue }
        UserDefaults.standard.set(widgetStrings, forKey: widgetConfigKey)
    }

    func isEnabled(_ metric: HealthMetric) -> Bool {
        enabledMetrics.contains(metric)
    }

    func isEnabled(_ heroScore: HeroScore) -> Bool {
        enabledHeroScores.contains(heroScore)
    }

    func isEnabled(_ widget: DailyWidget) -> Bool {
        enabledWidgets.contains(widget)
    }

    func toggle(_ metric: HealthMetric) {
        if enabledMetrics.contains(metric) {
            enabledMetrics.remove(metric)
        } else {
            enabledMetrics.insert(metric)
        }
    }

    func toggle(_ heroScore: HeroScore) {
        if enabledHeroScores.contains(heroScore) {
            enabledHeroScores.remove(heroScore)
        } else {
            enabledHeroScores.insert(heroScore)
        }
    }

    func toggle(_ widget: DailyWidget) {
        if enabledWidgets.contains(widget) {
            enabledWidgets.remove(widget)
        } else {
            enabledWidgets.insert(widget)
        }
    }
}

// MARK: - Insights Configuration

enum InsightSection: String, CaseIterable, Identifiable {
    case wellnessTrends = "Wellness Trends"
    case medicationAdherence = "Medication Adherence"
    case healthTrends = "Health Trends"
    case topPerformers = "Top Performers"
    case sleepImpact = "Sleep Impact"
    case hrvImpact = "HRV Impact"
    case rhrImpact = "Heart Rate Impact"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .wellnessTrends: return "heart.fill"
        case .medicationAdherence: return "pills.fill"
        case .healthTrends: return "chart.line.uptrend.xyaxis"
        case .topPerformers: return "trophy.fill"
        case .sleepImpact: return "bed.double.fill"
        case .hrvImpact: return "waveform.path.ecg"
        case .rhrImpact: return "heart.fill"
        }
    }

    var color: Color {
        switch self {
        case .wellnessTrends: return .pink
        case .medicationAdherence: return .green
        case .healthTrends: return .cyan
        case .topPerformers: return .yellow
        case .sleepImpact: return .purple
        case .hrvImpact: return .green
        case .rhrImpact: return .red
        }
    }

    var description: String {
        switch self {
        case .wellnessTrends:
            return "Track your daily mood ratings and see week-over-week wellness changes"
        case .medicationAdherence:
            return "View your medication adherence patterns and streaks"
        case .healthTrends:
            return "See how your health metrics are changing this week"
        case .topPerformers:
            return "Discover which habits have the biggest positive impact on your metrics"
        case .sleepImpact:
            return "Understand how your habits affect your sleep duration"
        case .hrvImpact:
            return "See which habits improve your heart rate variability"
        case .rhrImpact:
            return "Learn which habits optimize your resting heart rate"
        }
    }
}

class InsightsConfigurationManager: ObservableObject {
    static let shared = InsightsConfigurationManager()

    @Published var enabledSections: Set<InsightSection> {
        didSet {
            saveSectionConfiguration()
        }
    }

    private let sectionConfigKey = "enabledInsightSections"

    private init() {
        // Load saved configuration or default to all enabled
        if let saved = UserDefaults.standard.stringArray(forKey: sectionConfigKey) {
            self.enabledSections = Set(saved.compactMap { InsightSection(rawValue: $0) })
        } else {
            // Default: enable all sections
            self.enabledSections = Set(InsightSection.allCases)
        }
    }

    private func saveSectionConfiguration() {
        let sectionStrings = enabledSections.map { $0.rawValue }
        UserDefaults.standard.set(sectionStrings, forKey: sectionConfigKey)
    }

    func isEnabled(_ section: InsightSection) -> Bool {
        enabledSections.contains(section)
    }

    func toggle(_ section: InsightSection) {
        if enabledSections.contains(section) {
            enabledSections.remove(section)
        } else {
            enabledSections.insert(section)
        }
    }
}
