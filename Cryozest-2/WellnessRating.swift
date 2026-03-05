//
//  WellnessRating.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//  Supports multiple entries per day with timestamps
//

import Foundation
import CoreData

extension WellnessRating {
    // MARK: - Single Entry Queries (for backward compatibility)

    // Get the most recent rating for a specific date
    static func getRating(for date: Date, context: NSManagedObjectContext) -> WellnessRating? {
        let ratings = getAllRatingsForDay(date: date, context: context)
        return ratings.first // Already sorted by timestamp descending
    }

    // Get today's most recent rating if it exists
    static func getTodayRating(context: NSManagedObjectContext) -> WellnessRating? {
        return getRating(for: Date(), context: context)
    }

    // Check if any rating exists for today
    static func hasRatedToday(context: NSManagedObjectContext) -> Bool {
        return !getAllRatingsForDay(date: Date(), context: context).isEmpty
    }

    // MARK: - Multiple Entries Per Day

    // Get all ratings for a specific day, sorted by timestamp (newest first)
    static func getAllRatingsForDay(date: Date, context: NSManagedObjectContext) -> [WellnessRating] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let request: NSFetchRequest<WellnessRating> = WellnessRating.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WellnessRating.timestamp, ascending: false)]

        return (try? context.fetch(request)) ?? []
    }

    // Get average rating for a specific day (for correlations)
    static func getAverageRatingForDay(date: Date, context: NSManagedObjectContext) -> Double? {
        let ratings = getAllRatingsForDay(date: date, context: context)
        guard !ratings.isEmpty else { return nil }

        let total = ratings.reduce(0.0) { $0 + Double($1.rating) }
        return total / Double(ratings.count)
    }

    // Get count of ratings for a specific day
    static func getRatingCountForDay(date: Date, context: NSManagedObjectContext) -> Int {
        return getAllRatingsForDay(date: date, context: context).count
    }

    // MARK: - Creating Entries

    // Add a new rating entry (always creates new, never updates)
    static func addRating(rating: Int, for date: Date, context: NSManagedObjectContext) {
        DispatchQueue.main.async {
            let newRating = WellnessRating(context: context)
            newRating.id = UUID()
            newRating.date = date // Store actual timestamp, not start of day
            newRating.rating = Int16(rating)
            newRating.timestamp = Date()

            try? context.save()
        }
    }

    // Add a rating for right now
    static func addCurrentRating(rating: Int, context: NSManagedObjectContext) {
        addRating(rating: rating, for: Date(), context: context)
    }

    // Legacy method - now just adds a new entry
    static func setRating(rating: Int, for date: Date, context: NSManagedObjectContext) {
        addRating(rating: rating, for: date, context: context)
    }

    // Legacy method
    static func setTodayRating(rating: Int, context: NSManagedObjectContext) {
        addCurrentRating(rating: rating, context: context)
    }

    // MARK: - Deleting Entries

    // Delete a specific rating by ID
    static func deleteRating(id: UUID, context: NSManagedObjectContext) {
        DispatchQueue.main.async {
            let request: NSFetchRequest<WellnessRating> = WellnessRating.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            if let rating = try? context.fetch(request).first {
                context.delete(rating)
                try? context.save()
            }
        }
    }

    // Delete the most recent rating for a date
    static func deleteLatestRating(for date: Date, context: NSManagedObjectContext) {
        DispatchQueue.main.async {
            if let latestRating = getRating(for: date, context: context) {
                context.delete(latestRating)
                try? context.save()
            }
        }
    }

    // Delete all ratings for a specific date
    static func deleteAllRatings(for date: Date, context: NSManagedObjectContext) {
        DispatchQueue.main.async {
            let ratings = getAllRatingsForDay(date: date, context: context)
            for rating in ratings {
                context.delete(rating)
            }
            try? context.save()
        }
    }

    // Legacy method - now deletes the most recent
    static func deleteRating(for date: Date, context: NSManagedObjectContext) {
        deleteLatestRating(for: date, context: context)
    }

    // Legacy method
    static func deleteTodayRating(context: NSManagedObjectContext) {
        deleteLatestRating(for: Date(), context: context)
    }

    // MARK: - Date Range Queries (for insights)

    // Fetch all ratings for a date range
    static func getRatings(from startDate: Date, to endDate: Date, context: NSManagedObjectContext) -> [WellnessRating] {
        let request: NSFetchRequest<WellnessRating> = WellnessRating.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WellnessRating.date, ascending: true)]

        return (try? context.fetch(request)) ?? []
    }

    // Get daily averages for a date range (one value per day)
    static func getDailyAverages(from startDate: Date, to endDate: Date, context: NSManagedObjectContext) -> [(date: Date, average: Double)] {
        let calendar = Calendar.current
        var results: [(date: Date, average: Double)] = []

        var currentDate = calendar.startOfDay(for: startDate)
        let endDay = calendar.startOfDay(for: endDate)

        while currentDate < endDay {
            if let avg = getAverageRatingForDay(date: currentDate, context: context) {
                results.append((date: currentDate, average: avg))
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return results
    }

    // Get average wellness rating for a set of dates (uses daily averages)
    static func getAverageRating(for dates: [Date], context: NSManagedObjectContext) -> Double? {
        var total: Double = 0
        var count = 0

        for date in dates {
            if let dayAvg = getAverageRatingForDay(date: date, context: context) {
                total += dayAvg
                count += 1
            }
        }

        return count > 0 ? total / Double(count) : nil
    }
}

// MARK: - Wellness Level Descriptions
extension WellnessRating {
    static func moodEmoji(for rating: Int) -> String {
        switch rating {
        case 1: return "😫"
        case 2: return "😔"
        case 3: return "😐"
        case 4: return "🙂"
        case 5: return "😊"
        default: return "😐"
        }
    }

    static func moodLabel(for rating: Int) -> String {
        switch rating {
        case 1: return "Rough"
        case 2: return "Low"
        case 3: return "Okay"
        case 4: return "Good"
        case 5: return "Great"
        default: return "Unknown"
        }
    }

    static func moodColor(for rating: Int) -> String {
        switch rating {
        case 1: return "red"
        case 2: return "orange"
        case 3: return "yellow"
        case 4: return "mint"
        case 5: return "green"
        default: return "gray"
        }
    }
}
