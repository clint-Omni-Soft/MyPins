//
//  LocationNotesTableViewCell.swift
//  MyPins
//
//  Created by Clint Shank on 11/28/22.
//  Copyright © 2022 Omni-Soft, Inc. All rights reserved.
//

import UIKit


protocol LocationNotesTableViewCellDelegate: AnyObject {
    func locationNotesTableViewCellWantsToEdit(_ LocationNotesTableViewCell: LocationNotesTableViewCell )
}



class LocationNotesTableViewCell: UITableViewCell {
    
    // MARK: Public Variables
    
    @IBOutlet weak var notesButton: UIButton!
    @IBOutlet weak var notesTextView: UITextView!

    
    // MARK: Private Variables
    
    private var delegate: LocationNotesTableViewCellDelegate!
    
    
    
    // MARK: UITableViewCell Lifecycle Methods
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    
    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(false, animated: animated)
    }

    
    
    // MARK: Target/Action Methods
    
    @IBAction func notesButtonTouched(_ sender: UIButton) {
        delegate.locationNotesTableViewCellWantsToEdit( self )
    }
    
    
    
    // MARK: Public Initializer
    
    func initializeWith(_ notes: String, _ cellDelegate: LocationNotesTableViewCellDelegate ) {
        logTrace()
        delegate           = cellDelegate
        notesTextView.font = UIFont.systemFont(ofSize: 17.0 )
        notesTextView.text = notes

        notesButton.setTitle( NSLocalizedString( "LabelText.Notes", comment: "Notes" ), for: .normal )
    }
    
    
}
