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
        }
    }
}

enum HeroScore: String, CaseIterable, Identifiable {
    case exertion = "Exertion"
    case quality = "Sleep Quality"
    case readiness = "Readiness"
    case sleep = "Sleep"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .exertion: return "flame.fill"
        case .quality: return "moon.fill"
        case .readiness: return "bolt.fill"
        case .sleep: return "bed.double.fill"
        }
    }

    var color: Color {
        switch self {
        case .exertion: return .orange
        case .quality: return .yellow
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

    private let metricConfigKey = "enabledHealthMetrics"
    private let heroScoreConfigKey = "enabledHeroScores"

    private init() {
        // Load saved metric configuration or default to all enabled
        if let saved = UserDefaults.standard.stringArray(forKey: metricConfigKey) {
            self.enabledMetrics = Set(saved.compactMap { HealthMetric(rawValue: $0) })
        } else {
            // Default: enable all metrics
            self.enabledMetrics = Set(HealthMetric.allCases)
        }

        // Load saved hero score configuration or default to all enabled
        if let saved = UserDefaults.standard.stringArray(forKey: heroScoreConfigKey) {
            self.enabledHeroScores = Set(saved.compactMap { HeroScore(rawValue: $0) })
        } else {
            // Default: enable all hero scores
            self.enabledHeroScores = Set(HeroScore.allCases)
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

    func isEnabled(_ metric: HealthMetric) -> Bool {
        enabledMetrics.contains(metric)
    }

    func isEnabled(_ heroScore: HeroScore) -> Bool {
        enabledHeroScores.contains(heroScore)
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
}
