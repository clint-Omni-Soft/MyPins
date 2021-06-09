//
//  GlobalDefinitions.swift
//  MyPins
//
//  Created by Clint Shank on 6/9/21.
//  Copyright © 2021 Omni-Soft, Inc. All rights reserved.
//

import UIKit


struct DisplayUnits {
    static let altitude = "DisplayUnitsAltitude"
    static let feet     = "ft"
    static let meters   = "m"
}


struct GlobalConstants {
    static let feetPerMeter = 3.28084
    static let newPin       = -1
    static let noSelection  = -1
}


struct MapTypes {
    static let eStandard         = 0
    static let eSatellite        = 1
    static let eHybrid           = 2
    static let eSatelliteFlyover = 3
    static let eHybridFlyover    = 4
    static let eMutedStandard    = 5
}


struct Notifications {
    static let centerMap   = "CenterMap"
    static let pinsUpdated = "PinsUpdated"
}


struct PinColors {
    static let pinBlack     = Int16( 0 )
    static let pinBlue      = Int16( 1 )
    static let pinBrown     = Int16( 2 )
    static let pinCyan      = Int16( 3 )
    static let pinDarkGray  = Int16( 4 )
    static let pinGray      = Int16( 5 )
    static let pinGreen     = Int16( 6 )
    static let pinLightGray = Int16( 7 )
    static let pinMagenta   = Int16( 8 )
    static let pinOrange    = Int16( 9 )
    static let pinPurple    = Int16( 10 )
    static let pinRed       = Int16( 11 )
    static let pinWhite     = Int16( 12 )
    static let pinYellow    = Int16( 13 )
};


struct UserInfo {
    static let latitude  = "Latitude"
    static let longitude = "Longitude"
}


let pinColorArray: [UIColor] = [ .black,
                                 .blue,
                                 .brown,
                                 .cyan,
                                 .darkGray,
                                 .gray,
                                 .green,
                                 .lightGray,
                                 .magenta,
                                 .orange,
                                 .purple,
                                 .red,
                                 .white,
                                 .yellow ]


let pinColorNameArray = [ NSLocalizedString( "PinColor.Black"    , comment:  "Black"      ),
                          NSLocalizedString( "PinColor.Blue"     , comment:  "Blue"       ),
                          NSLocalizedString( "PinColor.Brown"    , comment:  "Brown"      ),
                          NSLocalizedString( "PinColor.Cyan"     , comment:  "Cyan"       ),
                          NSLocalizedString( "PinColor.DarkGray" , comment:  "Dark Gray"  ),
                          NSLocalizedString( "PinColor.Gray"     , comment:  "Gray"       ),
                          NSLocalizedString( "PinColor.Green"    , comment:  "Green"      ),
                          NSLocalizedString( "PinColor.LightGray", comment:  "Light Gray" ),
                          NSLocalizedString( "PinColor.Magenta"  , comment:  "Magenta"    ),
                          NSLocalizedString( "PinColor.Orange"   , comment:  "Orange"     ),
                          NSLocalizedString( "PinColor.Purple"   , comment:  "Purple"     ),
                          NSLocalizedString( "PinColor.Red"      , comment:  "Red"        ),
                          NSLocalizedString( "PinColor.White"    , comment:  "White"      ),
                          NSLocalizedString( "PinColor.Yellow"   , comment:  "Yellow"     )]


