//
//  TherapySessionEntity+CoreDataProperties.swift
//  
//
//  Created by owenkhoury on 11/19/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension TherapySessionEntity {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<TherapySessionEntity> {
        return NSFetchRequest<TherapySessionEntity>(entityName: "TherapySessionEntity")
    }

    @NSManaged public var averageHeartRate: Double
    @NSManaged public var averageRespirationRate: Double
    @NSManaged public var averageSpo2: Double
    @NSManaged public var bodyWeight: Double
    @NSManaged public var date: Date?
    @NSManaged public var duration: Double
    @NSManaged public var id: UUID?
    @NSManaged public var isAppleWatch: Bool
    @NSManaged public var maxHeartRate: Double
    @NSManaged public var minHeartRate: Double
    @NSManaged public var temperature: Double
    @NSManaged public var therapyType: String?

}

extension TherapySessionEntity : Identifiable {

}
