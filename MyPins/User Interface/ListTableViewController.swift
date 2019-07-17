//
//  ListTableViewController.swift
//  MyPins
//
//  Created by Clint Shank on 3/12/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit
import MapKit



class ListTableViewController: UITableViewController,
                               PinCentralDelegate,
                               LocationEditorViewControllerDelegate
{
    let     CELL_TAG_LABEL_NAME           = 10
    let     CELL_TAG_LABEL_DETAIL         = 11
    let     CELL_TAG_IMAGE_VIEW           = 12
    let     STORYBOARD_ID_LOCATION_EDITOR = "LocationEditorViewController"
    let     STORYBOARD_ID_MAP             = "MapViewController"
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad()
    {
        logTrace()
        super.viewDidLoad()
        
        title = NSLocalizedString( "Title.PinList", comment: "Pin List" )
    }
    
    
    override func viewWillAppear(_ animated: Bool)
    {
        logTrace()
        super.viewWillAppear( animated )
        
        
        let     pinCentral = PinCentral.sharedInstance
        
        
        pinCentral.delegate = self

        if !pinCentral.didOpenDatabase
        {
            pinCentral.openDatabase()
        }
        else
        {
            tableView.reloadData()
        }

        loadBarButtonItems()
        
        NotificationCenter.default.addObserver( self,
                                                selector: #selector( ListTableViewController.pinsUpdated( notification: ) ),
                                                name:     NSNotification.Name( rawValue: NOTIFICATION_PINS_UPDATED ),
                                                object:   nil )
    }

    
    override func viewWillDisappear(_ animated: Bool)
    {
        logTrace()
        super.viewWillDisappear( animated )
        
        NotificationCenter.default.removeObserver( self )
    }
    
    
    override func didReceiveMemoryWarning()
    {
        logTrace( "MEMORY WARNING!!!" )
        super.didReceiveMemoryWarning()
    }

    
    
    // MARK: LocationEditorViewControllerDelegate Methods
    
    func locationEditorViewController( locationEditorViewController: LocationEditorViewController,
                                       didEditLocationData: Bool )
    {
        logVerbose( "didEditLocationData[ %@ ]", stringFor( didEditLocationData ) )
        
        PinCentral.sharedInstance.delegate = self
        tableView.reloadData()
    }
    
    
    func locationEditorViewController( locationEditorViewController: LocationEditorViewController,
                                       wantsToCenterMapAt coordinate: CLLocationCoordinate2D )
    {
        logTrace()
        let     userInfoDictionary = [ USER_INFO_LATITUDE: coordinate.latitude, USER_INFO_LONGITUDE: coordinate.longitude ]
        
        
        if .phone == UIDevice.current.userInterfaceIdiom
        {
            tabBarController?.selectedIndex = 1
        }
        
        DispatchQueue.main.asyncAfter( deadline: ( .now() + 0.1 ) )
        {
            NotificationCenter.default.post( name: NSNotification.Name( rawValue: NOTIFICATION_CENTER_MAP ),
                                             object: self, userInfo: userInfoDictionary )
        }
        
    }
    
    
    
    // MARK: NSNotification Methods
    
    @objc func pinsUpdated( notification: NSNotification )
    {
        logTrace()
        
        // The reason we are using Notifications is because this view can be up in two different places on the iPad at the same time.
        // This approach allows a change in one to immediately be reflected in the other.
        
        tableView.reloadData()
    }
    
    
    
    // MARK: PinCentralDelegate Methods
    
    func pinCentral( pinCentral: PinCentral,
                     didOpenDatabase: Bool )
    {
        logVerbose( "[ %@ ]", stringFor( didOpenDatabase ) )
        if didOpenDatabase
        {
            pinCentral.fetchPins()
        }
        else
        {
            presentAlert( title: NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                          message: NSLocalizedString( "AlertMessage.CannotOpenDatabase", comment: "Fatal Error!  Cannot open database." ) )
        }
        
    }
    
    
    func pinCentralDidReloadPinArray( pinCentral: PinCentral )
    {
        logVerbose( "loaded [ %d ] pins", pinCentral.pinArray.count )
        tableView.reloadData()
    }

    
    
    // MARK: Target / Action Methods
    
    @IBAction @objc func addBarButtonItemTouched( barButtonItem: UIBarButtonItem )
    {
        logTrace()
        launchLocationEditorForPinAt( index: NEW_PIN)
    }
    
    
    
    // MARK: - UITableViewDataSource Methods

    override func tableView(_ tableView: UITableView,
                              numberOfRowsInSection section: Int) -> Int
    {
        return PinCentral.sharedInstance.pinArray.count
    }


    override func tableView(_ tableView: UITableView,
                              cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
        let         pin                      = PinCentral.sharedInstance.pinArray[indexPath.row]
        let         cell                     = tableView.dequeueReusableCell( withIdentifier: "ListTableViewControllerCell", for: indexPath )
        var         dateString               = ""
        let         detailLabel: UILabel     = cell.viewWithTag( CELL_TAG_LABEL_DETAIL ) as! UILabel
        let         nameLabel:   UILabel     = cell.viewWithTag( CELL_TAG_LABEL_NAME   ) as! UILabel
        let         imageView:   UIImageView = cell.viewWithTag( CELL_TAG_IMAGE_VIEW   ) as! UIImageView
        
        
        if let lastModified = pin.lastModified as Date?
        {
            dateString = DateFormatter.localizedString( from: lastModified as Date, dateStyle: DateFormatter.Style.short, timeStyle: DateFormatter.Style.short )
        }
        
        nameLabel  .text = pin.name
        detailLabel.text = dateString

        if let detailsText = pin.details
        {
            if !detailsText.isEmpty
            {
                detailLabel.text = String.init( format: "%@ - %@", detailsText, dateString )
            }
            
        }
        
        imageView.image  = nil

        if let imageName = pin.imageName
        {
            if !imageName.isEmpty
            {
                imageView.image = PinCentral.sharedInstance.imageWith( name: imageName )
            }

        }

        return cell
    }


    override func tableView(_ tableView: UITableView,
                            canEditRowAt indexPath: IndexPath) -> Bool
    {
        return true
    }

    
    override func tableView(_ tableView: UITableView,
                              commit editingStyle: UITableViewCellEditingStyle,
                              forRowAt indexPath: IndexPath)
    {
        if editingStyle == .delete
        {
            logVerbose( "delete pin at row [ %d ]", indexPath.row )
            PinCentral.sharedInstance.deletePinAtIndex( index: indexPath.row )
        }
        
    }
    
    
    
    // MARK: UITableViewDelegate Methods
    
    override func tableView(_ tableView: UITableView,
                              didSelectRowAt indexPath: IndexPath)
    {
        logTrace()
        launchLocationEditorForPinAt( index: indexPath.row )
    }
    
    
    
    // MARK: Utility Methods
    
    private func launchLocationEditorForPinAt( index: Int )
    {
        logVerbose( "[ %d ]", index )
        if let locationEditorVC: LocationEditorViewController = iPhoneViewControllerWithStoryboardId( storyboardId: STORYBOARD_ID_LOCATION_EDITOR ) as? LocationEditorViewController
        {
            locationEditorVC.delegate                = self
            locationEditorVC.indexOfItemBeingEdited  = index
            locationEditorVC.launchedFromDetailView = false
            
            navigationController?.pushViewController( locationEditorVC, animated: true )
        }
        else
        {
            logTrace( "ERROR: Could NOT load LocationEditorViewController!" )
        }
        
    }
    
    
    private func loadBarButtonItems()
    {
        logTrace()
        let     addBarButtonItem  = UIBarButtonItem.init( barButtonSystemItem: .add,
                                                          target: self,
                                                          action: #selector( addBarButtonItemTouched ) )

        navigationItem.rightBarButtonItem = addBarButtonItem
    }


    
}
