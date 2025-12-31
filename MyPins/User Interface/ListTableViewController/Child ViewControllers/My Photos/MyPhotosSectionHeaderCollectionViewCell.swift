//
//  MyPhotosSectionHeaderCollectionViewCell.swift
//  MyPins
//
//  Created by Clint Shank on 12/5/25.
//  Copyright © 2025 Omni-Soft, Inc. All rights reserved.
//

import UIKit


protocol MyPhotosSectionHeaderCollectionViewCellDelegate: AnyObject {
    func myPhotosSectionHeaderCollectionViewCell(_ cell: MyPhotosSectionHeaderCollectionViewCell, didRequestToggleForSection section: Int, isOpen: Bool )
}



class MyPhotosSectionHeaderCollectionViewCell: UICollectionViewCell {
    
    // MARK: Public Definitons
    
    @IBOutlet weak var openCloseButton: UIButton!
    
    
    // MARK: Private variables
    
    private weak var delegate: MyPhotosSectionHeaderCollectionViewCellDelegate?
    private      var isOpen  = false
    private      var section : Int = 0
    
    
    
    // MARK: UITableViewCell Lifecycle Methods
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
    }

    
    
    // MARK: Target/Action Methods
    
    @IBAction func openCloseButtonTouched(_ sender: UIButton) {
        delegate?.myPhotosSectionHeaderCollectionViewCell( self, didRequestToggleForSection: section, isOpen: isOpen )
    }
    
    
    
    // MARK: Public Interfaces
    
    func initializeForSection(_ section: Int, isOpen: Bool, _ delegate: MyPhotosSectionHeaderCollectionViewCellDelegate ) {
        let image = ( section == 0 ) ? UIImage(systemName: "photo") : UIImage(systemName: "heart.fill" )
        
        self.delegate = delegate
        self.isOpen   = isOpen
        self.section  = section
        
        openCloseButton.setImage( image, for: .normal )
    }
    
    
}
