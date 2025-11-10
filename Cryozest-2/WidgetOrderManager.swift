//
//  WidgetOrderManager.swift
//  Cryozest-2
//
//  Widget ordering and customization manager
//

import Foundation
import SwiftUI

enum DailyWidgetSection: String, Codable, CaseIterable, Identifiable {
    case wellnessCheckIn = "Wellness Check-In"
    case completedHabits = "Completed Habits"
    case medications = "Medications"
    case heroScores = "Hero Scores"
    case largeSteps = "Steps"
    case largeHeartRate = "Heart Rate"
    case metricsGrid = "Health Metrics"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .wellnessCheckIn: return "star.fill"
        case .completedHabits: return "checkmark.circle.fill"
        case .medications: return "pills.fill"
        case .heroScores: return "gauge.with.dots.needle.67percent"
        case .largeSteps: return "figure.walk"
        case .largeHeartRate: return "heart.fill"
        case .metricsGrid: return "square.grid.2x2.fill"
        }
    }

    var defaultColor: Color {
        switch self {
        case .wellnessCheckIn: return .pink
        case .completedHabits: return .cyan
        case .medications: return .green
        case .heroScores: return .purple
        case .largeSteps: return .orange
        case .largeHeartRate: return .red
        case .metricsGrid: return .blue
        }
    }
}

class WidgetOrderManager: ObservableObject {
    static let shared = WidgetOrderManager()

    @Published var widgetOrder: [DailyWidgetSection] = []

    private let orderKey = "dailyWidgetOrder"

    private init() {
        loadOrder()
    }

    func loadOrder() {
        if let data = UserDefaults.standard.data(forKey: orderKey),
           let decoded = try? JSONDecoder().decode([DailyWidgetSection].self, from: data) {
            widgetOrder = decoded
        } else {
            // Default order
            widgetOrder = [
                .largeSteps,
                .largeHeartRate,
                .medications,
                .metricsGrid,
                .heroScores,
                .wellnessCheckIn,
                .completedHabits
            ]
            saveOrder()
        }
    }

    func saveOrder() {
        if let encoded = try? JSONEncoder().encode(widgetOrder) {
            UserDefaults.standard.set(encoded, forKey: orderKey)
        }
    }

    func moveWidget(from source: IndexSet, to destination: Int) {
        widgetOrder.move(fromOffsets: source, toOffset: destination)
        saveOrder()
    }

    func resetToDefault() {
        widgetOrder = [
            .largeSteps,
            .largeHeartRate,
            .medications,
            .metricsGrid,
            .heroScores,
            .wellnessCheckIn,
            .completedHabits
        ]
        saveOrder()
    }
}
