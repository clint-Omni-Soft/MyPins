//
//  CommonExtensions.swift
//  MyPins
//
//  Created by Clint Shank on 12/19/23.
//  Copyright © 2023 Omni-Soft, Inc. All rights reserved.
//

import UIKit
import CoreData



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
            
            notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.cannotSeeExternalDevice ), object: self )
        }
        
    }
    
    
    func cloudCentral(_ cloudCentral: CloudCentral, didCompareLastUpdatedFiles: Int, lastUpdatedBy: String ) {
       logVerbose( "[ %@ ]", descriptionForCompare( didCompareLastUpdatedFiles ) )
       
        externalDeviceLastUpdatedBy = lastUpdatedBy
        
       if didCompareLastUpdatedFiles == LastUpdatedFileCompareResult.deviceIsNewer {
           if deviceAccessControl.locked && deviceAccessControl.byMe {
               deviceAccessControl.updating = true
               notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.transferringDatabase ), object: self )
               
               cloudCentral.copyDatabaseFromDeviceToCloud( self )
           }
           
       }
       else if didCompareLastUpdatedFiles == LastUpdatedFileCompareResult.cloudIsNewer {
           logTrace( "Verify that we can access all the database files before we start the tranfer" )
           missingDbFiles = []
           cloudCentral.fetchDbFiles( self )
       }
       else {  // This tells the ReceivingVC to reload the barButtonItems and table data
           transferInProgress = false
           notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )
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

        cloudCentral.unlockCloud( self )

        notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )

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

        notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )
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
        delegate?.pinCentral( self, didFetch: imageNames )  // Tailored to each implementation
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
            delegate.pinCentral( self, didFetchImage: didFetchImage, filename: filename, image : image )  // Tailored to each implementation

            if self.imageRequestQueue.count == 0 {
                self.notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )
            }

        }
        
    }
 
    
    func cloudCentral(_ cloudCentral: CloudCentral, didLockCloud: Bool ) {
        logVerbose( "didLockCloud[ %@ ]\n    %@", stringFor( didLockCloud ), deviceAccessControl.descriptor() )

        if deviceAccessControl.updating {
            notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.updatingExternalDevice ), object: self )
        }
        else if deviceAccessControl.locked && !deviceAccessControl.byMe {
            notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.externalDeviceLocked ), object: self )
        }
        else {
            cloudCentral.compareLastUpdatedFiles( self )
        }

    }
    
    
    func cloudCentral(_ cloudCentral: CloudCentral, didSaveImageData: Bool, filename: String) {
        logVerbose( "[ %@ ]", stringFor( didSaveImageData ) )
        self.delegate?.pinCentral( self, didSaveImageData: didSaveImageData )  // Tailored to each implementation
    }

    
    func cloudCentral(_ cloudCentral: CloudCentral, didStartSession: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didStartSession ) )
        
        if didStartSession {
            cloudCentral.lockCloud( self )
        }
        else {
            notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.unableToConnect ), object: self )
        }
        
    }
    
    
    func cloudCentral(_ cloudCentral: CloudCentral, didUnlockCloud: Bool) {
        logVerbose( "[ %@ ]", stringFor( didUnlockCloud ) )

        cloudCentral.endSession( self )
    }
    
    
    func cloudCentral(_ cloudCentral: CloudCentral, missingDbFiles: [String] ) {
        logVerbose( "[ %@ ]", missingDbFiles )
        self.missingDbFiles = missingDbFiles
        
        if missingDbFiles.count == 0 {
            notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.transferringDatabase ), object: self )
            didOpenDatabase = false
            
            cloudCentral.copyDatabaseFromCloudToDevice( self )
        }
        else {
            notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.cannotReadAllDbFiles ), object: self )
        }

    }
        
    
}



// MARK: Data Store Location Methods

extension PinCentral {
    
    func createLastUpdatedFile() {
        if let documentDirectoryURL = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).first {
            let     fileUrl   = documentDirectoryURL.appendingPathComponent( Filenames.lastUpdated )
            let     formatter = DateFormatter()
            
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            
            let     dateString   = formatter.string( from: Date() )
            let     outputString = dateString + GlobalConstants.separatorForLastUpdatedString + deviceName
            let     data         = outputString.data( using: .utf8 )
            
            if !fileManager.createFile( atPath: fileUrl.path, contents: data, attributes: nil ) {
                logTrace( "ERROR!  Create failed!" )
            }
            
        }
        else {
            logTrace( "ERROR!  Unable to unwrap documentDirectoryURL" )
        }
        
    }
    

    func dataStoreLocationFor(_ locationString : String ) -> DataStoreLocation {
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
    

}



// MARK: Image Convenience Methods (Public)

extension PinCentral {
    
    func createThumbnailFrom(_ imageName: String ) -> Bool {
        let directoryPath    = pictureDirectoryPath()
        var thumbNailCreated = false
        
        if directoryPath.isEmpty {
            logTrace( "ERROR!!!  directoryPath.isEmpty!" )
            return thumbNailCreated
        }
        
        let fetchResult = fetchFromDiskImageNamed( imageName )
        let imageLoaded = fetchResult.0
        
        if !imageLoaded {
           logTrace( "ERROR!!!  Unable to fetch image from disk!" )
           return thumbNailCreated
        }

        let normalizedImage      = normalize( fetchResult.1 )
        let picturesDirectoryURL = URL.init( fileURLWithPath: directoryPath )
        let thumbNailName        = GlobalConstants.thumbNailPrefix + imageName
        let pictureFileURL       = picturesDirectoryURL.appendingPathComponent( thumbNailName )
        
        guard let imageData = normalizedImage.jpegData( compressionQuality: 0.05 ) else {
            logTrace( "ERROR!  Could NOT convert UIImage to Data!" )
            return thumbNailCreated
        }
        
        do {
            try imageData.write( to: pictureFileURL, options: .atomic )
            
            logVerbose( "saved compressed image to [ %@ ]", thumbNailName )
            thumbNailCreated = true
            
            if dataStoreLocation == .iCloud || dataStoreLocation == .shareCloud {
                cloudCentral.saveImageData( imageData, filename: thumbNailName, self )
            }
            else if dataStoreLocation == .nas || dataStoreLocation == .shareNas {
                if stayOffline {
                    createImageRequestFor( OfflineImageRequestCommands.save, filename: thumbNailName )
                }
                else {
                    nasCentral.saveImageData( imageData, filename: thumbNailName, self )
                }
                
            }
            
        }
        catch let error as NSError {
            logVerbose( "ERROR!  Failed to save image for [ %@ ] ... Error[ %@ ]", thumbNailName, error.localizedDescription )
        }

        return thumbNailCreated
    }
    
    
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
                logTrace( "stayOffline!  queue request" )
                createImageRequestFor( OfflineImageRequestCommands.delete, filename: name )
            }
            else {
                logTrace( "Deleting from NAS" )
                nasCentral.deleteImage( name, self )
            }

        }
        
        return result
    }
    
    
    func downloadFromRemote(_ imageName: String, _ delegate: PinCentralDelegate ) {  // Tailored to each implementation
        logVerbose( "Requesting [ %@ ] from %@ ...", imageName, ( dataStoreLocation == .iCloud || dataStoreLocation == .shareCloud ) ? "Cloud": "NAS" )

        if dataStoreLocation == .iCloud || dataStoreLocation == .shareCloud {
            imageRequestQueue.append( (imageName, delegate ) )
            cloudCentral.fetchImage( imageName, self )
        }
        else if dataStoreLocation == .nas || dataStoreLocation == .shareNas {
            imageRequestQueue.append( (imageName, delegate ) )
            nasCentral.fetchImage( imageName, self )
        }

    }

    
    func fetchFromDiskImageFileNamed(_ name: String ) -> (Bool, Data) {
        let directoryPath = pictureDirectoryPath()
        
        if !directoryPath.isEmpty {
            let     picturesDirectoryURL = URL.init( fileURLWithPath: directoryPath )
            let     imageFileURL         = picturesDirectoryURL.appendingPathComponent( name )
            
            if fileManager.fileExists( atPath: imageFileURL.path ) {
                let     imageFileData = fileManager.contents( atPath: imageFileURL.path )
                
                if let imageData = imageFileData {
                    return ( true, imageData )
                }

                logVerbose( "ERROR!  Failed to unwrap data from \n    [ %@ ]", imageFileURL.path )
            }
            else {
                logVerbose( "ERROR!  File NOT found! \n    [ %@ ]", imageFileURL.path )
            }
            
        }
        else {
            logVerbose( "ERROR!  directoryPath is Empty!" )
        }

        return ( false, Data.init() )
    }
    
    
    func fetchImageNamesFromRemote(_ delegate: PinCentralDelegate ) {  // Tailored to each implementation
        logTrace()
        self.delegate = delegate
        
        if !stayOffline {
            if dataStoreLocation == .iCloud || dataStoreLocation == .shareCloud {
                cloudCentral.fetchImageNames( self )
            }
            else if dataStoreLocation == .nas || dataStoreLocation == .shareNas {
                nasCentral.fetchImageNames( self )
            }

        }
        
    }
    
    
    func fetchMissingImages(_ imageName: String, _ descriptor: String,  _ delegate: PinCentralDelegate ) -> Int {   // Tailored to each implementation
        var     imagesRequested = 0
        
        if !imageExistsWith( imageName ) {
            imagesRequested += 1
            
            if dataStoreLocation == .iCloud || dataStoreLocation == .shareCloud {
                logVerbose( "Image for [ %@ ] not on disk!  \n    Requesting [ %@ ] from the Cloud ...", descriptor, imageName )
                imageRequestQueue.append( (imageName, delegate ) )
                cloudCentral.fetchImage( imageName, self )
            }
            else if dataStoreLocation == .nas || dataStoreLocation == .shareNas {
                logVerbose( "Image for [ %@ ] not on disk!  \n    Requesting [ %@ ] from NAS ...", descriptor, imageName )
                imageRequestQueue.append( (imageName, delegate ) )
                nasCentral.fetchImage( imageName, self )
            }
            
        }
        
        let thumbnailName = GlobalConstants.thumbNailPrefix + imageName

        if !imageExistsWith( thumbnailName ) {
            imagesRequested += 1
            
            if dataStoreLocation == .iCloud || dataStoreLocation == .shareCloud {
                logVerbose( "Thumbnail for [ %@ ] not on disk!  \n    Requesting [ %@ ] from the Cloud ...", descriptor, thumbnailName )
                imageRequestQueue.append( (thumbnailName, delegate ) )
                cloudCentral.fetchImage( thumbnailName, self )
            }
            else if dataStoreLocation == .nas || dataStoreLocation == .shareNas {
                logVerbose( "Thumbnail for [ %@ ] not on disk!  \n    Requesting [ %@ ] from NAS ...", descriptor, thumbnailName )
                imageRequestQueue.append( (thumbnailName, delegate ) )
                nasCentral.fetchImage( thumbnailName, self )
            }
            
        }
                        
        return imagesRequested
    }
        

    func imageExistsWith(_ name: String ) -> Bool {
//        logTrace()
        let         directoryPath = pictureDirectoryPath()
        
        if !directoryPath.isEmpty {
            let     picturesDirectoryURL = URL.init( fileURLWithPath: directoryPath )
            let     imageFileURL         = picturesDirectoryURL.appendingPathComponent( name )
            
            return fileManager.fileExists( atPath: imageFileURL.path )
        }
            
        return false
    }
    
    
    func imageNamed(_ name: String, descriptor: String, _ delegate: PinCentralDelegate ) -> (Bool, UIImage) {  // Tailored to each implementation
//        logTrace()
        let result      = fetchFromDiskImageNamed( name )
        let imageLoaded = result.0
        
        if imageLoaded {
            return result
        }
        
        if dataStoreLocation == .iCloud || dataStoreLocation == .shareCloud {
            logVerbose( "Image for [ %@ ] not on disk!  Requesting from the Cloud [ %@ ]", descriptor, name )
            imageRequestQueue.append( (name, delegate) )
            cloudCentral.fetchImage( name, self )
        }
        else if dataStoreLocation == .nas || dataStoreLocation == .shareNas {
            if !stayOffline {
                logVerbose( "Image for [ %@ ] not on disk!  Requesting from NAS [ %@ ]", descriptor, name )
                imageRequestQueue.append( (name, delegate) )
                nasCentral.fetchImage( name, self )
            }
                
        }
        
        return ( false, UIImage.init() )
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
 

    func uploadImageNamed(_ imageName: String, _ delegate: PinCentralDelegate ) {  // Tailored to each implementation
        logTrace()
        let     directoryPath        = pictureDirectoryPath()
        let     picturesDirectoryURL = URL.init( fileURLWithPath: directoryPath )
        let     imageFileURL         = picturesDirectoryURL.appendingPathComponent( imageName )
        
        if fileManager.fileExists( atPath: imageFileURL.path ) {
            let     imageFileData = fileManager.contents( atPath: imageFileURL.path )
            
            if let imageData = imageFileData {
                self.delegate = delegate

                if dataStoreLocation == .iCloud || dataStoreLocation == .shareCloud {
                    cloudCentral.saveImageData( imageData, filename: imageName, self )
                }
                else if dataStoreLocation == .nas || dataStoreLocation == .shareNas {
                    nasCentral.saveImageData( imageData, filename: imageName, self )
                }
                        
            }
            else {
                logVerbose( "ERROR!  Failed to load data for image for [ %@ ]", imageName )
                delegate.pinCentral( self, didSaveImageData: false )  // Tailored to each implementation
            }

        }
        else {
            logVerbose( "ERROR!  [ %@ ] does NOT exist!", imageName )
            delegate.pinCentral( self, didSaveImageData: false )  // Tailored to each implementation
        }

    }
    
    
    func verifyImages() {
        logTrace()
        let directoryPath = pictureDirectoryPath()
        
        if directoryPath.isEmpty {
            logVerbose( "ERROR!  directoryPath is Empty!  [ %@ ]", directoryPath )
        }
        else {
            let     picturesDirectoryURL = URL.init( fileURLWithPath: directoryPath )
            
            logVerbose( "Retrieving contents of [ %@ ]", picturesDirectoryURL.path )
            
            do {
                let filenameArray = try fileManager.contentsOfDirectory(atPath: picturesDirectoryURL.path )
                let filesFound    = filenameArray.count
                var filesLoaded   = 0
                
                logVerbose( "Found [ %d ] image files", filesFound )
                
                for filename in filenameArray {
                    let result = fetchFromDiskImageNamed( filename )
                    
                    logVerbose( "We %@ image data from [ %@ ]", (result.0 ? "loaded" : "FAILED to load" ), filename )
                    
                    if result.0 {
                        filesLoaded += 1
                    }
                    
                }
                
                logVerbose( "Loaded [ %d ] out of [ %d ] image files", filesFound, filesLoaded )
            }
            catch let error as NSError {
                logVerbose( "ERROR!  Failed to retrieve contents of [ %@ ] ... Error[ %@ ]", picturesDirectoryURL.path, error.localizedDescription )
            }
            
        }

    }
 
    

    // MARK: Image Convenience Utility Methods (Private)

    private func createImageRequestFor(_ command: Int, filename: String ) {
        logVerbose( "Creating ImageRequest[ %@ ][ %@ ] ", nameForImageRequest( command ), filename )
        self.persistentContainer.viewContext.perform {
            let     imageRequest = NSEntityDescription.insertNewObject( forEntityName: EntityNames.imageRequest, into: self.managedObjectContext ) as! ImageRequest
            
            imageRequest.index    = Int16( self.offlineImageRequestQueue.count )
            imageRequest.command  = Int16( command )
            imageRequest.filename = filename
            
            self.saveContext()
            
            self.updatedOffline = true
        }
        
    }
    
    
    private func fetchFromDiskImageNamed(_ name: String ) -> (Bool, UIImage) {
        let result = fetchFromDiskImageFileNamed( name )
        
        if result.0 {
            if let image = UIImage.init( data: result.1 ) {
                return ( true, image )
            }
            
            logVerbose( "ERROR!  Failed to un-wrap image for \n    [ %@ ]", name )
        }

        return ( false, UIImage.init() )
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
    

}



// MARK: NASCentralDelegate Methods

extension PinCentral: NASCentralDelegate {
    
    func nasCentral(_ nasCentral: NASCentral, canSeeNasFolders: Bool) {
        if stayOffline {
            logVerbose( "[ %@ ]  Stay Offline!", stringFor( canSeeNasFolders ) )
            return
        }
        
        logVerbose( "[ %@ ]", stringFor( canSeeNasFolders ) )

        if canSeeNasFolders {
            nasCentral.startSession( self )
        }
        else {
            deviceAccessControl.initWith(ownerName: "Unknown", locked: true, byMe: false, updating: false )
            logVerbose( "%@", deviceAccessControl.descriptor() )
            
            notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.cannotSeeExternalDevice ), object: self )
        }
        
    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didCompareLastUpdatedFiles: Int, lastUpdatedBy: String ) {
        logVerbose( "[ %@ ] by [ %@ ]", descriptionForCompare( didCompareLastUpdatedFiles ), lastUpdatedBy )
        
        externalDeviceLastUpdatedBy = lastUpdatedBy
        
        if didCompareLastUpdatedFiles == LastUpdatedFileCompareResult.deviceIsNewer {
            if deviceAccessControl.locked && deviceAccessControl.byMe {
                notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.transferringDatabase ), object: self )
                
                deviceAccessControl.updating = true

                nasCentral.copyDatabaseFromDeviceToNas( self )
            }
            
        }
        else if didCompareLastUpdatedFiles == LastUpdatedFileCompareResult.nasIsNewer {
            logTrace( "Verify that we can access all the database files before we start the transfer" )
            missingDbFiles = []
            nasCentral.fetchDbFiles( self )
        }
        else {  // Must be same!
            // Tell the PleaseWaitVC that we are done
            transferInProgress = false
            notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )
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
        
        notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )
    }
        
        
    func nasCentral(_ nasCentral: NASCentral, didCopyDatabaseFromNasToDevice: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didCopyDatabaseFromNasToDevice ) )
        
        deviceAccessControl.updating = false

        notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )

        if didCopyDatabaseFromNasToDevice && !openInProgress {
            let     appDelegate = UIApplication.shared.delegate as! AppDelegate
            
            logTrace( "opening database" )
            openDatabaseWith( delegate != nil ? delegate! : appDelegate )
        }
        
    }
        
        
    func nasCentral(_ nasCentral: NASCentral, didDeleteImage: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didDeleteImage ) )
        if updatedOffline {
            persistentContainer.viewContext.perform {
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
        
        
    func nasCentral(_ nasCentral: NASCentral, didFetch imageNames: [String] ) {
        logTrace()
        DispatchQueue.main.async {
            self.delegate?.pinCentral( self, didFetch: imageNames )  // Tailored to each implementation
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
                logVerbose( "Saved [ %d ] bytes to [ %@ ]", imageData.count, pictureFileURL.path )
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

        if imageRequestQueue.count == 0 {
            notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )
        }
        
        if self.updatedOffline {
            self.persistentContainer.viewContext.perform {
                self.processNextOfflineImageRequest()
            }
            
        }
        else {
            DispatchQueue.main.async {
                delegate.pinCentral( self, didFetchImage: didFetchImage, filename: filename, image: image )       // Tailored to each implementation
            }

        }
        
    }
    
    
    func nasCentral(_ nasCentral: NASCentral, didLockNas: Bool ) {
        logVerbose( "didLockNas[ %@ ]", stringFor( didLockNas ) )

        if deviceAccessControl.updating {
            notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.updatingExternalDevice ), object: self )
        }
        else if deviceAccessControl.locked && !deviceAccessControl.byMe {
            notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.externalDeviceLocked ), object: self )
        }
        else {
            nasCentral.compareLastUpdatedFiles( self )
        }

    }
        
        
    func nasCentral(_ nasCentral: NASCentral, didSaveImageData: Bool, filename: String ) {
        logVerbose( "[ %@ ][ %@ ]", stringFor( didSaveImageData ), filename )
        
        if updatedOffline {
            persistentContainer.viewContext.perform {
                self.processNextOfflineImageRequest()
            }
            
        }
        else {
            delegate?.pinCentral( self, didSaveImageData: didSaveImageData )  // Tailored to each implementation
        }
        
    }
        
        
    func nasCentral(_ nasCentral: NASCentral, didStartSession: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didStartSession ) )
        
        if didStartSession {
            nasCentral.lockNas( self )
        }
        else {
            notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.unableToConnect ), object: self )
        }
        
    }
        
        
    func nasCentral(_ nasCentral: NASCentral, didUnlockNas: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didUnlockNas ) )
        
        nasCentral.endSession( self )
    }
        

    func nasCentral(_ nasCentral: NASCentral, missingDbFiles: [String] ) {
        logVerbose( "[ %@ ]", missingDbFiles )
        self.missingDbFiles = missingDbFiles
        
        if missingDbFiles.count == 0 {
            notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.transferringDatabase ), object: self )
            didOpenDatabase = false

            nasCentral.copyDatabaseFromNasToDevice( self )
        }
        else {
            if externalDeviceLastUpdatedBy == nasCentral.lastUpdatedUnknown {
                // TODO: The lastUpdated file was either not found or we were unable to read it ... what next?
                logTrace( "We are missing db files and the lastUpdated file was either not found or we were unable to read it" )
            }
            else if externalDeviceLastUpdatedBy == deviceName {
                // TODO: We are missing db files and we were the last one to update it... what next?
                logTrace( "We are missing db files and we were the last one to update it" )
            }
            
            notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.cannotReadAllDbFiles ), object: self )
        }

    }
        
    
}



// MARK: UserDefaults Methods (Public)

// The reason these are here is that we can't see the UIKitExtensions in PinCentral

extension PinCentral {
    
    func getStringFromUserDefaults(_ key : String ) -> String {
        var savedString = ""
        
        if let string = userDefaults.string( forKey: key ) {
            savedString = string
        }

        return savedString
    }
    
    
    func flagIsPresentInUserDefaults(_ key : String ) -> Bool {
        var     flagIsPresent = false
        
        if let _ = userDefaults.string( forKey: key ) {
            flagIsPresent = true
        }
        
        return flagIsPresent
    }
    
    
    func removeFlagFromUserDefaults(_ key: String ) {
        userDefaults.removeObject(forKey: key )
        
        userDefaults.synchronize()
    }
    
    
    func saveToUserDefaults(_ value: String, for key: String ) {
        userDefaults.removeObject( forKey: key )
        userDefaults.set( value,   forKey: key )
        
        userDefaults.synchronize()
    }
    
    
    func setFlagInUserDefaults(_ key: String ) {
        userDefaults.set( key, forKey: key )
        
        userDefaults.synchronize()
    }
    

}



