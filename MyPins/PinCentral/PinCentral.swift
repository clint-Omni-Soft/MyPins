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



protocol PinCentralDelegate: class
{
    func pinCentral( pinCentral: PinCentral,
                     didOpenDatabase: Bool )
    
    func pinCentralDidReloadPinArray( pinCentral: PinCentral )
}



class PinCentral: NSObject,
                  CLLocationManagerDelegate
{
    // MARK: Public Variables
    weak var delegate:      PinCentralDelegate?

    var currentAltitude       = 0.0
    var currentLocation       = CLLocationCoordinate2DMake( 0.0, 0.0 )
    var didOpenDatabase       = false
    var indexOfSelectedPin    = NO_SELECTION
    var locationEstablished   = false
    var newPinIndex           = NEW_PIN
    var pinArray              = [Pin].init()

    
    // MARK: Private Variables
    private let DATABASE_NAME   = "PinsDB.sqlite"
    private let ENTITY_NAME_PIN = "Pin"
    
    private var locationManager      : CLLocationManager?
    private var managedObjectContext : NSManagedObjectContext!
    private var newPinGuid           = ""
    private var persistentContainer  : NSPersistentContainer!

    
    
    // MARK: Our Singleton
    
    static let sharedInstance = PinCentral()        // Prevents anyone else from creating an instance


    
    // MARK: Database Access Methods (Public)
    
    func openDatabase()
    {
        logTrace()
        didOpenDatabase     = false
        pinArray            = Array.init()
        persistentContainer = NSPersistentContainer( name: "MyPins" )
        
        persistentContainer.loadPersistentStores( completionHandler:
        { ( storeDescription, error ) in
            
            if let error = error as NSError?
            {
                logVerbose( "Unresolved error[ %@ ]", error.localizedDescription )
            }
            else
            {
                self.loadCoreData()
                
                if !self.didOpenDatabase    // This is just in case I screw up and don't properly version the data model
                {
                    self.deleteDatabase()
                    self.loadCoreData()
                }

                self.locationManager = CLLocationManager()
                
                if CLLocationManager.locationServicesEnabled()
                {
                    self.locationManager?.delegate = self
                    self.locationManager?.desiredAccuracy = kCLLocationAccuracyNearestTenMeters
                    self.locationManager?.startUpdatingLocation()
                }
                
                self.currentAltitude = 0.0
                self.currentLocation = CLLocationCoordinate2DMake( 0.0, 0.0 )
            }
            
            DispatchQueue.main.async
            {
                logVerbose( "didOpenDatabase[ %@ ]", stringFor( self.didOpenDatabase ) )
                self.delegate?.pinCentral( pinCentral: self, didOpenDatabase: self.didOpenDatabase )
            }
            
        } )

    }
    
    
    
    // MARK: Pin Access/Modifier Methods (Public)
    
    func addPin( name:      String,
                 details:   String,
                 latitude:  Double,
                 longitude: Double,
                 altitude:  Double,
                 imageName: String,
                 pinColor:  Int16 )
    {
        if !self.didOpenDatabase
        {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logVerbose( "[ %@ ][ %@ ]", name, details )

        persistentContainer.viewContext.perform
        {
            let     pin = NSEntityDescription.insertNewObject( forEntityName: self.ENTITY_NAME_PIN, into: self.managedObjectContext ) as! Pin
            
            
            pin.altitude        = altitude
            pin.details         = details
            pin.guid            = UUID().uuidString
            pin.imageName       = imageName
            pin.lastModified    = NSDate.init()
            pin.latitude        = latitude
            pin.longitude       = longitude
            pin.name            = name
            pin.pinColor        = pinColor
            
            self.newPinGuid = pin.guid ?? "Unwrapping Failed"
            
            self.saveContext()
            self.refetchPinsAndNotifyDelegate()
        }
        
    }
    
    
    func deletePinAtIndex( index: Int )
    {
        if !self.didOpenDatabase
        {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        persistentContainer.viewContext.perform
        {
            logVerbose( "deleting pin at [ %d ]", index )
            let     pin = self.pinArray[index]
            
            
            self.managedObjectContext.delete( pin )
            self.saveContext()
            self.refetchPinsAndNotifyDelegate()
        }
        
    }
    
    
    func fetchPins()
    {
        if !self.didOpenDatabase
        {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logTrace()
        
        persistentContainer.viewContext.perform
        {
            self.refetchPinsAndNotifyDelegate()
        }
        
    }
    
    
    func saveUpdatedPin( pin: Pin )
    {
        if !self.didOpenDatabase
        {
            logTrace( "ERROR!  Database NOT open yet!" )
            return
        }
        
        logTrace()

        persistentContainer.viewContext.perform
        {
            self.saveContext()
            self.refetchPinsAndNotifyDelegate()
        }
        
    }
    
    
    
    // MARK: Image Convenience Methods (Public)
    
    func deleteImageWith( name: String ) -> Bool
    {
//        logTrace()
        let         directoryPath = pictureDirectoryPath()
        
        
        if !directoryPath.isEmpty
        {
            let     picturesDirectoryURL = URL.init( fileURLWithPath: directoryPath )
            let     imageFileURL         = picturesDirectoryURL.appendingPathComponent( name )


            do
            {
                try FileManager.default.removeItem( at: imageFileURL )
                
                logVerbose( "deleted image named [ %@ ]", name )
                return true
            }
                
            catch let error as NSError
            {
                logVerbose( "ERROR!  Failed to delete image named [ %@ ] ... Error[ %@ ]", name, error.localizedDescription )
            }
            
        }
        
        return false
    }
    
    
    func displayUnits() -> String
    {
        var         units = DISPLAY_UNITS_METERS
        
        
        if let displayUnits = UserDefaults.standard.string( forKey: DISPLAY_UNITS_ALTITUDE )
        {
            if !displayUnits.isEmpty
            {
                units = displayUnits
            }
            
        }
        
        return units
    }
    
    
    func imageWith( name: String ) -> UIImage
    {
//        logTrace()
        let         directoryPath = pictureDirectoryPath()

        
        if !directoryPath.isEmpty
        {
            let     picturesDirectoryURL = URL.init( fileURLWithPath: directoryPath )
            let     imageFileURL         = picturesDirectoryURL.appendingPathComponent( name )
            let     imageFileData        = FileManager.default.contents( atPath: imageFileURL.path )
            
            
            if let imageData = imageFileData
            {
                if let image = UIImage.init( data: imageData )
                {
//                    logVerbose( "Loaded image named [ %@ ]", name )
                    return image
                }
                
            }
            else
            {
                logVerbose( "ERROR!  Failed to load data for image [ %@ ]", name )
            }
            
        }
        else
        {
            logVerbose( "ERROR!  directoryPath is Empty!" )
        }
        
        return UIImage.init()
    }
    
    
    func saveImage( image: UIImage ) -> String
    {
//        logTrace()
        let         directoryPath = pictureDirectoryPath()
        
        
        if directoryPath.isEmpty
        {
            return String.init()
        }
        
        
        let     imageFilename        = UUID().uuidString
        let     picturesDirectoryURL = URL.init( fileURLWithPath: directoryPath )
        let     pictureFileURL       = picturesDirectoryURL.appendingPathComponent( imageFilename )
        
        
        guard let imageData = UIImageJPEGRepresentation( image, 1 ) ?? UIImagePNGRepresentation( image ) else
        {
            logTrace( "ERROR!  Could NOT convert UIImage to Data!" )
            return String.init()
        }
        
        do
        {
            try imageData.write( to: pictureFileURL, options: .atomic )
            
            logVerbose( "Saved image to file named[ %@ ]", imageFilename )
            return imageFilename
        }
            
        catch let error as NSError
        {
            logVerbose( "ERROR!  Failed to save image for [ %@ ] ... Error[ %@ ]", imageFilename, error.localizedDescription )
        }
        
        return String.init()
    }
    
    

    // MARK: CLLocationManagerDelegate Methods
    
    func locationManager(_ manager: CLLocationManager,
                           didUpdateLocations locations: [CLLocation] )
    {
        guard let currentLocation: CLLocationCoordinate2D = manager.location?.coordinate else
        {
            logVerbose( "ERROR!  Failed to extract currentLocation" )
            return
        }
        
        guard let currentAltitude = locations.last?.altitude else
        {
            logVerbose( "ERROR!  Failed to extract currentAltitude" )
            return
        }
        
        self.currentLocation = currentLocation
        self.currentAltitude = currentAltitude
        
        if !locationEstablished
        {
            locationEstablished = true
            
            logVerbose( "locationEstablished @ [ %f, %f ][ %f ]", currentLocation.latitude, currentLocation.longitude, currentAltitude )
        }

    }
    
    
    
    // MARK: Utility Methods
    
    private func deleteDatabase()
    {
        guard let docURL = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).last else
        {
            logTrace( "Error!  Unable to resolve document directory" )
            return
        }
        
        
        let     storeURL = docURL.appendingPathComponent( DATABASE_NAME )
        
        
        do
        {
            try FileManager.default.removeItem( at: storeURL )
            logVerbose( "deleted database @ [ %@ ]", storeURL.path )
        }
        
        catch
        {
            let     nsError = error as NSError
            
            
            logVerbose( "Error!  Unable delete store! ... Error[ %@ ]", nsError.localizedDescription )
        }
        
    }
    
    
    private func description() -> String
    {
        return "PinCentral"
    }
    
    
    private func fetchAllPinObjects()     // Must be called from within persistentContainer.viewContext
    {
        do
        {
            let     request : NSFetchRequest<Pin> = Pin.fetchRequest()
            let     fetchedPins = try managedObjectContext.fetch( request )
        
            
            pinArray = fetchedPins.sorted( by:
                        { (pin1, pin2) -> Bool in
                    
                            pin1.name! < pin2.name!     // We can do this because the name is a required field that must be unique
                        } )
            
            newPinIndex = NEW_PIN
            
            for index in 0..<self.pinArray.count
            {
                if pinArray[index].guid == newPinGuid
                {
                    newPinIndex = index
                    break
                }
                
            }
            
        }
            
        catch
        {
            pinArray = [Pin]()
            logTrace( "Error!  Fetch failed!" )
        }
        
    }
    
    
    private func loadCoreData()
    {
        guard let modelURL = Bundle.main.url( forResource: "MyPins", withExtension: "momd" ) else
        {
            logTrace( "Error!  Could NOT load model from bundle!" )
            return
        }
        
        logVerbose( "modelURL[ %@ ]", modelURL.path )

        guard let managedObjectModel = NSManagedObjectModel( contentsOf: modelURL ) else
        {
            logVerbose( "Error!  Could NOT initialize managedObjectModel from URL[ %@ ]", modelURL.path )
            return
        }
        
        
        let     persistentStoreCoordinator = NSPersistentStoreCoordinator( managedObjectModel: managedObjectModel )

    
        managedObjectContext = NSManagedObjectContext( concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType )
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        guard let docURL = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).last else
        {
            logTrace( "Error!  Unable to resolve document directory!" )
            return
        }
        
        
        let     storeURL = docURL.appendingPathComponent( DATABASE_NAME )
        
        
        logVerbose( "storeURL[ %@ ]", storeURL.path )

        do
        {
            try persistentStoreCoordinator.addPersistentStore( ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil )
            
            self.didOpenDatabase = true
//            logTrace( "added Pins store to coordinator" )
        }
            
        catch
        {
            let     nsError = error as NSError
            
            
            logVerbose( "Error!  Unable migrate store[ %@ ]", nsError.localizedDescription )
        }
        
    }
    
    
    private func pictureDirectoryPath() -> String
    {
        let         fileManager = FileManager.default
        
        
        if let documentDirectoryURL = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).first
        {
            let     picturesDirectoryURL = documentDirectoryURL.appendingPathComponent( "PinPictures" )
            
            
            if !fileManager.fileExists( atPath: picturesDirectoryURL.path )
            {
                do
                {
                    try fileManager.createDirectory( atPath: picturesDirectoryURL.path, withIntermediateDirectories: true, attributes: nil )
                }
                catch let error as NSError
                {
                    logVerbose( "ERROR!  Failed to create photos directory ... Error[ %@ ]", error.localizedDescription )
                    return String.init()
                }
                
            }
            
            if !fileManager.fileExists( atPath: picturesDirectoryURL.path )
            {
                logTrace( "ERROR!  photos directory does NOT exist!" )
                return String.init()
            }
            
//            logVerbose( "picturesDirectory[ %@ ]", picturesDirectoryURL.path )
            return picturesDirectoryURL.path
        }
        
//        logTrace( "ERROR!  Could NOT find the documentDirectory!" )
        return String.init()
    }
    
    
    private func refetchPinsAndNotifyDelegate()       // Must be called from within a persistentContainer.viewContext
    {
        fetchAllPinObjects()
        
        DispatchQueue.main.async
        {
            self.delegate?.pinCentralDidReloadPinArray( pinCentral: self )
        }

        if .pad == UIDevice.current.userInterfaceIdiom
        {
            NotificationCenter.default.post( name: NSNotification.Name( rawValue: NOTIFICATION_PINS_UPDATED ), object: self )
        }

    }
    

    private func saveContext()
    {
        if managedObjectContext.hasChanges
        {
            do
            {
                try managedObjectContext.save()
            }
            catch
            {
                let     nsError = error as NSError
                
                
                logVerbose( "Unresolved error[ %@ ]", nsError.localizedDescription )
            }
            
        }
        
    }
    
    
}



// MARK: Public Definitions & Utility Methods

struct PinColors
{
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


let DISPLAY_UNITS_ALTITUDE      = "DisplayUnitsAltitude"
let DISPLAY_UNITS_FEET          = "ft"
let DISPLAY_UNITS_METERS        = "m"
let FEET_PER_METER              = 3.28084
let NEW_PIN                     = -1
let NO_SELECTION                = -1
let NOTIFICATION_CENTER_MAP     = "CenterMap"
let NOTIFICATION_PINS_UPDATED   = "PinsUpdated"
let USER_INFO_LATITUDE          = "Latitude"
let USER_INFO_LONGITUDE         = "Longitude"



func viewControllerWithStoryboardId( storyboardId: String ) -> UIViewController
{
    logVerbose( "[ %@ ]", storyboardId )
    let     storyboardName = ( ( .pad == UIDevice.current.userInterfaceIdiom ) ? "Main_iPad" : "Main_iPhone" )
    let     storyboard     = UIStoryboard.init( name: storyboardName, bundle: nil )
    let     viewController = storyboard.instantiateViewController( withIdentifier: storyboardId )
    
    
    return viewController
}


func iPhoneViewControllerWithStoryboardId( storyboardId: String ) -> UIViewController
{
    logVerbose( "[ %@ ]", storyboardId )
    let     storyboardName = "Main_iPhone"
    let     storyboard     = UIStoryboard.init( name: storyboardName, bundle: nil )
    let     viewController = storyboard.instantiateViewController( withIdentifier: storyboardId )
    
    
    return viewController
}


