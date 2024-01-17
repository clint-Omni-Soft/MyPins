//
//  PinColorSelectorViewController.swift
//  MyPins
//
//  Created by Clint Shank on 4/9/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit



protocol PinColorSelectorViewControllerDelegate: AnyObject {
    func pinColorSelectorViewController(_ pinColorSelectorVC: PinColorSelectorViewController, didSelectColorAt index: Int )
}



class PinColorSelectorViewController: UIViewController {
    
    // MARK: Public Variables
    
    weak var delegate: PinColorSelectorViewControllerDelegate?
    
    @IBOutlet weak var myTableView: UITableView!
    
    
    // MARK: Private Variables
    
    private struct Constants {
        static let cellID = "PinColorSelectorViewControllerCell"
    }

    private let pinCentral = PinCentral.sharedInstance
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString( "Title.SelectPinColor", comment: "Select Pin Color" )
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        loadBarButtonItems()
    }
    
    
    //MARK: Target/Action Methods
    
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



// MARK: UITableViewDataSource Methods

extension PinColorSelectorViewController: UITableViewDataSource {
    
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
        
        cell.textLabel?.font      = UIFont.systemFont(ofSize: 17.0 )
        cell.textLabel?.text      = pinColor.name!
        cell.textLabel?.textColor = pinColorArray[Int( pinColor.colorId )]

        cell.detailTextLabel?.font      = UIFont.systemFont(ofSize: 17.0 )
        cell.detailTextLabel?.text      = pinColor.descriptor!
        cell.detailTextLabel?.textColor = pinColorArray[Int( pinColor.colorId )]
        
        return cell
    }
    
    
}



// MARK: UITableViewDelegate Methods

extension PinColorSelectorViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false )
        
        delegate?.pinColorSelectorViewController( self, didSelectColorAt: indexPath.row )
        navigationController?.popViewController( animated: true )
    }
    
    
}
