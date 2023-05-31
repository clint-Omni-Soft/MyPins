//
//  ListTableViewController.swift
//  MyPins
//
//  Created by Clint Shank on 3/12/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit
import MapKit



class ListTableViewController: UITableViewController {
    
    // MARK: Private Variables
        
    private struct Constants {
        static let cellID    = "ListTableViewControllerCell"
        static let rowHeight = CGFloat.init( 72.0 )
    }

    private struct StoryboardIds {
        static let locationEditor = "LocationEditorViewController"
        static let map            = "MapViewController"
    }
    
    private let deviceAccessControl = DeviceAccessControl.sharedInstance
    private let pinCentral          = PinCentral.sharedInstance
    private var sectionIndexTitles  : [String] = []
    private var sectionTitleIndexes : [Int]    = []

    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString( "Title.PinList", comment: "Pin List" )
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        loadBarButtonItems()
        
        if !pinCentral.didOpenDatabase {
            pinCentral.openDatabaseWith( self )
        }
        else {
            buildSectionTitleIndex()
            
            tableView.reloadData()

            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0 ) {
                let rowToScrollToTop = self.getIntValueFromUserDefaults( UserDefaultKeys.lastLocationRow )
                let indexPath        = IndexPath(row: rowToScrollToTop, section: 0)
                
                self.tableView.scrollToRow(at: indexPath, at: .top, animated: true )
            }
            
        }

        NotificationCenter.default.addObserver( self, selector: #selector( self.pinsUpdated( notification: ) ), name: NSNotification.Name( rawValue: Notifications.pinsArrayReloaded ), object: nil )
    }

    
    override func viewWillDisappear(_ animated: Bool) {
        logTrace()
        super.viewWillDisappear( animated )
        
        NotificationCenter.default.removeObserver( self )
    }
    
    
    
    
    // MARK: NSNotification Methods
    
    @objc func pinsUpdated( notification: NSNotification ) {
        logTrace()
        
        // The reason we are using Notifications is because this view can be up in two different places on the iPad at the same time.
        // This approach allows a change in one to immediately be reflected in the other.
        buildSectionTitleIndex()

        tableView.reloadData()
    }
    
    
    
    // MARK: Target / Action Methods
    
    @IBAction @objc func addBarButtonItemTouched( barButtonItem: UIBarButtonItem ) {
        logTrace()
        launchLocationEditorForPinAt( index: GlobalConstants.newPin)
    }
    
    
    
    
    // MARK: Utility Methods
    
    private func buildSectionTitleIndex() {
        var     currentTitle = ""
        var     index        = 0
        
        sectionIndexTitles .removeAll()
        sectionTitleIndexes.removeAll()
        
        for pin in pinCentral.pinArray {
            let     nameStartsWith: String = ( pin.name?.prefix(1).uppercased() )!
            
            if nameStartsWith != currentTitle {
                currentTitle = nameStartsWith
                sectionTitleIndexes.append( index )
                sectionIndexTitles .append( nameStartsWith )
            }
            
            index += 1
        }
        
    }
  
    
    private func launchLocationEditorForPinAt( index: Int ) {
        logVerbose( "[ %d ]", index )
        if let locationEditorVC: LocationEditorViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.locationEditor ) as? LocationEditorViewController {
            locationEditorVC.delegate               = self
            locationEditorVC.indexOfItemBeingEdited = index
            locationEditorVC.launchedFromDetailView = false
            
            navigationController?.pushViewController( locationEditorVC, animated: true )
        }
        else {
            logTrace( "ERROR: Could NOT load LocationEditorViewController!" )
        }
        
    }
    
    
    private func loadBarButtonItems() {
        logTrace()
        navigationItem.rightBarButtonItem = UIBarButtonItem.init( barButtonSystemItem: .add, target: self, action: #selector( addBarButtonItemTouched ) )
    }

    
}



// MARK: LocationEditorViewControllerDelegate Methods

extension ListTableViewController: LocationEditorViewControllerDelegate {
    
    func locationEditorViewController(_ locationEditorViewController: LocationEditorViewController, didEditLocationData: Bool ) {
        logVerbose( "didEditLocationData[ %@ ]", stringFor( didEditLocationData ) )
        
        if didEditLocationData {
            tableView.reloadData()
        }
        
    }
    
    
    func locationEditorViewController(_ locationEditorViewController: LocationEditorViewController, wantsToCenterMapAt coordinate: CLLocationCoordinate2D ) {
        logTrace()
        let     userInfoDictionary = [ UserInfo.latitude: coordinate.latitude, UserInfo.longitude: coordinate.longitude ]
        
        
        if .phone == UIDevice.current.userInterfaceIdiom {
            tabBarController?.selectedIndex = 1
        }
        
        DispatchQueue.main.asyncAfter( deadline: ( .now() + 0.1 ) ) {
            NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.centerMap ),
                                             object: self, userInfo: userInfoDictionary )
        }
        
    }
    

}



// MARK: PinCentralDelegate Methods

extension ListTableViewController: PinCentralDelegate {
    
    func pinCentral(_ pinCentral: PinCentral, didOpenDatabase: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didOpenDatabase ) )
        if didOpenDatabase {
            pinCentral.fetchPinsWith( self )
        }
        else {
            presentAlert( title:   NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                          message: NSLocalizedString( "AlertMessage.CannotOpenDatabase", comment: "Fatal Error!  Cannot open database." ) )
        }
        
    }
    
    
    func pinCentralDidReloadPinArray(_ pinCentral: PinCentral ) {
        logVerbose( "loaded [ %d ] pins", pinCentral.pinArray.count )
        buildSectionTitleIndex()
        
        tableView.reloadData()
    }


}



// MARK: - UITableViewDataSource Methods

extension ListTableViewController {

    override func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sectionIndexTitles
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return pinCentral.pinArray.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell( withIdentifier: Constants.cellID ) else {
            logTrace( "We FAILED to dequeueReusableCell!" )
            return UITableViewCell.init()
        }
        
        let     pin         = pinCentral.pinArray[indexPath.row]
        let     pinListCell = cell as! ListTableViewControllerCell

        pinListCell.initializeWith( pin )
        
        return cell
    }


    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return deviceAccessControl.byMe
    }

    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            logVerbose( "delete pin at row [ %d ]", indexPath.row )
            pinCentral.deletePinAt( indexPath.row, self )
        }
        
    }
    
    
    override func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        let     row = sectionTitleIndexes[index]
            
        tableView.scrollToRow(at: IndexPath(row: row, section: 0), at: .middle , animated: true )
        
        return row
    }
    
    
}



    // MARK: UITableViewDelegate Methods

extension ListTableViewController {
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        logTrace()
        if deviceAccessControl.byMe {
            launchLocationEditorForPinAt( index: indexPath.row )
            setIntValueInUserDefaults( indexPath.row, UserDefaultKeys.lastLocationRow )
        }
        
    }
    
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.rowHeight
    }
    

}
