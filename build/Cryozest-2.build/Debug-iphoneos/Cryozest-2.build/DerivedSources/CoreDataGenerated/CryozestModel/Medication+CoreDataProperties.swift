//
//  Medication+CoreDataProperties.swift
//  
//
//  Created by owenkhoury on 11/19/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension Medication {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Medication> {
        return NSFetchRequest<Medication>(entityName: "Medication")
    }

    @NSManaged public var id: UUID?
    @NSManaged public var name: String?
    @NSManaged public var frequency: String?
    @NSManaged public var reminderTime: Date?
    @NSManaged public var isActive: Bool
    @NSManaged public var createdDate: Date?

}

extension Medication : Identifiable {

}
