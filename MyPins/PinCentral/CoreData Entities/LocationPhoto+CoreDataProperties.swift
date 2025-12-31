//
//  LocationPhoto+CoreDataProperties.swift
//  MyPins
//
//  Created by Clint Shank on 12/15/25.
//  Copyright © 2025 Omni-Soft, Inc. All rights reserved.
//
//

public import Foundation
public import CoreData


public typealias LocationPhotoCoreDataPropertiesSet = NSSet

extension LocationPhoto {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<LocationPhoto> {
        return NSFetchRequest<LocationPhoto>(entityName: "LocationPhoto")
    }

    @NSManaged public var comment: String?
    @NSManaged public var dateCreated: Date?
    @NSManaged public var filename: String?
    @NSManaged public var index: Int16
    @NSManaged public var isVideo: Bool
    @NSManaged public var localIdentifier: String?
    @NSManaged public var pin: Pin?

}

extension LocationPhoto : Identifiable {

}
