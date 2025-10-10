
//
//  WellnessRating.swift
//  Cryozest-2
//
//  Created by Owen Khoury on 10/9/25.
//

import Foundation
import CoreData

extension WellnessRating {
    // Get today's rating if it exists
    static func getTodayRating(context: NSManagedObjectContext) -> WellnessRating? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let request: NSFetchRequest<WellnessRating> = WellnessRating.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.fetchLimit = 1

        return try? context.fetch(request).first
    }

    // Check if rating exists for today
    static func hasRatedToday(context: NSManagedObjectContext) -> Bool {
        return getTodayRating(context: context) != nil
    }

    // Create or update today's rating
    static func setTodayRating(rating: Int, context: NSManagedObjectContext) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())

        // Ensure we're on the main thread for Core Data operations
        DispatchQueue.main.async {
            // Check if already exists
            if let existing = getTodayRating(context: context) {
                existing.rating = Int16(rating)
                existing.timestamp = Date()
            } else {
                let newRating = WellnessRating(context: context)
                newRating.id = UUID()
                newRating.date = startOfDay
                newRating.rating = Int16(rating)
                newRating.timestamp = Date()
            }

            try? context.save()
        }
    }
}
