//
//  SelectedTherapy+CoreDataProperties.swift
//  
//
//  Created by owenkhoury on 11/19/25.
//
//  This file was automatically generated and should not be edited.
//

import Foundation
import CoreData


extension SelectedTherapy {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<SelectedTherapy> {
        return NSFetchRequest<SelectedTherapy>(entityName: "SelectedTherapy")
    }

    @NSManaged public var therapyType: String?

}

extension SelectedTherapy : Identifiable {

}
