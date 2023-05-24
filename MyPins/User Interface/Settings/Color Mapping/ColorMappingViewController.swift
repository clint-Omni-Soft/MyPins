//
//  ColorMappingViewController.swift
//  MyPins
//
//  Created by Clint Shank on 5/1/23.
//  Copyright © 2023 Omni-Soft, Inc. All rights reserved.
//

import UIKit

class ColorMappingViewController: UIViewController {

    // MARK: Public Variables
    
    @IBOutlet weak var myTableView: UITableView!

    
    
    // MARK: Private Variables
        
    private struct Constants {
        static let cellID    = "ColorMappingViewControllerCell"
    }

    private let pinCentral = PinCentral.sharedInstance
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString( "Title.ColorMapping", comment: "Color Mapping" )
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        loadBarButtonItems()
    }
    
    
    
    // MARK: Target / Action Methods
    
    @IBAction func backBarButtonTouched( sender : UIBarButtonItem ) {
        logTrace()
        navigationController?.popViewController( animated: true )
    }

    
    
    // MARK: Utility Methods
    
    private func loadBarButtonItems() {
        logTrace()
        navigationItem.leftBarButtonItem = UIBarButtonItem.init( title: NSLocalizedString( "ButtonTitle.Back", comment: "Back" ), style: .plain, target: self, action: #selector( backBarButtonTouched ) )
    }

    
}



// MARK: PinCentralDelegate Methods

extension ColorMappingViewController: PinCentralDelegate {
    
    func pinCentralDidReloadColorArray(_ pinCentral: PinCentral) {
        logTrace()
        myTableView.reloadData()
    }
    
    
}



// MARK: UITableViewDataSource Methods

extension ColorMappingViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pinCentral.colorArray.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell( withIdentifier: Constants.cellID ) else {
            logTrace( "We FAILED to dequeueReusableCell!" )
            return UITableViewCell.init()
        }
        
        var backgroundColor = UIColor.white
        let pinColor        = pinCentral.colorArray[indexPath.row]

        if ( ( pinColor.colorId == PinColors.pinWhite ) || ( pinColor.colorId == PinColors.pinYellow ) ) {
            backgroundColor = .lightGray
        }

        cell.backgroundColor = backgroundColor

        cell.detailTextLabel?.text = pinColor.name!
        cell.textLabel?.font       = UIFont.systemFont(ofSize: 17.0 )
        cell.textLabel?.text       = pinColor.descriptor!
        cell.textLabel?.textColor  = pinColorArray[Int( pinColor.colorId )]

        return cell
    }
    
    
}



// MARK: UITableViewDelegate Methods

extension ColorMappingViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false )
        
        promptForMappingFor( pinCentral.colorArray[indexPath.row] )
    }
    
    
    
    // MARK: UITableViewDelegate Utility Methods

    private func promptForMappingFor(_ pinColor: PinColor ) {
        let     title = NSLocalizedString( "AlertTitle.EditMappingFor", comment: "Edit Mapping for " ) + pinColor.name!
        let     alert = UIAlertController.init( title: title, message: nil, preferredStyle: .alert)

        let     saveAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Save", comment: "Save" ), style: .default )
        { ( alertAction ) in
            logTrace( "Save Action" )
            let     nicknameTextField = alert.textFields![0] as UITextField
            let     nickname = nicknameTextField.text ?? ""
            
            if nickname.isEmpty || nickname == "" {
                self.presentAlert(title: NSLocalizedString( "AlertTitle.MappingCannotBeBlank", comment: "Mapping Descriptor Cannot be Blank!" ), message: "" )
                return
            }
            
            pinColor.descriptor = nickname
            self.pinCentral.saveUpdated( pinColor, self )
        }
        
        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel, handler: nil )
        
        alert.addTextField
            { ( textField ) in
                textField.text = pinColor.descriptor
        }
        
        alert.addAction( saveAction   )
        alert.addAction( cancelAction )
        
        present( alert, animated: true, completion: nil )
    }

    
}
