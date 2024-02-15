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
    
    var colorArray: [PinColor]      = []
    var currentAltitude             = 0.0
    var currentLocation             = CLLocationCoordinate2DMake( 0.0, 0.0 )
    var didOpenDatabase             = false
    var externalDeviceLastUpdatedBy = ""
    var indexPathOfSelectedPin      = GlobalIndexPaths.noSelection
    var locationEstablished         = false
    var missingDbFiles: [String]    = []
    var numberOfPinsLoaded          = 0
    var newPinIndexPath             = GlobalIndexPaths.newPin
    var openInProgress              = false
    var pinArrayOfArrays            = [[Pin]]()
    var resigningActive             = false
    var stayOffline                 = false
    
    
    var dataStoreLocation : DataStoreLocation {
        get {
            if dataStoreLocationBacking != .notAssigned {
                return dataStoreLocationBacking
            }
            
            if let locationString = userDefaults.string( forKey: UserDefaultKeys.dataStoreLocation ) {
                return dataStoreLocationFor( locationString )
            }
            else {
                return .device
            }
            
        }
        
        set( newLocation ) {
            var     oldDataStore = DataStoreLocationName.device
            var     newDataStore = ""
            
            if let lastLocation = userDefaults.string( forKey: UserDefaultKeys.dataStoreLocation ) {
                oldDataStore = lastLocation
            }
            
            switch newLocation {
            case .device:       newDataStore = DataStoreLocationName.device
            case .iCloud:       newDataStore = DataStoreLocationName.iCloud
            case .nas:          newDataStore = DataStoreLocationName.nas
            case .shareCloud:   newDataStore = DataStoreLocationName.shareCloud
            case .shareNas:     newDataStore = DataStoreLocationName.shareNas
            default:            newDataStore = DataStoreLocationName.device
            }

            logVerbose( "[ %@ ] -> [ %@ ]", oldDataStore, newDataStore )
            
            dataStoreLocationBacking = newLocation
            
            userDefaults.set( newDataStore, forKey: UserDefaultKeys.dataStoreLocation )
            userDefaults.synchronize()
        }
        
    }
    
    
    var deviceName: String {
        get {
            var     nameOfDevice = ""

            if let deviceNameString = userDefaults.string( forKey: UserDefaultKeys.deviceName ) {
                if !deviceNameString.isEmpty && deviceNameString.count > 0 {
                    nameOfDevice = deviceNameString
                }

            }

            return nameOfDevice
        }
        
        
        set( newName ) {
            userDefaults.set( newName, forKey: UserDefaultKeys.deviceName )
            userDefaults.synchronize()
        }
        
    }
    
    
    var nasDescriptor : NASDescriptor {
        get {
            var     descriptor = NASDescriptor()
            
            if let descriptorString = userDefaults.string( forKey: UserDefaultKeys.nasDescriptor ) {
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
            
            userDefaults.set( descriptorString, forKey: UserDefaultKeys.nasDescriptor )
            userDefaults.synchronize()
        }
        
    }
    
    
    var sortDescriptor: (String, Bool) {
        get {
            if let descriptorString = userDefaults.string(forKey: UserDefaultKeys.currentSortOption ) {
                let sortComponents = descriptorString.components(separatedBy: GlobalConstants.separatorForSorts )
                
                if sortComponents.count == 2 {
                    let     option    = sortComponents[0]
                    let     direction = ( sortComponents[1] == GlobalConstants.sortAscendingFlag )
                    
                    return ( option, direction )
                }

            }
                
            return ( SortOptions.byName, true )
        }
        
        set ( sortTuple ) {
            let descriptorString = sortTuple.0 + GlobalConstants.separatorForSorts + ( sortTuple.1 ? GlobalConstants.sortAscendingFlag : GlobalConstants.sortDescendingFlag )
           
            userDefaults.set( descriptorString, forKey: UserDefaultKeys.currentSortOption )
            userDefaults.synchronize()
        }
        
    }
    
    
    
    // MARK: Private Variables
    
    private var databaseUpdated             = false
    private var dataStoreLocationBacking    = DataStoreLocation.notAssigned
    private var locationManager             : CLLocationManager?
    private var newPinGuid                  = ""
    private var updateTimer                 : Timer!

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

    
    
    // MARK: Definitions shared with CommonExtensions

    struct Constants {
        static let databaseModel = "MyPins"
        static let primedFlag    = "Primed"
        static let timerDuration = Double( 300 )
    }
    
    struct OfflineImageRequestCommands {
        static let delete = 1
        static let fetch  = 2
        static let save   = 3
    }
    
    var backgroundTaskID        : UIBackgroundTaskIdentifier = .invalid
    var cloudCentral            = CloudCentral.sharedInstance
    var delegate                : PinCentralDelegate?
    let deviceAccessControl     = DeviceAccessControl.sharedInstance
    let fileManager             = FileManager.default
    var imageRequestQueue       : [(String, PinCentralDelegate)] = []       // This queue is used to serialize transactions while online (both iCloud and NAS)
    var managedObjectContext    : NSManagedObjectContext!
    var nasCentral              = NASCentral.sharedInstance
    var notificationCenter      = NotificationCenter.default
    var offlineImageRequestQueue: [ImageRequest] = []                       // This queue is used to flush offline NAS image transactions to disk after we reconnect
    var persistentContainer     : NSPersistentContainer!
    var transferInProgress      = false
    let userDefaults            = UserDefaults.standard

    
    var updatedOffline: Bool {
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
        
        notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.enteringBackground ), object: self )
        stopTimer()
        locationManager?.stopUpdatingLocation()
    }
    
    
    func enteringForeground() {
        logTrace()
        resigningActive = false
        
        notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.enteringForeground ), object: self )
        canSeeExternalStorage()     // TODO: See if we need to check stayOffline
        locationManager?.startUpdatingLocation()
    }
    
    
    
    // MARK: Database Access Methods (Public)
    
    func openDatabaseWith(_ delegate: PinCentralDelegate ) {
        
        if openInProgress {
            logTrace( "openInProgress ... do nothing" )
            return
        }
        
        if deviceAccessControl.updating {
            logVerbose( "Updating ... try again later\n    %@", deviceAccessControl.descriptor() )
            return
        }
        
        logTrace()
        self.delegate       = delegate
        didOpenDatabase     = false
        openInProgress      = true
        pinArrayOfArrays    = Array.init()
        persistentContainer = NSPersistentContainer( name: Constants.databaseModel )
        
        persistentContainer.loadPersistentStores( completionHandler:
        { ( storeDescription, error ) in
            
            if let error = error as NSError? {
                logVerbose( "Unresolved error[ %@ ]", error.localizedDescription )
            }
            else {
                self.loadCoreData()
                
                if !self.didOpenDatabase {      // This is just in case I screw up and don't properly version the data model
                    self.deleteDatabase()       // TODO: Figure out if this is the right thing to do
                    self.loadCoreData()
                }
                
                self.loadBasicData()
                self.setupLocationManager()
                
                self.startTimer()
            }
            
            DispatchQueue.main.asyncAfter( deadline: ( .now() + 0.2 ), execute:  {
                logVerbose( "didOpenDatabase[ %@ ]", stringFor( self.didOpenDatabase ) )
                
                self.openInProgress = false
                self.delegate?.pinCentral( self, didOpenDatabase: self.didOpenDatabase )
                
                if self.updatedOffline && !self.stayOffline {
                    self.persistentContainer.viewContext.perform {
                        self.processNextOfflineImageRequest()
                    }
                    
                }
                
            } )
            
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
            let     pin = NSEntityDescription.insertNewObject( forEntityName: EntityNames.pin , into: self.managedObjectContext ) as! Pin
            
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
    
    
    func deletePinAt(_ indexPath: IndexPath, _ delegate: PinCentralDelegate ) {
        if !self.didOpenDatabase {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logVerbose( "deleting pin at [ %@ ]", stringFor( indexPath ) )
        self.delegate = delegate
        
        persistentContainer.viewContext.perform {
            let     pin = self.pinAt( indexPath )
            
            self.managedObjectContext.delete( pin )
            self.saveContext()
            self.refetchPinsAndNotifyDelegate()
        }
        
    }
    
    
    func displayUnits() -> String {
        var         units = DisplayUnits.meters
        
        if let displayUnits = userDefaults.string( forKey: DisplayUnits.altitude ) {
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
    
    
    func nameForSortType(_ sortType: String ) -> String {
        var name = "Unknown"
        
        switch sortType {
        case SortOptions.byDateLastModified: name = SortOptionNames.byDateLastModified
        case SortOptions.byType:             name = SortOptionNames.byType
        case SortOptions.byName:             name = SortOptionNames.byName
        default:                             break
        }
        
        return name
    }
    
    
    func pinAt(_ indexPath: IndexPath ) -> Pin {
        let sectionArray = pinArrayOfArrays[indexPath.section]
        
        return sectionArray[indexPath.row]
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

    
    
    // MARK: Methods shared with CommonExtensions (Public)

    func nameForImageRequest(_ command: Int ) -> String {
        var     name = "Unknown"
        
        switch command {
        case OfflineImageRequestCommands.delete:    name = "Delete"
        case OfflineImageRequestCommands.fetch:     name = "Fetch"
        default:                                    name = "Save"
        }
        
        return name
    }

    
    func pictureDirectoryPath() -> String {
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
    func processNextOfflineImageRequest() {
        if offlineImageRequestQueue.isEmpty {
            logTrace( "Done!" )
            updatedOffline = false
            
            if backgroundTaskID != UIBackgroundTaskIdentifier.invalid {
                nasCentral.unlockNas( self )
            }

            deviceAccessControl.updating = false
            
            notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )
        }
        else {
            guard let imageRequest = offlineImageRequestQueue.first else {
                logTrace( "ERROR!  Unable to remove request from front of queue!" )
                updatedOffline = false
                return
            }
            
            let command  = Int( imageRequest.command )
            let filename = imageRequest.filename ?? "Empty!"
            
            logVerbose( "pending[ %d ]  processing[ %@ ][ %@ ]", offlineImageRequestQueue.count, nameForImageRequest( command ), filename )
            
            switch command {
                case OfflineImageRequestCommands.delete:    nasCentral.deleteImage( filename, self )
                
//                case OfflineImageRequestCommands.fetch:     imageRequestQueue.append( (filename, delegate! ) )
//                                                            nasCentral.fetchImage( filename, self )

                case OfflineImageRequestCommands.save:      let result = fetchFromDiskImageFileNamed( filename )
                
                                                            if result.0 {
                                                                nasCentral.saveImageData( result.1, filename: filename, self )
                                                            }
                                                            else {
                                                                logVerbose( "ERROR!  NAS does NOT have [ %@ ]", filename )
                                                                DispatchQueue.main.async {
                                                                    self.processNextOfflineImageRequest()
                                                                }
                                                                
                                                            }
                default:    break
            }
            
            managedObjectContext.delete( imageRequest )
            offlineImageRequestQueue.remove( at: 0 )

            saveContext()
        }
        
    }


    func saveContext() {        // Must be called from within a persistentContainer.viewContext
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

    

    // MARK: Utility Methods (Private)
    
    private func canSeeExternalStorage() {
        if dataStoreLocation == .device {
            deviceAccessControl.initForDevice()
            logVerbose( "on device\n    %@", deviceAccessControl.descriptor() )
            return
        }
            
        logVerbose( "[ %@ ]", nameForDataStoreLocation( dataStoreLocation ) )

        if dataStoreLocation == .iCloud || dataStoreLocation == .shareCloud {
            cloudCentral.canSeeCloud( self )
        }
        else {  // NAS
            if didOpenDatabase && updatedOffline {
                self.persistentContainer.viewContext.perform {
                    self.fetchAllImageRequestObjects()
                }
                
            }

            nasCentral.emptyQueue()
            nasCentral.canSeeNasFolders( self )
        }

        notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.connectingToExternalDevice ), object: self )
    }
    
    
    private func deleteDatabase() {
        guard let docURL = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).last else {
            logTrace( "Error!  Unable to resolve document directory" )
            return
        }
        
        let     storeURL = docURL.appendingPathComponent( Filenames.database )
        
        do {
            logVerbose( "attempting to delete database @ [ %@ ]", storeURL.path )
            try fileManager.removeItem( at: storeURL )
            
            userDefaults.removeObject( forKey: Constants.primedFlag )
            userDefaults.synchronize()
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
        
        // TODO: Watch for crash here
        logVerbose( "Found [ %d ] requests", offlineImageRequestQueue.count )
    }
    

    // Must be called from within persistentContainer.viewContext
    private func fetchAllPins() {
        newPinIndexPath    = GlobalIndexPaths.newPin
        pinArrayOfArrays   = [[]]
        numberOfPinsLoaded = 0

        do {
            let     request : NSFetchRequest<Pin> = Pin.fetchRequest()
            let     fetchedPins = try managedObjectContext.fetch( request )
            
            logVerbose( "Retrieved %d pins ... sorting", fetchedPins.count )
            numberOfPinsLoaded = fetchedPins.count
            
            let sortTuple     = sortDescriptor
            let sortAscending = sortTuple.1
            let sortOption    = sortTuple.0

            switch sortOption {
            case SortOptions.byType:                sortByType(             fetchedPins, sortAscending )
            case SortOptions.byDateLastModified:    sortByDateLastModified( fetchedPins, sortAscending )
            default:                                sortByName(             fetchedPins, sortAscending )
            }
            
            var section        = 0
            var stillSearching = true

            while section < pinArrayOfArrays.count && stillSearching {
                let sectionArray = pinArrayOfArrays[section]
                
                for row in 0..<sectionArray.count {
                    if sectionArray[row].guid == newPinGuid {
                        newPinIndexPath = IndexPath(row: row, section: section )
                        stillSearching  = false
                        break
                    }
                    
                }

                section += 1
            }
            
        }
            
        catch {
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
            
            logVerbose( "Loaded Color[ %d ] & ImageRequest[ %d ] objects", self.colorArray.count, self.offlineImageRequestQueue.count )
        }
        
    }


    private func loadCoreData() {
        guard let modelURL = Bundle.main.url( forResource: Constants.databaseModel, withExtension: "momd" ) else {
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
    
    
    // Must be called from within a persistentContainer.viewContext
    private func refetchPinsAndNotifyDelegate() {
        fetchAllPins()

        DispatchQueue.main.async {
            self.delegate?.pinCentralDidReloadPinArray( self )
        }

        if .pad == UIDevice.current.userInterfaceIdiom {
            notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.pinsArrayReloaded ), object: self )
        }

    }
    

    private func setupLocationManager() {
        locationManager = CLLocationManager()
        
        if CLLocationManager.locationServicesEnabled() {
            locationManager?.delegate = self
            locationManager?.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
            locationManager?.startUpdatingLocation()
        }
        
        currentAltitude = 0.0
        currentLocation = CLLocationCoordinate2DMake( 0.0, 0.0 )
    }

    
    private func sortByDateLastModified(_ fetchedPins: [Pin], _ sortAscending: Bool ) {
        logVerbose( "sortAscending[ %@ ]", stringFor( sortAscending ) )
        let sortedArray = fetchedPins.sorted( by:
                    { (pin1, pin2) -> Bool in
                        if sortAscending {
                            pin1.lastModified! < pin2.lastModified!
                        }
                        else {
                            pin1.lastModified! > pin2.lastModified!
                        }
            
                    } )

        pinArrayOfArrays = [sortedArray]
    }
    
    
    private func sortByName(_ fetchedPins: [Pin], _ sortAscending: Bool ) {
        logVerbose( "sortAscending[ %@ ]", stringFor( sortAscending ) )
        let sortedArray = fetchedPins.sorted( by:
                    { (pin1, pin2) -> Bool in
                        if sortAscending {
                            pin1.name! < pin2.name!     // We can do this because the name is a required field that must be unique
                        }
                        else {
                            pin1.name! > pin2.name!
                        }
            
                    } )
        
        pinArrayOfArrays = [sortedArray]
    }
    
    
    private func sortByType(_ fetchedPins: [Pin], _ sortAscending: Bool ){
        logVerbose( "sortAscending[ %@ ]", stringFor( sortAscending ) )
        let sortedArray = fetchedPins.sorted( by:
                    { (pin1, pin2) -> Bool in
                        if sortAscending {
                            pin1.pinColor < pin2.pinColor
                        }
                        else {
                            pin1.pinColor > pin2.pinColor
                        }
            
                    } )
        
        let delta        = sortAscending ? 1 : -1
        var index        = 0
        var section      = sortAscending ? 0 : ( colorArray.count - 1 )
        var sectionArray = [Pin]()
        
//        logVerbose( "Starting with [ %@ ]", colorArray[section].descriptor! )
        while index < sortedArray.count {
            let pin = sortedArray[index]
            
            if pin.pinColor == section {
                sectionArray.append( pin )
//                logVerbose( "Section [ %d ][ %@ ] Added [ %@ ][ %@ ]", section, pinColorNameArray[ section ], pinColorNameArray[ Int( pin.pinColor ) ], pin.name! )
                index += 1
            }
            else {
                sectionArray = sectionArray.sorted( by:
                            { (pin1, pin2) -> Bool in
                                if sortAscending {
                                    pin1.name! < pin2.name!
                                }
                                else {
                                    pin1.name! > pin2.name!
                                }
                    
                            } )
                
//                logVerbose( "Added an array of %d pins to section %d [ %@ / %@ ]", sectionArray.count, section, pinColorNameArray[section], colorArray[section].descriptor! )
                pinArrayOfArrays.append( sectionArray )
                sectionArray = []
                section = section + delta
            }
            
        }
        
            // Pick up the last section
//        logVerbose( "Added an array of %d pins to section %d [ %@ / %@ ]", sectionArray.count, section, pinColorNameArray[section], colorArray[section].descriptor! )
        pinArrayOfArrays.append( sectionArray )

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



// MARK: Timer Methods (Public)

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
                    logVerbose( "databaseUpdated[ true ]\n    %@", self.deviceAccessControl.descriptor() )
                    
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
        
        logVerbose( "databaseUpdated[ %@ ]\n    %@", stringFor( databaseUpdated ), deviceAccessControl.descriptor() )
        
        if databaseUpdated {
            
            if !stayOffline {
                DispatchQueue.global().async {
                    self.backgroundTaskID = UIApplication.shared.beginBackgroundTask( withName: "Finish copying DB to External Device" ) {
                        // The OS calls this block if we don't finish in time
                        logTrace( "We ran out of time!  Killing background task..." )
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
            
            if !stayOffline {
                DispatchQueue.global().async {
                    self.backgroundTaskID = UIApplication.shared.beginBackgroundTask( withName: "Remove lock file" ) {
                        // The OS calls this block if we don't finish in time
                        logTrace( "We ran out of time!  Killing background task #2..." )
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
 
    
}

