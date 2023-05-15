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
    private let pinCentral          = PinCentral.sharedInstance
    private var showingAlert        = false
    
    
    
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
        
        NotificationCenter.default.removeObserver( self )
    }
    
    
    // MARK: Target/Action Methods
    
    @IBAction func stayOfflineButtonTouched(_ sender: UIButton) {
        logTrace()
        makeSureUserHasBeenWarned()
     }
    
    
    // MARK: NSNotification Methods
    
    @objc func cannotSeeExternalDevice( notification: NSNotification ) {
        logTrace()
        makeSureUserHasBeenWarned()
    }

    
    @objc func externalDeviceLocked( notification: NSNotification ) {
        logTrace()
        let     format  = NSLocalizedString( "AlertMessage.ExternalDriveLocked", comment: "The database on your external drive is locked by another user [ %@ ].  You can look around but you will not be allowed to change anything until it is unlocked by the other user (closing the app unlocks it)." )
        let     message = String( format: format, deviceAccessControl.ownerName )
        
        showAlertWith( NSLocalizedString( "AlertTitle.Warning", comment: "Warning!" ), message )
    }

    
    @objc func ready( notification: NSNotification ) {
        logTrace()
        if !showingAlert {
            switchToMainApp()
        }

    }
    
    
    @objc func unableToConnectToExternalDevice( notification: NSNotification ) {
        logTrace()
        makeSureUserHasBeenWarned()
    }

    
    @objc func updatingExternalDevice( notification: NSNotification ) {
        logTrace()
        showAlertWith( "", NSLocalizedString( "AlertMessage.UpdatingExternalDevice", comment: "This device is updating the database on your external device.  Please wait a few minutes then try again." ) )
    }
    


    // MARK: Utility Methods
    
    private func disableControls() {
        activityIndicator.stopAnimating()
        activityIndicator.isHidden = true
        pleaseWaitLabel  .isHidden = true
    }
    
    
    private func makeSureUserHasBeenWarned() {
        logTrace()
        disableControls()

        if !flagIsPresentInUserDefaults( UserDefaultKeys.userHasBeenWarned ) {
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
        NotificationCenter.default.addObserver( self,
                                                selector : #selector( cannotSeeExternalDevice( notification: ) ),
                                                name     : NSNotification.Name( rawValue: Notifications.cannotSeeExternalDevice ),
                                                object   : nil )
        NotificationCenter.default.addObserver( self,
                                                selector : #selector( externalDeviceLocked( notification: ) ),
                                                name     : NSNotification.Name( rawValue: Notifications.externalDeviceLocked ),
                                                object   : nil )
        NotificationCenter.default.addObserver( self,
                                                selector : #selector( ready( notification: ) ),
                                                name     : NSNotification.Name( rawValue: Notifications.ready ),
                                                object   : nil )
        NotificationCenter.default.addObserver( self,
                                                selector : #selector( unableToConnectToExternalDevice( notification: ) ),
                                                name     : NSNotification.Name( rawValue: Notifications.unableToConnect ),
                                                object   : nil )
        NotificationCenter.default.addObserver( self,
                                                selector : #selector( updatingExternalDevice( notification: ) ),
                                                name     : NSNotification.Name( rawValue: Notifications.updatingExternalDevice ),
                                                object   : nil )
    }
    
    
    private func showAlertWith(_ title : String, _ message : String ) {
        logVerbose( "[ %@ ]\n    [ %@ ]", title, message )
        
        disableControls()
        showingAlert = true

        let     alert    = UIAlertController.init( title: title, message: message, preferredStyle: .alert )
        let     okAction = UIAlertAction.init(     title: NSLocalizedString( "ButtonTitle.OK",   comment: "OK" ), style: .default ) {
            ( alertAction ) in
            logTrace( "OK Action" )
            
            self.switchToMainApp()
        }
        
        alert.addAction( okAction )

        present( alert, animated: true, completion: nil )
    }
    
    
    private func switchToMainApp() {
        logTrace()
        let     appDelegate = UIApplication.shared.delegate as! AppDelegate
        
        NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.pleaseWaitingDone ), object: self )
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
            self.saveFlagInUserDefaults( UserDefaultKeys.userHasBeenWarned )
            
            self.deviceAccessControl.byMe = true
            self.pinCentral.stayOffline   = true
            
            self.switchToMainApp()
        }
        
        alert.addAction( gotItAction )
        
        present( alert, animated: true, completion: nil )
    }
    
    
}


