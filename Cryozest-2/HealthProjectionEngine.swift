import Foundation

struct HealthProjection: Identifiable {
    let id = UUID()
    let metric: String
    let currentValue: Double
    let projectedValue: Double
    let projectedChange: Double
    let basedOnHabit: String
    let confidence: ConfidenceLevel
    let explanation: String
    let isPositiveDirection: Bool
}

class HealthProjectionEngine {
    func generateProjections(
        for habitType: TherapyType,
        impacts: [HabitImpact],
        sessions: [TherapySessionEntity]
    ) -> [HealthProjection] {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!

        // Count sessions in last 30 days for this habit
        let recentSessions = sessions.filter { session in
            guard let date = session.date else { return false }
            return date >= thirtyDaysAgo && session.therapyType == habitType.rawValue
        }
        let sessionsPerWeek = Double(recentSessions.count) / 4.3

        guard sessionsPerWeek > 0 else { return [] }

        var projections: [HealthProjection] = []

        for impact in impacts {
            // Project for impacts with statistical confidence OR meaningful observed change
            let hasConfidence = impact.confidenceLevel == .high ||
                                impact.confidenceLevel == .moderate ||
                                impact.confidenceLevel == .earlySignal
            let hasMeaningfulChange = abs(impact.percentageChange) >= 3
            guard hasConfidence || hasMeaningfulChange else { continue }

            // Project: if user continues at current frequency for 30 more days
            // Use a conservative scaling factor (diminishing returns)
            // Apply extra dampening for low/insufficient confidence
            let weeklyRate = sessionsPerWeek
            let monthProjectionFactor = min(weeklyRate / 3.0, 1.5) // Cap the multiplier
            let confidenceDampener: Double = hasConfidence ? 1.0 : 0.5
            let projectedAdditionalChange = impact.percentageChange * 0.5 * monthProjectionFactor * confidenceDampener

            let projectedValue: Double
            let isRHR = impact.metricName == "RHR" || impact.metricName == "Resting Heart Rate"

            if isRHR {
                projectedValue = impact.habitValue * (1.0 + projectedAdditionalChange / 100.0)
            } else {
                projectedValue = impact.habitValue * (1.0 + projectedAdditionalChange / 100.0)
            }

            let totalProjectedChange = ((projectedValue - impact.baselineValue) / impact.baselineValue) * 100

            let freqStr = String(format: "%.1f", sessionsPerWeek)
            let explanation = "If you keep doing this \(freqStr)x/week for the next 30 days"

            let isPositiveDirection: Bool
            if isRHR {
                isPositiveDirection = projectedValue < impact.baselineValue
            } else {
                isPositiveDirection = projectedValue > impact.baselineValue
            }

            projections.append(HealthProjection(
                metric: impact.metricName,
                currentValue: impact.habitValue,
                projectedValue: projectedValue,
                projectedChange: totalProjectedChange,
                basedOnHabit: habitType.rawValue,
                confidence: impact.confidenceLevel,
                explanation: explanation,
                isPositiveDirection: isPositiveDirection
            ))
        }

        return projections.sorted { $0.confidence.sortOrder < $1.confidence.sortOrder }
    }

    static func demoProjections() -> [HealthProjection] {
        [
            HealthProjection(
                metric: "HRV",
                currentValue: 48,
                projectedValue: 53,
                projectedChange: 26.2,
                basedOnHabit: "Running",
                confidence: .high,
                explanation: "Based on 12 sessions over 30 days (2.8x/week)",
                isPositiveDirection: true
            ),
            HealthProjection(
                metric: "Sleep Duration",
                currentValue: 7.3,
                projectedValue: 7.6,
                projectedChange: 15.2,
                basedOnHabit: "Running",
                confidence: .moderate,
                explanation: "Based on 12 sessions over 30 days (2.8x/week)",
                isPositiveDirection: true
            ),
            HealthProjection(
                metric: "RHR",
                currentValue: 56,
                projectedValue: 54,
                projectedChange: -12.9,
                basedOnHabit: "Running",
                confidence: .earlySignal,
                explanation: "Based on 12 sessions over 30 days (2.8x/week)",
                isPositiveDirection: true
            ),
        ]
    }
}

private extension ConfidenceLevel {
    var sortOrder: Int {
        switch self {
        case .high: return 0
        case .moderate: return 1
        case .earlySignal: return 2
        case .low: return 3
        case .insufficient: return 4
        }
    }
}
