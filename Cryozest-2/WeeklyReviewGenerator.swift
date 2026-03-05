import Foundation
import CoreData

// MARK: - Models

struct DailyRecoveryScore: Identifiable {
    let id = UUID()
    let day: String
    let score: Int
}

struct DailyHabitActivity: Identifiable {
    let id = UUID()
    let day: String
    let habitNames: [String]
}

struct PersonalBest: Identifiable {
    let id = UUID()
    let metric: String
    let value: String
    let timeframe: String
}

struct WeeklyReview {
    let weekStarting: Date
    let totalSessions: Int
    let totalMinutes: Int
    let uniqueHabits: Int
    let bestRecoveryDay: (day: String, score: Int)?
    let avgRecovery: Int?
    let avgSleepHours: Double?
    let sleepTrend: TrendDirection?
    let hrvTrend: TrendDirection?
    let topHabit: (name: String, count: Int)?
    let longestStreak: (habit: String, days: Int)?
    let newPersonalBests: [PersonalBest]
    let highlightMessage: String

    // Premium additions
    var dailyRecoveryScores: [DailyRecoveryScore] = []
    var dailyHabitActivity: [DailyHabitActivity] = []
    var allHabitNames: [String] = []
    var weekGrade: String = ""
    var previousWeekSessions: Int? = nil
    var previousWeekMinutes: Int? = nil
}

class WeeklyReviewGenerator {
    private let healthKitManager = HealthKitManager.shared

    func generate(
        sessions: [TherapySessionEntity],
        recoveryScores: [Int],
        context: NSManagedObjectContext,
        completion: @escaping (WeeklyReview) -> Void
    ) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let weekStart = calendar.date(byAdding: .day, value: -6, to: today)!

        // Filter sessions from this week
        let weekSessions = sessions.filter { session in
            guard let date = session.date else { return false }
            return date >= weekStart
        }

        let totalSessions = weekSessions.count
        let totalMinutes = Int(weekSessions.reduce(0.0) { $0 + $1.duration } / 60)
        let uniqueHabits = Set(weekSessions.compactMap { $0.therapyType }).count

        // Habit counts
        var habitCounts: [String: Int] = [:]
        for session in weekSessions {
            if let type = session.therapyType {
                habitCounts[type, default: 0] += 1
            }
        }
        let topHabit: (name: String, count: Int)? = habitCounts.max(by: { $0.value < $1.value }).map { ($0.key, $0.value) }

        // Recovery
        let validScores = recoveryScores.filter { $0 > 0 }
        let avgRecovery = validScores.isEmpty ? nil : validScores.reduce(0, +) / validScores.count

        let dayNames = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        var bestRecoveryDay: (day: String, score: Int)? = nil
        if !validScores.isEmpty {
            if let maxIdx = validScores.indices.max(by: { validScores[$0] < validScores[$1] }) {
                let daysAgo = recoveryScores.count - 1 - maxIdx
                if let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) {
                    let weekday = calendar.component(.weekday, from: date)
                    bestRecoveryDay = (dayNames[weekday - 1], validScores[maxIdx])
                }
            }
        }

        // Streaks
        let habitTypes = Set(weekSessions.compactMap { $0.therapyType })
        var longestStreak: (habit: String, days: Int)? = nil
        for habitTypeStr in habitTypes {
            guard let habitType = TherapyType(rawValue: habitTypeStr) else { continue }
            let streak = calculateStreak(for: habitType, sessions: sessions)
            if streak > 0 {
                if longestStreak == nil || streak > longestStreak!.days {
                    longestStreak = (habitTypeStr, streak)
                }
            }
        }

        // Daily recovery scores with day labels
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"
        var dailyRecoveryScores: [DailyRecoveryScore] = []
        for i in 0..<min(recoveryScores.count, 7) {
            let daysAgo = recoveryScores.count - 1 - i
            if let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) {
                let label = dayFormatter.string(from: date)
                dailyRecoveryScores.append(DailyRecoveryScore(day: label, score: recoveryScores[i]))
            }
        }

        // Daily habit activity grid
        var dailyActivity: [DailyHabitActivity] = []
        var allHabitNamesOrdered: [String] = []
        var seenHabits: Set<String> = []

        for daysAgo in (0...6).reversed() {
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { continue }
            let dayLabel = dayFormatter.string(from: date)
            let daySessions = weekSessions.filter { session in
                guard let d = session.date else { return false }
                return calendar.isDate(d, inSameDayAs: date)
            }
            let habitNames = Array(Set(daySessions.compactMap { session -> String? in
                guard let raw = session.therapyType, let type = TherapyType(rawValue: raw) else { return nil }
                return type.displayName(context)
            }))
            for name in habitNames.sorted() {
                if !seenHabits.contains(name) {
                    seenHabits.insert(name)
                    allHabitNamesOrdered.append(name)
                }
            }
            dailyActivity.append(DailyHabitActivity(day: dayLabel, habitNames: habitNames))
        }

        // Previous week comparison
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -13, to: today)!
        let prevWeekSessions = sessions.filter { session in
            guard let date = session.date else { return false }
            return date >= twoWeeksAgo && date < weekStart
        }
        let previousSessions = prevWeekSessions.count
        let previousMinutes = Int(prevWeekSessions.reduce(0.0) { $0 + $1.duration } / 60)

        // Fetch health data for trends
        let group = DispatchGroup()
        var sleepTrend: TrendDirection? = nil
        var hrvTrend: TrendDirection? = nil
        var avgSleepHours: Double? = nil
        var personalBests: [PersonalBest] = []

        // Sleep trend
        group.enter()
        healthKitManager.fetchAvgSleepDurationForLastNDays(numDays: 7) { thisWeek in
            self.healthKitManager.fetchAvgSleepDurationForLastNDays(numDays: 14) { last14 in
                defer { group.leave() }
                if let recent = thisWeek {
                    avgSleepHours = recent / 3600
                }
                guard let recent = thisWeek, let full = last14, recent > 0, full > 0 else { return }
                let previous = full * 2 - recent
                guard previous > 0 else { return }
                let change = ((recent - previous) / previous) * 100
                if change > 5 { sleepTrend = .up }
                else if change < -5 { sleepTrend = .down }
                else { sleepTrend = .neutral }
            }
        }

        // HRV trend
        group.enter()
        healthKitManager.fetchAvgHRVForLastDays(numberOfDays: 7) { thisWeek in
            self.healthKitManager.fetchAvgHRVForLastDays(numberOfDays: 14) { last14 in
                defer { group.leave() }
                guard let recent = thisWeek, let full = last14, recent > 0, full > 0 else { return }
                let previous = full * 2 - recent
                guard previous > 0 else { return }
                let change = ((recent - previous) / previous) * 100
                if change > 5 { hrvTrend = .up }
                else if change < -5 { hrvTrend = .down }
                else { hrvTrend = .neutral }

                // Check for personal best HRV
                if recent > full * 1.15 {
                    personalBests.append(PersonalBest(metric: "HRV", value: "\(Int(recent))ms", timeframe: "this month"))
                }
            }
        }

        group.notify(queue: .main) {
            let highlight = self.generateHighlight(
                avgRecovery: avgRecovery,
                totalSessions: totalSessions,
                sleepTrend: sleepTrend,
                hrvTrend: hrvTrend
            )

            let grade = self.computeGrade(avgRecovery: avgRecovery, totalSessions: totalSessions, avgSleep: avgSleepHours)

            var review = WeeklyReview(
                weekStarting: weekStart,
                totalSessions: totalSessions,
                totalMinutes: totalMinutes,
                uniqueHabits: uniqueHabits,
                bestRecoveryDay: bestRecoveryDay,
                avgRecovery: avgRecovery,
                avgSleepHours: avgSleepHours,
                sleepTrend: sleepTrend,
                hrvTrend: hrvTrend,
                topHabit: topHabit,
                longestStreak: longestStreak,
                newPersonalBests: personalBests,
                highlightMessage: highlight
            )

            review.dailyRecoveryScores = dailyRecoveryScores
            review.dailyHabitActivity = dailyActivity
            review.allHabitNames = allHabitNamesOrdered
            review.weekGrade = grade
            review.previousWeekSessions = previousSessions > 0 ? previousSessions : nil
            review.previousWeekMinutes = previousMinutes > 0 ? previousMinutes : nil

            completion(review)
        }
    }

    private func calculateStreak(for type: TherapyType, sessions: [TherapySessionEntity]) -> Int {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var checkDate = today

        while true {
            let hasSession = sessions.contains { session in
                guard let date = session.date else { return false }
                return calendar.isDate(date, inSameDayAs: checkDate) && session.therapyType == type.rawValue
            }
            if hasSession {
                streak += 1
                guard let prevDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
                checkDate = prevDay
            } else {
                break
            }
        }
        return streak
    }

    private func generateHighlight(avgRecovery: Int?, totalSessions: Int, sleepTrend: TrendDirection?, hrvTrend: TrendDirection?) -> String {
        if let recovery = avgRecovery, recovery >= 75 {
            return "Strong week — recovery averaging \(recovery)%"
        }
        if totalSessions >= 5 {
            return "Active week with \(totalSessions) sessions logged"
        }
        if hrvTrend == .up {
            return "HRV trending up — your body is adapting well"
        }
        if sleepTrend == .up {
            return "Sleep improving — great foundation for recovery"
        }
        if let recovery = avgRecovery, recovery < 55 {
            return "Recovery is low — consider lighter activity this week"
        }
        if totalSessions == 0 {
            return "No sessions yet — start tracking to see insights"
        }
        return "\(totalSessions) sessions this week — keep it up"
    }

    private func computeGrade(avgRecovery: Int?, totalSessions: Int, avgSleep: Double?) -> String {
        if totalSessions == 0 && avgRecovery == nil { return "" }

        var points: Double = 0
        var maxPoints: Double = 0

        if let recovery = avgRecovery {
            points += Double(min(recovery, 100)) * 0.4
            maxPoints += 40
        }

        points += min(Double(totalSessions) / 7.0, 1.0) * 30
        maxPoints += 30

        if let sleep = avgSleep {
            points += min(sleep / 8.0, 1.0) * 30
            maxPoints += 30
        }

        guard maxPoints > 0 else { return "" }
        let normalized = (points / maxPoints) * 100

        switch normalized {
        case 90...: return "A+"
        case 80..<90: return "A"
        case 70..<80: return "B+"
        case 60..<70: return "B"
        case 50..<60: return "C+"
        case 40..<50: return "C"
        case 30..<40: return "D"
        default: return "F"
        }
    }

    // Demo data
    static func demoReview() -> WeeklyReview {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        let dayFormatter = DateFormatter()
        dayFormatter.dateFormat = "EEE"

        let scores = [62, 71, 58, 75, 82, 68, 78]
        let dailyScores: [DailyRecoveryScore] = (0..<7).reversed().compactMap { daysAgo in
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { return nil }
            let index = 6 - daysAgo
            guard index >= 0 && index < scores.count else { return nil }
            return DailyRecoveryScore(day: dayFormatter.string(from: date), score: scores[index])
        }

        let activityData: [[String]] = [
            ["Running", "Meditation"],
            ["Weight Training", "Running"],
            ["Cycling", "Meditation"],
            ["Weight Training", "Running"],
            ["Meditation"],
            ["Cycling", "Running"],
            ["Running", "Meditation"]
        ]
        let dailyActivity: [DailyHabitActivity] = (0..<7).reversed().compactMap { daysAgo in
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: today) else { return nil }
            let index = 6 - daysAgo
            guard index >= 0 && index < activityData.count else { return nil }
            return DailyHabitActivity(day: dayFormatter.string(from: date), habitNames: activityData[index])
        }

        var review = WeeklyReview(
            weekStarting: calendar.date(byAdding: .day, value: -6, to: today)!,
            totalSessions: 8,
            totalMinutes: 342,
            uniqueHabits: 4,
            bestRecoveryDay: ("Thu", 82),
            avgRecovery: 72,
            avgSleepHours: 7.3,
            sleepTrend: .up,
            hrvTrend: .up,
            topHabit: ("Running", 3),
            longestStreak: ("Meditation", 4),
            newPersonalBests: [PersonalBest(metric: "HRV", value: "52ms", timeframe: "this month")],
            highlightMessage: "Strong week — recovery averaging 72%"
        )

        review.dailyRecoveryScores = dailyScores
        review.dailyHabitActivity = dailyActivity
        review.allHabitNames = ["Cycling", "Meditation", "Running", "Weight Training"]
        review.weekGrade = "B+"
        review.previousWeekSessions = 6
        review.previousWeekMinutes = 280

        return review
    }
}
