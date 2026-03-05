//
//  WaterIntake.swift
//  Cryozest-2
//
//  Water intake tracking data model extension
//

import Foundation
import CoreData

extension WaterIntake {
    // Default daily goal in cups (8 cups = ~64 oz)
    static let defaultDailyGoal: Int = 8

    // MARK: - Query Methods

    /// Get total cups for a specific day
    static func getTotalCups(for date: Date, context: NSManagedObjectContext) -> Int {
        let entries = getAllEntries(for: date, context: context)
        return entries.reduce(0) { $0 + Int($1.cups) }
    }

    /// Get all water intake entries for a specific day
    static func getAllEntries(for date: Date, context: NSManagedObjectContext) -> [WaterIntake] {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        let request: NSFetchRequest<WaterIntake> = WaterIntake.fetchRequest()
        request.predicate = NSPredicate(format: "date >= %@ AND date < %@", startOfDay as NSDate, endOfDay as NSDate)
        request.sortDescriptors = [NSSortDescriptor(keyPath: \WaterIntake.timestamp, ascending: false)]

        return (try? context.fetch(request)) ?? []
    }

    /// Check if any water logged today
    static func hasLoggedToday(context: NSManagedObjectContext) -> Bool {
        return getTotalCups(for: Date(), context: context) > 0
    }

    // MARK: - Add/Remove Methods

    /// Add cups of water (creates a new entry)
    static func addCups(_ cups: Int, for date: Date, context: NSManagedObjectContext) {
        DispatchQueue.main.async {
            let entry = WaterIntake(context: context)
            entry.id = UUID()
            entry.date = date
            entry.cups = Int16(cups)
            entry.timestamp = Date()

            try? context.save()
        }
    }

    /// Add one cup of water
    static func addOneCup(for date: Date, context: NSManagedObjectContext) {
        addCups(1, for: date, context: context)
    }

    /// Remove one cup (deletes most recent entry or decrements)
    static func removeOneCup(for date: Date, context: NSManagedObjectContext) {
        DispatchQueue.main.async {
            let entries = getAllEntries(for: date, context: context)
            guard let mostRecent = entries.first else { return }

            if mostRecent.cups > 1 {
                mostRecent.cups -= 1
            } else {
                context.delete(mostRecent)
            }

            try? context.save()
        }
    }

    /// Delete a specific entry by ID
    static func deleteEntry(id: UUID, context: NSManagedObjectContext) {
        DispatchQueue.main.async {
            let request: NSFetchRequest<WaterIntake> = WaterIntake.fetchRequest()
            request.predicate = NSPredicate(format: "id == %@", id as CVarArg)
            request.fetchLimit = 1

            if let entry = try? context.fetch(request).first {
                context.delete(entry)
                try? context.save()
            }
        }
    }

    /// Clear all entries for a day
    static func clearDay(for date: Date, context: NSManagedObjectContext) {
        DispatchQueue.main.async {
            let entries = getAllEntries(for: date, context: context)
            for entry in entries {
                context.delete(entry)
            }
            try? context.save()
        }
    }

    // MARK: - Date Range Queries (for insights)

    /// Get daily totals for a date range
    static func getDailyTotals(from startDate: Date, to endDate: Date, context: NSManagedObjectContext) -> [(date: Date, cups: Int)] {
        let calendar = Calendar.current
        var results: [(date: Date, cups: Int)] = []

        var currentDate = calendar.startOfDay(for: startDate)
        let endDay = calendar.startOfDay(for: endDate)

        while currentDate < endDay {
            let cups = getTotalCups(for: currentDate, context: context)
            if cups > 0 {
                results.append((date: currentDate, cups: cups))
            }
            currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)!
        }

        return results
    }

    /// Get average daily cups for a set of dates
    static func getAverageCups(for dates: [Date], context: NSManagedObjectContext) -> Double? {
        var total = 0
        var count = 0

        for date in dates {
            let cups = getTotalCups(for: date, context: context)
            if cups > 0 {
                total += cups
                count += 1
            }
        }

        return count > 0 ? Double(total) / Double(count) : nil
    }

    /// Get total cups for a set of dates
    static func getTotalCups(for dates: [Date], context: NSManagedObjectContext) -> Int {
        return dates.reduce(0) { $0 + getTotalCups(for: $1, context: context) }
    }
}

// MARK: - Hydration Helpers
extension WaterIntake {
    /// Convert cups to fluid ounces (1 cup = 8 oz)
    static func cupsToOunces(_ cups: Int) -> Int {
        return cups * 8
    }

    /// Convert cups to milliliters (1 cup ≈ 237 ml)
    static func cupsToMilliliters(_ cups: Int) -> Int {
        return cups * 237
    }

    /// Get hydration status based on cups consumed vs goal
    static func hydrationStatus(cups: Int, goal: Int = defaultDailyGoal) -> HydrationStatus {
        let progress = Double(cups) / Double(goal)
        if progress >= 1.0 {
            return .excellent
        } else if progress >= 0.75 {
            return .good
        } else if progress >= 0.5 {
            return .moderate
        } else if progress >= 0.25 {
            return .low
        } else {
            return .veryLow
        }
    }
}

enum HydrationStatus: String {
    case excellent = "Excellent"
    case good = "Good"
    case moderate = "Moderate"
    case low = "Low"
    case veryLow = "Very Low"

    var color: String {
        switch self {
        case .excellent: return "cyan"
        case .good: return "green"
        case .moderate: return "yellow"
        case .low: return "orange"
        case .veryLow: return "red"
        }
    }

    var message: String {
        switch self {
        case .excellent: return "Excellent"
        case .good: return "Good"
        case .moderate: return "Keep going"
        case .low: return "Drink more"
        case .veryLow: return "Low"
        }
    }
}
