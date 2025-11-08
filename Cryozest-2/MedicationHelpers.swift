//
//  MedicationHelpers.swift
//  Cryozest-2
//
//  Helper methods for Medication and MedicationIntake entities
//

import Foundation
import CoreData

// MARK: - Medication Extensions
extension Medication {
    // Get all active medications
    static func getActiveMedications(context: NSManagedObjectContext) -> [Medication] {
        let request: NSFetchRequest<Medication> = Medication.fetchRequest()
        request.predicate = NSPredicate(format: "isActive == YES")
        request.sortDescriptors = [NSSortDescriptor(keyPath: \Medication.createdDate, ascending: true)]

        return (try? context.fetch(request)) ?? []
    }

    // Create a new medication
    static func create(
        name: String,
        frequency: String,
        reminderTime: Date?,
        context: NSManagedObjectContext
    ) -> Medication {
        let medication = Medication(context: context)
        medication.id = UUID()
        medication.name = name
        medication.frequency = frequency
        medication.reminderTime = reminderTime
        medication.isActive = true
        medication.createdDate = Date()

        try? context.save()
        return medication
    }

    // Delete (deactivate) a medication
    func deactivate(context: NSManagedObjectContext) {
        self.isActive = false
        try? context.save()
    }

    // Permanently delete a medication
    func permanentlyDelete(context: NSManagedObjectContext) {
        context.delete(self)
        try? context.save()
    }
}

// MARK: - MedicationIntake Extensions
extension MedicationIntake {
    // Check if medication was taken on a specific date
    static func wasTaken(
        medicationId: UUID,
        on date: Date,
        context: NSManagedObjectContext
    ) -> Bool {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return false
        }

        let request: NSFetchRequest<MedicationIntake> = MedicationIntake.fetchRequest()
        request.predicate = NSPredicate(
            format: "medicationId == %@ AND date >= %@ AND date < %@ AND wasTaken == YES",
            medicationId as CVarArg,
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        request.fetchLimit = 1

        return (try? context.fetch(request).first) != nil
    }

    // Get intake record for a specific medication and date
    static func getIntake(
        medicationId: UUID,
        on date: Date,
        context: NSManagedObjectContext
    ) -> MedicationIntake? {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        guard let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay) else {
            return nil
        }

        let request: NSFetchRequest<MedicationIntake> = MedicationIntake.fetchRequest()
        request.predicate = NSPredicate(
            format: "medicationId == %@ AND date >= %@ AND date < %@",
            medicationId as CVarArg,
            startOfDay as NSDate,
            endOfDay as NSDate
        )
        request.fetchLimit = 1

        return try? context.fetch(request).first
    }

    // Mark medication as taken
    static func markAsTaken(
        medication: Medication,
        on date: Date,
        context: NSManagedObjectContext
    ) {
        // Check if already exists
        if let existing = getIntake(medicationId: medication.id!, on: date, context: context) {
            existing.wasTaken = true
            existing.timestamp = Date()
        } else {
            let intake = MedicationIntake(context: context)
            intake.id = UUID()
            intake.medicationId = medication.id
            intake.medicationName = medication.name
            intake.date = Calendar.current.startOfDay(for: date)
            intake.wasTaken = true
            intake.timestamp = Date()
        }

        try? context.save()
    }

    // Mark medication as not taken (undo)
    static func markAsNotTaken(
        medicationId: UUID,
        on date: Date,
        context: NSManagedObjectContext
    ) {
        if let intake = getIntake(medicationId: medicationId, on: date, context: context) {
            context.delete(intake)
            try? context.save()
        }
    }

    // Get adherence percentage for last N days
    static func getAdherencePercentage(
        medicationId: UUID,
        days: Int,
        context: NSManagedObjectContext
    ) -> Double {
        let calendar = Calendar.current
        let today = Date()
        var totalDays = 0
        var takenDays = 0

        for dayOffset in 0..<days {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            totalDays += 1

            if wasTaken(medicationId: medicationId, on: date, context: context) {
                takenDays += 1
            }
        }

        guard totalDays > 0 else { return 0 }
        return Double(takenDays) / Double(totalDays) * 100.0
    }
}
