//
//  WellnessRating+CoreDataProperties.swift
//  
//
//  Created by owenkhoury on 11/19/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension WellnessRating {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<WellnessRating> {
        return NSFetchRequest<WellnessRating>(entityName: "WellnessRating")
    }

    @NSManaged public var date: Date?
    @NSManaged public var id: UUID?
    @NSManaged public var rating: Int16
    @NSManaged public var timestamp: Date?

}

extension WellnessRating : Identifiable {

}
