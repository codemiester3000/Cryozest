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
    case painTracking = "Pain Tracking"
    case completedHabits = "Completed Habits"
    case medications = "Medications"
    case heroScores = "Hero Scores"
    case largeSteps = "Steps"
    case largeHeartRate = "Heart Rate"
    case exertion = "Training Load"
    case metricsGrid = "Health Metrics"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .wellnessCheckIn: return "star.fill"
        case .painTracking: return "bolt.heart.fill"
        case .completedHabits: return "checkmark.circle.fill"
        case .medications: return "pills.fill"
        case .heroScores: return "gauge.with.dots.needle.67percent"
        case .largeSteps: return "figure.walk"
        case .largeHeartRate: return "heart.fill"
        case .exertion: return "flame.fill"
        case .metricsGrid: return "square.grid.2x2.fill"
        }
    }

    var defaultColor: Color {
        switch self {
        case .wellnessCheckIn: return .pink
        case .painTracking: return .orange
        case .completedHabits: return .cyan
        case .medications: return .green
        case .heroScores: return .purple
        case .largeSteps: return .orange
        case .largeHeartRate: return .red
        case .exertion: return .orange
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
            var updatedOrder = decoded
            var needsSave = false

            // Migrate: add exertion if not present
            if !updatedOrder.contains(.exertion) {
                // Insert exertion after heart rate if present, otherwise after steps
                if let heartRateIndex = updatedOrder.firstIndex(of: .largeHeartRate) {
                    updatedOrder.insert(.exertion, at: heartRateIndex + 1)
                } else if let stepsIndex = updatedOrder.firstIndex(of: .largeSteps) {
                    updatedOrder.insert(.exertion, at: stepsIndex + 1)
                } else {
                    updatedOrder.append(.exertion)
                }
                needsSave = true
            }

            // Migrate: add painTracking if not present
            if !updatedOrder.contains(.painTracking) {
                // Insert pain tracking after wellness check-in
                if let wellnessIndex = updatedOrder.firstIndex(of: .wellnessCheckIn) {
                    updatedOrder.insert(.painTracking, at: wellnessIndex + 1)
                } else {
                    // Insert at second position
                    updatedOrder.insert(.painTracking, at: min(1, updatedOrder.count))
                }
                needsSave = true
            }

            widgetOrder = updatedOrder
            if needsSave {
                saveOrder()
            }
        } else {
            // Default order
            widgetOrder = [
                .wellnessCheckIn,
                .painTracking,
                .largeSteps,
                .largeHeartRate,
                .exertion,
                .medications,
                .metricsGrid,
                .heroScores,
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
            .wellnessCheckIn,
            .painTracking,
            .largeSteps,
            .largeHeartRate,
            .exertion,
            .medications,
            .metricsGrid,
            .heroScores,
            .completedHabits
        ]
        saveOrder()
    }
}
