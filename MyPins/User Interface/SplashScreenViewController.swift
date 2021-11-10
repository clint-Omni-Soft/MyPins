//
//  SplashScreenViewController.swift
//  MyPins
//
//  Created by Clint Shank on 4/10/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit



class SplashScreenViewController: UIViewController, UIGestureRecognizerDelegate {
    
    @IBOutlet weak var contactUsLabel       : UILabel!
    @IBOutlet      var downGestureRecognizer: UISwipeGestureRecognizer!
    @IBOutlet weak var titleLabel           : UILabel!
    @IBOutlet weak var versionLabel         : UILabel!
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString( "LabelText.About", comment: "About" )
        
        contactUsLabel  .text = NSLocalizedString( "LabelText.ContactUs", comment: "All rights reserved.  Contact us at" )
        titleLabel      .text = NSLocalizedString( "Title.App",           comment: "Where Was That?"                     )
        
        var     labelText = ""
        
        if let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String {
            labelText = version
        }
        
        versionLabel.isHidden = labelText.isEmpty
        versionLabel.text     = "v" + labelText

        downGestureRecognizer.delegate                = self
        downGestureRecognizer.direction               = .down
        downGestureRecognizer.numberOfTouchesRequired = 1
    }
    
    
    override func viewWillAppear(_ animated: Bool ) {
        logTrace()
        super.viewWillAppear( animated )
    }
    
    
    override func viewWillDisappear(_ animated: Bool ) {
        logTrace()
        super.viewWillDisappear( animated )
    }
    
    
    override func didReceiveMemoryWarning() {
        logTrace( "MEMORY WARNING!!!" )
        super.didReceiveMemoryWarning()
    }
    
    
    
    // MARK: Target/Action Methods
    
    @IBAction func respondToDownSwipeGesture(_ sender: UISwipeGestureRecognizer ) {
        logTrace()
//        presentAlert(title: "Ta Da!  Flare!", message: "We rock!" )
    }
    
    
    
    // MARK: GestureRecognizerDelegate Methods
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer ) -> Bool {
        logTrace()
        return true
    }
    
    
}
