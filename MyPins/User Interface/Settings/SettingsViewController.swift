//
//  SettingsViewController.swift
//  MyPins
//
//  Created by Clint Shank on 5/2/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit


class SettingsViewController: UIViewController {
    
    // MARK: Public Variables
    
    @IBOutlet weak var myActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var myTableView        : UITableView!
    
    
    // MARK: Private Variables
    
    private struct CellIndexes {
        static let about             = 0
        static let altitudeUnits     = 1
        static let colorMapping      = 2
        static let dataStoreLocation = 3
        static let howToUse          = 4
        static let missingImageCheck = 5
        static let setupThumbnails   = 6
        static let deviceName        = 7
    }
    
    private struct Constants {
        static let cellId = "SettingsTableViewCell"
    }
    
    private struct StoryboardIds {
        static let about             = "AboutViewController"
        static let colorMapping      = "ColorMappingViewController"
        static let dataStoreLocation = "DataStoreLocationViewController"
        static let howToUse          = "HowToUseViewController"
    }
    
    private var canSeeNasFolders    = false
    private var displayingAlert     = false
    private let fileManager         = FileManager.default
    private var imagesLoaded        = 0
    private var imagesRequested     : [String] = []
    private var nasCentral          = NASCentral.sharedInstance
    private let notificationCenter  = NotificationCenter.default
    private let pinCentral          = PinCentral.sharedInstance
    private var replies             = 0
    private var showHowToUse        = true
    private var usingThumbnails     = false
    private let userDefaults        = UserDefaults.standard

    private var optionArray         = [ NSLocalizedString( "Title.About",              comment: "About"               ),
                                        NSLocalizedString( "Title.AltitudeUnits",      comment: "Altitude Units"      ),
                                        NSLocalizedString( "Title.ColorMapping",       comment: "Color Mapping"       ),
                                        NSLocalizedString( "Title.DataStoreLocation",  comment: "Data Store Location" ),
                                        NSLocalizedString( "Title.HowToUse",           comment: "How to Use"          ) ]

    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString( "Title.Settings",  comment: "Settings"  )
        
        if flagIsPresentInUserDefaults( UserDefaultKeys.howToUseShown ) {
            showHowToUse = false
        }
        else {
            saveFlagInUserDefaults( UserDefaultKeys.howToUseShown   )
        }
        
        usingThumbnails = flagIsPresentInUserDefaults( UserDefaultKeys.usingThumbnails )
        
        if pinCentral.dataStoreLocation != .device {
            optionArray.append( NSLocalizedString( "Title.MissingImageCheck",      comment: "Missing Image Check"       ) )
            optionArray.append( NSLocalizedString( "Title.SetupThumbnails",        comment: "Setup Thumbnails"          ) )
            optionArray.append( NSLocalizedString( "Title.UserAssignedDeviceName", comment: "User Assigned Device Name" ) )
        }

//        if runningInSimulator() {   // Testing
//            optionArray.append( NSLocalizedString( "Title.ReduceImageSize",   comment: "Reduce Image Size" ) )
//        }
        
        notificationCenter.addObserver( self, selector: #selector( deviceNameNotSet( notification: ) ), name: NSNotification.Name( rawValue: Notifications.deviceNameNotSet ), object: nil )
        notificationCenter.addObserver( self, selector: #selector( ready(            notification: ) ), name: NSNotification.Name( rawValue: Notifications.ready            ), object: nil )
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        myActivityIndicator.isHidden = true
        myActivityIndicator.stopAnimating()

        if !pinCentral.stayOffline && ( pinCentral.dataStoreLocation == .nas || pinCentral.dataStoreLocation == .shareNas ) {
            canSeeNasFolders = false
            NASCentral.sharedInstance.canSeeNasFolders( self )
            
            myActivityIndicator.isHidden = false
            myActivityIndicator.startAnimating()
        }
        else {
            myActivityIndicator.isHidden = true
            myActivityIndicator.stopAnimating()
        }

        loadBarButtonItems()
        
        if showHowToUse {
            showHowToUse = false

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.pushViewControllerWith( StoryboardIds.howToUse )
            }
            
        }
        
    }
    

    
    // MARK: NSNotification Methods
    
    @objc func deviceNameNotSet( notification: NSNotification ) {
        logTrace()
        promptForDeviceName()
    }


    @objc func ready( notification: NSNotification ) {
        logTrace()
        showResults()
    }



    // MARK: Target/Action Methods
    
    @IBAction func infoBarButtonItemTouched(_ sender : UIBarButtonItem ) {
        let     message = String( format: NSLocalizedString( "AlertMessage.SelectHowToUseForInfo", comment: "Select '%@' for helpful information on: %@,%@,%@,%@ and\nmany other topics." ),
                                          NSLocalizedString( "Title.HowToUse",                     comment: "How to Use" ),
                                          NSLocalizedString( "Title.PinList",                      comment: "Pin List" ),
                                          NSLocalizedString( "Title.PinEditor",                    comment: "Pin Editor" ),
                                          NSLocalizedString( "Title.Map",                          comment: "Map" ),
                                          NSLocalizedString( "Title.DataStoreLocation",            comment: "Data Store Location" ) )
        
        presentAlert( title: NSLocalizedString( "AlertTitle.GotAQuestion", comment: "Got a question?" ), message: message )
    }
    
    

    // MARK: Utility Methods

    private func loadBarButtonItems() {
        logTrace()
        navigationItem.rightBarButtonItem = UIBarButtonItem.init( image: UIImage(named: "info" ), style: .plain, target: self, action: #selector( infoBarButtonItemTouched(_:) ) )
    }
    
    
    private func pushViewControllerWith(_ storyboardId: String ) {
        logVerbose( "[ %@ ]", storyboardId )
        let viewController = iPhoneViewControllerWithStoryboardId( storyboardId: storyboardId )
        
        navigationController?.pushViewController( viewController, animated: true )
    }

    
}



// MARK: NASCentral Delegate Methods

extension SettingsViewController: NASCentralDelegate {
    
    func nasCentral(_ nasCentral: NASCentral, canSeeNasFolders: Bool) {
        logVerbose( "[ %@ ]", stringFor( canSeeNasFolders ) )
        
        self.canSeeNasFolders = canSeeNasFolders
        
        myActivityIndicator.stopAnimating()
        myActivityIndicator.isHidden = true
    }

    
}



// MARK: UITableViewDataSource Methods

extension SettingsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell( withIdentifier: Constants.cellId, for: indexPath)
        
        cell.textLabel?.text = optionArray[indexPath.row]
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int ) -> Int {
        return optionArray.count
    }
    
    
}


// MARK: - UITableViewDelegate Methods

extension SettingsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath ) {
        logTrace()
        tableView.deselectRow( at: indexPath, animated: false )
        
        switch indexPath.row {
            case CellIndexes.about:             pushViewControllerWith( StoryboardIds.about             )
            case CellIndexes.altitudeUnits:     promptForAltitudeUnits()
            case CellIndexes.colorMapping:      pushViewControllerWith( StoryboardIds.colorMapping      )
            case CellIndexes.dataStoreLocation: pushViewControllerWith( StoryboardIds.dataStoreLocation )
            case CellIndexes.deviceName:        promptForDeviceName()
            case CellIndexes.howToUse:          pushViewControllerWith( StoryboardIds.howToUse          )
            case CellIndexes.missingImageCheck: checkForMissingImages()
            case CellIndexes.setupThumbnails:   checkThumbnailsAndPromptForActionToTake()
            default:    break
        }
            
    }
    
    
    
    // MARK: UITableViewDelegate Utility Methods
 
    private func checkForMissingImages() {
        let     alert = UIAlertController.init(title  : NSLocalizedString( "AlertTitle.CheckForMissingImages",   comment: "Check for missing images" ),
                                               message: NSLocalizedString( "AlertMessage.CheckForMissingImages", comment: "This may take some time.  If you want to do this you will need to keep the app in the foreground until it finishes." ), preferredStyle: .alert )
        
        let     okAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.OK", comment: "OK" ), style: .default ) {
            ( alertAction ) in
            logTrace( "OK Action" )
            self.myActivityIndicator.isHidden = false
            self.myActivityIndicator.startAnimating()

            self.imagesLoaded = 0
            self.replies      = 0
            
            let requestCount = self.scanForAndRequestMissingImages()
            // if we request any images we track the download progress in the pinCentral(didFetchImage::) method and will hide the activityIndicator when we finish
            
            if requestCount == 0 {
                self.presentAlert(title: NSLocalizedString( "AlertTitle.NoMissingImages", comment: "You have NO missing images." ), message: "" )
                
                self.myActivityIndicator.isHidden = true
                self.myActivityIndicator.stopAnimating()
            }
            
        }
        
        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel ) {
            ( alertAction ) in
            logTrace( "Cancel Action" )
        }

        alert.addAction( okAction )
        alert.addAction( cancelAction )

        present( alert, animated: true )
    }
    

    private func checkThumbnailsAndPromptForActionToTake() {
        logTrace()
        let     missingThumbNails = getImagesMissingThumbnails()
        
        if missingThumbNails.count == 0 {
            presentAlert(title: NSLocalizedString( "AlertTitle.NoMissingThumbnails", comment: "There are no missing thumbnail images." ), message: "" )
            return
        }
        
        let     titleMessage  = String( format: NSLocalizedString( "AlertTitle.MissingThumbnails", comment: "There are %d missing thumbnail images.  Would you like to create them now?" ), missingThumbNails.count )
        let     alert         = UIAlertController.init(title: titleMessage, message: "", preferredStyle: .alert )
        
        let     okAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.OK", comment: "OK" ), style: .default ) {
            ( alertAction ) in
            logTrace( "OK Action" )
            var thumbNailsCreated = 0
            
            self.myActivityIndicator.isHidden = false
            self.myActivityIndicator.startAnimating()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                for imageName in missingThumbNails {
                    if self.pinCentral.createThumbnailFrom( imageName ) {
                        thumbNailsCreated += 1
                    }

                }
                
                self.myActivityIndicator.isHidden = true
                self.myActivityIndicator.stopAnimating()
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                    let titleText = String( format: NSLocalizedString( "AlertTitle.CreatedThumbnails", comment: "Created %d out of %d missing thumbnail images." ), thumbNailsCreated, missingThumbNails.count )
                    
                    self.presentAlert(title: titleText, message: "" )
                }
                
                self.saveFlagInUserDefaults( UserDefaultKeys.usingThumbnails )
                self.usingThumbnails = true
            }

        }

        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel ) {
            ( alertAction ) in
            logTrace( "Cancel Action" )
        }

        alert.addAction( okAction )
        alert.addAction( cancelAction )

        present( alert, animated: true )
    }
    
    
    func getImagesMissingThumbnails() -> [String] {
        let directoryPath = pinCentral.pictureDirectoryPath()
        var missingImages: [String] = []

        if directoryPath.isEmpty {
            logTrace( "ERROR!!!  directoryPath.isEmpty!" )
            return []
        }
        
        let picturesDirectoryURL = URL.init( fileURLWithPath: directoryPath )

        for array in pinCentral.pinArrayOfArrays {
            for pin in array {
                if let imageName = pin.imageName {
                    if !imageName.isEmpty {
                        let thumbNailName = GlobalConstants.thumbNailPrefix + imageName
                        let imageFileURL  = picturesDirectoryURL.appendingPathComponent( thumbNailName )
                        
                        if !fileManager.fileExists( atPath: imageFileURL.path ) {
                            missingImages.append( imageName )
                        }
                        
                    }
                    
                }
                
            }

        }
            
        logVerbose( "discovered [ %d ] images missing thumbnails", missingImages.count )
        return missingImages
    }
    
    
    private func promptForAltitudeUnits() {
        let     units   = pinCentral.displayUnits() == DisplayUnits.meters ? NSLocalizedString( "ButtonTitle.Meters", comment: "Meters" ) : NSLocalizedString( "ButtonTitle.Feet", comment: "Feet" )
        let     message = String( format: NSLocalizedString( "AlertMessage.SelectUnitsForAltitude", comment: "Currently using %@ " ), units )
        let     alert   = UIAlertController.init(title: NSLocalizedString( "AlertTitle.SelectUnitsForAltitude", comment: "Select Units for Altitude" ), message: message, preferredStyle: .alert )
        
        let     feetAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Feet", comment: "Feet" ), style: .default ) {
            ( alertAction ) in
            logTrace( "Feet Action" )
            self.userDefaults.set( DisplayUnits.feet, forKey: DisplayUnits.altitude )
            self.userDefaults.synchronize()
        }

        let     metersAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Meters", comment: "Meters" ), style: .default ) {
            ( alertAction ) in
            logTrace( "Meters Action" )
            self.userDefaults.set( DisplayUnits.meters, forKey: DisplayUnits.altitude )
            self.userDefaults.synchronize()
        }

        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel ) {
            ( alertAction ) in
            logTrace( "Cancel Action" )
        }

        alert.addAction( feetAction   )
        alert.addAction( metersAction )
        alert.addAction( cancelAction )

        present( alert, animated: true )
    }
    
    
    private func promptForDeviceName() {
        let     alert = UIAlertController.init(title: NSLocalizedString( "AlertTitle.EnterDeviceName", comment: "Enter Device Name" ), message: "", preferredStyle: .alert )
        
        let     okAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.OK", comment: "OK" ), style: .default ) {
            ( alertAction ) in
            logTrace( "OK Action" )
            let     deviceNameTextField = alert.textFields![0] as UITextField
            
            if let textString = deviceNameTextField.text {
                
                if !textString.isEmpty {
                    if textString == self.pinCentral.deviceName {
                        logTrace( "No change ... do nothing" )
                    }
                    else {
                        logVerbose( "name[ %@ ]", textString )
                        self.pinCentral.deviceName = textString
                    }

                }
                else {
                    logTrace( "We got an empty string" )
                }
                
            }
            else {
                logTrace( "We didn't get anything" )
            }

        }

        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel ) {
            ( alertAction ) in
            logTrace( "Cancel Action" )
        }

        alert.addTextField
            { ( textField ) in
                textField.autocapitalizationType = .words
                textField.placeholder            = NSLocalizedString( "LabelText.NotSet", comment: "Not Set" )
                textField.text                   = self.pinCentral.deviceName
            }
        
        alert.addAction( okAction )
        alert.addAction( cancelAction )
        
        present( alert, animated: true, completion: {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) {
                var presentAgain = false
                
                // Keep after them until they provide a name
                if let deviceNameString = self.userDefaults.string( forKey: UserDefaultKeys.deviceName ) {
                    presentAgain = deviceNameString.isEmpty || deviceNameString.count == 0
                }
                else {
                    presentAgain = true
                }
                
                if presentAgain {
                    self.promptForDeviceName()
                }
                
            }
            
        })
        
    }
   
    
    private func scanForAndRequestMissingImages() -> Int {
        var requestCount = 0
        
        if !pinCentral.stayOffline && pinCentral.dataStoreLocation != .device {
            logTrace()
            for array in pinCentral.pinArrayOfArrays {
                for pin in array {
                    if let imageName = pin.imageName {
                        if !imageName.isEmpty {
                            let descriptor = pinCentral.shortDescriptionFor( pin )
                            var imageCount = pinCentral.fetchMissingImages( imageName, descriptor, self )
                            
                            requestCount += imageCount
                            
                            while imageCount > 0 {
                                imagesRequested.append( imageName )
                                imageCount -= 1
                            }
                            
                        }
                        
                    }
                   
                }

            }
            
        }
        else {
            logTrace( "Do nothing!" )
        }

        return requestCount
    }


}



// MARK: PinCentralDelegate Methods

extension SettingsViewController: PinCentralDelegate {
    
    func pinCentral(_ pinCentral: PinCentral, didFetchImage: Bool, filename: String, image: UIImage) {
        imagesLoaded += didFetchImage ? 1 : 0
        replies      += 1
        
//        logVerbose( "%d / %d / %d", imagesRequested.count, imagesLoaded, replies )
        
        if replies == imagesRequested.count {
            if replies == imagesRequested.count {
                showResults()
            }
            
        }
        
    }
        
        
    private func showResults() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
            let titleText = String( format: NSLocalizedString( "AlertTitle.RequestedImagesLoaded", comment: "Loaded %d of %d images requested." ), self.imagesLoaded, self.imagesRequested.count )
            
            self.myActivityIndicator.isHidden = true
            self.myActivityIndicator.stopAnimating()
            
            if self.displayingAlert {
                logTrace( "We are displaying an alert ... don't try it again." )
            }
            else {
                let     alert    = UIAlertController.init( title: titleText, message: nil, preferredStyle: .alert )
                let     okAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.OK", comment: "OK" ), style: .cancel )
                { ( alertAction ) in
                    logTrace( "OK Action" )
                    self.displayingAlert = false
                }

                alert.addAction( okAction )
                
                self.displayingAlert = true
                self.present( alert, animated: true, completion: nil )
            }

        }

    }

    
}



