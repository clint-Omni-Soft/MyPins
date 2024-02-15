//
//  PleaseWaitViewController.swift
//  MyPins
//
//  Ported by Clint Shank from WineStock on 03/23/23.
//  Copyright © 2020-2023 Omni-Soft, Inc. All rights reserved.
//

import UIKit



class PleaseWaitViewController: UIViewController {
    
    // MARK: Public Variables
    
    @IBOutlet weak var activityIndicator : UIActivityIndicatorView!
    @IBOutlet weak var pleaseWaitLabel   : UILabel!
    @IBOutlet weak var stayOfflineButton : UIButton!
    
    
    // MARK: Private Variables
    
    private let deviceAccessControl = DeviceAccessControl.sharedInstance
    private var displayingAlert     = false
    private let pinCentral          = PinCentral.sharedInstance
    private let notificationCenter  = NotificationCenter.default
    
    
        // MARK: UIViewController Lifecycle Methods

    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        pleaseWaitLabel.text = NSLocalizedString( "LabelText.PleaseWaitWhileWeConnect", comment: "Please wait while we connect to your external device ..." )
        stayOfflineButton.setTitle( NSLocalizedString( "ButtonTitle.StayOffline", comment: "Stay Offline" ), for: .normal)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        activityIndicator.startAnimating()
        registerForNotifications()
        
        deviceAccessControl.reset()
        pinCentral.stayOffline = false
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        logTrace()
        super.viewWillDisappear( animated )
        
        notificationCenter.removeObserver( self )
    }
    
    
    // MARK: Target/Action Methods
    
    @IBAction func stayOfflineButtonTouched(_ sender: UIButton) {
        logTrace()
        makeSureUserHasBeenWarned()
     }
    
    
    // MARK: NSNotification Methods
    
    @objc func cannotSeeExternalDevice( notification: NSNotification ) {
        logTrace()
        displayAlert(title: NSLocalizedString( "AlertTitle.Error", comment: "Error!" ), message: NSLocalizedString( "AlertMessage.CannotSeeExternalDevice", comment: "We cannot see your external device.  Move closer to your WiFi network and try again." ) )
    }

    
    @objc func externalDeviceLocked( notification: NSNotification ) {
        logTrace()
        let     format  = NSLocalizedString( "AlertMessage.ExternalDriveLocked", comment: "The database on your external drive is locked by another user [ %@ ].  You can wait until the other user closes the app (which unlocks it) or make you changes offline and upload them when the drive is no longer locked." )
        let     message = String( format: format, deviceAccessControl.ownerName )
        
        displayAlert(title: NSLocalizedString( "AlertTitle.Warning", comment: "Warning!" ), message: message )
    }

    
    @objc func ready( notification: NSNotification ) {
        logTrace()
        if !displayingAlert {
            switchToMainApp()
        }

    }
    
    
    @objc func unableToConnectToExternalDevice( notification: NSNotification ) {
        logTrace()
        displayAlert(title: NSLocalizedString( "AlertTitle.Error", comment: "Error!" ), message: NSLocalizedString( "AlertMessage.UnableToConnect", comment: "We are unable to connect to your external device.  Move closer to your WiFi network and try again." ) )
    }

    
    @objc func updatingExternalDevice( notification: NSNotification ) {
        logTrace()
        displayAlert(title: NSLocalizedString( "AlertMessage.UpdatingExternalDevice", comment: "This device is updating the database on your external device.  Please wait a few minutes then try again." ), message: "" )
    }
    


    // MARK: Utility Methods
    
    private func disableControls() {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        pleaseWaitLabel  .isHidden = true
    }
    
    
    private func displayAlert( title: String, message: String ) {
        if displayingAlert {
            logVerbose( "displayingAlert!  Suppressing this one.\n    [ %@ ][ %@ ]", title, message )
            return
        }
        
        let     alert = UIAlertController.init( title: title, message: message, preferredStyle: .alert )
        
        let     okAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.OK", comment: "OK" ), style: .default )
        { ( alertAction ) in
            logTrace( "OK Action" )
            self.displayingAlert = false
        }
        
        displayingAlert = true
        alert.addAction( okAction )
        
        present( alert, animated: true, completion: nil )
    }
    
    
    private func makeSureUserHasBeenWarned() {
        logTrace()
        disableControls()

        if !flagIsPresentInUserDefaults( UserDefaultKeys.dontRemindMeAgain ) {
            warnUser()
        }
        else {
            deviceAccessControl.byMe = true
            pinCentral.stayOffline   = true
            
            switchToMainApp()
        }
        
    }
    

    private func registerForNotifications() {
        logTrace()
        notificationCenter.addObserver( self, selector: #selector( cannotSeeExternalDevice(         notification: ) ), name: NSNotification.Name( rawValue: Notifications.cannotSeeExternalDevice ), object: nil )
        notificationCenter.addObserver( self, selector: #selector( externalDeviceLocked(            notification: ) ), name: NSNotification.Name( rawValue: Notifications.externalDeviceLocked    ), object: nil )
        notificationCenter.addObserver( self, selector: #selector( ready(                           notification: ) ), name: NSNotification.Name( rawValue: Notifications.ready                   ), object: nil )
        notificationCenter.addObserver( self, selector: #selector( unableToConnectToExternalDevice( notification: ) ), name: NSNotification.Name( rawValue: Notifications.unableToConnect         ), object: nil )
        notificationCenter.addObserver( self, selector: #selector( updatingExternalDevice(          notification: ) ), name: NSNotification.Name( rawValue: Notifications.updatingExternalDevice  ), object: nil )
    }
    
    
    private func switchToMainApp() {
        logTrace()
        let     appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        appDelegate.switchToMainApp()
    }
    
    
    private func warnUser() {
        logTrace()
        disableControls()
        
        let     alert = UIAlertController.init( title:   NSLocalizedString( "AlertTitle.Warning",          comment: "Warning!" ),
                                                message: NSLocalizedString( "AlertMessage.OfflineWarning", comment: "We cannot connect to your remote storage.  Because this app is designed to work offline, you can make changes that we will upload the next time you connect to your remote storage.  Just be aware that if more than one person makes changes offline, your changes may be overwritten." ),
                                                preferredStyle: .alert)

        let     gotItAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.GotIt", comment: "Got it!" ), style: .default )
        { ( alertAction ) in
            logTrace( "Got It Action" )
            self.deviceAccessControl.byMe = true
            self.pinCentral.stayOffline   = true
            
            self.switchToMainApp()
        }
        
        let     dontRemindMeAgainAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.DontRemindMeAgain", comment: "Don't remind me again." ), style: .destructive )
        { ( alertAction ) in
            logTrace( "Don't Remind Me Again Action" )
            self.saveFlagInUserDefaults( UserDefaultKeys.dontRemindMeAgain )
            
            self.deviceAccessControl.byMe = true
            self.pinCentral.stayOffline   = true
            
            self.switchToMainApp()
        }
        
        alert.addAction( gotItAction )
        
        if !flagIsPresentInUserDefaults( UserDefaultKeys.dontRemindMeAgain ) {
            alert.addAction( dontRemindMeAgainAction )
        }

        present( alert, animated: true, completion: nil )
    }
    
    
}


