//
//  GlobalDefinitions.swift
//  MyPins
//
//  Created by Clint Shank on 6/9/21.
//  Copyright © 2021 Omni-Soft, Inc. All rights reserved.
//

import UIKit


enum DataStoreLocation {
    case device
    case iCloud
    case nas
    case notAssigned
    case shareCloud
    case shareNas
}

struct DataStoreLocationName {
    static let device       = "device"
    static let iCloud       = "iCloud"
    static let nas          = "nas"
    static let notAssigned  = "notAssigned"
    static let shareCloud   = "shareCloud"
    static let shareNas     = "shareNas"
}

struct DirectoryNames {
    static let root     = "MyPins"
    static let pictures = "PinPictures"
}

struct DisplayUnits {
    static let altitude = "DisplayUnitsAltitude"
    static let feet     = "ft"
    static let meters   = "m"
}

struct Filenames {
    static let database    = "PinsDB.sqlite"
    static let databaseShm = "PinsDB.sqlite-shm"
    static let databaseWal = "PinsDB.sqlite-wal"
    static let lastUpdated = "LastUpdated"
    static let lockFile    = "LockFile"
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
    static let cannotSeeExternalDevice      = "CannotSeeExternalDevice"
    static let centerMap                    = "CenterMap"
    static let connectingToExternalDevice   = "ConnectingToExternalDevice"
    static let enteringBackground           = "EnteringBackground"
    static let enteringForeground           = "EnteringForeground"
    static let externalDeviceLocked         = "ExternalDeviceLocked"
    static let launchPinEditor              = "LaunchPinEditor"
    static let pinsArrayReloaded            = "PinsArrayReloaded"
    static let pleaseWaitingDone            = "PleaseWaitingDone"
    static let ready                        = "Ready"
    static let transferringDatabase         = "TransferringDatabase"
    static let unableToConnect              = "UnableToConnect"
    static let updatingExternalDevice       = "UpdatingExternalDevice"
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
}


struct UserDefaultKeys {
    static let dataStoreLocation     = "DataStoreLocation"
    static let howToUseShown         = "HowToUseShown"
    static let lastComponentSelected = "LastComponentSelected"
    static let lastTabSelected       = "LastTabSelected"
    static let lastTextColor         = "LastTextColor"
    static let nasDescriptor         = "NasDescriptor"
    static let networkPath           = "NetworkPath"
    static let updatedOffline        = "UpdatedOffline"
    static let userHasBeenWarned     = "UserHasBeenWarned"
}

struct UserInfo {
    static let latitude  = "Latitude"
    static let longitude = "Longitude"
}


