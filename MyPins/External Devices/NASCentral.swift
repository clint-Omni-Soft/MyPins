//
//  NASCentral.swift
//  Ported from WineStock
//
//  Created by Clint Shank on 4/10/20.
//  Copyright © 2020 Omni-Soft, Inc. All rights reserved.
//

import UIKit


protocol NASCentralDelegate : AnyObject {
    
    // Access Methods
    func nasCentral(_ nasCentral : NASCentral, canSeeNasFolders       : Bool )
    func nasCentral(_ nasCentral : NASCentral, didCloseShareAndDevice : Bool )
    func nasCentral(_ nasCentral : NASCentral, didConnectToDevice     : Bool, _ device         : SMBDevice   )
    func nasCentral(_ nasCentral : NASCentral, didCreateDirectory     : Bool )
    func nasCentral(_ nasCentral : NASCentral, didFetchDevices        : Bool, _ deviceArray    : [SMBDevice] )
    func nasCentral(_ nasCentral : NASCentral, didFetchDirectories    : Bool, _ directoryArray : [SMBFile]   )
    func nasCentral(_ nasCentral : NASCentral, didFetchFile           : Bool, _ data : Data )
    func nasCentral(_ nasCentral : NASCentral, didFetchShares         : Bool, _ shareArray     : [SMBShare]  )
    func nasCentral(_ nasCentral : NASCentral, didOpenShare           : Bool, _ share          : SMBShare    )
    func nasCentral(_ nasCentral : NASCentral, didSaveAccessKey       : Bool )
    func nasCentral(_ nasCentral : NASCentral, didSaveData            : Bool )

    // Session Methods
    func nasCentral(_ nasCentral : NASCentral, didCompareLastUpdatedFiles      : Int )
    func nasCentral(_ nasCentral : NASCentral, didFetch imageNames             : [String] )
    func nasCentral(_ nasCentral : NASCentral, didCopyAllImagesFromDeviceToNas : Bool )
    func nasCentral(_ nasCentral : NASCentral, didCopyAllImagesFromNasToDevice : Bool )
    func nasCentral(_ nasCentral : NASCentral, didCopyDatabaseFromDeviceToNas  : Bool )
    func nasCentral(_ nasCentral : NASCentral, didCopyDatabaseFromNasToDevice  : Bool )
    func nasCentral(_ nasCentral : NASCentral, didDeleteImage   : Bool )
    func nasCentral(_ nasCentral : NASCentral, didEndSession    : Bool )
    func nasCentral(_ nasCentral : NASCentral, didFetchImage    : Bool, image : UIImage, filename : String )
    func nasCentral(_ nasCentral : NASCentral, didLockNas       : Bool )
    func nasCentral(_ nasCentral : NASCentral, didSaveImageData : Bool, filename : String )
    func nasCentral(_ nasCentral : NASCentral, didStartSession  : Bool )
    func nasCentral(_ nasCentral : NASCentral, didUnlockNas     : Bool )

}


// Now we supply we provide a default implementation which makes them all optional
extension NASCentralDelegate {
    
    // Access Methods
    func nasCentral(_ nasCentral : NASCentral, canSeeNasFolders       : Bool ) {}
    func nasCentral(_ nasCentral : NASCentral, didCloseShareAndDevice : Bool ) {}
    func nasCentral(_ nasCentral : NASCentral, didConnectToDevice     : Bool, _ device         : SMBDevice   ) {}
    func nasCentral(_ nasCentral : NASCentral, didCreateDirectory     : Bool ) {}
    func nasCentral(_ nasCentral : NASCentral, didFetchDevices        : Bool, _ deviceArray    : [SMBDevice] ) {}
    func nasCentral(_ nasCentral : NASCentral, didFetchDirectories    : Bool, _ directoryArray : [SMBFile]   ) {}
    func nasCentral(_ nasCentral : NASCentral, didFetchFile           : Bool, _ data : Data ) {}
    func nasCentral(_ nasCentral : NASCentral, didFetchShares         : Bool, _ shareArray     : [SMBShare]  ) {}
    func nasCentral(_ nasCentral : NASCentral, didOpenShare           : Bool, _ share          : SMBShare    ) {}
    func nasCentral(_ nasCentral : NASCentral, didSaveAccessKey       : Bool ) {}
    func nasCentral(_ nasCentral : NASCentral, didSaveData            : Bool ) {}

    // Session Methods
    func nasCentral(_ nasCentral : NASCentral, didCompareLastUpdatedFiles      : Int ) {}
    func nasCentral(_ nasCentral : NASCentral, didFetch imageNames             : [String] ) {}
    func nasCentral(_ nasCentral : NASCentral, didCopyAllImagesFromDeviceToNas : Bool ) {}
    func nasCentral(_ nasCentral : NASCentral, didCopyAllImagesFromNasToDevice : Bool ) {}
    func nasCentral(_ nasCentral : NASCentral, didCopyDatabaseFromDeviceToNas  : Bool ) {}
    func nasCentral(_ nasCentral : NASCentral, didCopyDatabaseFromNasToDevice  : Bool ) {}
    func nasCentral(_ nasCentral : NASCentral, didDeleteImage   : Bool ) {}
    func nasCentral(_ nasCentral : NASCentral, didEndSession    : Bool ) {}
    func nasCentral(_ nasCentral : NASCentral, didFetchImage    : Bool, image : UIImage, filename : String ) {}
    func nasCentral(_ nasCentral : NASCentral, didLockNas       : Bool ) {}
    func nasCentral(_ nasCentral : NASCentral, didSaveImageData : Bool, filename : String ) {}
    func nasCentral(_ nasCentral : NASCentral, didStartSession  : Bool ) {}
    func nasCentral(_ nasCentral : NASCentral, didUnlockNas     : Bool ) {}

}



class NASCentral: NSObject {

    // MARK: Public Variables
    
    var nasAccessKey : NASDescriptor {
        get {
            var     accessKey = NASDescriptor()
            
            if let descriptorString = UserDefaults.standard.string( forKey: UserDefaultKeys.nasDescriptor ) {
                let     components = descriptorString.components( separatedBy: "," )
                
                if components.count == 7 {
                    accessKey.host         = components[0]
                    accessKey.netbiosName  = components[1]
                    accessKey.group        = components[2]
                    accessKey.userName     = components[3]
                    accessKey.password     = components[4]
                    accessKey.share        = components[5]
                    accessKey.path         = components[6]
                }

            }
            
            return accessKey
        }
        
        set ( accessKey ) {
            let     descriptorString = String( format: "%@,%@,%@,%@,%@,%@,%@",
                                               accessKey.host,      accessKey.netbiosName, accessKey.group,
                                               accessKey.userName,  accessKey.password,
                                               accessKey.share,     accessKey.path )

            UserDefaults.standard.set( descriptorString, forKey: UserDefaultKeys.nasDescriptor )
            UserDefaults.standard.synchronize()
        }
        
    }
    
    var returnCsvFiles = false      // Used by Settings/Import from CSV ... we will pass this through to SMBCentral

    
    
    // MARK: Private Variables
    
    private struct Constants {  // NOTE: lastUpdated needs to be first (which is processed last) to prevent trashing the database in the event that the update fails
        static let databaseFilenameArray   = [ Filenames.lastUpdated, Filenames.database, Filenames.databaseShm, Filenames.databaseWal ]
        static let scanTime : TimeInterval = 3
    }
    
    private enum Command {
        
        // Access Methods
        case CanSeeNasFolders
        case CloseShareAndDevice
        case ConnectTo
        case CreateDirectoryOn
        case FetchConnectedDevices
        case FetchDirectoriesFrom
        case FetchFileOn
        case FetchShares
        case OpenShare
        case SaveAccessKey
        case SaveData
        
        // Session Methods
        case CompareLastUpdatedFiles
        case CopyAllImagesFromDeviceToNas
        case CopyAllImagesFromNasToDevice
        case CopyDatabaseFromDeviceToNas
        case CopyDatabaseFromNasToDevice
        case DeleteImage
        case EndSession
        case FetchImage
        case FetchImageNames
        case LockNas
        case SaveImageData
        case StartSession
        case UnlockNas
    }
    
    private var currentCommand          : Command!
    private var currentFilename         = ""
    private var delegate                : NASCentralDelegate?
    private let deviceAccessControl     = DeviceAccessControl.sharedInstance
    private var deviceUrlArray          = [URL].init()
    private var deviceUrlArrayIndex     = 0
    private var deviceUrlsToDeleteArray = [URL].init()
    private var discoveryTimer          : Timer?
    private var documentDirectoryURL    : URL!
    private var nasImageFileArray       : [SMBFile] = []
    private var reEstablishConnection   = false
    private var requestQueue            : [[Any]] = []
    private var selectedDevice          : SMBDevice?
    private var selectedShare           : SMBShare?
    private var sessionActive           = false
    private var workingAccessKey        = NASDescriptor()
    
    
    
    // MARK: Our Singleton (Public)
    
    static let sharedInstance = NASCentral()        // Prevents anyone else from creating an instance
}



// MARK: External Interface Methods (Queued)

extension NASCentral {
    
    // MARK: Access Methods (Public)
    
    func canSeeNasFolders(_ delegate : NASCentralDelegate ) {
        addRequest( [Command.CanSeeNasFolders, delegate] )
    }
    

    func closeShareAndDevice(_ delegate : NASCentralDelegate ) {
        addRequest( [Command.CloseShareAndDevice, delegate] )
    }
    
    
    func connectTo(_ device : SMBDevice, _ userName : String, _ password : String, _ delegate : NASCentralDelegate ) {
        addRequest( [Command.ConnectTo, device, userName, password, delegate] )
    }
    
    
    func createDirectoryOn(_ share : SMBShare, _ path : String, _ delegate : NASCentralDelegate ) {
        addRequest( [Command.CreateDirectoryOn, share, path, delegate] )
    }
    
    
    func fetchConnectedDevices(_ delegate : NASCentralDelegate ) {
        addRequest( [Command.FetchConnectedDevices, delegate] )
    }
    
    
    func fetchDirectoriesFrom(_ share : SMBShare, _ atPath : String, _ delegate : NASCentralDelegate ) {
        addRequest( [Command.FetchDirectoriesFrom, share, atPath, delegate] )
    }
    
    
    func fetchFileOn(_ share : SMBShare, _ fullpath : String, _ delegate : NASCentralDelegate ) {
        addRequest( [Command.FetchFileOn, share, fullpath, delegate] )
    }
    
    
    func fetchShares(_ delegate : NASCentralDelegate ) {
        addRequest( [Command.FetchShares, delegate] )
    }
    
    
    func openShare(_ share : SMBShare, _ delegate : NASCentralDelegate ) {
        addRequest( [Command.OpenShare, share, delegate] )
    }
    
    
    func saveAccessKey(_ path : String, _ delegate : NASCentralDelegate  ) {
        addRequest( [Command.SaveAccessKey, path, delegate] )
    }
    
    
    func saveData(_ data : Data, _ share : SMBShare, _ fullPath : String, _ delegate : NASCentralDelegate ) {
        addRequest( [Command.SaveData, data, share, fullPath, delegate] )
    }
    
    
    
    // MARK: Session Methods
    
    func compareLastUpdatedFiles(_ delegate : NASCentralDelegate ) {
        addRequest( [Command.CompareLastUpdatedFiles, delegate] )
    }

    
    func fetchImageNames(_ delegate : NASCentralDelegate ) {
        addRequest( [Command.FetchImageNames, delegate] )
    }

    
    func copyAllImagesFromDeviceToNas(_ delegate : NASCentralDelegate ) {
        addRequest( [Command.CopyAllImagesFromDeviceToNas, delegate] )
    }
    
    
    func copyAllImagesFromNasToDevice(_ delegate : NASCentralDelegate ) {
        addRequest( [Command.CopyAllImagesFromNasToDevice, delegate] )
    }
    
    
    func copyDatabaseFromDeviceToNas(_ delegate : NASCentralDelegate ) {
        addRequest( [Command.CopyDatabaseFromDeviceToNas, delegate] )
    }
    
    
    func copyDatabaseFromNasToDevice(_ delegate : NASCentralDelegate ) {
        addRequest( [Command.CopyDatabaseFromNasToDevice, delegate] )
    }
    
    
    func deleteImage(_ filename : String, _ delegate : NASCentralDelegate ) {
        addRequest( [Command.DeleteImage, filename, delegate] )
    }
    
    
    func endSession(_ delegate : NASCentralDelegate ) {
        addRequest( [Command.EndSession, delegate] )
    }
    
    
    func fetchImage(_ filename : String, _ delegate : NASCentralDelegate ) {
        addRequest( [Command.FetchImage, filename, delegate] )
    }
    
    
    func lockNas(_ delegate : NASCentralDelegate ) {
        addRequest( [Command.LockNas, delegate] )
    }
    
    
    func saveImageData(_ imageData : Data, filename : String, _ delegate : NASCentralDelegate ) {
        addRequest( [Command.SaveImageData, imageData, filename, delegate] )
    }
    
    
    func startSession(_ delegate : NASCentralDelegate  ) {
        addRequest( [Command.StartSession, delegate] )
    }

    
    func unlockNas(_ delegate : NASCentralDelegate ) {
        addRequest( [Command.UnlockNas, delegate] )
    }

    
    
    // MARK: Utility Methods (Private)
    
    private func addRequest(_ request : [Any] ) {
        let     requestQueueIdle = requestQueue.isEmpty
        
        logVerbose( "[ %@ ] ... queued requests[ %d ]", stringForCommand( request[0] as! Command ), requestQueue.count )
        requestQueue.append( request )
        
        if requestQueueIdle {
            DispatchQueue.global().async {
                self.processNextRequest( false )
            }

        }
        
    }
    
    
    private func isSessionCommand(_ command : Command ) -> Bool {
        var isSession = true
        
        switch command {
        case .CanSeeNasFolders, .CloseShareAndDevice, .ConnectTo, .CreateDirectoryOn, .FetchConnectedDevices, .FetchDirectoriesFrom, .FetchFileOn, .FetchShares, .OpenShare, .SaveAccessKey, .SaveData:
             isSession = false
        default:    break
        }
        
        return isSession
    }
    
    
    private func processNextRequest(_ popHeadOfQueue : Bool = true ) {
        
        if popHeadOfQueue && !requestQueue.isEmpty {
            requestQueue.remove( at: 0 )
        }

        if requestQueue.isEmpty {
//            logTrace( "going IDLE" )
            return
        }
        
        guard let request = requestQueue.first else {
            logTrace( "ERROR!  Unable to remove request from front of queue!" )
            return
        }

        let command = request[0] as! Command
        
        if !sessionActive && isSessionCommand( command ) && command != .StartSession {
            logTrace( "Re-establishing session" )
            reEstablishConnection = true
            SMBCentral.sharedInstance.startSession( nasAccessKey, self )
            return
        }
        
        logVerbose( "[ %@ ]", stringForCommand( command ) )
        currentCommand = command

        switch currentCommand {
            
            // Access Methods
        case .CanSeeNasFolders:                 _canSeeNasFolders(      request[1] as! NASCentralDelegate )
        case .CloseShareAndDevice:              _closeShareAndDevice(   request[1] as! NASCentralDelegate )
        case .ConnectTo:                        _connectTo(             request[1] as! SMBDevice, request[2] as! String, request[3] as! String, request[4] as! NASCentralDelegate )
        case .CreateDirectoryOn:                _createDirectoryOn(     request[1] as! SMBShare,  request[2] as! String, request[3] as! NASCentralDelegate )
        case .FetchConnectedDevices:            _fetchConnectedDevices( request[1] as! NASCentralDelegate )
        case .FetchDirectoriesFrom:             _fetchDirectoriesFrom(  request[1] as! SMBShare,  request[2] as! String, request[3] as! NASCentralDelegate )
        case .FetchFileOn:                      _fetchFileOn(   request[1] as! SMBShare, request[2] as! String, request[3] as! NASCentralDelegate )
        case .FetchShares:                      _fetchShares(   request[1] as! NASCentralDelegate )
        case .OpenShare:                        _openShare(     request[1] as! SMBShare, request[2] as! NASCentralDelegate )
        case .SaveAccessKey:                    _saveAccessKey( request[1] as! String, request[2] as! NASCentralDelegate )
        case .SaveData:                         _saveData(      request[1] as! Data, request[2] as! SMBShare, request[3] as! String, request[4] as! NASCentralDelegate )

            // Session Methods
        case .CompareLastUpdatedFiles:          _compareLastUpdatedFiles(      request[1] as! NASCentralDelegate )
        case .CopyAllImagesFromDeviceToNas:     _copyAllImagesFromDeviceToNas( request[1] as! NASCentralDelegate )
        case .CopyAllImagesFromNasToDevice:     _copyAllImagesFromNasToDevice( request[1] as! NASCentralDelegate )
        case .CopyDatabaseFromDeviceToNas:      _copyDatabaseFromDeviceToNas(  request[1] as! NASCentralDelegate )
        case .CopyDatabaseFromNasToDevice:      _copyDatabaseFromNasToDevice(  request[1] as! NASCentralDelegate )
        case .DeleteImage:                      _deleteImage( request[1] as! String, request[2] as! NASCentralDelegate )
        case .EndSession:                       _endSession(  request[1] as! NASCentralDelegate )
        case .FetchImage:                       _fetchImage(  request[1] as! String, request[2] as! NASCentralDelegate )
        case .FetchImageNames:                  _fetchImageNames( request[1] as! NASCentralDelegate )
        case .LockNas:                          _lockNas(     request[1] as! NASCentralDelegate )
        case .SaveImageData:                    _saveImageData( request[1] as! Data, filename : request[2] as! String, request[3] as! NASCentralDelegate )
        case .StartSession:                     _startSession(  request[1] as! NASCentralDelegate )
        case .UnlockNas:                        _unlockNas(     request[1] as! NASCentralDelegate )
            
        default:                                logTrace( "SBH!" )
        }
        
    }
    
    
    private func stringForCommand(_ command : Command ) -> String {
        var     description = "Unknown"
        
        switch command {
        case .CanSeeNasFolders:                 description = "CanSeeNasFolders"
        case .CloseShareAndDevice:              description = "CloseShareAndDevice"
        case .CompareLastUpdatedFiles:          description = "CompareLastUpdatedFiles"
        case .ConnectTo:                        description = "ConnectTo"
        case .CopyAllImagesFromDeviceToNas:     description = "CopyAllImagesFromDeviceToNas"
        case .CopyAllImagesFromNasToDevice:     description = "CopyAllImagesFromNasToDevice"
        case .CopyDatabaseFromDeviceToNas:      description = "CopyDatabaseFromDeviceToNas"
        case .CopyDatabaseFromNasToDevice:      description = "CopyDatabaseFromNasToDevice"
        case .CreateDirectoryOn:                description = "CreateDirectoryOn"
        case .DeleteImage:                      description = "DeleteImage"
        case .EndSession:                       description = "EndSession"
        case .FetchConnectedDevices:            description = "FetchConnectedDevices"
        case .FetchDirectoriesFrom:             description = "FetchDirectoriesFrom"
        case .FetchFileOn:                      description = "FetchFileOn"
        case .FetchImage:                       description = "FetchImage"
        case .FetchImageNames:                  description = "FetchImageNames"
        case .FetchShares:                      description = "FetchShares"
        case .LockNas:                          description = "LockNas"
        case .OpenShare:                        description = "OpenShare"
        case .SaveAccessKey:                    description = "SaveAccessKey"
        case .SaveData:                         description = "SaveData"
        case .SaveImageData:                    description = "SaveImageData"
        case .StartSession:                     description = "StartSession"
        case .UnlockNas:                        description = "UnlockNas"
        }
        
        return description
    }
    
    
}



// MARK: Access Methods (Private)

extension NASCentral {
    
    private func _canSeeNasFolders(_ delegate : NASCentralDelegate ) {
//        logTrace()
        self.delegate = delegate
        SMBCentral.sharedInstance.findFolderAt( nasAccessKey, self )
    }
    
    
    private func _closeShareAndDevice(_ delegate : NASCentralDelegate ) {
//        logTrace()
        if let share = selectedShare {
            if share.isOpen {
                share.close( {
                    (error) in
                    
                    if error != nil {
                        logVerbose( "ERROR!  [ %@ ]", error?.localizedDescription ?? "Unknown error" )
                    }
                        
                    if let _ = self.selectedDevice {
                        SMBCentral.sharedInstance.disconnect()
                    }
                   
                    DispatchQueue.main.async {
                        delegate.nasCentral( self, didCloseShareAndDevice : true )
                    }

                    self.processNextRequest()
                })

            }

        }
        else {
            if let _ = self.selectedDevice {
                SMBCentral.sharedInstance.disconnect()
             }
            
            DispatchQueue.main.async {
                delegate.nasCentral( self, didCloseShareAndDevice : true )
            }
            
            self.processNextRequest()
        }

        self.selectedShare  = nil
        self.selectedDevice = nil
    }
    
    
    private func _connectTo(_ device : SMBDevice, _ userName : String, _ password : String, _ delegate : NASCentralDelegate ) {
//       logTrace()
       self.delegate = delegate
       
       selectedDevice = device
       
       workingAccessKey.host        = device.host
       workingAccessKey.netbiosName = device.netbiosName
       workingAccessKey.group       = device.group
       workingAccessKey.password    = password
       workingAccessKey.userName    = userName
       workingAccessKey.share       = ""
       workingAccessKey.path        = ""
       
       SMBCentral.sharedInstance.connectTo( device, userName, password, self )
    }
       
       
    private func _createDirectoryOn(_ share : SMBShare, _ path : String, _ delegate : NASCentralDelegate ) {
//       logTrace()
       self.delegate = delegate

       SMBCentral.sharedInstance.createDirectoryOn( share, path, self )
    }
       
    
    private func _fetchConnectedDevices(_ delegate : NASCentralDelegate ) {
//        logTrace()
        self.delegate = delegate
        
        if SMBCentral.sharedInstance.startDiscoveryWith( self ) {
            DispatchQueue.main.async {
                self.discoveryTimer = Timer.scheduledTimer( timeInterval: Constants.scanTime, target: self, selector: #selector( self.timerFired ), userInfo: nil, repeats: false )
            }
            
        }
        else {
            logTrace( "ERROR!  Unable to start discovery!" )
            
            DispatchQueue.main.async {
                delegate.nasCentral( self, didFetchDevices: false, [] )
            }
            
            processNextRequest()
        }
        
    }
    
    
    private func _fetchDirectoriesFrom(_ share : SMBShare, _ atPath : String, _ delegate : NASCentralDelegate ) {
//        logVerbose( "[ %@/%@ ]  returnCsvFiles[ %@ ]", share.name, atPath, stringFor( returnCsvFiles ) )
        if let share = selectedShare {
            self.delegate          = delegate
            workingAccessKey.share = share.name
            
            SMBCentral.sharedInstance.returnCsvFiles = returnCsvFiles
            SMBCentral.sharedInstance.fetchDirectoriesFor( share, atPath, self )
        }
        else {
            logTrace( "ERROR!  selectedShare NOT set!" )
            
            DispatchQueue.main.async {
                delegate.nasCentral( self, didFetchDirectories: false, [] )
            }
            
            processNextRequest()
        }
        
    }
    
    
    private func _fetchFileOn(_ share : SMBShare, _ fullpath : String, _ delegate : NASCentralDelegate ) {
//        logTrace()
        self.delegate = delegate

        SMBCentral.sharedInstance.fetchFileOn( share, fullpath, self )
    }
    
    
    private func _fetchShares(_ delegate : NASCentralDelegate ) {
//        logTrace()
        self.delegate = delegate

        SMBCentral.sharedInstance.fetchSharesOnConnectedDevice( self )
    }
    
    
    private func _openShare(_ share : SMBShare, _ delegate : NASCentralDelegate ) {
//        logTrace()
        var didOpenShare = false
                
        selectedShare = nil
        
        share.open {
            (error) in
            
            if let myError = error {
                logVerbose( "ERROR!  Unable to open share[ %@ ] ... [ %@ ]", share.name, myError.localizedDescription )
                share.close( nil )
            }
            else {
//                logVerbose( "Opened share[ %@ ]", share.name )
                didOpenShare = true
                self.selectedShare = share
            }
            
            DispatchQueue.main.async {
                delegate.nasCentral( self, didOpenShare: didOpenShare, share )
            }
            
            self.processNextRequest()
        }
        
    }
    
    
    private func _saveAccessKey(_ path : String, _ delegate : NASCentralDelegate  ) {
        logVerbose( "[ %@ ]", path )
        workingAccessKey.path = path
        nasAccessKey          = workingAccessKey
        
        DispatchQueue.main.async {
            delegate.nasCentral( self, didSaveAccessKey: true )
        }
        
        processNextRequest()
    }
    
    
    private func _saveData(_ data : Data, _ share : SMBShare, _ fullpath : String, _ delegate : NASCentralDelegate  ) {
//        logTrace()
        self.delegate = delegate

        SMBCentral.sharedInstance.saveData( data, selectedShare!, fullpath, self )
    }
    
    

    // MARK: Timer Methods
    
    @objc func timerFired() {
        logTrace()
        discoveryTimer?.invalidate()

        SMBCentral.sharedInstance.stopDiscovery()
        
        DispatchQueue.main.async {
            self.delegate?.nasCentral( self, didFetchDevices: true, SMBCentral.sharedInstance.deviceArray )
        }
        
        processNextRequest()
    }

    
}



// MARK: Session Methods

extension NASCentral {
    
    private func _compareLastUpdatedFiles(_ delegate : NASCentralDelegate ) {
//        logTrace()
        let     fullPath = nasAccessKey.path + "/" + Filenames.lastUpdated
        
        self.delegate = delegate
        currentFilename = Filenames.lastUpdated
        
        SMBCentral.sharedInstance.readFileAt( fullPath, self )
    }

    
    private func _fetchImageNames(_ delegate : NASCentralDelegate ) {
//        logTrace()
        let     fullPath = nasAccessKey.path + "/" + DirectoryNames.pictures
        
        self.delegate = delegate
        
        SMBCentral.sharedInstance.fetchFilesAt( fullPath, self )
    }
    
    
    private func _copyAllImagesFromDeviceToNas(_ delegate : NASCentralDelegate ) {
//        logTrace()
        self.delegate = delegate
        
        loadDevicePicturesIntoFileUrlArray()
        deleteFilesFromNas()
    }
    

    private func _copyAllImagesFromNasToDevice(_ delegate : NASCentralDelegate ) {
//        logTrace()
        let     fullPath = nasAccessKey.path + "/" + DirectoryNames.pictures
        
        self.delegate = delegate
        
        SMBCentral.sharedInstance.fetchFilesAt( fullPath, self )
    }
    
    
    private func _copyDatabaseFromDeviceToNas(_ delegate : NASCentralDelegate ) {
//        logTrace()
        self.delegate = delegate
        
        loadDatabaseFilesIntoDeviceUrlArray()
        deleteFilesFromNas()
    }
    
    
    private func _copyDatabaseFromNasToDevice(_ delegate : NASCentralDelegate ) {
//        logTrace()
        self.delegate = delegate
        
        loadDatabaseFilesIntoDeviceUrlArray()
        deleteFilesFromDevice()
        readNextRootFileFromNas()
    }
    
    
    private func _deleteImage(_ filename : String, _ delegate : NASCentralDelegate ) {
//        logVerbose( "[ %@ ]", filename )
        currentFilename = filename
        self.delegate   = delegate

        var     imageUrl = URL( fileURLWithPath: nasAccessKey.path )
        
        imageUrl = imageUrl.appendingPathComponent( DirectoryNames.pictures )
        imageUrl = imageUrl.appendingPathComponent( filename )
        
        SMBCentral.sharedInstance.deleteFileAt( imageUrl.path, self )
    }
    
    
    private func _endSession(_ delegate : NASCentralDelegate ) {
//        logTrace()
        self.delegate = delegate

        SMBCentral.sharedInstance.endSession( self )
    }
    
    
    private func _fetchImage(_ filename : String, _ delegate : NASCentralDelegate ) {
        logVerbose( "[ %@ ] last[ %@ ]", filename, currentFilename )

        let     fullPath  = nasAccessKey.path + "/" + DirectoryNames.pictures + "/" + filename

        currentFilename = filename
        self.delegate   = delegate

        SMBCentral.sharedInstance.readFileAt( fullPath, self )
    }
    
    
    private func _lockNas(_ delegate : NASCentralDelegate ) {
//        logTrace()
        let     fullPath = nasAccessKey.path + "/" + Filenames.lockFile
        
        self.delegate   = delegate
        currentFilename = Filenames.lockFile
        
        SMBCentral.sharedInstance.readFileAt( fullPath, self )
    }
    
    
    private func _saveImageData(_ imageData : Data, filename : String, _ delegate : NASCentralDelegate ) {
//        logTrace()
        let     fullPath  = nasAccessKey.path + "/" + DirectoryNames.pictures + "/" + filename

        currentFilename = filename
        self.delegate   = delegate
        
        SMBCentral.sharedInstance.writeData( imageData, toFileAt: fullPath, self )
    }
    
    
    private func _startSession(_ delegate : NASCentralDelegate ) {
//        logTrace()
        self.delegate = delegate

        if let url = FileManager.default.urls( for: .documentDirectory, in: .userDomainMask ).first {
            documentDirectoryURL = url
        }
        else {
            logTrace( "ERROR:  Unable to load documentDirectoryURL" )
            documentDirectoryURL = URL( fileURLWithPath: "" )
        }

        SMBCentral.sharedInstance.startSession( nasAccessKey, self )
    }
    
    
    private func _unlockNas(_ delegate : NASCentralDelegate ) {
//        logTrace()
        let     fullPath = nasAccessKey.path + "/" + Filenames.lockFile
        
        SMBCentral.sharedInstance.deleteFileAt( fullPath, self )
    }

    
    
    // MARK: Session Utility Methods
    
    private func deleteFilesFromDevice() {
//        logTrace()
        let     fileManager = FileManager.default
        
        for fileUrl in deviceUrlsToDeleteArray {
            do {
                if fileManager.fileExists(atPath: fileUrl.path ) {
                    try fileManager.removeItem( at: fileUrl )
                    logVerbose( "Deleted [ %@ ]", fileUrl.lastPathComponent )
                }
                else {
                    logVerbose( "Doesn't Exist [ %@ ] ", fileUrl.lastPathComponent )
                }
                
            }
            catch let error as NSError {
                logVerbose( "Error: [ %@ ] -> [ %@ ]", fileUrl.lastPathComponent, error.localizedDescription )
            }
            
        }
        
        deviceUrlsToDeleteArray.removeAll()
    }
        
        
    private func deleteFilesFromNas() {
        
        if deviceUrlsToDeleteArray.isEmpty {
            let     path = currentCommand == .CopyDatabaseFromDeviceToNas ? "" : DirectoryNames.pictures
            
            logTrace( "nothing to delete ... start transfer" )
            readAndWriteDeviceDataToNasAt( path )
        }
        else {
            var     fullPath = nasAccessKey.path + "/"
            let     url      = deviceUrlsToDeleteArray.last!
           
            if currentCommand == .CopyAllImagesFromDeviceToNas{
                fullPath += DirectoryNames.pictures + "/"
            }
            
            fullPath += url.lastPathComponent
            deviceUrlsToDeleteArray.removeLast()
            logVerbose( "[ %@ ]", url.lastPathComponent )

            SMBCentral.sharedInstance.deleteFileAt( fullPath, self )
        }

    }

            
    private func loadDatabaseFilesIntoDeviceUrlArray() {
//        logTrace()
        deviceUrlArray         .removeAll()
        deviceUrlsToDeleteArray.removeAll()

        for filename in Constants.databaseFilenameArray {
            let     fileUrl = documentDirectoryURL.appendingPathComponent( filename )
            
            deviceUrlArray.append( fileUrl )
//            logVerbose( "[ %@ ]", fileUrl.path )
        }
        
        deviceUrlsToDeleteArray.append( contentsOf: deviceUrlArray )
    }
        
        
    private func loadDevicePicturesIntoFileUrlArray() {
//        logTrace()
        var     filenameArray        = [String].init()
        let     picturesDirectoryURL = documentDirectoryURL.appendingPathComponent( DirectoryNames.pictures )
        
        deviceUrlArray         .removeAll()
        deviceUrlsToDeleteArray.removeAll()

        if !FileManager.default.fileExists( atPath: picturesDirectoryURL.path ) {
            logVerbose( "Pictures directory does NOT exist!\n    [ %@ ] ", picturesDirectoryURL.path )
            return
        }
        
        do {
            try filenameArray = FileManager.default.contentsOfDirectory( atPath: picturesDirectoryURL.path )
            
            for filename in filenameArray {
                let     index             = filename.index( filename.startIndex, offsetBy: 1 )
                let     startingSubstring = filename.prefix( upTo: index )
                let     startingString    = String( startingSubstring )
                
                // Filter out hidden files and the Library folder
                if startingString == "." || filename == "Library" {
                    continue
                }
                
                // Filter out databases and directories
                let     fileUrl      = picturesDirectoryURL.appendingPathComponent( filename )
                var     isaDirectory = ObjCBool( false )
                
                if FileManager.default.fileExists( atPath: fileUrl.path, isDirectory : &isaDirectory ) {
                    if !isaDirectory.boolValue {
                        deviceUrlArray.append( fileUrl )
//                        logVerbose( "[ %@ ]", fileUrl.path )
                    }
                    
                }
                
            }
            
            deviceUrlsToDeleteArray.append( contentsOf: deviceUrlArray )
        }
        catch let error as NSError {
            logVerbose( "Error: [ %@ ]", error )
        }
        
    }

    
    private func readNextRootFileFromNas() {
//        logTrace()
        if let fileUrl = deviceUrlArray.last {
            let     fullPath = nasAccessKey.path + "/" + fileUrl.lastPathComponent
        
            currentFilename = fileUrl.lastPathComponent
            logVerbose( "[ %@ ]", currentFilename )
            
            SMBCentral.sharedInstance.readFileAt( fullPath, self )
        }
        else {
            logTrace( "ERROR!  Unable to unwrap deviceUrlArray.last!" )
            DispatchQueue.main.async {
                self.delegate?.nasCentral( self, didCopyDatabaseFromNasToDevice: false )
            }
            
            processNextRequest()
        }
        
    }
    
    
    private func readNextImageFromNas() {
        if nasImageFileArray.isEmpty {
            logTrace( "Done!" )
            DispatchQueue.main.async {
                if self.currentCommand == .CopyAllImagesFromNasToDevice {
                    self.delegate?.nasCentral( self, didCopyAllImagesFromNasToDevice: true )
                }
                else {
                    self.delegate?.nasCentral( self, didCopyAllImagesFromDeviceToNas: true )
                }
                
            }
            
            processNextRequest()
        }
        else {
            if let imageFile = nasImageFileArray.last {
                let     fullPath = nasAccessKey.path + "/" + DirectoryNames.pictures + "/" + imageFile.name

                currentFilename = imageFile.name
                logVerbose( "[ %@/%@ ]", DirectoryNames.pictures, currentFilename )
                
                SMBCentral.sharedInstance.readFileAt( fullPath, self )
            }
            else {
                logTrace( "ERROR!  Unable to extract last object from nasImageArray" )
                DispatchQueue.main.async {
                    if self.currentCommand == .CopyAllImagesFromNasToDevice {
                        self.delegate?.nasCentral( self, didCopyAllImagesFromNasToDevice: false )
                    }
                    else {
                        self.delegate?.nasCentral( self, didCopyAllImagesFromDeviceToNas: false )
                    }
                    
                }
                
                processNextRequest()
            }

        }
        
    }
        
        

}



// MARK: SMBCentralDelegate Methods

extension NASCentral : SMBCentralDelegate {
    
    // MARK: Access Callbacks
    
    func smbCentral(_ smbCentral: SMBCentral, didFindFolder: Bool) {
//        logVerbose( "[ %@ ]", stringFor( didFindFolder ) )
        
        DispatchQueue.main.async {
            self.delegate?.nasCentral( self, canSeeNasFolders: didFindFolder )
        }
        
        processNextRequest()
    }
    
    
    func smbCentral(_ smbCentral: SMBCentral, didCloseShareAndDevice: Bool) {
//        logVerbose( "[ %@ ]", stringFor( didCloseShareAndDevice ) )

        DispatchQueue.main.async {
            self.delegate?.nasCentral( self, didCloseShareAndDevice: true )
        }
        
        processNextRequest()
    }
    
    
    func smbCentral(_ smbCentral : SMBCentral, didConnectToDevice : Bool ) {
//        logVerbose( "[ %@ ]", stringFor( didConnectToDevice ) )
        
        DispatchQueue.main.async {
            self.delegate?.nasCentral( self, didConnectToDevice: didConnectToDevice, self.selectedDevice! )
        }
        
        processNextRequest()
    }
    
    
    func smbCentral(_ smbCentral : SMBCentral, didCreateDirectory : Bool) {
//        logVerbose( "[ %@ ]", stringFor( didCreateDirectory ) )
        
        DispatchQueue.main.async {
            self.delegate?.nasCentral( self, didCreateDirectory: didCreateDirectory )
        }
        
        processNextRequest()
    }
        

    func smbCentral(_ smbCentral : SMBCentral, didFetchDirectories : Bool, _ directoryArray : [SMBFile] ) {
//        logVerbose( "[ %@ ]", stringFor( didFetchDirectories ) )
        
        DispatchQueue.main.async {
            self.delegate?.nasCentral( self, didFetchDirectories: didFetchDirectories, directoryArray )
        }
        
        processNextRequest()
    }
    
    
    func smbCentral(_ smbCentral: SMBCentral, didFetchFile: Bool, _ fileData: Data) {
//        logVerbose( "[ %@ ]", stringFor( didFetchFile ) )
        
        DispatchQueue.main.async {
            self.delegate?.nasCentral( self, didFetchFile: didFetchFile, fileData )
        }
        
        processNextRequest()
    }
        
        
    func smbCentral(_ smbCentral : SMBCentral, didFetchShares : Bool, _ shares : [SMBShare] ) {
//        logVerbose( "[ %@ ]", stringFor( didFetchShares ) )
        
        DispatchQueue.main.async {
            self.delegate?.nasCentral( self, didFetchShares: didFetchShares, shares )
        }
        
        processNextRequest()
    }
    

    
    // MARK: Session Callbacks
    
    func smbCentral(_ smbCentral : SMBCentral, didDeleteFile : Bool, _ filename : String ) {
//        logVerbose( "[ %@ ][ %@ ]", stringFor( didDeleteFile ), filename )

        if currentCommand == .CopyDatabaseFromDeviceToNas || currentCommand == .CopyAllImagesFromDeviceToNas {
            if deviceUrlsToDeleteArray.count != 0 {
                deleteFilesFromNas()
            }
            else {
                let     path = currentCommand == .CopyDatabaseFromDeviceToNas ? "" : DirectoryNames.pictures
                
                readAndWriteDeviceDataToNasAt( path )
            }
            
        }
        else if currentCommand == .DeleteImage {
            DispatchQueue.main.async {
                self.delegate?.nasCentral( self, didDeleteImage: didDeleteFile )
            }
            
            processNextRequest()
        }
        else if currentCommand == .UnlockNas {
            DispatchQueue.main.async {
                self.delegate?.nasCentral( self, didUnlockNas: didDeleteFile )
            }
            
            processNextRequest()
        }
        else {
            logTrace( "SBH!" )
        }

    }
    
    
    func smbCentral(_ smbCentral: SMBCentral, didEndSession: Bool) {
//        logVerbose( "[ %@ ]", stringFor( didEndSession ) )
        sessionActive = false
        
        DispatchQueue.main.async {
            self.delegate?.nasCentral( self, didEndSession: didEndSession )
        }
        
        processNextRequest()
    }
    
    
    func smbCentral(_ smbCentral: SMBCentral, didFetchFiles: Bool, _ fileArray: [SMBFile] ) {
//        logVerbose( "[ %@ ] returned [ %d ] files", stringFor( didFetchFiles ), fileArray.count )
        
        if currentCommand == .FetchImageNames {
            var     imageNameArray = [String].init()
            
            for smbFile in fileArray {
                imageNameArray.append( smbFile.name )
            }
            
            DispatchQueue.main.async {
                self.delegate?.nasCentral( self, didFetch: imageNameArray )
            }
            
            processNextRequest()
        }
        else {
            if didFetchFiles {
                nasImageFileArray = fileArray
            }
            else {
                logTrace( "ERROR!  Unable to retrieve image files from NAS ... assuming there are none!" )
            }
            
            deleteFilesFromDevice()
            readNextImageFromNas()
        }

    }
    
    
    func smbCentral(_ smbCentral: SMBCentral, didReadFile: Bool, _ fileData: Data) {
        logVerbose( "[ %@ ]", stringFor( didReadFile ) )
        
        switch currentCommand {
        
        case .CompareLastUpdatedFiles:      if didReadFile {
                                                compareLastUpdatedDates( fileData )
                                            }
                                            else {
                                                DispatchQueue.main.async {
                                                    self.delegate?.nasCentral( self, didCompareLastUpdatedFiles: LastUpdatedFileCompareResult.equal )
                                                }
                                                
                                                processNextRequest()
                                            }
         
        case .CopyAllImagesFromNasToDevice: if didReadFile {
                                                writeNasImageDataToDevice( fileData )
                                            }
                                            
                                            nasImageFileArray.removeLast()
                                            readNextImageFromNas()

        case .CopyDatabaseFromNasToDevice:  writeNasRootDataToDevice( fileData )
            
        case .FetchImage:                   var     imageAvailable = false
                                            var     myImage        = UIImage.init()

                                            if didReadFile {
                                                if let image = UIImage.init( data: fileData ) {
                                                    myImage = image
                                                    imageAvailable = true
                                                }
                                                else {
                                                    logTrace( "ERROR!  Unable to create image from data!" )
                                                }
                                                
                                            }
                                            
                                            DispatchQueue.main.async {
                                                self.delegate?.nasCentral( self, didFetchImage: imageAvailable, image: myImage, filename : self.currentFilename )
                                                self.processNextRequest()
                                            }
                                            
         
        case .LockNas:                      if !didReadFile {
                                                logTrace( "Creating lockfile" )
                                                createLockFile()
                                                return
                                            }

                                            analyzeLockFile( fileData )
                                            processNextRequest()

                                            DispatchQueue.main.async {
                                                self.delegate?.nasCentral( self, didLockNas: self.deviceAccessControl.byMe )
                                            }

        default:                            logTrace( "SBH!" )
        }

    }
    
    
    func smbCentral(_ smbCentral : SMBCentral, didStartSession : Bool ) {
        logVerbose( "[ %@ ]", stringFor( didStartSession ) )
        sessionActive = didStartSession

        if reEstablishConnection && didStartSession {
            reEstablishConnection = false
            logTrace( "Session re-established" )
            processNextRequest( false )
        }
        else {
            DispatchQueue.main.async {
                self.delegate?.nasCentral( self, didStartSession: didStartSession )
            }
            
            processNextRequest()
        }
        
    }
    
    
    func smbCentral(_ smbCentral: SMBCentral, didWriteFile: Bool ) {
        logVerbose( "[ %@ ][ %@ ]", stringFor( didWriteFile ), currentFilename )

        switch currentCommand {
        
        case .CopyDatabaseFromDeviceToNas,
             .CopyAllImagesFromDeviceToNas:
            
                                    if didWriteFile {
                                        deviceUrlArrayIndex += 1
                                        
                                        if deviceUrlArrayIndex < deviceUrlArray.count {
                                            let     path = currentCommand == .CopyDatabaseFromDeviceToNas ? "" : DirectoryNames.pictures

                                            readAndWriteDeviceDataToNasAt( path )
                                        }
                                        else {
                                            logVerbose( "Transferred [ %d ] files to NAS drive", deviceUrlArrayIndex )
                                            
                                            deviceUrlArrayIndex = 0
                                            
                                            DispatchQueue.main.async {
                                                if self.currentCommand == .CopyDatabaseFromDeviceToNas {
                                                    self.delegate?.nasCentral( self, didCopyDatabaseFromDeviceToNas: true )
                                                }
                                                else {
                                                    self.delegate?.nasCentral( self, didCopyAllImagesFromDeviceToNas: true )
                                                }
                                                
                                            }

                                            processNextRequest()
                                        }

                                    }
                                    else {
                                        logTrace( "ERROR!  overwrite NAS data failed!" )
                                        
                                        DispatchQueue.main.async {
                                            if self.currentCommand == .CopyDatabaseFromDeviceToNas {
                                                self.delegate?.nasCentral( self, didCopyDatabaseFromDeviceToNas: false )
                                            }
                                            else {
                                                self.delegate?.nasCentral( self, didCopyAllImagesFromDeviceToNas: false )
                                            }
                                            
                                        }
                                        
                                        processNextRequest()
                                    }

            
        case .LockNas:              deviceAccessControl.reset()
                                    deviceAccessControl.locked = true

                                    if didWriteFile {
                                        deviceAccessControl.byMe      = true
                                        deviceAccessControl.ownerName = UIDevice.current.name
                                        logVerbose( "Created lock file ... %@", deviceAccessControl.descriptor() )
                                    }
                                    else {
                                        deviceAccessControl.ownerName = "Unknown"
                                        logVerbose( "ERROR!!!  Lock file create failed! ... %@", deviceAccessControl.descriptor() )
                                    }
                                    
                                    DispatchQueue.main.async {
                                        self.delegate?.nasCentral( self, didLockNas: self.deviceAccessControl.byMe )
                                    }
                                    
                                    processNextRequest()

            
        case .SaveImageData:        DispatchQueue.main.async {
                                        self.delegate?.nasCentral( self, didSaveImageData: didWriteFile, filename: self.currentFilename )
                                    }
                                    
                                    processNextRequest()
        
        
        default:                    logTrace( "SBH!" )

        }
        
    }
    
    
    func smbCentral(_ smbCentral: SMBCentral, didSaveData: Bool ) {
//        logVerbose( "[ %@ ]", stringFor( didSaveData ) )
        
        DispatchQueue.main.async {
            self.delegate?.nasCentral( self, didSaveData: didSaveData )
        }
        
        processNextRequest()
    }
    
    
    
    // MARK: Session Callback Utility Methods

    private func analyzeLockFile(_ fileData : Data ) {
        let     lockFileContents    = String( decoding: fileData, as: UTF8.self )
        let     components          = lockFileContents.components( separatedBy: "," )
        let     thisDeviceId        = UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"
        let     thisDeviceName      = UIDevice.current.name

        deviceAccessControl.reset()
        
        if components.count == 2 {
            let     lockDeviceId   = components[1]
            let     lockDeviceName = components[0]
            let     byMe           = ( thisDeviceName == lockDeviceName ) && ( thisDeviceId == lockDeviceId )
            
            deviceAccessControl.byMe      = byMe
            deviceAccessControl.locked    = true
            deviceAccessControl.ownerName = lockDeviceName
            logVerbose( "From existing lock file ... %@", deviceAccessControl.descriptor() )
        }
        else {
            logVerbose( "ERROR!  lockMessage NOT properly formatted\n    [ %@ ]", lockFileContents )

            if lockFileContents.count == 0 {
                createLockFile()

                deviceAccessControl.byMe      = true
                deviceAccessControl.locked    = true
                deviceAccessControl.ownerName = thisDeviceName
                logVerbose( "Overriding ... %@", deviceAccessControl.descriptor() )
            }
            
        }
        
    }
    
    
    private func compareLastUpdatedDates(_ nasData : Data ) {
        let     fileManager = FileManager.default
        let     formatter   = DateFormatter()
        
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        
        if let documentDirectoryURL = fileManager.urls( for: .documentDirectory, in: .userDomainMask ).first {
            let     deviceFileUrl = documentDirectoryURL.appendingPathComponent( Filenames.lastUpdated )
            
            if FileManager.default.fileExists(atPath: deviceFileUrl.path ) {
                
                if let deviceFileData = FileManager.default.contents( atPath: deviceFileUrl.path ) {
                    var     compareResult    = LastUpdatedFileCompareResult.equal
                    let     deviceDateString = String( decoding: deviceFileData, as: UTF8.self )
                    let     deviceDate       = formatter.date( from: deviceDateString )
                    let     nasDateString    = String( decoding: nasData, as: UTF8.self )
                    let     nasDate          = formatter.date( from: nasDateString )
                    
                    if let dateOnNas = nasDate?.timeIntervalSince1970, let dateOnDevice = deviceDate?.timeIntervalSince1970 {
                        if dateOnNas < dateOnDevice {
                            compareResult = LastUpdatedFileCompareResult.deviceIsNewer
                        }
                        else if dateOnDevice < dateOnNas {
                            compareResult = LastUpdatedFileCompareResult.nasIsNewer
                        }
                        
                    }
                    else {
                        logTrace( "ERROR!  Could NOT unwrap dateOnNas or dateOnDevice!" )
                    }
                    
                    logVerbose( "[ %@ ]", descriptionForCompare( compareResult ) )
                    
                    DispatchQueue.main.async {
                        self.delegate?.nasCentral( self, didCompareLastUpdatedFiles: compareResult )
                    }
                    
                    processNextRequest()
                    return
                }
                else {
                    logTrace( "ERROR!  Could NOT unwrap deviceFileData!" )
                }

            }
            else {
                logTrace( "LastUpdated file does NOT Exist on Device" )
            }

        }
        else {
            logTrace( "ERROR!  Could NOT unwrap documentDirectoryURL!" )
        }

        logTrace( "defaulting to [ nasIsNewer ]" )
        DispatchQueue.main.async {
            self.delegate?.nasCentral( self, didCompareLastUpdatedFiles: LastUpdatedFileCompareResult.nasIsNewer )
        }
        
        processNextRequest()
    }
    
    
    private func createLockFile() {
//        logTrace()
        let     deviceName  = UIDevice.current.name
        let     deviceId    = UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"
        let     fullPath    = nasAccessKey.path + "/" + Filenames.lockFile
        let     lockMessage = String( format: "%@,%@", deviceName, deviceId )
        let     fileData    = Data( lockMessage.utf8 )
        
        currentFilename = Filenames.lockFile
        
        DispatchQueue.main.async {
            SMBCentral.sharedInstance.writeData( fileData, toFileAt: fullPath, self )
        }

    }
    
    
    private func readAndWriteDeviceDataToNasAt(_ localPath : String ) {
        
        if deviceUrlArray.isEmpty {
//            logTrace( "Done!" )
            DispatchQueue.main.async {
                if self.currentCommand == .CopyDatabaseFromDeviceToNas {
                    self.delegate?.nasCentral( self, didCopyDatabaseFromDeviceToNas: true )
                }
                else {
                    self.delegate?.nasCentral( self, didCopyAllImagesFromDeviceToNas: true )
                }
                
            }
            
            processNextRequest()
            return
        }
        
        currentFilename = deviceUrlArray[deviceUrlArrayIndex].lastPathComponent

        if let fileData = FileManager.default.contents( atPath: deviceUrlArray[deviceUrlArrayIndex].path ) {
            var     fullPath = nasAccessKey.path + "/"
            
            if !localPath.isEmpty {
                fullPath += localPath + "/"
            }
            
            fullPath += currentFilename
            
            logVerbose( "[ %@ ]", currentFilename )
            DispatchQueue.main.async {
                SMBCentral.sharedInstance.writeData( fileData, toFileAt: fullPath, self )
            }
            
        }
        else {
            logVerbose( "ERROR!  Could not un-wrap data for [ %@ ]", currentFilename )
            
            if currentCommand == .CopyDatabaseFromDeviceToNas {
                DispatchQueue.main.async {
                    self.delegate?.nasCentral( self, didCopyDatabaseFromDeviceToNas: false )
                }
                
            }
            else {
                logTrace( "SBH!" )
            }
            
            processNextRequest()
        }
        
    }
    
    
    private func writeNasRootDataToDevice(_ fileData : Data ) {
//        logTrace()
        var     successFlag = true
        
        if let targetUrl = deviceUrlArray.last {
            logVerbose( "[ %@ ]", targetUrl.lastPathComponent )
            FileManager.default.createFile( atPath: targetUrl.path, contents: fileData, attributes: nil )
            
            deviceUrlArray.removeLast()
            
            if deviceUrlArray.count != 0 {
                readNextRootFileFromNas()
                return
            }
            
        }
        else {
            logTrace( "ERROR!  Could NOT unwrap targetUrl" )
            successFlag = false
        }
       
        DispatchQueue.main.async {
            switch self.currentCommand {
            case .CopyAllImagesFromDeviceToNas:         self.delegate?.nasCentral( self, didCopyAllImagesFromDeviceToNas: successFlag )
            case .CopyDatabaseFromDeviceToNas:          self.delegate?.nasCentral( self, didCopyDatabaseFromDeviceToNas:  successFlag )
            case .CopyDatabaseFromNasToDevice:          self.delegate?.nasCentral( self, didCopyDatabaseFromNasToDevice:  successFlag )
            case .UnlockNas:                            self.delegate?.nasCentral( self, didUnlockNas: successFlag )
            default:                                    logTrace( "SBH!" )
           }
            
        }
        
        logTrace( "Done!" )
        processNextRequest()
    }
        

    private func writeNasImageDataToDevice(_ fileData : Data ) {
        var     targetUrl = documentDirectoryURL.appendingPathComponent( DirectoryNames.pictures )
        
        targetUrl = targetUrl.appendingPathComponent( currentFilename )
        logVerbose( "[ %@ ]", targetUrl.path )
        
        FileManager.default.createFile( atPath: targetUrl.path, contents: fileData, attributes: nil )
    }
    

}
    


// MARK: Globally Accessible Definitions and Methods

struct LastUpdatedFileCompareResult {
    static let deviceIsNewer = Int( 0 )
    static let equal         = Int( 1 )
    static let nasIsNewer    = Int( 2 )
    static let cloudIsNewer  = Int( 3 )
}


func descriptionForCompare(_ lastUpdatedCompare: Int ) -> String {
    var     description = "Unknown"
    
    if lastUpdatedCompare == LastUpdatedFileCompareResult.deviceIsNewer {
        description = "Device is Newer"
    }
    else if lastUpdatedCompare == LastUpdatedFileCompareResult.equal {
        description = "Equal"
    }
    else if lastUpdatedCompare == LastUpdatedFileCompareResult.nasIsNewer {
        description = "NAS is Newer"
    }
    else if lastUpdatedCompare == LastUpdatedFileCompareResult.cloudIsNewer {
        description = "Cloud is Newer"
    }

    return description
}


