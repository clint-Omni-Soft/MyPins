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
    
    @IBOutlet weak var detailLabel: UILabel!
    @IBOutlet weak var myImageView: UIImageView!
    @IBOutlet weak var nameLabel  : UILabel!

    
    
    // MARK: Private Variables
    
    private let     pinCentral = PinCentral.sharedInstance
    
    
    
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
            if !detailsText.isEmpty {
                detailLabel.text = String.init( format: "%@ - %@", detailsText, dateString )
            }
            
        }
        
        if let imageName = pin.imageName {
            if !imageName.isEmpty {
                let result = self.pinCentral.imageNamed( imageName )

                imageLoaded = result.0

                if imageLoaded {
                    self.myImageView.image = result.1
                }

            }

        }
        
        if !imageLoaded {
            self.myImageView.image = UIImage( named: "missingImage" )
        }
            
    }
    

}
