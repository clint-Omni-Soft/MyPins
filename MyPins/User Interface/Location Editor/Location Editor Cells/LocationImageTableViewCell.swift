//
//  LocationImageTableViewCell.swift
//  MyPins
//
//  Created by Clint Shank on 7/8/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit


protocol LocationImageTableViewCellDelegate: AnyObject {
    func locationImageTableViewCell(_ locationImageTableViewCell: LocationImageTableViewCell, cameraButtonTouched: Bool )
}



class LocationImageTableViewCell: UITableViewCell {
    
    // MARK: Public Variables ... these are guaranteed to be set by our creator
    
    @IBOutlet weak var cameraButton      : UIButton!
    @IBOutlet weak var locationImageView : UIImageView!
    
    
    
    // MARK: Private Variables
        
    private struct Constants {
        static let cameraImage  = "camera"
        static let missingImage = "missingImage"
    }

    private var     delegate   : LocationImageTableViewCellDelegate!
    private let     pinCentral = PinCentral.sharedInstance

    
    
    // MARK: UITableViewCell Lifecycle Methods
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(false, animated: animated)
    }
    
    
    
    // MARK: Target/Action Methods

    @IBAction func cameraButtonTouched(_ sender: UIButton) {
        logTrace()
        delegate?.locationImageTableViewCell( self, cameraButtonTouched: true )
    }
    
    

    // MARK: Public Initializer
    
    func initializeWith(_ imageName: String, _ delegate: LocationImageTableViewCellDelegate ) {
//        logTrace()
        cameraButton.setImage( ( imageName.isEmpty ? UIImage.init( named: Constants.cameraImage ) : nil ), for: .normal )
        cameraButton.backgroundColor = ( imageName.isEmpty ? .white : .clear )
        
        self.delegate = delegate
        
        var     imageLoaded = false

        if !imageName.isEmpty {
            let     result = pinCentral.imageNamed( imageName )
            
            imageLoaded = result.0
            
            if imageLoaded {
                locationImageView.image = result.1
            }
            
        }
        
        if !imageLoaded {
            locationImageView.image = UIImage( named: Constants.missingImage )
        }

    }
    
}
