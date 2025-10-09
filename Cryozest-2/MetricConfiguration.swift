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

class MetricConfigurationManager: ObservableObject {
    static let shared = MetricConfigurationManager()

    @Published var enabledMetrics: Set<HealthMetric> {
        didSet {
            saveConfiguration()
        }
    }

    private let configKey = "enabledHealthMetrics"

    private init() {
        // Load saved configuration or default to all enabled
        if let saved = UserDefaults.standard.stringArray(forKey: configKey) {
            self.enabledMetrics = Set(saved.compactMap { HealthMetric(rawValue: $0) })
        } else {
            // Default: enable all metrics
            self.enabledMetrics = Set(HealthMetric.allCases)
        }
    }

    private func saveConfiguration() {
        let metricStrings = enabledMetrics.map { $0.rawValue }
        UserDefaults.standard.set(metricStrings, forKey: configKey)
    }

    func isEnabled(_ metric: HealthMetric) -> Bool {
        enabledMetrics.contains(metric)
    }

    func toggle(_ metric: HealthMetric) {
        if enabledMetrics.contains(metric) {
            enabledMetrics.remove(metric)
        } else {
            enabledMetrics.insert(metric)
        }
    }
}
