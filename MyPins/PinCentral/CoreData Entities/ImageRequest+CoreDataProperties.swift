//
//  ImageRequest+CoreDataProperties.swift
//  MyPins
//
//  Created by Clint Shank on 5/4/23.
//  Copyright © 2023 Omni-Soft, Inc. All rights reserved.
//
//

import Foundation
import CoreData


extension ImageRequest {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<ImageRequest> {
        return NSFetchRequest<ImageRequest>(entityName: "ImageRequest")
    }

    @NSManaged public var index: Int16
    @NSManaged public var command: Int16
    @NSManaged public var filename: String?

}
