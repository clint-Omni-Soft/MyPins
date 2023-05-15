//
//  DataStoreLocationViewController.swift
//  MyPins
//
//  Ported by Clint Shank from WineStock on 03/24/23.
//  Copyright © 2020-2023 Omni-Soft, Inc. All rights reserved.
//

import UIKit

class DataStoreLocationViewController: UIViewController {
    
    // MARK: Public Variables
    
    @IBOutlet weak var myActivityIndicator : UIActivityIndicatorView!
    @IBOutlet weak var myTableView         : UITableView!
    
    
    
    // MARK: Private Variables
    
    private struct CellIDs {
        static let basic  = "DataStoreLocationViewControllerCell"
        static let detail = "DataStoreLocationViewControllerDetailCell"
    }
    
    private struct CellIndexes {
        static let device = 0
        static let iCloud = 1
        static let nas    = 2
        static let unused = 3
    }
    
    private struct StoryboardIds {
        static let nasSelector      = "NasDriveSelectorViewController"
        static let transferProgress = "TransferProgressViewController"
    }
    
    private var canSeeCloud      = false
    private var canSeeNasFolders = false
    private var canSeeCount      = 0
    private let pinCentral       = PinCentral.sharedInstance
    private var selectedOption   = CellIndexes.device

    private let optionArray = [ NSLocalizedString( "Title.Device",     comment: "Device" ),
                                NSLocalizedString( "Title.iCloud",     comment: "iCloud" ),
                                NSLocalizedString( "Title.InNASDrive", comment: "Network Accessible Storage" ) ]
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        self.navigationItem.title = NSLocalizedString( "Title.SaveDataIn", comment: "Save Data In?" )
        
        if let dataStoreLocation = UserDefaults.standard.string( forKey: UserDefaultKeys.dataStoreLocation ) {
            
            switch dataStoreLocation {
            case DataStoreLocationName.device:      selectedOption = CellIndexes.device
            case DataStoreLocationName.shareCloud:  selectedOption = CellIndexes.iCloud
            case DataStoreLocationName.iCloud:      selectedOption = CellIndexes.iCloud
            case DataStoreLocationName.nas:         selectedOption = CellIndexes.nas
            case DataStoreLocationName.shareNas:    selectedOption = CellIndexes.nas
            default:                                logTrace( "ERROR!  SBH!" )
            }
            
        }
        else {
            selectedOption = CellIndexes.device
        }
        
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        canSeeCount      = 0
        canSeeCloud      = false
        canSeeNasFolders = false
        
        CloudCentral.sharedInstance.canSeeCloud( self )
        NASCentral.sharedInstance.canSeeNasFolders( self )
        
        myActivityIndicator.isHidden = false
        myActivityIndicator.startAnimating()
        
        loadBarButtonItems()
        
        myTableView.reloadData()
    }

    
    
    // MARK: Target/Action Methods
    
    @IBAction func backBarButtonTouched( sender : UIBarButtonItem ) {
        logTrace()
        navigationController?.popViewController( animated: true )
    }
    

    @IBAction func infoBarButtonTouched(_ sender : UIBarButtonItem ) {
        let     message = NSLocalizedString( "InfoText.DataStoreLocation1", comment: "DATA STORE LOCATION\n\nWe provide support for three different storage location options...\n\n   (a) on your device (default),\n   (b) in the cloud and \n   (c) on a Network Accessible Storage (NAS) unit.\n\n" ) +
                          NSLocalizedString( "InfoText.DataStoreLocation2", comment: "The key point here is that there is no sharing on the device.  If you chose the cloud then your data can be shared across all of your devices.  If you chose NAS then anyone who has access to your Wi-Fi can access it.\n" ) 

        presentAlert( title: NSLocalizedString( "AlertTitle.GotAQuestion", comment: "Got a question?" ), message: message )
    }

    
    
    // MARK: Utility Methods
    
    private func loadBarButtonItems() {
//        logTrace()
        navigationItem.leftBarButtonItem  = UIBarButtonItem.init( title: NSLocalizedString( "ButtonTitle.Back", comment: "Back" ), style: .plain, target: self, action: #selector( backBarButtonTouched ) )
        navigationItem.rightBarButtonItem = UIBarButtonItem.init( image: UIImage(named: "info" ), style: .plain, target: self, action: #selector( infoBarButtonTouched(_:) ) )
    }
    

}



// MARK: CloudCentralDelegate Methods

extension DataStoreLocationViewController : CloudCentralDelegate {
    
    func cloudCentral(_ cloudCentral: CloudCentral, canSeeCloud: Bool) {
        logVerbose( "[ %@ ]", stringFor( canSeeCloud ) )
        
        self.canSeeCloud = canSeeCloud
        
        canSeeCount += 1
        
        if canSeeCount == 2 {
            myActivityIndicator.stopAnimating()
            myActivityIndicator.isHidden = true
            myTableView.reloadData()
        }
        
    }
    
    
    func cloudCentral(_ cloudCentral: CloudCentral, didCreateDirectoryTree: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didCreateDirectoryTree ) )
        
        if didCreateDirectoryTree {
            presentConfirmationForCloudTransfer( shared: true )
        }
        else {
            presentAlert( title   : NSLocalizedString( "AlertTitle.Error", comment: "Error" ),
                          message : NSLocalizedString( "AlertMessage.UnableToCreateCloudFolders", comment: "Unable to create our directories on your iCloud Drive." ) )
        }
        
    }
    
    
    func cloudCentral(_ cloudCentral: CloudCentral, rootDirectoryIsPresent: Bool ) {
        logVerbose( "[ %@ ]", stringFor( rootDirectoryIsPresent ) )

        if rootDirectoryIsPresent {
            presentConfirmationForCloudTransfer( shared: pinCentral.dataStoreLocation != .device )
        }
        else {
            cloudCentral.createDrirectoryTree( self )
        }

    }
    
    

    // MARK: CloudCentralDelegate Utility Methods
    
    private func launchTransferProgressViewController() {
        guard let transferProgressVC : TransferProgressViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.transferProgress ) as? TransferProgressViewController else {
            logTrace( "Error!  Unable to load TransferProgressViewController!" )
            return
        }

        transferProgressVC.modalPresentationStyle = .overFullScreen
        
        transferProgressVC.popoverPresentationController?.delegate                 = self
        transferProgressVC.popoverPresentationController?.permittedArrowDirections = .any
        transferProgressVC.popoverPresentationController?.sourceRect               = view.frame
        transferProgressVC.popoverPresentationController?.sourceView               = view
        
        present( transferProgressVC, animated: true, completion: nil )
    }
    
    
    private func presentConfirmationForCloudTransfer( shared : Bool ) {
        logVerbose( "[ %@ ]", stringFor( shared ) )
        var     message = shared ? NSLocalizedString( "AlertMessage.DataWillBeShared",  comment: "When you hit the OK button we will transfer your data then kill the app.  When you re-start the app will SHARE the data in your " ) :
                                   NSLocalizedString( "AlertMessage.DataWillBeMovedTo", comment: "When you hit the OK button we will transfer your data then kill the app.  When you re-start the app your data will stored be on your " )
        let     title   = NSLocalizedString( "Title.DataStoreLocation", comment: "Data Store Location" )
        
        message += NSLocalizedString( "Title.iCloud", comment: "iCloud" )
        
        let     alert = UIAlertController.init( title : title, message : message, preferredStyle : .alert )

        let     okAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.OK", comment: "OK" ), style: .default )
        { ( alertAction ) in
            logTrace( "OK Action" )
            self.pinCentral.dataStoreLocation = ( shared ? .shareCloud : .iCloud )
            self.launchTransferProgressViewController()
        }
        
        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel, handler: nil )

        alert.addAction( cancelAction )
        alert.addAction( okAction     )
        
        present( alert, animated: true, completion: nil )

    }

}



// MARK: NASCentralDelegate Methods

extension DataStoreLocationViewController : NASCentralDelegate {
    
    func nasCentral(_ nasCentral: NASCentral, canSeeNasFolders: Bool) {
        logVerbose( "[ %@ ]", stringFor( canSeeNasFolders ) )
        
        self.canSeeNasFolders = canSeeNasFolders
        
        canSeeCount += 1
        
        if canSeeCount == 2 {
            myActivityIndicator.stopAnimating()
            myActivityIndicator.isHidden = true
            myTableView.reloadData()
        }
        
    }

    
}



// MARK: UIPopoverPresentationControllerDelegate Methods

extension DataStoreLocationViewController : UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle( for controller : UIPresentationController ) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    
}



// MARK: UITableViewDataSource Methods

extension DataStoreLocationViewController : UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return optionArray.count
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let     useDetailCell = ( indexPath.row == CellIndexes.nas ) && canSeeNasFolders && ( selectedOption == CellIndexes.nas )
        let     cellID        = useDetailCell ? CellIDs.detail : CellIDs.basic
        
        guard let cell = tableView.dequeueReusableCell( withIdentifier: cellID ) else {
            logTrace( "We FAILED to dequeueReusableCell!" )
            return UITableViewCell.init()
        }

        cell.textLabel?.text = optionArray[indexPath.row]
        cell.accessoryType   = ( indexPath.row == selectedOption ) ? .checkmark : .none
        
        if useDetailCell {
            let     descriptor = pinCentral.nasDescriptor
            let     fullPath   = String( format: "%@/%@/%@", descriptor.netbiosName, descriptor.share, descriptor.path )
            
            cell.detailTextLabel?.text = fullPath
        }
        
        return cell
    }
    
    
}



// MARK: UITableViewDelegate Methods

extension DataStoreLocationViewController : UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow( at: indexPath, animated: false )
        
        if  indexPath.row == selectedOption && indexPath.row != CellIndexes.nas {
            return
        }
        
        switch indexPath.row {
        case CellIndexes.device:
            tableView.reloadData()
            // NOTE - We are assuming that the data on the device is either more current or at least up to date
            //        with where ever it was previously stored (NAS or iCloud) so we don't have to copy any files.
            presentConfirmationForMoveToDevice()

        case CellIndexes.nas:
            if selectedOption == CellIndexes.iCloud {
                presentAlert( title  : NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                              message: NSLocalizedString( "AlertMessage.CannotGoDirectFromCloudToNas", comment: "You can't go from iCloud directly to NAS, you must go back to the Device and then to NAS" ) )
                return
            }
            
//            if canSeeNasFolders {
                launchNasSelectorViewController()
//            }
//            else {
//                presentAlert( title   : NSLocalizedString( "AlertTitle.Error", comment:  "Error" ),
//                              message : NSLocalizedString( "AlertMessage.CannotSeeExternalDevice", comment: "We cannot see your external device.  Move closer to your WiFi network and try again." ) )
//            }

        case CellIndexes.iCloud:
            if selectedOption == CellIndexes.nas {
                presentAlert( title  : NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                              message: NSLocalizedString( "AlertMessage.CannotGoDirectFromNasToCloud", comment: "You can't go from NAS directly to iCloud, you must go back to the Device and then to iCloud" ) )
                return
            }
            
            if canSeeCloud {
                CloudCentral.sharedInstance.isRootDirectoryPresent( self )
            }
            else {
                presentAlert( title   : NSLocalizedString( "AlertTitle.Error", comment:  "Error" ),
                              message : NSLocalizedString( "AlertMessage.CannotSeeContainer", comment: "Cannot see your iCloud container!  Please go to Settings and verify that you have signed into iCloud with your Apple ID then navigate to the iCloud setting screen and make sure iCloud Drive is on.  Finally, verify that iCloud is enabled for this app." ) )
            }

        default:
            logTrace( "ERROR!  SBH!" )
        }
        
    }
    
    
    
    // MARK: UITableViewDelegate Utility Methods
    
    private func launchNasSelectorViewController() {
        guard let nasDriveSelector : NasDriveSelectorViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.nasSelector ) as? NasDriveSelectorViewController else {
            logTrace( "Error!  Unable to load NasDriveSelectorViewController!" )
            return
        }
        
        logTrace()
        navigationController?.pushViewController( nasDriveSelector, animated: true )
    }
    
    
    private func presentConfirmationForMoveToDevice() {
        var     message = NSLocalizedString( "AlertMessage.DataWillBeMovedTo", comment: "When you hit the OK button we will kill the app.  When you re-start the app your data will be moved to your " )
        let     title   = NSLocalizedString( "Title.DataStoreLocation", comment: "Data Store Location" )
        
        message += NSLocalizedString( "Title.Device", comment: "Device" )
        
        let     alert = UIAlertController.init( title : title, message : message, preferredStyle : .alert )

        let     okAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.OK", comment: "OK" ), style: .default )
        { ( alertAction ) in
            logTrace( "OK Action" )
            self.pinCentral.dataStoreLocation = ( .device )
            UserDefaults.standard.removeObject(forKey: UserDefaultKeys.nasDescriptor )

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
                exit( 0 )
            })

        }
        
        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel, handler: nil )

        alert.addAction( cancelAction )
        alert.addAction( okAction     )
        
        present( alert, animated: true, completion: nil )
    }
    
    
}
