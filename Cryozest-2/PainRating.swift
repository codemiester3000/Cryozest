//
//  PainRating.swift
//  Cryozest-2
//
//  Pain tracking data model extension
//  Supports multiple entries per day with timestamps
//

import Foundation
import CoreData

extension PainRating {
    // MARK: - Single Entry Queries (for backward compatibility)

    // Get the most recent rating for a specific date
    static func getRating(for date: Date, context: NSManagedObjectContext) -> PainRating? {
        let ratings = getAllRatingsForDay(date: date, context: context)
        return ratings.first // Already sorted by timestamp descending
    }

    // Get today's most recent rating if it exists
    static func getTodayRating(context: NSManagedObjectContext) -> PainRating? {
        return getRating(for: Date(), context: context)
    }

    // Check if any rating exists for today
    static func hasRatedToday(context: NSManagedObjectContext) -> Bool {
        return !getAllRatingsForDay(date: Date(), context: context).isEmpty
    }

    // MARK: - Multiple Entries Per Day

    // Get all ratings for a specific day, sorted by timestamp (newest first)
    static func getAllRatingsForDay(date: Date, context: NSManagedObjectContext) -> [PainRating] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let request: NSFetchRequest<PainRating> = PainRating.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PainRating.timestamp, ascending: false)]

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
    static func addRating(rating: Int, for date: Date, bodyLocation: String? = nil, notes: String? = nil, context: NSManagedObjectContext) {
        DispatchQueue.main.async {
            let newRating = PainRating(context: context)
            newRating.id = UUID()
            newRating.date = date // Store actual timestamp, not start of day
            newRating.rating = Int16(rating)
            newRating.bodyLocation = bodyLocation
            newRating.notes = notes
            newRating.timestamp = Date()

            try? context.save()
        }
    }

    // Add a rating for right now
    static func addCurrentRating(rating: Int, bodyLocation: String? = nil, notes: String? = nil, context: NSManagedObjectContext) {
        addRating(rating: rating, for: Date(), bodyLocation: bodyLocation, notes: notes, context: context)
    }

    // Legacy method - now just adds a new entry
    static func setRating(rating: Int, for date: Date, bodyLocation: String? = nil, notes: String? = nil, context: NSManagedObjectContext) {
        addRating(rating: rating, for: date, bodyLocation: bodyLocation, notes: notes, context: context)
    }

    // Legacy method
    static func setTodayRating(rating: Int, bodyLocation: String? = nil, notes: String? = nil, context: NSManagedObjectContext) {
        addCurrentRating(rating: rating, bodyLocation: bodyLocation, notes: notes, context: context)
    }

    // MARK: - Deleting Entries

    // Delete a specific rating by ID
    static func deleteRating(id: UUID, context: NSManagedObjectContext) {
        DispatchQueue.main.async {
            let request: NSFetchRequest<PainRating> = PainRating.fetchRequest()
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
    static func getRatings(from startDate: Date, to endDate: Date, context: NSManagedObjectContext) -> [PainRating] {
        let request: NSFetchRequest<PainRating> = PainRating.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startDate as NSDate, endDate as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \PainRating.date, ascending: true)]

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

    // Get average pain rating for a set of dates (uses daily averages)
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

// MARK: - Pain Level Descriptions
extension PainRating {
    static func painLabel(for rating: Int) -> String {
        switch rating {
        case 0: return "None"
        case 1: return "Minimal"
        case 2: return "Mild"
        case 3: return "Moderate"
        case 4: return "Severe"
        case 5: return "Extreme"
        default: return "Unknown"
        }
    }

    static func painEmoji(for rating: Int) -> String {
        switch rating {
        case 0: return "😌"
        case 1: return "🙂"
        case 2: return "😐"
        case 3: return "😣"
        case 4: return "😖"
        case 5: return "😫"
        default: return "😐"
        }
    }

    static func painColor(for rating: Int) -> String {
        switch rating {
        case 0: return "green"
        case 1: return "mint"
        case 2: return "yellow"
        case 3: return "orange"
        case 4: return "red"
        case 5: return "purple"
        default: return "gray"
        }
    }
}
