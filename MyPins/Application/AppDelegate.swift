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

    var window: UIWindow?
    var locationManager: CLLocationManager?
    
    private let pinCentral = PinCentral.sharedInstance


    
    // MARK: UIApplication Lifecycle Methods
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? ) -> Bool {
        LogCentral.sharedInstance.setupLogging()

        locationManager = CLLocationManager()
        locationManager?.requestWhenInUseAuthorization()
        
        pinCentral.enteringForeground()
        
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

    func switchToMainApp() {
        logTrace()
        let     storyboardName = UIDevice.current.userInterfaceIdiom == .pad ? "Main_iPad" : "Main_iPhone"
        let     storyboard     = UIStoryboard(name: storyboardName, bundle: .main )

        if let initialViewController = storyboard.instantiateInitialViewController() {
            window?.rootViewController = initialViewController
            window?.makeKeyAndVisible()
        }
        
    }
    
    
    
    // MARK: Utility Methods (Private)
    
    private func showPleaseWaitScreen() {
        logTrace()
        let storyboard = UIStoryboard(name: "PleaseWait", bundle: .main )

        if let initialViewController = storyboard.instantiateInitialViewController() {
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

