//
//  CustomTherapy+CoreDataProperties.swift
//  
//
//  Created by owenkhoury on 11/19/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension CustomTherapy {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<CustomTherapy> {
        return NSFetchRequest<CustomTherapy>(entityName: "CustomTherapy")
    }

    @NSManaged public var id: Int16
    @NSManaged public var name: String?

}

extension CustomTherapy : Identifiable {

}
