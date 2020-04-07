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

class AppDelegate: UIResponder, UIApplicationDelegate
{

    var window: UIWindow?
    var locationManager: CLLocationManager?
    


    // MARK: UIApplication Lifecycle Methods
    
    func application(_ application: UIApplication,
                       didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? )  -> Bool
    {
        locationManager = CLLocationManager()
        locationManager?.requestWhenInUseAuthorization()
        
        setupLogging()
        
        return true
    }
    

    func applicationWillResignActive(_ application: UIApplication )
    {
    }
    

    func applicationDidEnterBackground(_ application: UIApplication )
    {
    }
    

    func applicationWillEnterForeground(_ application: UIApplication )
    {
    }
    

    func applicationDidBecomeActive(_ application: UIApplication )
    {
    }
    

    func applicationWillTerminate(_ application: UIApplication )
    {
    }
    
    


}

