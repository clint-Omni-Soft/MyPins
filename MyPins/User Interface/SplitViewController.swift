//
//  SplitViewController.swift
//  MyPins
//
//  Created by Clint Shank on 3/20/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit



class SplitViewController: UISplitViewController {

    private let appDelegate = UIApplication.shared.delegate as! AppDelegate

    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        logTrace()

        appDelegate.splitViewController = self
        appDelegate.configureSplitViewController()
    }
    

}
