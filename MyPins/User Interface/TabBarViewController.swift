//
//  TabBarViewController.swift
//  MyPins
//
//  Created by Clint Shank on 5/2/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit


class TabBarViewController: UITabBarController,
                            PinCentralDelegate
{

    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad()
    {
        appLogTrace()
        super.viewDidLoad()

        tabBar.items![0].title = NSLocalizedString( "Title.PinList",   comment: "Pin List"  )
        tabBar.items![1].title = NSLocalizedString( "Title.Map",       comment: "Map"       )
        tabBar.items![2].title = NSLocalizedString( "Title.Settings",  comment: "Settings"  )
        
        if .pad == UIDevice.current.userInterfaceIdiom
        {
            if 1 < ( viewControllers?.count )!
            {
                var     viewControllerArray = viewControllers
                
                
                viewControllerArray?.remove( at: 1 )
                viewControllers = viewControllerArray
            }
            
        }
        
        
        let     pinCentral = PinCentral.sharedInstance
        
        
        if !pinCentral.didOpenDatabase
        {
            pinCentral.delegate = self
            pinCentral.openDatabase()
        }
        
    }
    
    
    override func viewWillAppear(_ animated: Bool)
    {
        appLogTrace()
        super.viewWillAppear( animated )
    }
    
    
    override func didReceiveMemoryWarning()
    {
        appLogVerbose( format: "MEMORY WARNING!!!" )
        super.didReceiveMemoryWarning()
    }
    
    
    
    // MARK: PinCentralDelegate Methods
    
    func pinCentral( pinCentral: PinCentral,
                     didOpenDatabase: Bool )
    {
        appLogVerbose( format: "didOpenDatabase[ %@ ]", parameters: String( didOpenDatabase ) )
        if !didOpenDatabase
        {
            presentAlert( title:   NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                          message: NSLocalizedString( "AlertMessage.CannotOpenDatabase", comment: "Fatal Error!  Cannot open database." ) )
        }
        
    }
    
    
    func pinCentralDidReloadPinArray( pinCentral: PinCentral )
    {
        appLogVerbose( format: "loaded [ %@ ] pins", parameters: String( pinCentral.pinArray!.count ) )
    }
    
    
    
    
    
    
    

}
