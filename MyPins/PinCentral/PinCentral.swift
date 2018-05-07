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
    let DATABASE_NAME               = "PinsDB.sqlite"
    let DISPLAY_UNITS_ALTITUDE      = "DisplayUnitsAltitude"
    let ENTITY_NAME_PIN             = "Pin"
    let NEW_PIN                     = -1
    let NOTIFICATION_CENTER_MAP     = "CenterMap"
    let NOTIFICATION_PINS_UPDATED   = "PinsUpdated"
    let USER_INFO_LATITUDE          = "Latitude"
    let USER_INFO_LONGITUDE         = "Longitude"
    
    
    weak var delegate:      PinCentralDelegate?

    var     currentAltitude:        Double?
    var     currentLocation:        CLLocationCoordinate2D?
    var     didOpenDatabase       = false
    var     indexOfSelectedPin:     Int?
    var     locationEstablished   = false
    var     newPinIndex:            Int?
    var     pinArray: [Pin]?      = Array.init()

    private var     locationManager:        CLLocationManager?
    private var     managedObjectContext:   NSManagedObjectContext!
    private var     newPinGuid:             String?
    private var     persistentContainer:    NSPersistentContainer!

    
    
    // MARK: Our Singleton
    
    static let sharedInstance = PinCentral()        // Prevents anyone else from creating an instance


    
    // MARK: Database Access Methods
    
    func openDatabase()
    {
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "Begin" )
        didOpenDatabase     = false
        pinArray            = Array.init()
        persistentContainer = NSPersistentContainer( name: "MyPins" )
        
        persistentContainer.loadPersistentStores( completionHandler:
        { ( storeDescription, error ) in
            
            if let error = error as NSError?
            {
                NSLog( "%@:%@[%d] - Unresolved error[ %@ ][ %@ ]", self.description(), #function, #line, error, error.userInfo )
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
                NSLog( "%@:%@[%d] - didOpenDatabase[ %@ ]", self.description(), #function, #line, stringForBool( boolValue: self.didOpenDatabase ) )
                self.delegate?.pinCentral( pinCentral: self, didOpenDatabase: self.didOpenDatabase )
            }
            
        } )

    }
    
    
    
    // MARK: Pin Access/Modifier Methods
    
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
            NSLog( "%@:%@[%d] - ERROR!  Database NOT open yet!", description(), #function, #line )
            return
        }
        
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )

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
            
            self.newPinGuid = pin.guid
            
            self.saveContext()
            self.refetchPinsAndNotifyDelegate()
        }
        
    }
    
    
    func deletePinAtIndex( index: Int )
    {
        if !self.didOpenDatabase
        {
            NSLog( "%@:%@[%d] - ERROR!  Database NOT open yet!", description(), #function, #line )
            return
        }
        
        persistentContainer.viewContext.perform
        {
            NSLog( "%@:%@[%d] - deleting pin at [ %d ]", self.description(), #function, #line, index )
            let     pin = self.pinArray![index]
            
            
            self.managedObjectContext.delete( pin )
            self.saveContext()
            self.refetchPinsAndNotifyDelegate()
        }
        
    }
    
    
    func fetchPins()
    {
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )
        if !self.didOpenDatabase
        {
            NSLog( "%@:%@[%d] - ERROR!  Database NOT open yet!", description(), #function, #line )
            return
        }
        
        persistentContainer.viewContext.perform
        {
            self.refetchPinsAndNotifyDelegate()
        }
        
    }
    
    
    func saveUpdatedPin( pin: Pin )
    {
        if !self.didOpenDatabase
        {
            NSLog( "%@:%@[%d] - ERROR!  Database NOT open yet!", description(), #function, #line )
            return
        }
        
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )

        persistentContainer.viewContext.perform
        {
            self.saveContext()
            self.refetchPinsAndNotifyDelegate()
        }
        
    }
    
    
    
    // MARK: Image Convenience Methods
    
    func deleteImageWith( name: String ) -> Bool
    {
//        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )
        let         directoryPath = pictureDirectoryPath()
        
        
        if !directoryPath.isEmpty
        {
            let     picturesDirectoryURL = URL.init( fileURLWithPath: directoryPath )
            let     imageFileURL         = picturesDirectoryURL.appendingPathComponent( name )


            do
            {
                try FileManager.default.removeItem( at: imageFileURL )
                
                NSLog( "%@:%@[%d] - deleted image named [ %@ ]", self.description(), #function, #line, name )
                return true
            }
                
            catch let error as NSError
            {
                NSLog( "%@:%@[%d] - ERROR!  Failed to delete image named [ %@ ] ... Reason[ %@ ]", self.description(), #function, #line, name, error.localizedDescription )
            }
            
        }
        
        return false
    }
    
    
    func displayUnits() -> String
    {
        var         units = DISPLAY_UNITS_METERS
        
        
        if let displayUnits = UserDefaults.standard.string( forKey: PinCentral.sharedInstance.DISPLAY_UNITS_ALTITUDE )
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
//        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )
        let         directoryPath = pictureDirectoryPath()

        
        if !directoryPath.isEmpty
        {
            let     picturesDirectoryURL = URL.init( fileURLWithPath: directoryPath )
            let     imageFileURL         = picturesDirectoryURL.appendingPathComponent( name )
            let     imageFileData        = FileManager.default.contents( atPath: imageFileURL.path )
            
            
            if let image = UIImage.init( data: imageFileData! )
            {
//                NSLog( "%@:%@[%d] - Loaded image named [ %@ ]", self.description(), #function, #line, name )
                return image
            }
            
        }
        
        NSLog( "%@:%@[%d] - ERROR!  Failed to load image for [ %@ ]", self.description(), #function, #line, name )
        
        return UIImage.init()
    }
    
    
    func saveImage( image: UIImage ) -> String
    {
//        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )
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
            NSLog( "%@:%@[%d] - ERROR!  Could NOT convert UIImage to Data!", self.description(), #function, #line )
            return String.init()
        }
        
        do
        {
            try imageData.write( to: pictureFileURL, options: .atomic )
            
            NSLog( "%@:%@[%d] - Saved image to file named[ %@ ]", description(), #function, #line, imageFilename )
            return imageFilename
        }
            
        catch let error as NSError
        {
            NSLog( "%@:%@[%d] - ERROR!  Failed to save image named [ %@ ] ... Reason[ %@ ]", self.description(), #function, #line, imageFilename, error.localizedDescription )
        }
        
        return String.init()
    }
    
    

    // MARK: CLLocationManagerDelegate Methods
    
    func locationManager(_ manager: CLLocationManager,
                           didUpdateLocations locations: [CLLocation] )
    {
        guard let currentLocation: CLLocationCoordinate2D = manager.location?.coordinate else
        {
            return
        }
        
        self.currentAltitude = locations.last?.altitude
        self.currentLocation = currentLocation
        
        if !locationEstablished
        {
            locationEstablished = true
            
            NSLog( "%@:%@[%d] - locationEstablished @ [ %f, %f ][ %f ]", description(), #function, #line, currentLocation.latitude, currentLocation.longitude, currentAltitude! )
        }

    }
    
    
    
    // MARK: Utility Methods
    
    private func deleteDatabase()
    {
        guard let docURL = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).last else
        {
            NSLog( "%@:%@[%d] - Error!  Unable to resolve document directory", self.description(), #function, #line )
            return
        }
        
        
        let     storeURL = docURL.appendingPathComponent( DATABASE_NAME )
        
        
        do
        {
            try FileManager.default.removeItem( at: storeURL )
            NSLog( "%@:%@[%d] - deleted database @ [ %@ ]", self.description(), #function, #line, storeURL.path )
        }
        
        catch
        {
            let     nsError = error as NSError
            
            
            NSLog( "%@:%@[%d] - Error!  Unable delete store[ %@ ][ %@ ]", self.description(), #function, #line, nsError, nsError.userInfo )
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
                    
                            pin1.name! < pin2.name!
                        } )
            
            newPinIndex = NEW_PIN
            
            for index in 0..<self.pinArray!.count
            {
                if pinArray![index].guid == newPinGuid
                {
                    newPinIndex = index
                    break
                }
                
            }
            
        }
            
        catch
        {
            pinArray = [Pin]()
            NSLog( "%@:%@[%d] - Error!  Fetch failed!", description(), #function, #line )
        }
        
    }
    
    
    private func loadCoreData()
    {
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )

        guard let modelURL = Bundle.main.url( forResource: "MyPins", withExtension: "momd" ) else
        {
            NSLog( "%@:%@[%d] - %@", description(), #function, #line, "Error!  Could NOT load model from bundle" )
            return
        }
        
        NSLog( "%@:%@[%d] - modelURL[ %@ ]", description(), #function, #line, modelURL.path )

        guard let managedObjectModel = NSManagedObjectModel( contentsOf: modelURL ) else
        {
            NSLog( "%@:%@[%d] - Error!  Could NOT initialize managedObjectModel from URL[ %@ ]", description(), #function, #line, modelURL.path )
            return
        }
        
        
        let     persistentStoreCoordinator = NSPersistentStoreCoordinator( managedObjectModel: managedObjectModel )

    
        managedObjectContext = NSManagedObjectContext( concurrencyType: NSManagedObjectContextConcurrencyType.mainQueueConcurrencyType )
        managedObjectContext.persistentStoreCoordinator = persistentStoreCoordinator
        
        guard let docURL = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).last else
        {
            NSLog( "%@:%@[%d] - Error!  Unable to resolve document directory", self.description(), #function, #line )
            return
        }
        
        
        let     storeURL = docURL.appendingPathComponent( DATABASE_NAME )
        
        
        NSLog( "%@:%@[%d] - storeURL[ %@ ]", self.description(), #function, #line, storeURL.path )

        do
        {
            try persistentStoreCoordinator.addPersistentStore( ofType: NSSQLiteStoreType, configurationName: nil, at: storeURL, options: nil )
            
            self.didOpenDatabase = true
//            NSLog( "%@:%@[%d] - added Pins store to coordinator", self.description(), #function, #line )
        }
            
        catch
        {
            let     nsError = error as NSError
            
            
            NSLog( "%@:%@[%d] - Error!  Unable migrate store[ %@ ][ %@ ]", self.description(), #function, #line, nsError, nsError.userInfo )
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
                    NSLog( "%@:%@[%d] - ERROR!  Failed to create photos directory ... Reason[ %@ ]", self.description(), #function, #line, error.localizedDescription )
                    return String.init()
                }
                
            }
            
            if !fileManager.fileExists( atPath: picturesDirectoryURL.path )
            {
                NSLog( "%@:%@[%d] - ERROR!  photos directory does NOT exist!", self.description(), #function, #line )
                return String.init()
            }
            
//            NSLog( "%@:%@[%d] - [ %@ ]", description(), #function, #line, picturesDirectoryURL.path )
            return picturesDirectoryURL.path
        }
        
        NSLog( "%@:%@[%d] - ERROR!  Could NOT find the documentDirectoryURL!", self.description(), #function, #line )
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
                
                
                NSLog( "%@:%@[%d] - Unresolved error[ %@ ][ %@ ]", self.description(), #function, #line, nsError, nsError.userInfo )
            }
            
        }
        
    }
    
    
}



// MARK: Global Utility Methods

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

let DISPLAY_UNITS_FEET      = "ft"
let DISPLAY_UNITS_METERS    = "m"
let FEET_PER_METER          = 3.28084



func stringForBool( boolValue: Bool ) -> String
{
    return ( boolValue ? "true" : "false" )
}


func viewControllerWithStoryboardId( storyboardId: String ) -> UIViewController
{
    NSLog( "viewControllerWithStoryboardId:%@[%d] - [ %@ ]", #function, #line, storyboardId )
    let     storyboardName = ( ( .pad == UIDevice.current.userInterfaceIdiom ) ? "Main_iPad" : "Main_iPhone" )
    let     storyboard     = UIStoryboard.init( name: storyboardName, bundle: nil )
    let     viewController = storyboard.instantiateViewController( withIdentifier: storyboardId )
    
    
    return viewController
}



func iPhoneViewControllerWithStoryboardId( storyboardId: String ) -> UIViewController
{
    NSLog( "iPhoneViewControllerWithStoryboardId:%@[%d] - [ %@ ]", #function, #line, storyboardId )
    let     storyboardName = "Main_iPhone"
    let     storyboard     = UIStoryboard.init( name: storyboardName, bundle: nil )
    let     viewController = storyboard.instantiateViewController( withIdentifier: storyboardId )
    
    
    return viewController
}













// MARK: Dumpster Diving Area

/*
func addNewPinAtCurrentUserLocation()   // Should only be called iff locationEstablished == true
{
    if !self.didOpenDatabase
    {
        NSLog( "%@:%@[%d] - ERROR!  Database NOT open yet!", description(), #function, #line )
        return
    }
    
    if !self.locationEstablished
    {
        NSLog( "%@:%@[%d] - ERROR!  User's location NOT established yet!", description(), #function, #line )
        return
    }
    
    NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )
    
    persistentContainer.viewContext.perform
        {
            let     pin = NSEntityDescription.insertNewObject( forEntityName: self.ENTITY_NAME_PIN, into: self.managedObjectContext ) as! Pin
            
            
            pin.altitude        = self.currentAltitude!
            pin.details         = ""
            pin.guid            = UUID().uuidString
            pin.imageName       = ""
            pin.lastModified    = NSDate.init()
            pin.latitude        = self.currentLocation!.latitude
            pin.longitude       = self.currentLocation!.longitude
            pin.name            = "New Pin"
            
            self.newPinGuid = pin.guid
            
            self.saveContext()
            self.refetchPinsAndNotifyDelegate()
    }
    
}


// This was a test I took for YNAB
func sortedArray( inputArray: [Int] )->[Int]
{
    var myDictionary = [Int: Int]()
    
    
    for value in inputArray
    {
        myDictionary[value] = 0
    }
    
    
    let     myArray = myDictionary.keys
    
    return myArray.sorted()
}
 */














