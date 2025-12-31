//
//  Pin+CoreDataProperties.swift
//  MyPins
//
//  Created by Clint Shank on 11/20/25.
//  Copyright © 2025 Omni-Soft, Inc. All rights reserved.
//
//

public import Foundation
public import CoreData


public typealias PinCoreDataPropertiesSet = NSSet

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
    @NSManaged public var notes: String?
    @NSManaged public var pinColor: Int16
    @NSManaged public var numberOfPhotos: Int16
    @NSManaged public var locationPhotos: NSSet?

}

// MARK: Generated accessors for locationPhotos
extension Pin {

    @objc(addLocationPhotosObject:)
    @NSManaged public func addToLocationPhotos(_ value: LocationPhoto)

    @objc(removeLocationPhotosObject:)
    @NSManaged public func removeFromLocationPhotos(_ value: LocationPhoto)

    @objc(addLocationPhotos:)
    @NSManaged public func addToLocationPhotos(_ values: NSSet)

    @objc(removeLocationPhotos:)
    @NSManaged public func removeFromLocationPhotos(_ values: NSSet)

}

extension Pin : Identifiable {

}
