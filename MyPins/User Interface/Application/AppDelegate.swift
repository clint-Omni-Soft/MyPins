//
//  AppDelegate.swift
//  MyPins
//
//  Created by Clint Shank on 3/12/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit
import CoreLocation


@UIApplicationMain


class AppDelegate: UIResponder, UIApplicationDelegate {

    
    // MARK: Public Definitions
    var hidePrimary        = false
    var mapView            : MapViewController!
    var splitViewController: UISplitViewController!
    var window             : UIWindow?
    
    
    // MARK: Private Definitions
    private var locationManager    : CLLocationManager?
    private let notificationCenter = NotificationCenter.default
    private let pinCentral         = PinCentral.sharedInstance
    
    private var activeWindow: UIWindow? {
        get {
            var myWindow = window
            
            if myWindow == nil {
                let sceneDelegate = (UIApplication.shared.connectedScenes.first as? UIWindowScene)!.delegate as! SceneDelegate
                myWindow = sceneDelegate.window
            }
            
            return myWindow
        }
        
    }

    
    // MARK: UIApplication Lifecycle Methods
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? ) -> Bool {
        LogCentral.sharedInstance.setupLogging()
        logTrace()

        UNUserNotificationCenter.current().requestAuthorization( options: .badge ) { ( granted, error ) in
            logVerbose( "request to badge icon authorized[ %@ ]", stringFor( granted ) )
            
            self.pinCentral.userNotificationsAllowed = granted
        }
        
        locationManager = CLLocationManager()
        locationManager?.requestWhenInUseAuthorization()
        
        if #available(iOS 15, *) {
            UITableView.appearance().sectionHeaderTopPadding = 0.0
        }

        return true
    }
    

    func applicationWillEnterForeground(_ application: UIApplication ) {
        logTrace()
        if pinCentral.dataStoreLocation != .device {
            showPleaseWaitScreen()
        }
        
        pinCentral.enteringForeground()
   }
    

    func applicationWillResignActive(_ application: UIApplication ) {
        logTrace()
        pinCentral.enteringBackground()
   }
    

    func applicationWillTerminate(_ application: UIApplication ) {
        logTrace()
        pinCentral.enteringBackground()
    }
    
    
    
    // MARK: Public Interfaces

    func configureSplitViewController() {
        logTrace()
        if haveLinkToSplitViewController() {
            splitViewController.presentsWithGesture = false
            
            let minimumWidth = min( CGRectGetWidth( splitViewController.view.bounds ), CGRectGetHeight( splitViewController.view.bounds ) )
            
            splitViewController.minimumPrimaryColumnWidth = minimumWidth / 2
            splitViewController.maximumPrimaryColumnWidth = minimumWidth;
        }

    }

    
    func hidePrimaryView(_ isHidden: Bool ) {
        if haveLinkToSplitViewController() {
            hidePrimary = isHidden

            UIView.animate(withDuration: 0.5 ) { () -> Void in
                self.splitViewController?.preferredDisplayMode = self.hidePrimary ? UISplitViewController.DisplayMode.secondaryOnly : UISplitViewController.DisplayMode.oneBesideSecondary
            }
            
        }
       
        if self.mapView != nil {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 ) {
                self.mapView.primaryWindow( isHidden )
            }
            
        }
        
    }
    
    
    func primaryIsHidden() -> Bool {
        var isHidden = true
        
        if haveLinkToSplitViewController() {
            isHidden = splitViewController.isCollapsed
        }

        return isHidden
    }
    
    
    func switchToMainApp() {
        let     storyboardName = UIDevice.current.userInterfaceIdiom == .pad ? "Main_iPad" : "Main_iPhone"
        let     storyboard     = UIStoryboard(name: storyboardName, bundle: .main )

        logVerbose( "[ %@ ]", storyboardName )
        splitViewController = nil
        pinCentral.didOpenDatabase = false
        
        if let initialViewController = storyboard.instantiateInitialViewController() {
            pinCentral.pleaseWaiting = false

            activeWindow?.rootViewController = initialViewController
            activeWindow?.makeKeyAndVisible()
            
        }
        else {
            logTrace( "ERROR!!!!  Unable to instantiate initial view controller!" )
        }

    }
    
    
    
    // MARK: Utility Methods (Private)
    
    private func haveLinkToSplitViewController() -> Bool {
        var foundIt = true
        
        if splitViewController == nil {
            if let splitVC = self.activeWindow?.rootViewController as? UISplitViewController {
                splitViewController = splitVC
            }
            else {
                foundIt = false
                logVerbose( "NOT instantiated!" )
            }

        }
        
        return foundIt
    }
    
    
    private func showPleaseWaitScreen() {
        logTrace()
        let storyboard = UIStoryboard(name: "PleaseWait", bundle: .main )

        if let initialViewController = storyboard.instantiateInitialViewController() {
            pinCentral.pleaseWaiting = true

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 ) {
                self.activeWindow?.rootViewController = initialViewController
                self.activeWindow?.makeKeyAndVisible()
            }

        }

    }

    
}



// MARK: PinCentralDelegate Methods

extension AppDelegate: PinCentralDelegate {
    
    func pinCentral(_ pinCentral: PinCentral, didOpenDatabase: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didOpenDatabase ) )
        
        if didOpenDatabase {
            pinCentral.fetchPinsWith( self )
        }
        
    }
    
    
    func pinCentralDidReloadPinArray(_ pinCentral: PinCentral ) {
        logTrace()
        
        if pinCentral.dataStoreLocation == .device {
            if .pad == UIDevice.current.userInterfaceIdiom {
                logTrace( "Posting pinsArrayReloaded" )
                NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.pinsArrayReloaded ), object: self )
            }

        }

        logTrace( "Posting ready" )
        NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )
    }
    

}

