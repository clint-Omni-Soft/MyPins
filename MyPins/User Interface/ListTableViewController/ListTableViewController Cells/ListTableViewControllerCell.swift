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
        var     imageLoaded = false
        
        if let lastModified = pin.lastModified as Date? {
            dateString = DateFormatter.localizedString( from: lastModified as Date, dateStyle: DateFormatter.Style.short, timeStyle: DateFormatter.Style.short )
        }
        
        detailLabel.text = dateString
        nameLabel  .text = pin.name

        if let detailsText = pin.details {
            detailLabel.text = detailsText
            dateLabel  .text = dateString
        }
        
        if let imageName = pin.imageName {
            if !imageName.isEmpty {
                let result = self.pinCentral.imageNamed( imageName, descriptor: pinCentral.shortDescriptionFor( pin ), self )

                imageLoaded = result.0

                if imageLoaded {
                    myImageView.image = result.1
                }

            }

        }
        
        if !imageLoaded {
            myImageView.image = UIImage( named: "missingImage" )
        }
            
    }
    

}



// MARK: PinCentralDelegate Methods

extension ListTableViewControllerCell: PinCentralDelegate {
    
    func pinCentral(_ pinCentral: PinCentral, didFetchImage: Bool, filename: String, image: UIImage) {
        logTrace()
        if didFetchImage {
            myImageView.image = image
        }
        
    }
    
    
}
