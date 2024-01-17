//
//  ListTableViewSectionCell.swift
//  MyPins
//
//  Created by Clint Shank on 11/20/23.
//  Copyright © 2023 Omni-Soft, Inc. All rights reserved.
//

import UIKit


protocol ListTableViewSectionCellDelegate {
    func listTableViewSectionCell(_ listTableViewSectionCell: ListTableViewSectionCell, section: Int, isOpen: Bool )
}



class ListTableViewSectionCell: UITableViewCell {


    // MARK: Public Variables
    
    @IBOutlet weak var titleLabel  : UILabel!
    @IBOutlet weak var toggleButton: UIButton!

    
    
    // MARK: Private Variables
    
    private var     delegate      : ListTableViewSectionCellDelegate!
    private var     sectionIsOpen = false
    private var     sectionNumber = 0
    private let     pinCentral    = PinCentral.sharedInstance

        
        
    // MARK: Target/Action Methods
    
    @IBAction func toggleButtonTouched(_ sender: UIButton) {
        delegate.listTableViewSectionCell( self, section: sectionNumber, isOpen: sectionIsOpen )
    }

        
        
    // MARK: Public Initializer

    func initializeFor(_ section: Int, with titleText: String, isOpen: Bool, _ delegate: ListTableViewSectionCellDelegate ) {
        self.delegate = delegate
        sectionIsOpen = isOpen
        sectionNumber = section
        
        titleLabel.text      = titleText
        titleLabel.textColor = .black
        toggleButton.setTitle( "", for: .normal )
    }

    
}
