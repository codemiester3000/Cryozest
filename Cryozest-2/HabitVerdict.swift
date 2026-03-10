import Foundation
import CoreData

// MARK: - Verdict Tier

enum VerdictTier: Int, Comparable {
    case mvp = 0
    case strong = 1
    case promising = 2
    case mixed = 3
    case concerning = 4
    case insufficient = 5

    static func < (lhs: VerdictTier, rhs: VerdictTier) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    var label: String {
        switch self {
        case .mvp: return "Your recovery MVP"
        case .strong: return "Strong"
        case .promising: return "Early signs look good"
        case .mixed: return "Mixed signals"
        case .concerning: return "Concerning"
        case .insufficient: return "Not enough data"
        }
    }

    var color: String {
        switch self {
        case .mvp: return "green"
        case .strong: return "green"
        case .promising: return "cyan"
        case .mixed: return "yellow"
        case .concerning: return "orange"
        case .insufficient: return "gray"
        }
    }
}

// MARK: - HabitVerdict

struct HabitVerdict: Identifiable {
    let id = UUID()
    let habitType: TherapyType
    let impacts: [HabitImpact]
    let overallScore: Double
    let verdict: VerdictTier
    let weeklyFrequency: Int
    let currentStreak: Int
    let bestMetric: HabitImpact?
    let worstMetric: HabitImpact?

    var headline: String {
        switch verdict {
        case .mvp:
            return "Your recovery MVP"
        case .strong:
            if let best = bestMetric {
                return "Great for your \(shortMetric(best.metricName))"
            }
            return "Strong performer"
        case .promising:
            return "Early signs look good"
        case .mixed:
            return "Mixed signals"
        case .concerning:
            if let worst = worstMetric {
                return "Hurting your \(shortMetric(worst.metricName))"
            }
            return "Needs attention"
        case .insufficient:
            return "Not enough data"
        }
    }

    private func shortMetric(_ name: String) -> String {
        switch name {
        case "Sleep Duration": return "Sleep"
        case "Resting Heart Rate": return "RHR"
        case "Pain Level": return "Pain"
        case "Mood": return "Mood"
        default: return name
        }
    }

    // MARK: - Factory

    static func buildVerdicts(
        from habitImpactsByType: [TherapyType: [HabitImpact]],
        sessions: [TherapySessionEntity]
    ) -> [HabitVerdict] {
        var verdicts: [HabitVerdict] = []

        for (habitType, impacts) in habitImpactsByType {
            guard !impacts.isEmpty else { continue }

            // Score: sum of percentageChange * direction * confidence
            let score = impacts.reduce(0.0) { total, impact in
                let direction: Double = impact.isPositive ? 1 : -1
                let confidenceMultiplier: Double
                switch impact.confidenceLevel {
                case .high: confidenceMultiplier = 1.0
                case .moderate: confidenceMultiplier = 0.8
                case .earlySignal: confidenceMultiplier = 0.6
                case .low: confidenceMultiplier = 0.5
                case .insufficient: confidenceMultiplier = 0.2
                }
                return total + abs(impact.percentageChange) * direction * confidenceMultiplier
            }

            let positiveImpacts = impacts.filter { $0.isPositive }
            let negativeImpacts = impacts.filter { !$0.isPositive }
            let bestMetric = positiveImpacts.max(by: { $0.impactScore < $1.impactScore })
            let worstMetric = negativeImpacts.max(by: { abs($0.percentageChange) < abs($1.percentageChange) })

            // Streak & frequency
            let (streak, frequency) = computeStreakAndFrequency(for: habitType, sessions: sessions)

            // Determine tier (will assign MVP after sorting)
            let tier: VerdictTier
            if score > 15 {
                tier = .strong
            } else if score > 5 {
                tier = .promising
            } else if score > -5 {
                tier = .mixed
            } else {
                tier = .concerning
            }

            verdicts.append(HabitVerdict(
                habitType: habitType,
                impacts: impacts,
                overallScore: score,
                verdict: tier,
                weeklyFrequency: frequency,
                currentStreak: streak,
                bestMetric: bestMetric,
                worstMetric: worstMetric
            ))
        }

        // Sort by score descending
        verdicts.sort { $0.overallScore > $1.overallScore }

        // Promote rank #1 to MVP if positive
        if let first = verdicts.first, first.overallScore > 0 {
            verdicts[0] = HabitVerdict(
                habitType: first.habitType,
                impacts: first.impacts,
                overallScore: first.overallScore,
                verdict: .mvp,
                weeklyFrequency: first.weeklyFrequency,
                currentStreak: first.currentStreak,
                bestMetric: first.bestMetric,
                worstMetric: first.worstMetric
            )
        }

        return verdicts
    }

    // MARK: - Streak & Frequency Helpers

    private static func computeStreakAndFrequency(
        for habitType: TherapyType,
        sessions: [TherapySessionEntity]
    ) -> (streak: Int, frequency: Int) {
        let calendar = Calendar.current
        let habitSessions = sessions.filter { $0.therapyType == habitType.rawValue }
        let dates = habitSessions.compactMap { $0.date }

        // Weekly frequency (last 7 days)
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
        let frequency = dates.filter { $0 >= sevenDaysAgo }.count

        // Current streak (reuse HabitDashboardCard pattern)
        let sortedDates = dates.sorted(by: >)
        guard !sortedDates.isEmpty else { return (0, frequency) }

        let todayStart = calendar.startOfDay(for: Date())
        let hasToday = sortedDates.contains { calendar.isDate(calendar.startOfDay(for: $0), inSameDayAs: todayStart) }

        var streak = 0
        var checkDate = hasToday ? todayStart : calendar.date(byAdding: .day, value: -1, to: todayStart)!

        for date in sortedDates {
            let sessionDay = calendar.startOfDay(for: date)
            if calendar.isDate(sessionDay, inSameDayAs: checkDate) {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else if sessionDay < checkDate {
                break
            }
        }

        return (streak, frequency)
    }
}
