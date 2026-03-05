//
//  WellnessImpactAnalysis.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//

import Foundation
import CoreData
import SwiftUI

struct WellnessImpact: Identifiable {
    let id = UUID()
    let habitType: TherapyType
    let averageRatingWithHabit: Double
    let averageRatingWithoutHabit: Double
    let impact: Double // Positive = good, negative = bad
    let sampleSize: Int

    var impactDescription: String {
        let sign = impact >= 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", impact))★"
    }

    var isPositive: Bool {
        impact > 0.2 // Threshold for meaningful positive impact
    }
}

class WellnessImpactAnalyzer {

    // Calculate wellness impact for each therapy type
    static func calculateImpacts(
        ratings: [WellnessRating],
        sessions: [TherapySessionEntity],
        therapyTypes: [TherapyType]
    ) -> [WellnessImpact] {
        var impacts: [WellnessImpact] = []

        // Create a set of dates with therapy sessions by type
        var sessionDatesByType: [TherapyType: Set<Date>] = [:]
        for type in therapyTypes {
            let dates = sessions
                .filter { $0.therapyType == type.rawValue }
                .compactMap { $0.date }
                .map { Calendar.current.startOfDay(for: $0) }
            sessionDatesByType[type] = Set(dates)
        }

        for type in therapyTypes {
            guard let therapyDates = sessionDatesByType[type], therapyDates.count >= 3 else {
                continue
            }

            // Get ratings on therapy days vs non-therapy days
            var ratingsWithTherapy: [Double] = []
            var ratingsWithoutTherapy: [Double] = []

            for rating in ratings {
                guard let date = rating.date else { continue }
                let ratingDate = Calendar.current.startOfDay(for: date)
                let ratingValue = Double(rating.rating)

                if therapyDates.contains(ratingDate) {
                    ratingsWithTherapy.append(ratingValue)
                } else {
                    ratingsWithoutTherapy.append(ratingValue)
                }
            }

            // Need at least 3 samples for each
            guard ratingsWithTherapy.count >= 3 && ratingsWithoutTherapy.count >= 3 else {
                continue
            }

            let avgWith = ratingsWithTherapy.reduce(0, +) / Double(ratingsWithTherapy.count)
            let avgWithout = ratingsWithoutTherapy.reduce(0, +) / Double(ratingsWithoutTherapy.count)
            let impact = avgWith - avgWithout

            impacts.append(WellnessImpact(
                habitType: type,
                averageRatingWithHabit: avgWith,
                averageRatingWithoutHabit: avgWithout,
                impact: impact,
                sampleSize: ratingsWithTherapy.count
            ))
        }

        // Sort by impact (highest first)
        return impacts.sorted { $0.impact > $1.impact }
    }

    // Calculate overall weekly average
    static func weeklyAverage(ratings: [WellnessRating]) -> Double? {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!

        let recentRatings = ratings.filter {
            guard let date = $0.date else { return false }
            return date >= weekAgo
        }

        guard !recentRatings.isEmpty else { return nil }

        let sum = recentRatings.reduce(0.0) { $0 + Double($1.rating) }
        return sum / Double(recentRatings.count)
    }

    // Calculate previous week average
    static func previousWeekAverage(ratings: [WellnessRating]) -> Double? {
        let calendar = Calendar.current
        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        let twoWeeksAgo = calendar.date(byAdding: .day, value: -14, to: Date())!

        let previousWeekRatings = ratings.filter {
            guard let date = $0.date else { return false }
            return date >= twoWeeksAgo && date < weekAgo
        }

        guard !previousWeekRatings.isEmpty else { return nil }

        let sum = previousWeekRatings.reduce(0.0) { $0 + Double($1.rating) }
        return sum / Double(previousWeekRatings.count)
    }

    // Get trend data for line chart (last 30 days)
    static func getTrendData(ratings: [WellnessRating]) -> [TrendDataPoint] {
        let calendar = Calendar.current
        let thirtyDaysAgo = calendar.date(byAdding: .day, value: -30, to: Date())!

        let recentRatings = ratings
            .compactMap { rating -> (Date, Int16)? in
                guard let date = rating.date else { return nil }
                return (date, rating.rating)
            }
            .filter { $0.0 >= thirtyDaysAgo }
            .sorted { $0.0 < $1.0 }

        return recentRatings.map { (date, rating) in
            TrendDataPoint(
                date: date,
                value: Double(rating)
            )
        }
    }
}

struct TrendDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}
