//
//  HabitStats.swift
//  Cryozest-2
//
//  Habit statistics and streak calculation
//

import Foundation
import CoreData

struct HabitStats {
    let currentStreak: Int
    let bestStreak: Int
    let totalSessions: Int
    let thisWeekCount: Int
    let lastWeekCount: Int
    let thisMonthCount: Int
    let monthlyConsistency: Int // Percentage
    let averagePerWeek: Double

    static func calculate(for therapyType: TherapyType, sessions: [TherapySessionEntity]) -> HabitStats {
        // Filter sessions for this therapy type
        let typeSessions = sessions.filter { $0.therapyType == therapyType.rawValue }

        // Sort by date descending
        let sortedSessions = typeSessions.sorted { ($0.date ?? Date.distantPast) > ($1.date ?? Date.distantPast) }

        let calendar = Calendar.current
        let now = Date()
        let today = calendar.startOfDay(for: now)

        // Calculate current streak
        var currentStreak = 0
        var checkDate = today

        for session in sortedSessions {
            guard let sessionDate = session.date else { continue }
            let sessionDay = calendar.startOfDay(for: sessionDate)

            // If this session is on the current check date, increment streak
            if calendar.isDate(sessionDay, inSameDayAs: checkDate) {
                currentStreak += 1
                // Move to previous day
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate) ?? checkDate
            } else if sessionDay < checkDate {
                // Gap found, stop counting
                break
            }
        }

        // Calculate best streak
        var bestStreak = 0
        var tempStreak = 0
        var lastSessionDay: Date?

        for session in sortedSessions.reversed() {
            guard let sessionDate = session.date else { continue }
            let sessionDay = calendar.startOfDay(for: sessionDate)

            if let last = lastSessionDay {
                let daysDifference = calendar.dateComponents([.day], from: last, to: sessionDay).day ?? 0

                if daysDifference == 1 {
                    // Consecutive day
                    tempStreak += 1
                } else {
                    // Gap found
                    bestStreak = max(bestStreak, tempStreak)
                    tempStreak = 1
                }
            } else {
                tempStreak = 1
            }

            lastSessionDay = sessionDay
        }
        bestStreak = max(bestStreak, tempStreak)

        // This week count
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!
        let thisWeekSessions = typeSessions.filter {
            guard let date = $0.date else { return false }
            return date >= startOfWeek && date < endOfWeek
        }

        // Last week count
        let startOfLastWeek = calendar.date(byAdding: .day, value: -7, to: startOfWeek)!
        let lastWeekSessions = typeSessions.filter {
            guard let date = $0.date else { return false }
            return date >= startOfLastWeek && date < startOfWeek
        }

        // This month count
        let startOfMonth = calendar.date(from: calendar.dateComponents([.year, .month], from: now))!
        let endOfMonth = calendar.date(byAdding: .month, value: 1, to: startOfMonth)!
        let thisMonthSessions = typeSessions.filter {
            guard let date = $0.date else { return false }
            return date >= startOfMonth && date < endOfMonth
        }

        // Monthly consistency
        let currentDayOfMonth = calendar.component(.day, from: now)
        let monthlyConsistency = currentDayOfMonth > 0 ? Int((Double(thisMonthSessions.count) / Double(currentDayOfMonth)) * 100) : 0

        // Average per week (last 12 weeks)
        let twelveWeeksAgo = calendar.date(byAdding: .weekOfYear, value: -12, to: now)!
        let recentSessions = typeSessions.filter {
            guard let date = $0.date else { return false }
            return date >= twelveWeeksAgo
        }
        let averagePerWeek = Double(recentSessions.count) / 12.0

        return HabitStats(
            currentStreak: currentStreak,
            bestStreak: bestStreak,
            totalSessions: typeSessions.count,
            thisWeekCount: thisWeekSessions.count,
            lastWeekCount: lastWeekSessions.count,
            thisMonthCount: thisMonthSessions.count,
            monthlyConsistency: min(monthlyConsistency, 100),
            averagePerWeek: averagePerWeek
        )
    }
}
