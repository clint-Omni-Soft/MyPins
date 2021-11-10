//
//  SplitViewController.swift
//  MyPins
//
//  Created by Clint Shank on 3/20/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit



class SplitViewController: UISplitViewController {
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
    }
    

    override func didReceiveMemoryWarning() {
        logTrace( "MEMORY WARNING!!!" )
        super.didReceiveMemoryWarning()
    }
    

}
