//
//  LocationImageTableViewCell.swift
//  MyPins
//
//  Created by Clint Shank on 7/8/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit


protocol LocationImageTableViewCellDelegate: class
{
    func locationImageTableViewCell( locationImageTableViewCell: LocationImageTableViewCell,
                                     cameraButtonTouched: Bool )
}



class LocationImageTableViewCell: UITableViewCell
{
    // MARK: Public Variables ... these are guaranteed to be set by our creator
    weak var delegate: LocationImageTableViewCellDelegate?
    
    @IBOutlet weak var cameraButton      : UIButton!
    @IBOutlet weak var locationImageView : UIImageView!
    

    
    // MARK: UITableViewCell Lifecycle Methods
    
    override func awakeFromNib()
    {
        logTrace()
        super.awakeFromNib()
    }

    
    override func setSelected(_ selected: Bool, animated: Bool)
    {
        super.setSelected(false, animated: animated)
    }
    
    
    
    // MARK: Target/Action Methods

    @IBAction func cameraButtonTouched(_ sender: UIButton)
    {
        logTrace()
        delegate?.locationImageTableViewCell( locationImageTableViewCell: self,
                                              cameraButtonTouched: true )
    }
    
    
    // MARK: Public Initializer
    
    func initializeWith( imageName: String )
    {
        logTrace()
        cameraButton.setImage( ( imageName.isEmpty ? UIImage.init( named: "camera" ) : nil ), for: .normal )
        cameraButton.backgroundColor = ( imageName.isEmpty ? .white : .clear )
        
        locationImageView.image = ( imageName.isEmpty ? nil : PinCentral.sharedInstance.imageWith( name: imageName ) )
    }
    
}
