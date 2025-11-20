//
//  CustomTimer+CoreDataProperties.swift
//  
//
//  Created by owenkhoury on 11/19/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension CustomTimer {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CustomTimer> {
        return NSFetchRequest<CustomTimer>(entityName: "CustomTimer")
    }

    @NSManaged public var duration: Int32

}

extension CustomTimer : Identifiable {

}
