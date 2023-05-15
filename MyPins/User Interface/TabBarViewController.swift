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
    
    private let pinCentral = PinCentral.sharedInstance
    

    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()

        tabBar.items![0].title = NSLocalizedString( "Title.PinList",   comment: "Pin List"  )
        tabBar.items![1].title = NSLocalizedString( "Title.Map",       comment: "Map"       )
        tabBar.items![2].title = NSLocalizedString( "Title.Settings",  comment: "Settings"  )
        
        if .pad == UIDevice.current.userInterfaceIdiom {
            if 1 < ( viewControllers?.count )! {
                var viewControllerArray = viewControllers
                
                viewControllerArray?.remove( at: 1 )
                viewControllers = viewControllerArray
            }
            
        }
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )

        NotificationCenter.default.addObserver( self, selector: #selector( self.pleaseWaitingDone( notification: ) ), name: NSNotification.Name( rawValue: Notifications.pleaseWaitingDone ), object: nil )
    }
    
    
    override func didReceiveMemoryWarning() {
        logTrace( "MEMORY WARNING!!!" )
        super.didReceiveMemoryWarning()
    }
    
    

    // MARK: NSNotification Methods
    
    @objc func pleaseWaitingDone( notification: NSNotification ) {
        logTrace()
        if !pinCentral.didOpenDatabase {
            pinCentral.openDatabaseWith( self )
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
        logVerbose( "loaded [ %d ] pins", pinCentral.pinArray.count )
        NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.pinsArrayReloaded ), object: self )
    }
    
    
}
