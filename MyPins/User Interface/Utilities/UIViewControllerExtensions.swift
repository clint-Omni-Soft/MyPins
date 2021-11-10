//
//  UIViewControllerExtensionsViewController.swift
//  ClearedTo
//
//  Created by Clint Shank on 3/1/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit



extension UIViewController {
    
    func iPhoneViewControllerWithStoryboardId( storyboardId: String ) -> UIViewController {
        logVerbose( "[ %@ ]", storyboardId )
        let     storyboardName = "Main_iPhone"
        let     storyboard     = UIStoryboard.init( name: storyboardName, bundle: nil )
        let     viewController = storyboard.instantiateViewController( withIdentifier: storyboardId )
        
        
        return viewController
    }


    func presentAlert( title: String, message: String ) {
        logVerbose( "[ %@ ][ %@ ]", title, message )
        let         alert    = UIAlertController.init( title: title, message: message, preferredStyle: .alert )
        let         okAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.OK", comment: "OK" ),
                                                   style: .default,
                                                   handler: nil )
        alert.addAction( okAction )
        
        present( alert, animated: true, completion: nil )
    }
    
    
    func viewControllerWithStoryboardId( storyboardId: String ) -> UIViewController {
        logVerbose( "[ %@ ]", storyboardId )
        let     storyboardName = ( ( .pad == UIDevice.current.userInterfaceIdiom ) ? "Main_iPad" : "Main_iPhone" )
        let     storyboard     = UIStoryboard.init( name: storyboardName, bundle: nil )
        let     viewController = storyboard.instantiateViewController( withIdentifier: storyboardId )
        
        
        return viewController
    }


}



// MARK: Global Methods

func stringFor(_ boolValue: Bool ) -> String {
    return ( boolValue ? "true" : "false" )
}


