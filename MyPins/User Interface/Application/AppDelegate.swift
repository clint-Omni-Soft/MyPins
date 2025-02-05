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
    var hidePrimary = false
    var mapView     : MapViewController!
    var window      : UIWindow?
    
    
    // MARK: Private Definitions
    private var locationManager    : CLLocationManager?
    private let notificationCenter = NotificationCenter.default
    private let pinCentral         = PinCentral.sharedInstance
    private var splitViewController: UISplitViewController!


    
    // MARK: UIApplication Lifecycle Methods
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? ) -> Bool {
        LogCentral.sharedInstance.setupLogging()
        pinCentral.enteringForeground()

        UNUserNotificationCenter.current().requestAuthorization( options: .badge ) { ( granted, error ) in
            logVerbose( "request to badge icon authorized[ %@ ]", stringFor( granted ) )
            self.pinCentral.userNotificationsAllowed = granted
        }
        
        locationManager = CLLocationManager()
        locationManager?.requestWhenInUseAuthorization()
        
        if pinCentral.dataStoreLocation != .device {
            showPleaseWaitScreen()
        }

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
    

    func applicationDidBecomeActive(_ application: UIApplication ) {
    }
    

    func applicationDidEnterBackground(_ application: UIApplication ) {
    }
    

    func applicationWillTerminate(_ application: UIApplication ) {
    }
    
    
    
    // MARK: Public Interfaces

    func hidePrimaryView(_ isHidden: Bool ) {
        if splitViewController != nil {
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
        
//        logVerbose( "hidePrimary[ %@ ]", stringFor( hidePrimary ) )
    }
    
    
    func primaryIsHidden() -> Bool {
        var isHidden = true
        
        if let splitVC = self.splitViewController {
            isHidden = splitVC.isCollapsed
            logVerbose( "instantiated - [ %@ ]", stringFor( isHidden ) )
        }
        else {
            logTrace( "NOT instantiated" )
        }
        
        return isHidden
    }
    
    
    func switchToMainApp() {
        logTrace()
        let     storyboardName = UIDevice.current.userInterfaceIdiom == .pad ? "Main_iPad" : "Main_iPhone"
        let     storyboard     = UIStoryboard(name: storyboardName, bundle: .main )

        pinCentral.didOpenDatabase = false
        
        if let initialViewController = storyboard.instantiateInitialViewController() {
            pinCentral.pleaseWaiting = false

            window?.rootViewController = initialViewController
            window?.makeKeyAndVisible()
            
            if UIDevice.current.userInterfaceIdiom == .pad {
                getLinkToSplitViewController()
            }
            
        }
        
    }
    
    
    
    // MARK: Utility Methods (Private)
    
    private func getLinkToSplitViewController() {
        DispatchQueue.main.asyncAfter(deadline: .now() ) {
            if let splitVC = self.window!.rootViewController as? UISplitViewController {
                self.splitViewController = splitVC
                self.splitViewController.presentsWithGesture = false
                
                let minimumWidth = min( CGRectGetWidth(self.splitViewController.view.bounds), CGRectGetHeight(self.splitViewController.view.bounds) )
                
                self.splitViewController.minimumPrimaryColumnWidth = minimumWidth * 0.6
                self.splitViewController.maximumPrimaryColumnWidth = minimumWidth;
                logTrace( "Captured pointer to SplitViewController" )
            }
            else {
                logTrace( "ERROR!  Could NOT capture pointer to SplitViewController!" )
            }

        }

    }
    
    
    private func showPleaseWaitScreen() {
        logTrace()
        let storyboard = UIStoryboard(name: "PleaseWait", bundle: .main )

        if let initialViewController = storyboard.instantiateInitialViewController() {
            pinCentral.pleaseWaiting = true

            window?.rootViewController = initialViewController
            window?.makeKeyAndVisible()
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
                NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.pinsArrayReloaded ), object: self )
            }

        }

        NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.ready ), object: self )
    }
    

}

