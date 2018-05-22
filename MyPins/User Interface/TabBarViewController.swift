//
//  TabBarViewController.swift
//  MyPins
//
//  Created by Clint Shank on 5/2/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit
//import Swifty


class TabBarViewController: UITabBarController,
                            PinCentralDelegate
{

    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad()
    {
        logTrace()
        super.viewDidLoad()

//        playWithSwifty()

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
        logTrace()
        super.viewWillAppear( animated )
    }
    
    
    override func didReceiveMemoryWarning()
    {
        logTrace( "MEMORY WARNING!!!" )
        super.didReceiveMemoryWarning()
    }
    
    
    
    // MARK: PinCentralDelegate Methods
    
    func pinCentral( pinCentral: PinCentral,
                     didOpenDatabase: Bool )
    {
        logVerbose( "[ %@ ]", stringFor( didOpenDatabase ) )
        if !didOpenDatabase
        {
            presentAlert( title:   NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                          message: NSLocalizedString( "AlertMessage.CannotOpenDatabase", comment: "Fatal Error!  Cannot open database." ) )
        }
        
    }
    
    
    func pinCentralDidReloadPinArray( pinCentral: PinCentral )
    {
        logVerbose( "loaded [ %d ] pins", pinCentral.pinArray!.count )
    }
    
    
    
    
/*
    func playWithSwifty()
    {
        NSLog( "playWithSwifty ... ENTER" )
        let     swifty2 = Swifty2.init()
        
        
        swifty2.hello()


//        let     swifty1 = SwiftyOne.init()
//        var     count   = swifty1.incrementCount()
//
//
//        count = swifty1.incrementCountBy( count: 2 )
//
//        swifty1.helloSwift2()
//
//        NSLog( "playWithSwifty ... EXIT ... count[ %d ]", count )
//        
//        globalHello()
    }
*/

}
/*
 The following is the output of the method above ...

2018-05-22 15:06:13.216611-0700 MyPins[5251:273584] 18-05-22 15:06:13:216 PDT [273518] V TabBarViewController::viewDidLoad() [ 24 ] -
2018-05-22 15:06:13.216707-0700 MyPins[5251:273518] playWithSwifty ... ENTER
2018-05-22 15:06:13.216825-0700 MyPins[5251:273518] Swifty2::init
2018-05-22 15:06:13.216890-0700 MyPins[5251:273518] Swifty2::hello ... ENTER
2018-05-22 15:06:13.217230-0700 MyPins[5251:273518] SwiftyOne::init - [ 2 ]
2018-05-22 15:06:13.217332-0700 MyPins[5251:273518] SwiftyOne::incrementCountBy[ 3 ] + [ 2 ]
2018-05-22 15:06:13.217432-0700 MyPins[5251:273518] Swifty2::hello ... newValue[ 5 ]
2018-05-22 15:06:13.217546-0700 MyPins[5251:273518] SwiftyOne::incrementCountBy[ 3 ] + [ 5 ]
2018-05-22 15:06:13.217646-0700 MyPins[5251:273518] globalHello!
2018-05-22 15:06:13.217736-0700 MyPins[5251:273518] Swifty2::init
2018-05-22 15:06:13.217807-0700 MyPins[5251:273518] Swifty2::howdyBackAtYou
2018-05-22 15:06:13.217884-0700 MyPins[5251:273518] Swifty2::hello ... newValue2[ 8 ]
2018-05-22 15:06:13.217981-0700 MyPins[5251:273518] SwiftyOne::helloSwift2
2018-05-22 15:06:13.218058-0700 MyPins[5251:273518] Swifty2::init
2018-05-22 15:06:13.218138-0700 MyPins[5251:273518] Swifty2::howdyBackAtYou
2018-05-22 15:06:13.218215-0700 MyPins[5251:273518] Swifty2::hello ... EXIT

 
 This log demonstrates that a Swift class in an external project can call an ObjC class in a framework and the ObjC class in the
 framework can call a Swift class inside the same framework and that Swift class can call another Swift class inside that framework.
 What I find most disconcerting is that I cannot call a Swift class inside the framework from the external project...
 at least I haven't figured that one out yet. :)
*/
