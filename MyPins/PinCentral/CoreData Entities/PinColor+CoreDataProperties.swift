//
//  PinColor+CoreDataProperties.swift
//  MyPins
//
//  Created by Clint Shank on 5/1/23.
//  Copyright © 2023 Omni-Soft, Inc. All rights reserved.
//
//

import Foundation
import CoreData


extension PinColor {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<PinColor> {
        return NSFetchRequest<PinColor>(entityName: "PinColor")
    }

    @NSManaged public var name: String?
    @NSManaged public var colorId: Int16
    @NSManaged public var descriptor: String?

}
