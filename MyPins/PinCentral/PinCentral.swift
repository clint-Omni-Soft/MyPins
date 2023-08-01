//
//  PinCentral.swift
//  MyPins
//
//  Created by Clint Shank on 3/12/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit
import CoreData
import CoreLocation



protocol PinCentralDelegate: AnyObject {
    func pinCentral(_ pinCentral: PinCentral, didFetchImage      : Bool, filename : String, image : UIImage )
    func pinCentral(_ pinCentral: PinCentral, didFetch imageNames: [String] )
    func pinCentral(_ pinCentral: PinCentral, didOpenDatabase    : Bool )
    func pinCentral(_ pinCentral: PinCentral, didSaveImageData   : Bool )
    func pinCentral(_ pinCentral: PinCentral, didUpdateDatabase  : Bool )
    func pinCentralDidReloadColorArray(_ pinCentral: PinCentral )
    func pinCentralDidReloadPinArray(_   pinCentral: PinCentral )
}


// MARK: PinCentralDelegate Default Implementation Methods (makes all optional)

extension PinCentralDelegate {
    func pinCentral(_ pinCentral: PinCentral, didFetchImage      : Bool, filename : String, image : UIImage ) {}
    func pinCentral(_ pinCentral: PinCentral, didFetch imageNames: [String] ) {}
    func pinCentral(_ pinCentral: PinCentral, didOpenDatabase    : Bool ) {}
    func pinCentral(_ pinCentral: PinCentral, didSaveImageData   : Bool ) {}
    func pinCentral(_ pinCentral: PinCentral, didUpdateDatabase  : Bool ) {}
    func pinCentralDidReloadColorArray(_ pinCentral: PinCentral ) {}
    func pinCentralDidReloadPinArray(_   pinCentral: PinCentral ) {}
}



class PinCentral: NSObject {
    
    // MARK: Public Variables
    
    var colorArray          : [PinColor] = []
    var currentAltitude     = 0.0
    var currentLocation     = CLLocationCoordinate2DMake( 0.0, 0.0 )
    var didOpenDatabase     = false
    var indexOfSelectedPin  = GlobalConstants.noSelection
    var locationEstablished = false
    var newPinIndex         = GlobalConstants.newPin
    var pinArray            = [Pin].init()
    var resigningActive     = false
    var stayOffline         = false
    
    var dataStoreLocation : DataStoreLocation {
        get {
            if dataStoreLocationBacking != .notAssigned {
                return dataStoreLocationBacking
            }
            
            if let locationString = UserDefaults.standard.string( forKey: UserDefaultKeys.dataStoreLocation ) {
                return dataStoreLocationFor( locationString )
            }
            else {
                return .device
            }
            
        }
        
        set( newLocation ) {
            var     oldDataStore = DataStoreLocationName.device
            let     newDataStore = nameForDataStoreLocation( newLocation )
            
            if let lastLocation = UserDefaults.standard.string( forKey: UserDefaultKeys.dataStoreLocation ) {
                oldDataStore = lastLocation
            }
            
            logVerbose( "[ %@ ] -> [ %@ ]", oldDataStore, newDataStore )
            dataStoreLocationBacking = newLocation
            
            UserDefaults.standard.set( newDataStore, forKey: UserDefaultKeys.dataStoreLocation )
            UserDefaults.standard.synchronize()
        }
        
    }
    
    var nasDescriptor : NASDescriptor {
        get {
            var     descriptor = NASDescriptor()
            
            if let descriptorString = UserDefaults.standard.string( forKey: UserDefaultKeys.nasDescriptor ) {
                let     components = descriptorString.components( separatedBy: "," )
                
                if components.count == 7 {
                    descriptor.host         = components[0]
                    descriptor.netbiosName  = components[1]
                    descriptor.group        = components[2]
                    descriptor.userName     = components[3]
                    descriptor.password     = components[4]
                    descriptor.share        = components[5]
                    descriptor.path         = components[6]
                }
                
            }
            
            return descriptor
        }
        
        set ( newDescriptor ){
            let     descriptorString = String( format: "%@,%@,%@,%@,%@,%@,%@",
                                               newDescriptor.host,      newDescriptor.netbiosName, newDescriptor.group,
                                               newDescriptor.userName,  newDescriptor.password,
                                               newDescriptor.share,     newDescriptor.path )
            
            UserDefaults.standard.set( descriptorString, forKey: UserDefaultKeys.nasDescriptor )
            UserDefaults.standard.synchronize()
        }
        
    }
    
    
    
    // MARK: Private Variables
    
    private struct Constants {
        static let databaseModel = "MyPins"
        static let primedFlag    = "Primed"
        static let timerDuration = Double( 300 )
    }
    
    private struct EntityNames {
        static let imageRequest = "ImageRequest"
        static let pin          = "Pin"
        static let pinColor     = "PinColor"
    }

    private struct OfflineImageRequestCommands {
        static let delete = 1
        static let fetch  = 2
        static let save   = 3
    }
    
    private let pinColorNameArray = [ NSLocalizedString( "PinColor.Black"    , comment:  "Black"      ),
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


    private let pinColorDefaultNicknameArray = [ NSLocalizedString( "DefaultColorNickname.Black"     , comment: "Airport"               ),
                                                 NSLocalizedString( "DefaultColorNickname.Blue"      , comment: "Business"              ),
                                                 NSLocalizedString( "DefaultColorNickname.Brown"     , comment: "Dry Cleaners"          ),
                                                 NSLocalizedString( "DefaultColorNickname.Cyan"      , comment: "Entertainment"         ),
                                                 NSLocalizedString( "DefaultColorNickname.DarkGray"  , comment: "Friends & Family"      ),
                                                 NSLocalizedString( "DefaultColorNickname.Gray"      , comment: "Geographic"            ),
                                                 NSLocalizedString( "DefaultColorNickname.Green"     , comment: "Recreation"            ),
                                                 NSLocalizedString( "DefaultColorNickname.LightGray" , comment: "Grocery Store"         ),
                                                 NSLocalizedString( "DefaultColorNickname.Magenta"   , comment: "Hotel"                 ),
                                                 NSLocalizedString( "DefaultColorNickname.Orange"    , comment: "Meeting Point"         ),
                                                 NSLocalizedString( "DefaultColorNickname.Purple"    , comment: "Professional Services" ),
                                                 NSLocalizedString( "DefaultColorNickname.Red"       , comment: "Restaurant"            ),
                                                 NSLocalizedString( "DefaultColorNickname.White"     , comment: "Shopping"              ),
                                                 NSLocalizedString( "DefaultColorNickname.Yellow"    , comment: "Winery"                ) ]

    private var backgroundTaskID            : UIBackgroundTaskIdentifier = .invalid
    private var cloudCentral                = CloudCentral.sharedInstance
    private var databaseUpdated             = false
    private var dataStoreLocationBacking    = DataStoreLocation.notAssigned
    private var delegate                    : PinCentralDelegate?
    private let deviceAccessControl         = DeviceAccessControl.sharedInstance
    private let fileManager                 = FileManager.default
    private var imageRequestQueue           : [(String, PinCentralDelegate)] = []       // This queue is used to serialize transactions while online (both iCloud and NAS)
    private var locationManager             : CLLocationManager?
    private var managedObjectContext        : NSManagedObjectContext!
    private var nasCentral                  = NASCentral.sharedInstance
    private var newPinGuid                  = ""
    private var offlineImageRequestQueue    : [ImageRequest] = []                       // This queue is used to flush offline NAS image transactions to disk after we reconnect
    private var openInProgress              = false
    private var persistentContainer         : NSPersistentContainer!
    private var updateTimer                 : Timer!

    private var updatedOffline: Bool {
        get {
            return flagIsPresentInUserDefaults( UserDefaultKeys.updatedOffline )
        }
        
        set ( setFlag ) {
            if setFlag {
                setFlagInUserDefaults( UserDefaultKeys.updatedOffline )
            }
            else {
                removeFlagFromUserDefaults( UserDefaultKeys.updatedOffline )
            }
            
        }
        
    }
    

    
    // MARK: Our Singleton
    
    static let sharedInstance = PinCentral()        // Prevents anyone else from creating an instance
    
    
    
    // MARK: AppDelegate Methods
    
    func enteringBackground() {
        logTrace()
        resigningActive = true
        
        NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.enteringBackground ), object: self )
        stopTimer()
    }
    
    
    func enteringForeground() {
        logTrace()
        resigningActive = false
        
        NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.enteringForeground ), object: self )
        canSeeExternalStorage()
    }
    
    
    
    // MARK: Database Access Methods (Public)
    
    func openDatabaseWith(_ delegate: PinCentralDelegate ) {
        
        if openInProgress {
            logTrace( "openInProgress ... do nothing" )
            return
        }
        
        if deviceAccessControl.updating {
            logVerbose( "Updating ... try again later ... %@", deviceAccessControl.descriptor() )
            return
        }
        
        logTrace()
        self.delegate       = delegate
        didOpenDatabase     = false
        openInProgress      = true
        pinArray            = Array.init()
        persistentContainer = NSPersistentContainer( name: Constants.databaseModel )
        
        persistentContainer.loadPersistentStores( completionHandler:
                                                    { ( storeDescription, error ) in
            
            if let error = error as NSError? {
                logVerbose( "Unresolved error[ %@ ]", error.localizedDescription )
            }
            else {
                self.loadCoreData()
                
                if !self.didOpenDatabase {      // This is just in case I screw up and don't properly version the data model
                    self.deleteDatabase()
                    self.loadCoreData()
                }
                
                self.loadBasicData()
                self.locationManager = CLLocationManager()
                
                if CLLocationManager.locationServicesEnabled() {
                    self.locationManager?.delegate = self
                    self.locationManager?.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                    self.locationManager?.startUpdatingLocation()
                }
                
                self.currentAltitude = 0.0
                self.currentLocation = CLLocationCoordinate2DMake( 0.0, 0.0 )
                
                self.startTimer()
            }
            
            DispatchQueue.main.async {
                logVerbose( "didOpenDatabase[ %@ ]", stringFor( self.didOpenDatabase ) )
                
                self.openInProgress = false
                self.delegate?.pinCentral( self, didOpenDatabase: self.didOpenDatabase )
                
                if self.updatedOffline && !self.stayOffline {
                    self.persistentContainer.viewContext.perform {
                        self.processNextOfflineImageRequest()
                    }
                    
                }
                
            }
            
        } )
        
    }
    
        
    
    // MARK: Pin Access/Modifier Methods (Public)
    
    func addPinNamed(_ name: String, details: String, latitude: Double, longitude: Double, altitude: Double, imageName: String, pinColor: Int16, notes: String, _ delegate: PinCentralDelegate ) {
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logVerbose( "[ %@ ][ %@ ]", name, details )
        self.delegate = delegate
        
        persistentContainer.viewContext.perform {
            let     pin = NSEntityDescription.insertNewObject( forEntityName: EntityNames.pin, into: self.managedObjectContext ) as! Pin
            
            pin.altitude        = altitude
            pin.details         = details
            pin.guid            = UUID().uuidString
            pin.imageName       = imageName
            pin.lastModified    = Date()  //NSDate.init()
            pin.latitude        = latitude
            pin.longitude       = longitude
            pin.name            = name
            pin.notes           = notes
            pin.pinColor        = pinColor
            
            self.newPinGuid = pin.guid ?? "Unwrapping Failed"
            
            self.saveContext()
            self.refetchPinsAndNotifyDelegate()
        }
        
    }
    
    
    func deletePinAt(_ index: Int, _ delegate: PinCentralDelegate ) {
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logVerbose( "deleting pin at [ %d ]", index )
        self.delegate = delegate
        
        persistentContainer.viewContext.perform {
            let     pin = self.pinArray[index]
            
            
            self.managedObjectContext.delete( pin )
            self.saveContext()
            self.refetchPinsAndNotifyDelegate()
        }
        
    }
    
    
    func displayUnits() -> String {
        var         units = DisplayUnits.meters
        
        if let displayUnits = UserDefaults.standard.string( forKey: DisplayUnits.altitude ) {
            if !displayUnits.isEmpty {
                units = displayUnits
            }
            
        }
        
        return units
    }
    
    
    func fetchPinsWith(_ delegate: PinCentralDelegate ) {
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        //        logTrace()
        self.delegate = delegate
        
        persistentContainer.viewContext.perform {
            self.refetchPinsAndNotifyDelegate()
        }
        
    }
    
    
    func saveUpdated(_ pin: Pin, _ delegate: PinCentralDelegate ) {
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logTrace()
        self.delegate = delegate
        
        persistentContainer.viewContext.perform {
            self.saveContext()
            self.refetchPinsAndNotifyDelegate()
        }
        
    }
    
    
    func saveUpdated(_ color: PinColor, _ delegate: PinCentralDelegate ) {
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
          
        logVerbose( "[ %@ ]", color.name! )

        persistentContainer.viewContext.perform {
            self.saveContext()
            
            self.fetchAllColorObjects()
            delegate.pinCentralDidReloadColorArray( self )
        }

    }
    
    
    func shortDescriptionFor(_ pin: Pin ) -> String {
        return String(format: "%@ %@", pin.name!, pin.details ?? "" )
    }
    
    

    // MARK: Utility Methods (Private)
    
    private func canSeeExternalStorage() {
        if dataStoreLocation == .device {
            deviceAccessControl.initForDevice()
            logVerbose( "on device ... %@", deviceAccessControl.descriptor() )
            return
        }
            
        logVerbose( "dataStoreLocation[ %@ ]", nameForDataStoreLocation( dataStoreLocation ) )

        if dataStoreLocation == .iCloud || dataStoreLocation == .shareCloud {
            cloudCentral.canSeeCloud( self )
        }
        else {  // NAS
            if didOpenDatabase && updatedOffline {
                self.persistentContainer.viewContext.perform {
                    self.fetchAllImageRequestObjects()
                }
                
            }

            nasCentral.canSeeNasFolders( self )
        }

        NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.connectingToExternalDevice ), object: self )
    }
    
    
    private func createImageRequestFor(_ command: Int, filename: String ) {
        logVerbose( "Creating ImageRequest[ %@ ][ %@ ] ", nameForImageRequest( command ), filename )
        self.persistentContainer.viewContext.perform {
            let     imageRequest = NSEntityDescription.insertNewObject( forEntityName: EntityNames.imageRequest, into: self.managedObjectContext ) as! ImageRequest
            
            imageRequest.index    = Int16( self.offlineImageRequestQueue.count )
            imageRequest.command  = Int16( command )
            imageRequest.filename = filename
            
            self.saveContext()
            
            self.setFlagInUserDefaults( Constants.primedFlag )
        }
        
    }
    
    
    private func deleteDatabase() {
        guard let docURL = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).last else {
            logTrace( "Error!  Unable to resolve document directory" )
            return
        }
        
        let     storeURL = docURL.appendingPathComponent( Filenames.database )
        
        do {
            try fileManager.removeItem( at: storeURL )
            logVerbose( "deleted database @ [ %@ ]", storeURL.path )
        }
        
        catch let error as NSError {
            logVerbose( "Error!  Unable delete store! ... Error[ %@ ]", error.localizedDescription )
        }
        
    }
    
    
    // Must be called from within persistentContainer.viewContext
    private func fetchAllColorObjects() {
        colorArray = []
        
        do {
            let     request       : NSFetchRequest<PinColor> = PinColor.fetchRequest()
            let     fetchedColors = try managedObjectContext.fetch( request )
            
            colorArray = fetchedColors.sorted( by:
                { (color1, color2) -> Bool in
                    return color1.colorId < color2.colorId
                })
            
        }
        catch {
            logTrace( "Error!  Fetch failed!" )
        }

    }
    
    
    // Must be called from within persistentContainer.viewContext
    private func fetchAllImageRequestObjects() {
        offlineImageRequestQueue = []
        
        do {
            let     request         : NSFetchRequest<ImageRequest> = ImageRequest.fetchRequest()
            let     fetchedRequests = try managedObjectContext.fetch( request )
            
            offlineImageRequestQueue = fetchedRequests.sorted( by:
                { (request1, request2) -> Bool in
                    return request1.index < request2.index
                })
            
        }
        catch {
            logTrace( "Error!  Fetch failed!" )
        }

        logVerbose( "Found [ %d ] requests", offlineImageRequestQueue.count )
    }
    

    // Must be called from within persistentContainer.viewContext
    private func fetchAllPinObjects() {
        do {
            let     request : NSFetchRequest<Pin> = Pin.fetchRequest()
            let     fetchedPins = try managedObjectContext.fetch( request )
            
            pinArray = fetchedPins.sorted( by:
                        { (pin1, pin2) -> Bool in
                            pin1.name! < pin2.name!     // We can do this because the name is a required field that must be unique
                        } )
            
            newPinIndex = GlobalConstants.newPin
            
            for index in 0..<self.pinArray.count {
                if pinArray[index].guid == newPinGuid {
                    newPinIndex = index
                    break
                }
                
            }
            
        }
            
        catch {
            pinArray = [Pin]()
            logTrace( "Error!  Fetch failed!" )
        }
        
    }
    
    
    private func loadBasicData() {
        let primedFlag = flagIsPresentInUserDefaults( Constants.primedFlag )
        
        logVerbose( "primedFlag[ %@ ]", stringFor( primedFlag ) )
        
        // Load and sort our public convenience arrays
        self.persistentContainer.viewContext.perform {
            if !primedFlag {
                for index in 0..<self.pinColorNameArray.count {
                    let     pinColor = NSEntityDescription.insertNewObject( forEntityName: EntityNames.pinColor, into: self.managedObjectContext ) as! PinColor

                    pinColor.colorId    = Int16(index)
                    pinColor.name       = self.pinColorNameArray[index]
                    pinColor.descriptor = self.pinColorDefaultNicknameArray[index]
                }
                
                self.saveContext()

                self.setFlagInUserDefaults( Constants.primedFlag )
            }
            
            self.fetchAllColorObjects()
            self.fetchAllImageRequestObjects()

            logVerbose( "Loaded Color[ %d ] and ImageRequest[ %d ] objects", self.colorArray.count, self.offlineImageRequestQueue.count )
        }
        
    }


    private func loadCoreData() {
        guard let modelURL = Bundle.main.url( forResource: "MyPins", withExtension: "momd" ) else {
            logTrace( "Error!  Could NOT load model from bundle!" )
            return
        }
        
        logVerbose( "modelURL[ %@ ]", modelURL.path )

        guard let managedObjectModel = NSManagedObjectModel( contentsOf: modelURL ) else {
            logVerbose( "Error!  Could NOT initialize managedObjectModel from URL[ %@ ]", modelURL.path )
            return
        }
        
        let     persistentStoreCoordinator = NSPersistentStoreCoordinator( managedObjectModel: managedObjectModel )

        managedObjectContext = NSManagedObjectContext( concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType )
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        guard let docURL = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).last else {
            logTrace( "Error!  Unable to resolve document directory!" )
            return
        }
        
        let     storeURL = docURL.appendingPathComponent( Filenames.database )
        
        logVerbose( "storeURL[ %@ ]", storeURL.path )

        do {
            let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]

            try persistentStoreCoordinator.addPersistentStore( ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: options )
            
            self.didOpenDatabase = true
//            logTrace( "added Pins store to coordinator" )
        }
            
        catch let error as NSError {
            logVerbose( "Error!  Unable migrate store[ %@ ]", error.localizedDescription )
        }
        
    }
    
    
    private func normalize(_ image : UIImage ) -> UIImage {
        var     rotation : Float = 0.0

        switch image.imageOrientation {
        case .down:             rotation = .pi
        case .downMirrored:     rotation = .pi
        case .left:             rotation = -.pi/2
        case .leftMirrored:     rotation = -.pi/2
        case .right:            rotation = .pi/2
        case .rightMirrored:    rotation = .pi/2
        case .up:               rotation = 0.0
        case .upMirrored:       rotation = 0.0
        default: break
        }
        
        if rotation == 0.0 {
            return image
        }

        logOrientationOf( image )
        logVerbose( "rotation[ %f ]", rotation )
        
        let     naturalImage = UIImage( cgImage: (image.cgImage)!, scale: image.scale, orientation: .up )
        let     rotatedImage = naturalImage.rotate( radians: rotation )!
        
        return rotatedImage
    }
    
    
    private func logOrientationOf(_ image : UIImage ) {
        var  imageOrientation = "Unknown"
        
        switch image.imageOrientation {
        case .down:             imageOrientation = "down"
        case .downMirrored:     imageOrientation = "downMirrored"
        case .left:             imageOrientation = "left"
        case .leftMirrored:     imageOrientation = "leftMirrored"
        case .right:            imageOrientation = "right"
        case .rightMirrored:    imageOrientation = "rightMirrored"
        case .up:               imageOrientation = "up"
        case .upMirrored:       imageOrientation = "upMirrored"
        default: break
        }
        
        logVerbose( "imageOrientation[ %@ ]", imageOrientation )
    }

    
    private func nameForImageRequest(_ command: Int ) -> String {
        var     name = "Unknown"
        
        switch command {
        case OfflineImageRequestCommands.delete:    name = "Delete"
        case OfflineImageRequestCommands.fetch:     name = "Fetch"
        default:                                    name = "Save"
        }
        
        return name
    }
    
    
    private func pictureDirectoryPath() -> String {
        if let documentDirectoryURL = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).first {
            let     picturesDirectoryURL = documentDirectoryURL.appendingPathComponent( "PinPictures" )
            
            if !fileManager.fileExists( atPath: picturesDirectoryURL.path ) {
                do {
                    try fileManager.createDirectory( atPath: picturesDirectoryURL.path, withIntermediateDirectories: true, attributes: nil )
                }
                
                catch let error as NSError {
                    logVerbose( "ERROR!  Failed to create photos directory ... Error[ %@ ]", error.localizedDescription )
                    return ""
                }
                
            }
            
            if !fileManager.fileExists( atPath: picturesDirectoryURL.path ) {
                logTrace( "ERROR!  photos directory does NOT exist!" )
                return ""
            }
            
//            logVerbose( "picturesDirectory[ %@ ]", picturesDirectoryURL.path )
            return picturesDirectoryURL.path
        }
        
//        logTrace( "ERROR!  Could NOT find the documentDirectory!" )
        return ""
    }
    
    
    // Must be called from within persistentContainer.viewContext
    private func processNextOfflineImageRequest() {
        
        if offlineImageRequestQueue.isEmpty {
            logTrace( "Done!" )
            updatedOffline = false
            
            if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                nasCentral.unlockNas( self )
            }

            deviceAccessControl.updating = false
            
            NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )
        }
        else {
            guard let imageRequest = offlineImageRequestQueue.first else {
                logTrace( "ERROR!  Unable to remove request from front of queue!" )
                updatedOffline = false
                return
            }
            
            let command  = Int( imageRequest.command )
            var doNext   = false
            let filename = imageRequest.filename!
            
            logVerbose( "pending[ %d ]  processing[ %@ ][ %@ ]", offlineImageRequestQueue.count, nameForImageRequest( command ), filename )
            
            switch command {
                case OfflineImageRequestCommands.delete:    nasCentral.deleteImage( filename, self )
                
//                case OfflineImageRequestCommands.fetch:     imageRequestQueue.append( (filename, delegate! ) )
//                                                            nasCentral.fetchImage( filename, self )

                case OfflineImageRequestCommands.save:      let result = fetchFromDiskImageFileDataNamed( filename )
                
                                                            if result.0 {
                                                                nasCentral.saveImageData( result.1, filename: filename, self )
                                                            }
                                                            else {
                                                                logVerbose( "ERROR!  NAS does NOT have [ %@ ]", filename )
                                                                doNext = true
                                                            }
                default:    break
            }
            
            self.managedObjectContext.delete( imageRequest )
            offlineImageRequestQueue.remove( at: 0 )

            self.saveContext()
            
            if doNext {
                doNext = false
                
                DispatchQueue.main.async {
                    self.processNextOfflineImageRequest()
                }
                
            }
            
        }
        
    }


    // Must be called from within a persistentContainer.viewContext
    private func refetchPinsAndNotifyDelegate() {
        fetchAllPinObjects()
        
        DispatchQueue.main.async {
            self.delegate?.pinCentralDidReloadPinArray( self )
        }

        if .pad == UIDevice.current.userInterfaceIdiom {
            NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.pinsArrayReloaded ), object: self )
        }

    }
    

    private func saveContext() {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
                
                if dataStoreLocation != .device {
                    databaseUpdated = true
                    
                    if stayOffline {
                        updatedOffline = true
                    }

                    createLastUpdatedFile()
                }
                
           }
            
            catch let error as NSError {
                logVerbose( "Unresolved error[ %@ ]", error.localizedDescription )
            }
            
        }
        
    }
    
    
}




// MARK: CLLocationManagerDelegate Methods

extension PinCentral: CLLocationManagerDelegate {
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation] ) {
        guard let currentLocation: CLLocationCoordinate2D = manager.location?.coordinate else {
            logVerbose( "ERROR!  Failed to extract currentLocation" )
            return
        }
        
        guard let currentAltitude = locations.last?.altitude else {
            logVerbose( "ERROR!  Failed to extract currentAltitude" )
            return
        }
        
        self.currentLocation = currentLocation
        self.currentAltitude = currentAltitude
        
        if !locationEstablished {
            locationEstablished = true
            
            logVerbose( "locationEstablished @ [ %f, %f ][ %f ]", currentLocation.latitude, currentLocation.longitude, currentAltitude )
        }

    }
    

}



// MARK: ClouldCentralDelegate Methods

extension PinCentral: CloudCentralDelegate {
    
    func cloudCentral(_ cloudCentral: CloudCentral, canSeeCloud: Bool ) {
        logVerbose( "[ %@ ]", stringFor( canSeeCloud ) )
        
        if stayOffline {
            logTrace( "Stay Offline!" )
        }
        else if canSeeCloud {
            cloudCentral.startSession( self )
        }
        else {
            deviceAccessControl.initWith(ownerName: "Unknown", locked: true, byMe: false, updating: false)
            logVerbose( "%@", deviceAccessControl.descriptor() )
            
            NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.cannotSeeExternalDevice ), object: self )
        }
        
    }
    
    
    func cloudCentral(_ cloudCentral: CloudCentral, didCompareLastUpdatedFiles: Int ) {
        logVerbose( "[ %@ ]", descriptionForCompare( didCompareLastUpdatedFiles ) )
        
        if didCompareLastUpdatedFiles == LastUpdatedFileCompareResult.deviceIsNewer {
            if deviceAccessControl.locked && deviceAccessControl.byMe {
                deviceAccessControl.updating = true
                
                cloudCentral.copyDatabaseFromDeviceToCloud( self )
            }
            
        }
        else if didCompareLastUpdatedFiles == LastUpdatedFileCompareResult.cloudIsNewer {
            deviceAccessControl.updating = true
            
            cloudCentral.copyDatabaseFromCloudToDevice( self )
        }
        else {
            deviceAccessControl.updating = false
            
            NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )
        }

    }
    
    
    func cloudCentral(_ cloudCentral: CloudCentral, didCopyAllImagesFromCloudToDevice: Bool) {
        logVerbose( "[ %@ ] ... SBH!", stringFor( didCopyAllImagesFromCloudToDevice ) )
    }
    
    
    func cloudCentral(_ cloudCentral: CloudCentral, didCopyAllImagesFromDeviceToCloud: Bool) {
        logVerbose( "[ %@ ] ... SBH!", stringFor( didCopyAllImagesFromDeviceToCloud ) )
    }
    
    
    func cloudCentral(_ cloudCentral: CloudCentral, didCopyDatabaseFromCloudToDevice: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didCopyDatabaseFromCloudToDevice ) )
        deviceAccessControl.updating = false

        NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )

        if didCopyDatabaseFromCloudToDevice && !openInProgress {
            let     appDelegate = UIApplication.shared.delegate as! AppDelegate
            
            logTrace( "opening database" )
            openDatabaseWith( delegate != nil ? delegate! : appDelegate )
        }
        
    }
    
    
    func cloudCentral(_ cloudCentral: CloudCentral, didCopyDatabaseFromDeviceToCloud: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didCopyDatabaseFromDeviceToCloud ) )
        
        if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
            cloudCentral.unlockCloud( self )
        }

        deviceAccessControl.updating = false

        NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )
    }
    
    
    func cloudCentral(_ cloudCentral: CloudCentral, didDeleteImage: Bool) {
        logVerbose( "[ %@ ]", stringFor( didDeleteImage ) )
    }
    
    
    func cloudCentral(_ cloudCentral: CloudCentral, didEndSession: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didEndSession ) )

        if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
            UIApplication.shared.endBackgroundTask( self.backgroundTaskID )
            
            self.backgroundTaskID = UIBackgroundTaskIdentifier.invalid
        }
        
    }

    
    func cloudCentral(_ cloudCentral: CloudCentral, didFetch imageNames: [String] ) {
        logTrace()
        delegate?.pinCentral( self, didFetch: imageNames )
    }

    
    func cloudCentral(_ cloudCentral: CloudCentral, didFetchImage: Bool, filename: String, image: UIImage ) {
//        logVerbose( "[ %@ ]  filename[ %@ ]", stringFor( didFetchImage ), filename )

        if didFetchImage {
            let     imageData            = image.pngData()!
            let     picturesDirectoryURL = URL.init( fileURLWithPath: pictureDirectoryPath() )
            let     pictureFileURL       = picturesDirectoryURL.appendingPathComponent( filename )
            
//            guard let imageData = image.jpegData( compressionQuality: 1.0 ) ?? image.pngData() else {
//                logVerbose( "ERROR!  Could NOT convert UIImage to Data! [ %@ ]", filename )
//                return
//            }
            
            do {
                try imageData.write( to: pictureFileURL, options: .atomic )
                logVerbose( "Saved image to file named[ %@ ]", filename )
            }
            catch let error as NSError {
                logVerbose( "ERROR!  Failed to save image for [ %@ ] ... Error[ %@ ]", filename, error.localizedDescription )
            }
            
        }
        
        guard let imageRequest = imageRequestQueue.first else {
            logTrace( "ERROR!  Unable to remove request from front of queue!" )
            return
        }

        let     delegate  = imageRequest.1
        let     imageName = imageRequest.0
        
        imageRequestQueue.remove( at: 0 )
        
        if imageName != filename {
            logVerbose( "ERROR!  Image returned[ %@ ] is not what was requested [ %@ ]", filename, imageName )
        }
        
        DispatchQueue.main.async {
            delegate.pinCentral( self, didFetchImage: didFetchImage, filename: filename, image : image )

            if self.imageRequestQueue.count == 0 {
                NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )
            }

        }
        
    }
 
    
    func cloudCentral(_ cloudCentral: CloudCentral, didLockCloud: Bool ) {
        logVerbose( "didLockCloud[ %@ ] ... %@", stringFor( didLockCloud ), deviceAccessControl.descriptor() )

        if deviceAccessControl.updating {
            NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.updatingExternalDevice ), object: self )
        }
        else if deviceAccessControl.locked && !deviceAccessControl.byMe {
            NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.externalDeviceLocked ), object: self )
        }
        else {
            cloudCentral.compareLastUpdatedFiles( self )
        }

    }
    
    
    func cloudCentral(_ cloudCentral: CloudCentral, didSaveImageData: Bool, filename: String) {
        logVerbose( "[ %@ ]", stringFor( didSaveImageData ) )
        self.delegate?.pinCentral( self, didSaveImageData: didSaveImageData )
    }

    
    func cloudCentral(_ cloudCentral: CloudCentral, didStartSession: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didStartSession ) )
        
        if didStartSession {
            cloudCentral.lockCloud( self )
        }
        else {
            NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.unableToConnect ), object: self )
        }
        
    }
    
    
    func cloudCentral(_ cloudCentral: CloudCentral, didUnlockCloud: Bool) {
        logVerbose( "[ %@ ]", stringFor( didUnlockCloud ) )

        cloudCentral.endSession( self )
    }
    
    
}



// MARK: Data Store Location Methods

extension PinCentral {
    
    func createLastUpdatedFile() {
        if let documentDirectoryURL = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).first {
            let     fileUrl   = documentDirectoryURL.appendingPathComponent( Filenames.lastUpdated )
            let     formatter = DateFormatter()
            
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            let     dateString = formatter.string( from: Date() )
            let     data       = dateString.data( using: .utf8 )
            
            if !fileManager.createFile( atPath: fileUrl.path, contents: data, attributes: nil ) {
                logTrace( "ERROR!  Create failed!" )
            }
            
        }
        else {
            logTrace( "ERROR!  Unable to unwrap documentDirectoryURL" )
        }
        
    }
    

    func nameForDataStoreLocation(_ location : DataStoreLocation ) -> String {
        var     name = "Undefined!"
        
        switch location {
        case .device:       name = DataStoreLocationName.device
        case .iCloud:       name = DataStoreLocationName.iCloud
        case .nas:          name = DataStoreLocationName.nas
        case .shareCloud:   name = DataStoreLocationName.shareCloud
        case .shareNas:     name = DataStoreLocationName.shareNas
        default:            name = DataStoreLocationName.notAssigned
        }
        
        return name
    }
    
    

    // MARK: Data Store Location Utility Methods (Private)

    private func dataStoreLocationFor(_ locationString : String ) -> DataStoreLocation {
        var     location : DataStoreLocation = .notAssigned
        
        switch locationString {
        case DataStoreLocationName.device:      location = .device
        case DataStoreLocationName.iCloud:      location = .iCloud
        case DataStoreLocationName.nas:         location = .nas
        case DataStoreLocationName.shareCloud:  location = .shareCloud
        case DataStoreLocationName.shareNas:    location = .shareNas
        default:                                location = .notAssigned
        }
        
        return location
    }
    
    
}



// MARK: Image Convenience Methods (Public)

extension PinCentral {
    
    func deleteImageNamed(_ name: String ) -> Bool {
        //        logTrace()
        let         directoryPath = pictureDirectoryPath()
        var         result        = false
        
        if !directoryPath.isEmpty {
            let     picturesDirectoryURL = URL.init( fileURLWithPath: directoryPath )
            let     imageFileURL         = picturesDirectoryURL.appendingPathComponent( name )
            
            if !fileManager.fileExists( atPath: imageFileURL.path ) {
                logTrace( "Image does NOT exist!" )
                result = true
            }
            else {
                do {
                    try fileManager.removeItem( at: imageFileURL )
                    
                    logVerbose( "deleted image named [ %@ ]", name )
                    result = true
                }
                
                catch let error as NSError {
                    logVerbose( "ERROR!  Failed to delete image named [ %@ ] ... Error[ %@ ]", name, error.localizedDescription )
                }
                
            }
            
        }
        
        if dataStoreLocation == .iCloud || dataStoreLocation == .shareCloud {
            logTrace( "Deleting from the Cloud" )
            self.cloudCentral.deleteImage( name, self )
        }
        else if dataStoreLocation == .nas || dataStoreLocation == .shareNas {
            if stayOffline {
                createImageRequestFor( OfflineImageRequestCommands.delete, filename: name )
            }
            else {
                logTrace( "Deleting from NAS" )
                nasCentral.deleteImage( name, self )
            }

        }
        
        return result
    }
    
    
    func imageNamed(_ name: String, descriptor: String, _ delegate: PinCentralDelegate ) -> (Bool, UIImage) {
//        logTrace()
        let result = fetchFromDiskImageNamed( name )
        
        if result.0 {
            return result
        }
        else {
            if dataStoreLocation == .iCloud || dataStoreLocation == .shareCloud {
                logVerbose( "Image for [ %@ ] not on disk!  Requesting from the Cloud [ %@ ]", descriptor, name )
                imageRequestQueue.append( (name, delegate) )
                cloudCentral.fetchImage( name, self )
            }
            else if dataStoreLocation == .nas || dataStoreLocation == .shareNas {
                if stayOffline {
//                    createImageRequestFor( OfflineImageRequestCommands.fetch, filename: name )
                }
                else {
                    logVerbose( "Image for [ %@ ] not on disk!  Requesting from NAS [ %@ ]", descriptor, name )
                    imageRequestQueue.append( (name, delegate) )
                    nasCentral.fetchImage( name, self )
                }
                
            }
            
        }
        
        return ( false, UIImage( named: "missingImage" ) ?? .init() )
    }
    
    
    func saveImage(_ image: UIImage, compressed: Bool ) -> String {
//        logTrace()
        let         directoryPath = pictureDirectoryPath()
        
        if directoryPath.isEmpty {
            logTrace( "ERROR!!!  directoryPath.isEmpty!" )
            return ""
        }
        
        let     normalizedImage      = normalize( image )
        let     compressionQuality   : CGFloat = ( compressed ? 0.25 : 1.0 )
        let     imageFilename        = UUID().uuidString + ".jpg"
        let     picturesDirectoryURL = URL.init( fileURLWithPath: directoryPath )
        let     pictureFileURL       = picturesDirectoryURL.appendingPathComponent( imageFilename )
        
        guard let imageData = normalizedImage.jpegData( compressionQuality: compressionQuality ) else {
            logTrace( "ERROR!  Could NOT convert UIImage to Data!" )
            return ""
        }
        
        do {
            try imageData.write( to: pictureFileURL, options: .atomic )
            
            logVerbose( "saved compressed[ %@ ] image to [ %@ ]", stringFor( compressed ), imageFilename )
            
            if dataStoreLocation == .iCloud || dataStoreLocation == .shareCloud {
                cloudCentral.saveImageData( imageData, filename: imageFilename, self )
            }
            else if dataStoreLocation == .nas || dataStoreLocation == .shareNas {
                if stayOffline {
                    createImageRequestFor( OfflineImageRequestCommands.save, filename: imageFilename )
                }
                else {
                    nasCentral.saveImageData( imageData, filename: imageFilename, self )
                }
                
            }
            
            return imageFilename
        }
        catch let error as NSError {
            logVerbose( "ERROR!  Failed to save image for [ %@ ] ... Error[ %@ ]", imageFilename, error.localizedDescription )
        }
        
        return ""
    }
 
    
    
    // MARK: Image Convenience Utility Methods (Private)

    private func fetchFromDiskImageNamed(_ name: String ) -> (Bool, UIImage) {
        let result = fetchFromDiskImageFileDataNamed( name )
        
        if result.0 {
            if let image = UIImage.init( data: result.1 ) {
                return ( true, image )
            }
            else {
                logVerbose( "ERROR!  Failed to un-wrap image for [ %@ ]", name )
            }
            
        }

        return ( false, UIImage( named: "missingImage" ) ?? .init() )
    }
    
    

    private func fetchFromDiskImageFileDataNamed(_ name: String ) -> (Bool, Data) {
        let directoryPath = pictureDirectoryPath()
        
        if !directoryPath.isEmpty {
            let     picturesDirectoryURL = URL.init( fileURLWithPath: directoryPath )
            let     imageFileURL         = picturesDirectoryURL.appendingPathComponent( name )
            
            if fileManager.fileExists( atPath: imageFileURL.path ) {
                let     imageFileData = fileManager.contents( atPath: imageFileURL.path )
                
                if let imageData = imageFileData {
                    return ( true, imageData )
                }
                else {
                    logVerbose( "ERROR!  Failed to load data for image for [ %@ ]", name )
                }
                
            }
            
        }
        else {
            logVerbose( "ERROR!  directoryPath is Empty!" )
        }

        return ( false, Data.init() )
    }
    
    
}



// MARK: NASCentralDelegate Methods

extension PinCentral: NASCentralDelegate {
    
    func nasCentral(_ nasCentral: NASCentral, canSeeNasFolders: Bool) {
        logVerbose( "[ %@ ]", stringFor( canSeeNasFolders ) )

        if stayOffline {
            logTrace( "stay offline" )
        }
        else if canSeeNasFolders {
            nasCentral.startSession( self )
        }
        else {
            deviceAccessControl.initWith(ownerName: "Unknown", locked: true, byMe: false, updating: false )
            logVerbose( "%@", deviceAccessControl.descriptor() )
            
            NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.cannotSeeExternalDevice ), object: self )
        }
        
    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didCompareLastUpdatedFiles: Int ) {
        logVerbose( "[ %@ ]", descriptionForCompare( didCompareLastUpdatedFiles ) )
        
        if didCompareLastUpdatedFiles == LastUpdatedFileCompareResult.deviceIsNewer {
            if deviceAccessControl.locked && deviceAccessControl.byMe {
                NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.transferringDatabase ), object: self )
                
                deviceAccessControl.updating = true
                
                nasCentral.copyDatabaseFromDeviceToNas( self )
            }
            
        }
        else if didCompareLastUpdatedFiles == LastUpdatedFileCompareResult.nasIsNewer {
            NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.transferringDatabase ), object: self )
            deviceAccessControl.updating = true

            nasCentral.copyDatabaseFromNasToDevice( self )
        }
        else {
            deviceAccessControl.updating = false
            
            NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )
        }

    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didCopyAllImagesFromDeviceToNas: Bool ) {
        logVerbose( "[ %@ ] ... SBH!", stringFor( didCopyAllImagesFromDeviceToNas ) )
    }
        
        
    func nasCentral(_ nasCentral: NASCentral, didCopyAllImagesFromNasToDevice: Bool ) {
        logVerbose( "[ %@ ] ... SBH!", stringFor( didCopyAllImagesFromNasToDevice ) )
    }
        
        
    func nasCentral(_ nasCentral: NASCentral, didCopyDatabaseFromDeviceToNas: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didCopyDatabaseFromDeviceToNas ) )
        
        if updatedOffline {
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 4.0 ) {
                self.persistentContainer.viewContext.perform {
                    self.processNextOfflineImageRequest()
                }

            }
           
        }

        if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
            nasCentral.unlockNas( self )
        }

        deviceAccessControl.updating = false
        
        NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )
    }
        
        
    func nasCentral(_ nasCentral: NASCentral, didCopyDatabaseFromNasToDevice: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didCopyDatabaseFromNasToDevice ) )
        
        deviceAccessControl.updating = false

        NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )

        if didCopyDatabaseFromNasToDevice && !openInProgress {
            let     appDelegate = UIApplication.shared.delegate as! AppDelegate
            
            logTrace( "opening database" )
            openDatabaseWith( delegate != nil ? delegate! : appDelegate )
        }
        
    }
        
        
    func nasCentral(_ nasCentral: NASCentral, didDeleteImage: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didDeleteImage ) )
        
        if self.updatedOffline {
            self.persistentContainer.viewContext.perform {
                self.processNextOfflineImageRequest()
            }
            
        }

    }
        
        
    func nasCentral(_ nasCentral: NASCentral, didEndSession: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didEndSession ) )
        
        if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
            UIApplication.shared.endBackgroundTask( self.backgroundTaskID )
            
            self.backgroundTaskID = UIBackgroundTaskIdentifier.invalid
        }
        
        if !resigningActive {
            logTrace( "re-establishing session" )
            nasCentral.startSession( self )
        }
        
    }
        
        
    func nasCentral(_ nasCentral: NASCentral, didFetchImage: Bool, image: UIImage, filename: String ) {
        logVerbose( "[ %@ ]  filename[ %@ ]", stringFor( didFetchImage ), filename )
        
        if didFetchImage {
            let     imageData            = image.pngData()!
            let     picturesDirectoryURL = URL.init( fileURLWithPath: pictureDirectoryPath() )
            let     pictureFileURL       = picturesDirectoryURL.appendingPathComponent( filename )
            
            do {
                try imageData.write( to: pictureFileURL, options: .atomic )
                logVerbose( "Saved image to [ %@ ]", pictureFileURL.path )
            }
            catch let error as NSError {
                logVerbose( "ERROR!  Failed to save image for [ %@ ] ... Error[ %@ ]", filename, error.localizedDescription )
            }
            
        }

        let     imageRequest = imageRequestQueue.first
        let     delegate     = imageRequest!.1
        let     imageName    = imageRequest!.0
        
        imageRequestQueue.removeFirst()
        
        if didFetchImage && imageName != filename {
            logVerbose( "ERROR!  Image returned[ %@ ] is not what was requested [ %@ ]", filename, imageName )
        }
        

        if self.imageRequestQueue.count == 0 {
            NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )
        }
        
        if self.updatedOffline {
            self.persistentContainer.viewContext.perform {
                self.processNextOfflineImageRequest()
            }
            
        }
        else {
            DispatchQueue.main.async {
                delegate.pinCentral( self, didFetchImage: didFetchImage, filename: filename, image : image )
            }

        }
        
    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didFetch imageNames: [String] ) {
        logTrace()
        DispatchQueue.main.async {
            self.delegate?.pinCentral( self, didFetch: imageNames )
        }

    }
        
        
    func nasCentral(_ nasCentral: NASCentral, didLockNas: Bool ) {
        logVerbose( "didLockNas[ %@ ]", stringFor( didLockNas ) )

        if deviceAccessControl.updating {
            NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.updatingExternalDevice ), object: self )
        }
        else if deviceAccessControl.locked && !deviceAccessControl.byMe {
            NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.externalDeviceLocked ), object: self )
        }
        else {
            nasCentral.compareLastUpdatedFiles( self )
        }

    }
        
        
    func nasCentral(_ nasCentral: NASCentral, didSaveImageData: Bool, filename: String ) {
        logVerbose( "[ %@ ][ %@ ]", stringFor( didSaveImageData ), filename )
        
        if self.updatedOffline {
            self.persistentContainer.viewContext.perform {
                self.processNextOfflineImageRequest()
            }
            
        }
        else {
            self.delegate?.pinCentral( self, didSaveImageData: didSaveImageData )
        }
        
    }
        
        
    func nasCentral(_ nasCentral: NASCentral, didStartSession: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didStartSession ) )
        
        if didStartSession {
            nasCentral.lockNas( self )
        }
        else {
            NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.unableToConnect ), object: self )
        }
        
    }
        
        
    func nasCentral(_ nasCentral: NASCentral, didUnlockNas: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didUnlockNas ) )
        
        nasCentral.endSession( self )
    }
        

}



// MARK: Timer Methods

extension PinCentral {
    
    func startTimer() {
        if dataStoreLocation == .device {
            logTrace( "Database on device ... do nothing!" )
            return
        }
        
        if stayOffline {
            logTrace( "stay offline" )
            return
        }
        
        logTrace()
        if let timer = updateTimer {
            timer.invalidate()
        }
        
        DispatchQueue.main.async {
            self.updateTimer = Timer.scheduledTimer( withTimeInterval: Constants.timerDuration, repeats: true ) {
                (timer) in
                
                if self.deviceAccessControl.updating {
                    logTrace( "We are updating ... do nothing!" )
                }
                else if self.databaseUpdated {
                    self.databaseUpdated = false
                    logVerbose( "databaseUpdated[ true ] ... %@", self.deviceAccessControl.descriptor() )
                    
                    if self.dataStoreLocation == .iCloud || self.dataStoreLocation == .shareCloud {
                        logVerbose( "copying database to iCloud" )
                        self.cloudCentral.copyDatabaseFromDeviceToCloud( self )
                    }
                    else {  // .nas
                        logVerbose( "copying database to NAS" )
                        self.nasCentral.copyDatabaseFromDeviceToNas( self )
                    }
                    
                }
                else {
                    if self.dataStoreLocation == .iCloud || self.dataStoreLocation == .shareCloud {
                        logTrace( "ending iCloud session" )
                        self.cloudCentral.endSession( self )
                    }
                    else {  // .nas
                        logTrace( "ending NAS session" )
                        self.nasCentral.endSession( self )
                    }
                    
                }
                
            }
            
        }
        
    }
    
    
    func stopTimer() {
        if dataStoreLocation == .device {
            logTrace( "Database on device ... do nothing!" )
            databaseUpdated = false
            return
        }
        
        if let timer = updateTimer {
            timer.invalidate()
        }
        
        logVerbose( "databaseUpdated[ %@ ] ... %@", stringFor( databaseUpdated ), deviceAccessControl.descriptor() )
        
        if databaseUpdated {
            
            if !stayOffline {
                DispatchQueue.global().async {
                    self.backgroundTaskID = UIApplication.shared.beginBackgroundTask( withName: "Finish copying DB to External Device" ) {
                        // The OS calls this block if we don't finish in time
                        UIApplication.shared.endBackgroundTask( self.backgroundTaskID )
                        
                        self.backgroundTaskID = UIBackgroundTaskIdentifier.invalid
                    }
                    
                    if self.deviceAccessControl.updating {
                        logTrace( "we are updating the external device ... do nothing, just let the process complete!" )
                    }
                    else {
                        self.databaseUpdated = false
                        self.deviceAccessControl.updating = true
                        
                        if self.dataStoreLocation == .iCloud || self.dataStoreLocation == .shareCloud {
                            logTrace( "copying database to iCloud" )
                            self.cloudCentral.copyDatabaseFromDeviceToCloud( self )
                        }
                        else {  // .nas
                            logTrace( "copying database to NAS" )
                            self.nasCentral.copyDatabaseFromDeviceToNas( self )
                        }
                        
                    }
                    
                }

            }
            
        }
        else {
            
            if !deviceAccessControl.byMe {
                logTrace( "do nothing!" )
                return
            }
            
            DispatchQueue.global().async {
                self.backgroundTaskID = UIApplication.shared.beginBackgroundTask( withName: "Remove lock file" ) {
                    // The OS calls this block if we don't finish in time
                    UIApplication.shared.endBackgroundTask( self.backgroundTaskID )
                    
                    self.backgroundTaskID = UIBackgroundTaskIdentifier.invalid
                }
                
                if self.deviceAccessControl.updating {
                    logTrace( "we are updating the external device ... do nothing, just let the process complete!" )
                }
                else {
                    logTrace( "removing lock file" )
                    if self.dataStoreLocation == .iCloud || self.dataStoreLocation == .shareCloud {
                        self.cloudCentral.unlockCloud( self )
                    }
                    else {  // .nas
                        self.nasCentral.unlockNas( self )
                    }
                    
                }
                
            }
            
        }
        
    }
 
    
}



extension PinCentral {
    
    func flagIsPresentInUserDefaults(_ key : String ) -> Bool {
        var     flagIsPresent = false
        
        if let _ = UserDefaults.standard.string( forKey: key ) {
            flagIsPresent = true
        }
        
        return flagIsPresent
    }
    
    
    func removeFlagFromUserDefaults(_ key: String ) {
        UserDefaults.standard.removeObject(forKey: key )
        UserDefaults.standard.synchronize()
    }
    
    
    func setFlagInUserDefaults(_ key: String ) {
        UserDefaults.standard.set( key, forKey: key )
        UserDefaults.standard.synchronize()
    }
    

}

