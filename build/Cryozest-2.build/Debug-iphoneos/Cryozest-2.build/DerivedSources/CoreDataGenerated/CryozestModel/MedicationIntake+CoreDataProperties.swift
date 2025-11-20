//
//  MedicationIntake+CoreDataProperties.swift
//  
//
//  Created by owenkhoury on 11/19/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension MedicationIntake {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<MedicationIntake> {
        return NSFetchRequest<MedicationIntake>(entityName: "MedicationIntake")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var medicationId: UUID?
    @NSManaged public var medicationName: String?
    @NSManaged public var date: Date?
    @NSManaged public var wasTaken: Bool
    @NSManaged public var timestamp: Date?

}

extension MedicationIntake : Identifiable {

}
