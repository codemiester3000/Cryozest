//
//  ScreenshotDataManager.swift
//  Cryozest-2
//
//  Generates realistic mock data for App Store screenshots
//

import Foundation
import CoreData
import SwiftUI

class ScreenshotDataManager {
    static let shared = ScreenshotDataManager()

    /// Set this to true to enable mock data mode for screenshots
    static var isScreenshotMode: Bool = false

    private init() {}

    // MARK: - Generate All Mock Data

    func generateAllMockData(context: NSManagedObjectContext) {
        clearExistingData(context: context)
        generateTherapySessions(context: context)
        generateWellnessRatings(context: context)
        try? context.save()
        print("✅ Screenshot mock data generated successfully!")
    }

    // MARK: - Clear Existing Data

    private func clearExistingData(context: NSManagedObjectContext) {
        // Clear therapy sessions
        let sessionFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "TherapySessionEntity")
        let sessionDelete = NSBatchDeleteRequest(fetchRequest: sessionFetch)
        try? context.execute(sessionDelete)

        // Clear wellness ratings
        let wellnessFetch = NSFetchRequest<NSFetchRequestResult>(entityName: "WellnessRating")
        let wellnessDelete = NSBatchDeleteRequest(fetchRequest: wellnessFetch)
        try? context.execute(wellnessDelete)

        context.reset()
    }

    // MARK: - Generate Therapy Sessions

    private func generateTherapySessions(context: NSManagedObjectContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Define habits to use - realistic mix
        let primaryHabits: [(TherapyType, Int)] = [
            (.running, 70),        // 70% chance on workout days
            (.meditation, 85),     // 85% chance daily
            (.weightTraining, 60), // 60% chance
            (.stretching, 50),     // 50% chance
            (.walking, 40),        // 40% chance
        ]

        // Generate 90 days of data
        for dayOffset in 0..<90 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

            let isWeekend = calendar.isDateInWeekend(date)
            let dayOfWeek = calendar.component(.weekday, from: date)

            // Generate sessions for this day
            for (habit, baseChance) in primaryHabits {
                var chance = baseChance

                // Adjust chances based on day
                if habit == .running || habit == .weightTraining {
                    // Less likely on weekends, skip Sundays for strength
                    if isWeekend { chance -= 20 }
                    if dayOfWeek == 1 && habit == .weightTraining { chance = 0 }
                }

                if habit == .meditation {
                    // More consistent, slight dip on weekends
                    if isWeekend { chance -= 10 }
                }

                // Add some randomness for natural patterns
                chance += Int.random(in: -15...15)

                if Int.random(in: 0..<100) < chance {
                    createSession(
                        type: habit,
                        date: date,
                        context: context
                    )
                }
            }

            // Ensure at least one session most days for good streak appearance
            if dayOffset < 14 && Int.random(in: 0..<100) < 90 {
                // Recent 2 weeks - high activity for screenshots
                if !hasSessionOnDate(date, context: context) {
                    createSession(type: .meditation, date: date, context: context)
                }
            }
        }

        // Ensure today has multiple completed sessions for the screenshot
        createSession(type: .running, date: today, context: context, duration: 1800) // 30 min run
        createSession(type: .meditation, date: today, context: context, duration: 900) // 15 min meditation
        createSession(type: .stretching, date: today, context: context, duration: 600) // 10 min stretch
    }

    private func createSession(type: TherapyType, date: Date, context: NSManagedObjectContext, duration: Int? = nil) {
        let session = TherapySessionEntity(context: context)
        session.id = UUID()
        session.therapyType = type.rawValue
        session.date = randomTimeOnDate(date)
        session.duration = Double(duration ?? randomDuration(for: type))
        session.isAppleWatch = type == .running || type == .walking || type == .cycling
    }

    private func randomTimeOnDate(_ date: Date) -> Date {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: date)
        components.hour = Int.random(in: 6...20)
        components.minute = Int.random(in: 0...59)
        return calendar.date(from: components) ?? date
    }

    private func randomDuration(for type: TherapyType) -> Int {
        switch type {
        case .running: return Int.random(in: 1200...3600) // 20-60 min
        case .meditation: return Int.random(in: 600...1800) // 10-30 min
        case .weightTraining: return Int.random(in: 2400...4500) // 40-75 min
        case .stretching: return Int.random(in: 300...900) // 5-15 min
        case .walking: return Int.random(in: 1200...2700) // 20-45 min
        case .cycling: return Int.random(in: 1800...5400) // 30-90 min
        case .coldYoga: return Int.random(in: 1800...3600) // 30-60 min
        default: return Int.random(in: 600...1800) // 10-30 min default
        }
    }

    private func hasSessionOnDate(_ date: Date, context: NSManagedObjectContext) -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let request: NSFetchRequest<TherapySessionEntity> = TherapySessionEntity.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.fetchLimit = 1

        return (try? context.count(for: request)) ?? 0 > 0
    }

    // MARK: - Generate Wellness Ratings

    private func generateWellnessRatings(context: NSManagedObjectContext) {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())

        // Generate 60 days of wellness ratings
        for dayOffset in 0..<60 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }

            // Generate rating with realistic patterns
            var rating: Int16

            if dayOffset < 7 {
                // Recent week - mostly good (4-5)
                rating = Int16.random(in: 4...5)
            } else if dayOffset < 30 {
                // Last month - good variety (3-5)
                rating = Int16.random(in: 3...5)
            } else {
                // Older data - full range but weighted toward middle
                let weights = [1, 2, 3, 3, 2] // Weights for ratings 1-5
                let total = weights.reduce(0, +)
                var random = Int.random(in: 0..<total)
                rating = 3 // default
                for (index, weight) in weights.enumerated() {
                    random -= weight
                    if random < 0 {
                        rating = Int16(index + 1)
                        break
                    }
                }
            }

            // Skip some days randomly for realism
            if Int.random(in: 0..<100) < 15 && dayOffset > 3 {
                continue
            }

            WellnessRating.setRating(rating: Int(rating), for: date, context: context)
        }

        // Ensure today has a good rating for screenshots
        WellnessRating.setRating(rating: 5, for: today, context: context)
    }
}

// MARK: - Mock Health Data

extension ScreenshotDataManager {

    /// Mock heart rate data for screenshots
    struct MockHeartRateData {
        let restingHeartRate: Int = 58
        let lastHourAverage: Int = 64
        let weeklyAverage: Int = 61
        let trend: String = "Improving"
        let lastReadingTime: Date = Date().addingTimeInterval(-1800) // 30 min ago

        // 24-hour chart data (hourly averages)
        let hourlyData: [Int] = [
            58, 56, 54, 52, 51, 52, // 12am-5am (sleeping)
            58, 72, 85, 78, 74, 70, // 6am-11am (morning, workout)
            68, 72, 70, 68, 65, 64, // 12pm-5pm (afternoon)
            66, 70, 68, 64, 62, 60  // 6pm-11pm (evening, winding down)
        ]

        // Last 7 days RHR
        let weeklyRHR: [Int] = [62, 60, 61, 59, 58, 57, 58]
    }

    /// Mock steps data for screenshots
    struct MockStepsData {
        let todaySteps: Int = 8_247
        let dailyGoal: Int = 10_000
        var progress: Double { Double(todaySteps) / Double(dailyGoal) }

        // Last 7 days
        let weeklySteps: [Int] = [9_432, 7_891, 11_234, 8_567, 6_789, 10_123, 8_247]
        let weeklyGoalMet: [Bool] = [false, false, true, false, false, true, false]
    }

    /// Mock sleep data for screenshots
    struct MockSleepData {
        let totalSleep: TimeInterval = 7.5 * 3600 // 7.5 hours
        let deepSleep: TimeInterval = 1.75 * 3600 // 1h 45m
        let remSleep: TimeInterval = 2.0 * 3600   // 2h
        let coreSleep: TimeInterval = 3.75 * 3600 // 3h 45m
        let sleepScore: Int = 85

        // Last 7 days total sleep (hours)
        let weeklySleep: [Double] = [7.2, 6.8, 8.1, 7.5, 6.5, 7.8, 7.5]
    }

    /// Mock HRV data for screenshots
    struct MockHRVData {
        let currentHRV: Int = 58 // ms
        let weeklyAverage: Int = 52
        let trend: String = "Improving"

        // Last 7 days
        let weeklyHRV: [Int] = [48, 51, 49, 54, 56, 55, 58]
    }

    /// Mock exertion/readiness scores
    struct MockScoreData {
        let exertionScore: Int = 72
        let readinessScore: Int = 85
        let recoveryScore: Int = 78
        let sleepScore: Int = 82
    }

    /// Mock exertion model data for screenshots
    struct MockExertionData {
        let exertionScore: Double = 72.0
        let avgRestingHeartRate: Double = 58.0

        // Time in each zone (5 zones) in minutes
        // Zone 1: Recovery, Zone 2-3: Conditioning, Zone 4-5: Overload
        let zoneTimes: [Double] = [45.0, 32.0, 18.0, 8.0, 3.0] // 106 total minutes of elevated HR

        var recoveryMinutes: Double { zoneTimes[0] } // Zone 1
        var conditioningMinutes: Double { zoneTimes[1] + zoneTimes[2] } // Zones 2-3
        var overloadMinutes: Double { zoneTimes[3] + zoneTimes[4] } // Zones 4-5

        // Heart rate zone ranges (based on ~30 year old with 58 resting HR)
        // Using Karvonen formula: Target HR = ((Max HR - Resting HR) × %Intensity) + Resting HR
        let heartRateZoneRanges: [(lowerBound: Double, upperBound: Double)] = [
            (94, 117),   // Zone 1: 40-60% (Recovery)
            (117, 132),  // Zone 2: 60-70% (Easy)
            (132, 146),  // Zone 3: 70-80% (Aerobic)
            (146, 161),  // Zone 4: 80-90% (Threshold)
            (161, 186)   // Zone 5: 90-100% (Max)
        ]
    }

    /// Mock streak data for screenshots
    struct MockStreakData {
        let currentStreak: Int = 12
        let bestStreak: Int = 47
        let thisWeekCompletions: Int = 5
        let totalSessions: Int = 234
        let completionRate: Int = 78

        // This week's completion pattern (Sun-Sat)
        let weekPattern: [Bool] = [true, true, true, false, true, true, false]
    }

    /// Mock insights/correlations for screenshots
    struct MockInsightData {
        struct HabitImpact {
            let habitName: String
            let habitIcon: String
            let habitColor: Color
            let metric: String
            let impact: String
            let isPositive: Bool
        }

        let topImpacts: [HabitImpact] = [
            HabitImpact(habitName: "Morning Run", habitIcon: "figure.run", habitColor: .cyan, metric: "Sleep Quality", impact: "+23%", isPositive: true),
            HabitImpact(habitName: "Meditation", habitIcon: "brain.head.profile", habitColor: .purple, metric: "HRV", impact: "+18%", isPositive: true),
            HabitImpact(habitName: "Weight Training", habitIcon: "dumbbell.fill", habitColor: .orange, metric: "Resting HR", impact: "-4 bpm", isPositive: true),
            HabitImpact(habitName: "Stretching", habitIcon: "figure.flexibility", habitColor: .green, metric: "Recovery", impact: "+12%", isPositive: true),
        ]

        let healthTrends: [(metric: String, current: String, change: String, isPositive: Bool)] = [
            ("Resting HR", "58 bpm", "-3 bpm", true),
            ("HRV", "58 ms", "+8 ms", true),
            ("Sleep", "7.5 hrs", "+0.3 hrs", true),
            ("Steps", "8.2K", "+1.2K", true),
        ]
    }

    // MARK: - Static Mock Accessors

    static var mockHeartRate: MockHeartRateData { MockHeartRateData() }
    static var mockSteps: MockStepsData { MockStepsData() }
    static var mockSleep: MockSleepData { MockSleepData() }
    static var mockHRV: MockHRVData { MockHRVData() }
    static var mockScores: MockScoreData { MockScoreData() }
    static var mockExertion: MockExertionData { MockExertionData() }
    static var mockStreak: MockStreakData { MockStreakData() }
    static var mockInsights: MockInsightData { MockInsightData() }
}

// MARK: - Preview Helper

#if DEBUG
extension ScreenshotDataManager {
    /// Call this in your app's initialization to enable screenshot mode
    static func enableScreenshotMode() {
        isScreenshotMode = true
        print("📸 Screenshot mode enabled")
    }

    /// Generate mock data in the provided context
    static func setupForScreenshots(context: NSManagedObjectContext) {
        enableScreenshotMode()
        shared.generateAllMockData(context: context)
    }
}
#endif
