//
//  UIViewControllerExtensionsViewController.swift
//  ClearedTo
//
//  Created by Clint Shank on 3/1/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit



extension UIViewController
{
    func presentAlert( title: String, message: String )
    {
        NSLog( "presentAlert: [ %@ ][ %@ ]", title, message )
        let         alert    = UIAlertController.init( title: title, message: message, preferredStyle: UIAlertControllerStyle.alert )
        let         okAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.OK", comment: "OK" ),
                                                   style: UIAlertActionStyle.default,
                                                   handler: nil )
        alert.addAction( okAction )
        
        present( alert, animated: true, completion: nil )
    }
    
}

