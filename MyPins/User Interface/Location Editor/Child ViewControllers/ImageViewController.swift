//
//  ImageViewController.swift
//  MyPins
//
//  Created by Clint Shank on 7/12/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit


class ImageViewController: UIViewController, UIScrollViewDelegate {
    
    var imageName : String!     // Set by our creator
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView : UIImageView!
    
    
    
    // MARK: Private Variables
    
    private let pinCentral = PinCentral.sharedInstance
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 6.0
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        let result      = pinCentral.imageNamed( imageName, descriptor: "ImageViewController", self )
        let imageLoaded = result.0
        
        imageView.image = imageLoaded ? result.1 : UIImage( named: GlobalConstants.missingImage )
        
        loadBarButtonItems()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        logTrace()
        super.viewWillDisappear( animated )
    }
    
    
    
    // MARK: Target/Action Methods
    
    @IBAction func leftBarButtonTouched(sender : UIBarButtonItem ) {
        logTrace()
        removeViewControllerByIdiom()
    }
    
    
    
    // MARK: Utilities
    
    private func loadBarButtonItems() {
        let title = (UIDevice.current.userInterfaceIdiom == .phone) ? NSLocalizedString( "ButtonTitle.Back", comment: "Back" ) : NSLocalizedString( "ButtonTitle.Done", comment: "Done" )
        
        navigationItem.leftBarButtonItem = UIBarButtonItem.init( title: title, style: .plain, target: self, action: #selector( leftBarButtonTouched ) )
    }

    
    
    // MARK: UIScrollViewDelegate Methods
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
//        logTrace()
        return imageView
    }
    
    
}



// MARK: PinCentralDelegate Methods

extension ImageViewController: PinCentralDelegate {
    
    func pinCentral(_ pinCentral: PinCentral, didFetchImage: Bool, filename: String, image: UIImage) {
        logTrace()
        if didFetchImage {
            imageView.image = image
        }
        
    }
    
    
}
