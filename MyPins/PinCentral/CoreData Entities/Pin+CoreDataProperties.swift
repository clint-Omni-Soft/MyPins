//
//  Pin+CoreDataProperties.swift
//  MyPins
//
//  Created by Clint Shank on 11/28/22.
//  Copyright © 2022 Omni-Soft, Inc. All rights reserved.
//
//

import Foundation
import CoreData


extension Pin {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Pin> {
        return NSFetchRequest<Pin>(entityName: "Pin")
    }

    @NSManaged public var altitude: Double
    @NSManaged public var details: String?
    @NSManaged public var guid: String?
    @NSManaged public var imageName: String?
    @NSManaged public var lastModified: Date?
    @NSManaged public var latitude: Double
    @NSManaged public var longitude: Double
    @NSManaged public var name: String?
    @NSManaged public var pinColor: Int16
    @NSManaged public var notes: String?

}
