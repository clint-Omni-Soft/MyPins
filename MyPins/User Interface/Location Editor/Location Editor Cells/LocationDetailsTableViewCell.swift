//
//  LocationDetailsTableViewCell.swift
//  MyPins
//
//  Created by Clint Shank on 7/8/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit
import CoreLocation


protocol LocationDetailsTableViewCellDelegate: AnyObject {
    func locationDetailsTableViewCell(_ locationDetailsTableViewCell: LocationDetailsTableViewCell, requestingEditOfNameAndDetails: Bool )
    func locationDetailsTableViewCell(_ locationDetailsTableViewCell: LocationDetailsTableViewCell, requestingEditOfLocation: Bool )
    func locationDetailsTableViewCell(_ locationDetailsTableViewCell: LocationDetailsTableViewCell, requestingEditOfPinColor: Bool )
}



class LocationDetailsTableViewCell: UITableViewCell {
    
    // MARK: Public Variables ... these are guaranteed to be set by our creator
    
    var altitude    = 0.0
    var details     : String!
    var latitude    = 0.0
    var longitude   = 0.0
    var name        : String!
    var colorIndex  : Int16 = 0

    weak var delegate: LocationDetailsTableViewCellDelegate?
    
    @IBOutlet weak var detailsButton    : UIButton!
    @IBOutlet weak var locationButton   : UIButton!
    @IBOutlet weak var nameButton       : UIButton!
    @IBOutlet weak var pinColorButton   : UIButton!

    
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
    
    func initialize() {
//        logTrace()
        let         units                  = pinCentral.displayUnits()
        let         altitudeInDesiredUnits = ( ( DisplayUnits.meters == units ) ? altitude : ( altitude * GlobalConstants.feetPerMeter ) )
        let         altitudeText           = String( format: "%7.1f", altitudeInDesiredUnits ).trimmingCharacters(in: .whitespaces)
        let         pinColor               = pinCentral.colorArray[Int( colorIndex )]

        detailsButton  .setTitle( ( details.isEmpty ? NSLocalizedString( "LabelText.Details", comment: "Address / Description" ) : details ), for: .normal )
        nameButton     .setTitle( ( name   .isEmpty ? NSLocalizedString( "LabelText.Name",    comment: "Name"                  ) : name    ), for: .normal )
        locationButton .setTitle( String( format: "%7.4f, %7.4f at %@ %@", latitude, longitude, altitudeText, units ), for: .normal )
        pinColorButton .setTitle( NSLocalizedString( "ButtonTitle.PinColor",  comment: "Pin Color"   ), for: .normal )
        
        pinColorButton .setTitleColor( pinColorArray[Int( pinColor.colorId )], for: .normal)
        
        setPinColorButtonBackgroundImage()
    }
    
    
    
    // MARK: Target/Action Methods
    
    @IBAction func locationButtonTouched(_ sender: UIButton ) {
        logTrace()
        delegate?.locationDetailsTableViewCell( self, requestingEditOfLocation: true )
    }
    
    
    @IBAction func nameOrDetailsButtonTouched(_ sender: UIButton ) {
        logTrace()
        delegate?.locationDetailsTableViewCell( self, requestingEditOfNameAndDetails: true )
    }
    
    
    @IBAction func pinColorButtonTouched(_ sender: UIButton ) {
        logTrace()
        delegate?.locationDetailsTableViewCell( self, requestingEditOfPinColor: true )
    }
    
    
    
    // MARK: Utility Methods (Private)
    
    private func setPinColorButtonBackgroundImage() {
        let size = pinColorButton.frame.size
        let rect = CGRect( x: 0, y: 0, width: size.width, height: size.height )
        var backgroundColor : UIColor = .white
        let pinColor = pinCentral.colorArray[Int( colorIndex )]

        if ( ( pinColor.colorId == PinColors.pinWhite ) || ( pinColor.colorId == PinColors.pinYellow ) ) {
            backgroundColor = .lightGray
        }
        
        UIGraphicsBeginImageContextWithOptions( size, false, 0 )
        
        backgroundColor.setFill()
        UIRectFill( rect )
        
        let backgroundImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
        
        UIGraphicsEndImageContext()
      
        pinColorButton.setBackgroundImage( backgroundImage, for: .normal )
    }
    
    
}
