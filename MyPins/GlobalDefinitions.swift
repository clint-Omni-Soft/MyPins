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

struct EntityNames {
    static let imageRequest = "ImageRequest"
    static let pin          = "Pin"
    static let pinColor     = "PinColor"
}

struct Filenames {
    static let database    = "PinsDB.sqlite"
    static let databaseShm = "PinsDB.sqlite-shm"
    static let databaseWal = "PinsDB.sqlite-wal"
    static let lastUpdated = "LastUpdated"
    static let lockFile    = "LockFile"
}

struct GlobalConstants {
    static let feetPerMeter                     = 3.28084
    static let missingImage                     = "missingImage"
    static let newPin                           = -1
    static let noImage                          = "noImage"
    static let noSelection                      = -1
    static let offlineColor                     = UIColor.init( red: 242/255, green: 242/255, blue: 242/255, alpha: 1.0 )
    static let onlineColor                      = UIColor.init( red: 204/255, green: 255/255, blue: 204/255, alpha: 1.0 )
    static let separatorForLastUpdatedString    = ","
    static let separatorForLockfileString       = ","
    static let separatorForSorts                = ";"
    static let sortAscending                    = "↑"    // "▴"
    static let sortAscendingFlag                = "A"
    static let sortDescending                   = "↓"    // "▾"
    static let sortDescendingFlag               = "D"
    static let thumbNailPrefix                  = "tn"
}

struct ImageState {
    static let noName  = 0
    static let missing = 1
    static let loaded  = 2
}

struct GlobalIndexPaths {
    static let newPin      = IndexPath(row: GlobalConstants.newPin,      section: GlobalConstants.newPin      )
    static let noSelection = IndexPath(row: GlobalConstants.noSelection, section: GlobalConstants.noSelection )
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
    static let cannotReadAllDbFiles         = "CannotReadAllDbFiles"
    static let cannotSeeExternalDevice      = "CannotSeeExternalDevice"
    static let centerMap                    = "CenterMap"
    static let connectingToExternalDevice   = "ConnectingToExternalDevice"
    static let deviceNameNotSet             = "DeviceNameNotSet"
    static let enteringBackground           = "EnteringBackground"
    static let enteringForeground           = "EnteringForeground"
    static let externalDeviceLocked         = "ExternalDeviceLocked"
    static let launchPinEditor              = "LaunchPinEditor"
    static let pinsArrayReloaded            = "PinsArrayReloaded"
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

struct SortOptions {
    static let byDateLastModified = "byLastModified"
    static let byName             = "byName"
    static let byType             = "byType"
}


struct SortOptionNames {
    static let byDateLastModified = NSLocalizedString( "SortOption.DateLastModified", comment: "Date Last Modified" )
    static let byName             = NSLocalizedString( "SortOption.Name",             comment: "Name" )
    static let byType             = NSLocalizedString( "SortOption.Type",             comment: "Type" )
}

struct UserDefaultKeys {
    static let currentSortOption     = "CurrentSortOption"
    static let dataStoreLocation     = "DataStoreLocation"
    static let deviceName            = "DeviceName"
    static let dontRemindMeAgain     = "DontRemindMeAgain"
    static let howToUseShown         = "HowToUseShown"
    static let lastAccessedPinsGuid  = "LastAccessedPinsGuid"
    static let lastComponentSelected = "LastComponentSelected"
    static let lastLocationIndexPath = "LastLocationIndexPath"
    static let lastTabSelected       = "LastTabSelected"
    static let lastTextColor         = "LastTextColor"
    static let nasDescriptor         = "NasDescriptor"
    static let networkPath           = "NetworkPath"
    static let networkAccessGranted  = "NetworkAccessGranted"
    static let thumbnailsRemoved     = "ThumbnailsRemoved"
    static let updatedOffline        = "UpdatedOffline"
    static let usingThumbnails       = "UsingThumbnails"
}

struct UserInfo {
    static let latitude  = "Latitude"
    static let longitude = "Longitude"
}


