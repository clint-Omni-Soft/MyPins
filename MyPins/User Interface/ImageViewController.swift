//
//  ImageViewController.swift
//  MyPins
//
//  Created by Clint Shank on 7/12/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit

class ImageViewController: UIViewController, UIScrollViewDelegate
{
    var imageName : String!     // Set by our creator
    
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var imageView : UIImageView!
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad()
    {
        logTrace()
        super.viewDidLoad()
        
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 6.0
    }
    
    
    override func viewWillAppear(_ animated: Bool)
    {
        logTrace()
        super.viewWillAppear( animated )
        imageView.image = PinCentral.sharedInstance.imageWith( name: imageName )
    }
    
    
    override func viewWillDisappear(_ animated: Bool)
    {
        logTrace()
        super.viewWillDisappear( animated )
    }


    
    // MARK: UIScrollViewDelegate Methods
    
    func viewForZooming(in scrollView: UIScrollView) -> UIView?
    {
//        logTrace()
        return imageView
    }
    
    
}
