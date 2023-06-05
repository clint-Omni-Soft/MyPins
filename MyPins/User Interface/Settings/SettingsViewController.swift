//
//  SettingsViewController.swift
//  MyPins
//
//  Created by Clint Shank on 5/2/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit


class SettingsViewController: UIViewController {
    
    // MARK: Public Variables
    
    @IBOutlet weak var myActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var myTableView        : UITableView!
    
    
    // MARK: Private Variables
    
    private struct CellIndexes {
        static let about             = 0
        static let colorMapping      = 1
        static let dataStoreLocation = 2
        static let howToUse          = 3
    }
    
    private struct Constants {
        static let cellId = "SettingsTableViewCell"
    }
    
    private struct StoryboardIds {
        static let about             = "AboutViewController"
        static let colorMapping      = "ColorMappingViewController"
        static let dataStoreLocation = "DataStoreLocationViewController"
        static let howToUse          = "HowToUseViewController"
    }
    
    private var canSeeNasFolders    = false
    private let deviceAccessControl = DeviceAccessControl.sharedInstance
    private let pinCentral          = PinCentral.sharedInstance
    private var showHowToUse        = true

    private var optionArray      = [ NSLocalizedString( "Title.About",              comment: "About"               ),
                                     NSLocalizedString( "Title.ColorMapping",       comment: "Color Mapping"       ),
                                     NSLocalizedString( "Title.DataStoreLocation",  comment: "Data Store Location" ),
                                     NSLocalizedString( "Title.HowToUse",           comment: "How to Use"          ) ]

    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString( "Title.Settings",  comment: "Settings"  )
        
//        if runningInSimulator() {   // Testing
//            optionArray.append( NSLocalizedString( "Title.ReduceImageSize",   comment: "Reduce Image Size" ) )
//        }
        
        if let _ = UserDefaults.standard.string(forKey: UserDefaultKeys.howToUseShown ) {
            showHowToUse = false
        }
        else {
            UserDefaults.standard.set( UserDefaultKeys.howToUseShown, forKey: UserDefaultKeys.howToUseShown )
        }
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        myActivityIndicator.isHidden = true
        myActivityIndicator.stopAnimating()

        if !pinCentral.stayOffline && ( pinCentral.dataStoreLocation == .nas || pinCentral.dataStoreLocation == .shareNas ) {
            canSeeNasFolders = false
            NASCentral.sharedInstance.canSeeNasFolders( self )
            
            myActivityIndicator.isHidden = false
            myActivityIndicator.startAnimating()
        }
        else {
            myActivityIndicator.isHidden = true
            myActivityIndicator.stopAnimating()
        }

        loadBarButtonItems()
        
        if showHowToUse {
            showHowToUse = false
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                self.pushViewControllerWith( StoryboardIds.howToUse )
            }
            
        }
        
    }
    

    
    // MARK: Target/Action Methods
    
    @IBAction func infoBarButtonItemTouched(_ sender : UIBarButtonItem ) {
        let     message = String( format: NSLocalizedString( "AlertMessage.SelectHowToUseForInfo", comment: "Select '%@' for helpful information on: %@,%@,%@,%@ and\nmany other topics." ),
                                          NSLocalizedString( "Title.HowToUse",          comment: "How to Use" ),
                                          NSLocalizedString( "Title.PinList",           comment: "Pin List" ),
                                          NSLocalizedString( "Title.PinEditor",         comment: "Pin Editor" ),
                                          NSLocalizedString( "Title.Map",               comment: "Map" ),
                                          NSLocalizedString( "Title.DataStoreLocation", comment: "Data Store Location" ) )
        
        presentAlert( title: NSLocalizedString( "AlertTitle.GotAQuestion", comment: "Got a question?" ), message: message )
    }
    
    

    // MARK: Utility Methods

    private func loadBarButtonItems() {
        logTrace()
        navigationItem.rightBarButtonItem = UIBarButtonItem.init( image: UIImage(named: "info" ), style: .plain, target: self, action: #selector( infoBarButtonItemTouched(_:) ) )
    }
    
    
    private func pushViewControllerWith(_ storyboardId: String ) {
        logVerbose( "[ %@ ]", storyboardId )
        let viewController = iPhoneViewControllerWithStoryboardId( storyboardId: storyboardId )
        
        navigationController?.pushViewController( viewController, animated: true )
    }

    
}



// MARK: NASCentral Delegate Methods

extension SettingsViewController: NASCentralDelegate {
    
    func nasCentral(_ nasCentral: NASCentral, canSeeNasFolders: Bool) {
        logVerbose( "[ %@ ]", stringFor( canSeeNasFolders ) )
        
        self.canSeeNasFolders = canSeeNasFolders
        
        myActivityIndicator.stopAnimating()
        myActivityIndicator.isHidden = true
    }

    
}



// MARK: UITableViewDataSource Methods

extension SettingsViewController: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell( withIdentifier: Constants.cellId, for: indexPath)
        
        cell.textLabel?.text = optionArray[indexPath.row]
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int ) -> Int {
        return optionArray.count
    }
    
    
}


// MARK: - UITableViewDelegate Methods

extension SettingsViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath ) {
        logTrace()
        tableView.deselectRow( at: indexPath, animated: false )
        
        switch indexPath.row {
            case CellIndexes.about:             pushViewControllerWith( StoryboardIds.about             )
            case CellIndexes.colorMapping:      pushViewControllerWith( StoryboardIds.colorMapping      )
            case CellIndexes.dataStoreLocation: pushViewControllerWith( StoryboardIds.dataStoreLocation )
            case CellIndexes.howToUse:          pushViewControllerWith( StoryboardIds.howToUse          )
            default:    break
        }
            
    }
    

}



