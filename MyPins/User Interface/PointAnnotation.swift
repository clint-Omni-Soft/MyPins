//
//  PointAnnotation.swift
//  MyPins
//
//  Created by Clint Shank on 3/15/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit
import MapKit



class PointAnnotation: MKPointAnnotation
{
    var      pinIndex: Int?
    
    
    func initWith( pin: Pin, atIndex: Int )
    {
        pinIndex   = atIndex    // The reason we derived this class in the first place
        
        coordinate = CLLocationCoordinate2D( latitude: pin.latitude, longitude: pin.longitude )
        subtitle   = pin.details
        title      = pin.name
    }
    
}
