//
//  SortOptionsViewController.swift
//  MyPins
//
//  Created by Clint Shank on 11/14/23.
//  Copyright © 2023 Omni-Soft, Inc. All rights reserved.
//

import UIKit


protocol SortOptionsViewControllerDelegate: AnyObject {
    func sortOptionsViewController(_ sortOptionsViewController: SortOptionsViewController, didSelectNewSortOption: Bool )
}


class SortOptionsViewController: UIViewController {
    
    
    // MARK: Public Variables
    
    weak var delegate: SortOptionsViewControllerDelegate?
    
    @IBOutlet weak var cancelButton         : UIButton!
    @IBOutlet weak var myTableView          : UITableView!
    @IBOutlet weak var saveButton           : UIButton!
    @IBOutlet weak var sortAscendingLabel   : UILabel!
    @IBOutlet weak var sortAscendingSwitch  : UISwitch!
    @IBOutlet weak var titleLabel           : UILabel!
    
    
    
    // MARK: Private Variables

    private struct Constants {
        static let cellID = "SortOptionsTableViewCell"
    }

    private let pinCentral          = PinCentral.sharedInstance
    private var originalOptionIndex = 0
    private var originalOptionTuple = ( "", true )
    private var selectedOptionIndex = 0
    private var somethingChanged    = false
    private let sortOptionNames     = [SortOptionNames.byDateLastModified, SortOptionNames.byName, SortOptionNames.byType]
    private let sortOptions         = [SortOptions.byDateLastModified,     SortOptions.byName,     SortOptions.byType    ]
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()

        preferredContentSize = CGSize(width: 375, height: 300 )

        titleLabel        .text = NSLocalizedString( "Title.SelectSortOptions",   comment: "Select Sort Options" )
        sortAscendingLabel.text = NSLocalizedString( "ButtonTitle.SortAscending", comment: "Sort Ascending"      )
        
        cancelButton.setTitle( NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), for: .normal )
        saveButton  .setTitle( NSLocalizedString( "ButtonTitle.Save",   comment: "Save"   ), for: .normal )
        
        saveButton.isHidden = !somethingChanged
        
        originalOptionTuple = pinCentral.sortDescriptor

        switch originalOptionTuple.0 {
        case SortOptions.byDateLastModified: selectedOptionIndex = 0
        case SortOptions.byType:             selectedOptionIndex = 2
        default:                             selectedOptionIndex = 1    // byName
        }
        
        originalOptionIndex = selectedOptionIndex
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear(animated)
        
        sortAscendingSwitch.isOn = originalOptionTuple.1
        myTableView.reloadData()
    }
    
    
    
    //MARK: Target/Action Methods
    
    @IBAction func cancelButtonTouched(_ sender: Any) {
        logTrace()
        dismiss(animated: true)
    }
    
    
    @IBAction func saveButtonTouched(_ sender: Any) {
        let sortAscendingFlag = sortAscendingSwitch.isOn
        let sortOption        = sortOptions[selectedOptionIndex]
        
        if ( sortAscendingFlag != originalOptionTuple.1 ) || ( sortOption != originalOptionTuple.0 ) {
            pinCentral.sortDescriptor = ( sortOption, sortAscendingFlag )
            
            delegate?.sortOptionsViewController( self, didSelectNewSortOption: true )
        }
        
        dismiss(animated: true)
    }
    
    
    @IBAction func sortAscendingSwitchValueChanged(_ sender: Any) {
        saveButton.isHidden = ( sortAscendingSwitch.isOn == originalOptionTuple.1 ) && ( originalOptionIndex == selectedOptionIndex )
    }
    
    
}



// MARK: UITableViewDataSource Methods

extension SortOptionsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return sortOptionNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell( withIdentifier: Constants.cellID ) else {
            logTrace( "We FAILED to dequeueReusableCell!" )
            return UITableViewCell.init()
        }
        
        cell.accessoryType   = ( indexPath.row == selectedOptionIndex ) ? .checkmark : .none
        cell.textLabel!.text = sortOptionNames[indexPath.row]
        
        return cell
    }
    
    
}



// MARK: UITableViewDataSource Methods

extension SortOptionsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let currentSelectedCell = tableView.cellForRow(at: indexPath )
        let lastSelectedCell    = tableView.cellForRow(at: IndexPath(row: selectedOptionIndex, section: 0 ) )

        tableView.deselectRow(at: indexPath, animated: false )
        
        lastSelectedCell?   .accessoryType = .none
        currentSelectedCell?.accessoryType = .checkmark
        
        selectedOptionIndex = indexPath.row
        
        saveButton.isHidden = ( sortAscendingSwitch.isOn == originalOptionTuple.1 ) && ( originalOptionIndex == selectedOptionIndex )
    }
    
    
}