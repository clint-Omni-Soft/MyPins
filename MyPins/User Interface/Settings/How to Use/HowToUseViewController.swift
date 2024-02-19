//
//  HowToUseViewController.swift
//  MyPins
//
//  Created by Clint Shank on 5/2/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit



class HowToUseViewController: UIViewController {
    
    @IBOutlet weak var myTextView: UITextView!
    
    
    // MARK: Private Definitions
    
    private let  contents = NSLocalizedString( "InfoText.PinList",    comment: "PIN LIST\n\nAdd a Pin - Touching the plus sign (+) button will take you to the Pin Editor where you can associate provide information about that pin.\n\n" ) +
                            NSLocalizedString( "InfoText.PinEditor1", comment: "PIN EDITOR\n\nProvides the ability to (a) associate an image with the pin, (b) assign it a name, (c) addresss and/or description, (d) modify its coordinates and/or altitude, " ) +
                            NSLocalizedString( "InfoText.PinEditor2", comment: "(e) change the altitude display units and (f) set its pin color.  Touch the Save button when you are done.  To see the pin's location on the map, touch the Show on Map button.\n\n" ) +
                            NSLocalizedString( "InfoText.Map1",       comment: "MAP\n\nTouching the plus sign (+) bar button will take you to the Pin Editor where you can associate provide information about that pin.\n\n" ) +
                            NSLocalizedString( "InfoText.Map2",       comment: "Touching the 'Map Type' bar button will produce a popover that will allow you to choose from the supported map display modes.\n\n" ) +
                            NSLocalizedString( "InfoText.Map3",       comment: "Touching the 'Dart' bar button will produce a popover that will give the device's current latitude, longitude and altitude." ) +
                            NSLocalizedString( "InfoText.Map4",       comment: "When you tap on a pin, its description will displayed above it on the map and the 'Compass' bar button will be displayed. " ) +
                            NSLocalizedString( "InfoText.Map5",       comment: "Touching the 'Compass' bar button will take you to the Apple Maps app which will display the available routes from your current position to the selected pin.\n\n" ) +
                            NSLocalizedString( "InfoText.Settings1",  comment: "SETTINGS\n\nTouch any row in the table to get information/configuration data about this app.\n\nAbout - Our contact information.\n\n" ) +
                            NSLocalizedString( "InfoText.Settings2",  comment: "Data Store Location - Allows you to specify where your data is saved.\n\nHow to Use - This view.\n\n" )
                            

    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString( "Title.HowToUse", comment: "How to Use" )
        
        myTextView.text = contents
    }
    
    
    override func viewDidLayoutSubviews() {
        logTrace()
        super.viewDidLayoutSubviews()
        
        myTextView.setContentOffset( CGPoint.zero, animated: true )
    }
    
    
}
