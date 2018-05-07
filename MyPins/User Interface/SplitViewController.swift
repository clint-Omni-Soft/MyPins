//
//  SplitViewController.swift
//  MyPins
//
//  Created by Clint Shank on 3/20/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit



class SplitViewController: UISplitViewController
{
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad()
    {
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "" )
        super.viewDidLoad()
    }
    

    override func didReceiveMemoryWarning()
    {
        NSLog( "%@:%@[%d] - %@", description(), #function, #line, "MEMORY WARNING!!!" )
        super.didReceiveMemoryWarning()
    }
    
    
    
    // MARK: Utility Methods
    
    private func description() -> String
    {
        return "SplitViewController"
    }
    
    

}
