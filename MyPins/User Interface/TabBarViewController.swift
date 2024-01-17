//
//  TabBarViewController.swift
//  MyPins
//
//  Created by Clint Shank on 5/2/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit



class TabBarViewController: UITabBarController {
    
    // MARK: Private Variables

    private var inBackground         = false
    private var lastTabSelected      = ""
    private let pinCentral           = PinCentral.sharedInstance
    private let notificationCenter   = NotificationCenter.default
    private var transferringDatabase = false
    private var userDefaults         = UserDefaults.standard


    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()

        logVerbose( "didOpenDatabase[ %@ ]", stringFor( pinCentral.didOpenDatabase ) )

        if !pinCentral.didOpenDatabase {
            pinCentral.openDatabaseWith( self )
        }
        
        self.delegate = self    // We are now the UITabBarControllerDelegate
        
        lastTabSelected = userDefaults.string(forKey: UserDefaultKeys.lastTabSelected ) ?? ""
        logVerbose("lastTabSelected[ %@ ]", lastTabSelected )

        if !flagIsPresentInUserDefaults( UserDefaultKeys.howToUseShown ) {
            lastTabSelected = "Settings"
            saveFlagInUserDefaults( UserDefaultKeys.usingThumbnails )   // We want to do this by default... so, the first time in we set it
        }

    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear( animated )

        if inBackground {
            logTrace( "inBackground ... do nothing" )
            notificationCenter.addObserver( self, selector: #selector( enteringForeground( notification: ) ), name: NSNotification.Name( rawValue: Notifications.enteringForeground ), object: nil )
            return
        }
        
        logTrace()
        setupTabBar()
        setupNotifications()
        setSystemTint()

        if pinCentral.dataStoreLocation == .nas || pinCentral.dataStoreLocation == .shareNas {
            checkDeviceName()
        }
        else {
            if !self.flagIsPresentInUserDefaults( UserDefaultKeys.usingThumbnails ) {
                promptToEnableThumbnails()
            }

        }
            
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        logTrace()
        super.viewWillDisappear( animated )
        
        NotificationCenter.default.removeObserver( self )
    }
    
    
    override func didReceiveMemoryWarning() {
        logTrace( "MEMORY WARNING!!!" )
        super.didReceiveMemoryWarning()
    }
    
    

    // MARK: NSNotification Methods
    
    @objc func cannotReadAllDbFiles( notification: NSNotification ) {
        logTrace()
        let formatString  = NSLocalizedString( "AlertMessage.CannotReadAllDbFiles", comment: "The last update to the database on the remote device did not complete properly.  Please contact the user of '%@' and ask them to re-submit their last post.  The database will remain locked until this is resolved." )
        let messageString = String(format: formatString, pinCentral.externalDeviceLastUpdatedBy )
        
        presentAlert( title: NSLocalizedString( "AlertTitle.CannotReadAllDbFiles", comment: "Cannot Read ALL Database Files on Remote!" ), message: messageString )
    }
    
    
    @objc func enteringBackground( notification: NSNotification ) {
        logTrace()
        inBackground = true
    }


    @objc func enteringForeground( notification: NSNotification ) {
        logTrace()
        inBackground = false
    }


    @objc func transferringDatabase( notification: NSNotification ) {
        logTrace()
        transferringDatabase = true
    }

    
    
    // MARK: Utility Methods
    
    private func checkDeviceName() {
        if let deviceNameString = userDefaults.string( forKey: UserDefaultKeys.deviceName ) {
            if !deviceNameString.isEmpty && deviceNameString.count != 0 {
                logVerbose( "[ %@ ]", deviceNameString )
                return
            }
            
        }

        logTrace( "Name Has NOT Been Set!" )
        if UIDevice.current.userInterfaceIdiom == .phone {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.selectedIndex = self.viewControllers!.count - 1

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.deviceNameNotSet ), object: self )
                }
                
            }
            
        }
        else {
            if !self.flagIsPresentInUserDefaults( UserDefaultKeys.usingThumbnails ) {
                presentAlert( title:   NSLocalizedString( "AlertTitle.SetupRequired",   comment: "We need to change a few things ..." ),
                              message: NSLocalizedString( "AlertMessage.SetupRequired", comment: "Please go to the Settings tab, tap on the 'User Assigned Device Name' entry in the table and enter a name for this device then tap on the 'Setup Thumbnails' entry." ) )
            }
            else {
                presentAlert( title:   NSLocalizedString( "AlertTitle.DeviceNameRequired",   comment: "Device Name is Required for NAS or iCloud" ),
                              message: NSLocalizedString( "AlertMessage.DeviceNameRequired", comment: "Please go to the Settings tab, tap on the 'User Assigned Device Name' entry in the table and enter a name for this device." ) )
            }

        }
            
    }
    

    private func promptToEnableThumbnails() {
        logTrace()
        if UIDevice.current.userInterfaceIdiom == .phone {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.selectedIndex = self.viewControllers!.count - 1

                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.enableThumbnails ), object: self )
                }
                
            }
            
        }
        else {
            presentAlert( title:   NSLocalizedString( "AlertTitle.SetupThumbnails",   comment: "For performance reasons, we need to enable thumbnail images." ),
                          message: NSLocalizedString( "AlertMessage.SetupThumbnails", comment: "Please go to the Settings tab, tap on the 'Setup Thumbnails' entry in the table." ) )
        }

    }
    

    private func setSystemTint() {
        var     tintColor = GlobalConstants.offlineColor
        
        if pinCentral.dataStoreLocation != .device {
            tintColor = DeviceAccessControl.sharedInstance.byMe ? GlobalConstants.onlineColor : GlobalConstants.offlineColor
        }

//        logVerbose( "tintColor[ %@ ]", tintColor == GlobalConstants.offlineColor ? "Offline" : "Online" )
        tabBar.barTintColor = tintColor
        UITabBar.appearance().backgroundColor = tintColor
    }
    
    
    private func setupNotifications() {
        logTrace()
        notificationCenter.addObserver( self, selector: #selector( cannotReadAllDbFiles( notification: ) ), name: NSNotification.Name( rawValue: Notifications.cannotReadAllDbFiles ), object: nil )
        notificationCenter.addObserver( self, selector: #selector( enteringBackground(   notification: ) ), name: NSNotification.Name( rawValue: Notifications.enteringBackground   ), object: nil )
        notificationCenter.addObserver( self, selector: #selector( transferringDatabase( notification: ) ), name: NSNotification.Name( rawValue: Notifications.transferringDatabase ), object: nil )
    }

    
   private func setupTabBar() {
        logTrace()
        tabBar.items![0].title = NSLocalizedString( "Title.PinList", comment: "Pin List"  )

        if UIDevice.current.userInterfaceIdiom == .pad {
            tabBar.items![1].title = NSLocalizedString( "Title.Settings", comment: "Settings"  )
        }
        else {
            tabBar.items![1].title = NSLocalizedString( "Title.Map",      comment: "Map"       )
            tabBar.items![2].title = NSLocalizedString( "Title.Settings", comment: "Settings"  )
        }
        
        // Switch to the last active tab
        for index in 0 ..< tabBar.items!.count {
            let     item = tabBar.items![index]
            
            if item.title == lastTabSelected {
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    self.selectedIndex = index
                }
                
            }
            
        }

    }

    
}



// MARK: PinCentralDelegate Methods

extension TabBarViewController: PinCentralDelegate {
    
    func pinCentral(_ pinCentral: PinCentral, didOpenDatabase: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didOpenDatabase ) )
        
        if didOpenDatabase {
            pinCentral.fetchPinsWith( self )
        }
        else {
            presentAlert( title:   NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                          message: NSLocalizedString( "AlertMessage.CannotOpenDatabase", comment: "Fatal Error!  Cannot open database." ) )
        }
        
    }
    
    
    func pinCentralDidReloadPinArray(_ pinCentral: PinCentral ) {
        logVerbose( "loaded [ %d ] pins", pinCentral.numberOfPinsLoaded )
        
        if pinCentral.dataStoreLocation == .device || transferringDatabase {
            transferringDatabase = false
            
            if .pad == UIDevice.current.userInterfaceIdiom {
                notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.pinsArrayReloaded ), object: self )
            }

        }

        notificationCenter.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )
    }
    
    
}



// MARK: UITabBarControllerDelegate

extension TabBarViewController : UITabBarControllerDelegate {

    override func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
//        logVerbose("Selected item[ %@ ]", item.title! )
        userDefaults.set( item.title!, forKey: UserDefaultKeys.lastTabSelected )
        userDefaults.synchronize()
        
        setSystemTint()
    }

    
}
