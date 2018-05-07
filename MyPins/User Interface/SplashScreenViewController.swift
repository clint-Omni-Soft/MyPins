//
//  SplashScreenViewController.swift
//  MyPins
//
//  Created by Clint Shank on 4/10/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit



class SplashScreenViewController: UIViewController
{
    @IBOutlet weak var contactUsLabel:      UILabel!
    @IBOutlet weak var titleLabel:          UILabel!

    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad()
    {
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString( "LabelText.About", comment: "About" )
        
        contactUsLabel  .text = NSLocalizedString( "LabelText.ContactUs", comment: "All rights reserved.  Contact us at" )
        titleLabel      .text = NSLocalizedString( "Title.App",           comment: "Where Was That?"                     )
    }
    
    
    override func viewWillAppear(_ animated: Bool )
    {
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )
        super.viewWillAppear( animated )
    }
    
    
    override func viewWillDisappear(_ animated: Bool )
    {
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )
        super.viewWillDisappear( animated )
    }
    
    
    override func didReceiveMemoryWarning()
    {
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "MEMORY WARNING!!!" )
        super.didReceiveMemoryWarning()
    }
    
    
    
    // MARK: Utility Methods
    
    private func description() -> String
    {
        return "SplashScreenViewController"
    }
    
    

}
