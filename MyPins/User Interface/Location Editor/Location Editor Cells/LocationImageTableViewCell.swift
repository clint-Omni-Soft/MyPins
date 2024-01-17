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
    
    // MARK: Public Variables
    
    var imageName  = ""
    var imageState = ImageState.noName

    @IBOutlet weak var cameraButton      : UIButton!
    @IBOutlet weak var locationImageView : UIImageView!
    
    
    
    // MARK: Private Variables
        
    private struct Constants {
        static let cameraImage = "camera"
    }

    private var delegate   : LocationImageTableViewCellDelegate!
    private let pinCentral = PinCentral.sharedInstance

    
    
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
        
        self.delegate  = delegate
        self.imageName = imageName

        locationImageView.image = UIImage( named: GlobalConstants.noImage )

        if !imageName.isEmpty {
            let result      = pinCentral.imageNamed( imageName, descriptor: "", self )
            let imageLoaded = result.0
            
            imageState              = imageLoaded ? ImageState.loaded : ImageState.missing
            locationImageView.image = imageLoaded ? result.1 : UIImage( named: GlobalConstants.missingImage )
        }
        
    }
    
    
    
}



// MARK: PinCentralDelegate Methods

extension LocationImageTableViewCell: PinCentralDelegate {
    
    func pinCentral(_ pinCentral: PinCentral, didFetchImage: Bool, filename: String, image: UIImage) {
        logVerbose( "[ %@ ]", stringFor( didFetchImage ) )
        imageState = didFetchImage ? ImageState.loaded : ImageState.missing
        
        if didFetchImage {
            locationImageView.image = image
        }
        
    }
    
    
}
