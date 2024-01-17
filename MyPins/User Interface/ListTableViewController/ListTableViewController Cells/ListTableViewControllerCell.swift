//
//  ListTableViewControllerCell.swift
//  MyPins
//
//  Created by Clint Shank on 6/8/21.
//  Copyright © 2021 Omni-Soft, Inc. All rights reserved.
//


import UIKit


class ListTableViewControllerCell: UITableViewCell {

    // MARK: Public Variables
    
    var imageState = ImageState.noName

    @IBOutlet weak var dateLabel  : UILabel!
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var nameLabel  : UILabel!
    
    
    
    // MARK: Private Variables
    
    private let pinCentral = PinCentral.sharedInstance

    
    
    // MARK: UITableViewCell Lifecycle Methods

    override func awakeFromNib() {
        super.awakeFromNib()
    }

    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(false, animated: animated)
    }

    
    
    // MARK: Public Initializer
    
    func initializeWith(_ pin: Pin ) {
        var     dateString  = ""
        
        if let lastModified = pin.lastModified as Date? {
            dateString = DateFormatter.localizedString( from: lastModified as Date, dateStyle: DateFormatter.Style.short, timeStyle: DateFormatter.Style.short )
        }
        
        detailLabel.text = dateString
        nameLabel  .text = pin.name

        if let detailsText = pin.details {
            detailLabel.text = detailsText
            dateLabel  .text = dateString
        }
        
        myImageView.image = UIImage( named: GlobalConstants.noImage )

        if let imageName = pin.imageName {
            if !imageName.isEmpty {
                var     usingThumbnails = false
                
                if let _ = UserDefaults.standard.string( forKey: UserDefaultKeys.usingThumbnails ) {
                    usingThumbnails = true
                }

                let imageToFetch = usingThumbnails ? ( GlobalConstants.thumbNailPrefix + imageName ) : imageName
                let result       = self.pinCentral.imageNamed( imageToFetch, descriptor: pinCentral.shortDescriptionFor( pin ), self )
                let imageLoaded  = result.0
                
                imageState        = imageLoaded ? ImageState.loaded : ImageState.missing
                myImageView.image = imageLoaded ? result.1 : UIImage( named: GlobalConstants.missingImage )
            }

        }
        
    }
    

}



// MARK: PinCentralDelegate Methods

extension ListTableViewControllerCell: PinCentralDelegate {
    
    func pinCentral(_ pinCentral: PinCentral, didFetchImage: Bool, filename: String, image: UIImage) {
        logVerbose( "didFetchImage[ %@ ] [ %@ ]", stringFor( didFetchImage ), filename )
        imageState = didFetchImage ? ImageState.loaded : ImageState.missing

        if didFetchImage {
            myImageView.image = image
        }
        
    }
    
    
}
