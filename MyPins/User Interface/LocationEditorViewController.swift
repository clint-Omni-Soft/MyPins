//
//  LocationEditorViewController.swift
//  MyPins
//
//  Created by Clint Shank on 6/24/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit
import MapKit



protocol LocationEditorViewControllerDelegate: class
{
    func locationEditorViewController( locationEditorViewController: LocationEditorViewController,
                                       didEditLocationData: Bool )
    
    func locationEditorViewController( locationEditorViewController: LocationEditorViewController,
                                       wantsToCenterMapAt coordinate: CLLocationCoordinate2D )
}



class LocationEditorViewController: UIViewController,
                                    LocationDetailsTableViewCellDelegate,
                                    LocationImageTableViewCellDelegate,
                                    PinCentralDelegate,
                                    PinColorSelectorViewControllerDelegate,
                                    UIImagePickerControllerDelegate,
                                    UINavigationControllerDelegate,  // Required for UIImagePickerControllerDelegate
                                    UIPopoverPresentationControllerDelegate,
                                    UITableViewDataSource,
                                    UITableViewDelegate
 {
    @IBOutlet weak var myTableView: UITableView!
    
    // MARK: Public Variables
    weak var delegate: LocationEditorViewControllerDelegate?
    
    var     centerOfMap:                CLLocationCoordinate2D!     // Only set by MapViewController when indexOfItemBeingEdited == NEW_PIN
    var     indexOfItemBeingEdited:     Int!                        // Set by delegate
    var     launchedFromDetailView    = false                       // Set by delegate
    var     useCenterOfMap            = false                       // Only set by MapViewController when indexOfItemBeingEdited == NEW_PIN
    
    
    // MARK: Private Variables
    private let     CELL_ID_DETAILS              = "LocationDetailsTableViewCell"
    private let     CELL_ID_IMAGE                = "LocationImageTableViewCell"
    private let     STORYBOARD_ID_COLOR_SELECTOR = "PinColorSelectorViewController"
    
    private var     altitude                  = 0.0
    private var     changingColors            = false
    private var     details                   = String()
    private var     detailsCell               : LocationDetailsTableViewCell!   // Set in LocationDetailsTableViewCellDelegate Method
    private var     firstTimeIn               = true
    private var     imageAssigned             = false
    private var     imageCell                 : LocationImageTableViewCell!     // Set in LocationImageTableViewCellDelegate Method
    private var     imageName                 = String()
    private var     latitude                  = 0.0
    private var     longitude                 = 0.0
    private var     name                      = String()
    private var     originalAltitude          = 0.0
    private var     originalDetails           = String()
    private var     originalImageName         = String()
    private var     originalLatitude          = 0.0
    private var     originalLongitude         = 0.0
    private var     originalName              = String()
    private var     originalPinColor          : Int16!      // Set in initializeVariables()
    private var     pinColor                  : Int16!      // Set in initializeVariables()
    private var     savedPinBeforeShowingMap  = false
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad()
    {
        logTrace()
        super.viewDidLoad()

        title = NSLocalizedString( "Title.PinEditor", comment: "Pin Editor" )
        
        showSaveBarButtonItem(show: false)
        preferredContentSize = CGSize( width: 320, height: 460 )
        
        initializeVariables()
    }
    
    
    override func viewWillAppear(_ animated: Bool)
    {
        logTrace()
        super.viewWillAppear( animated )
        
        navigationItem.leftBarButtonItem  = UIBarButtonItem.init( title: ( launchedFromDetailView ? NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ) : NSLocalizedString( "ButtonTitle.Back",   comment: "Back"   ) ),
                                                                  style: .plain,
                                                                  target: self,
                                                                  action: #selector( cancelBarButtonTouched ) )
        myTableView.reloadData()
        
        NotificationCenter.default.addObserver( self,
                                                selector: #selector( LocationEditorViewController.pinsUpdated( notification: ) ),
                                                name:     NSNotification.Name( rawValue: NOTIFICATION_PINS_UPDATED ),
                                                object:   nil )
        
        if !firstTimeIn || ( NEW_PIN != indexOfItemBeingEdited )
        {
            showSaveBarButtonItem(show: dataChanged())
        }
        
    }
    
    
    override func viewWillDisappear(_ animated: Bool)
    {
        logTrace()
        super.viewWillDisappear( animated )
        
        NotificationCenter.default.removeObserver( self )
        
        if !imageAssigned && !changingColors
        {
            deleteImage()
        }
        
    }
    
    
    override func didReceiveMemoryWarning()
    {
        logTrace( "MEMORY WARNING!!!" )
        super.didReceiveMemoryWarning()
    }
    
    
    

    // MARK: LocationDetailsTableViewCellDelegate Methods
    
    func locationDetailsTableViewCell( locationDetailsTableViewCell: LocationDetailsTableViewCell,
                                       requestingEditOfNameAndDetails: Bool )
    {
        logTrace()
        editNameAndDetails(locationDetailsTableViewCell: locationDetailsTableViewCell)
    }

    
    
    func locationDetailsTableViewCell( locationDetailsTableViewCell: LocationDetailsTableViewCell,
                                       requestingEditOfLocation: Bool )
    {
        logTrace()
        editLatLongAndAlt(locationDetailsTableViewCell: locationDetailsTableViewCell)
    }
    
    
    func locationDetailsTableViewCell( locationDetailsTableViewCell: LocationDetailsTableViewCell,
                                       requestingEditOfPinColor: Bool )
    {
        logTrace()
        detailsCell = locationDetailsTableViewCell
        
        if let  pinColorSelectorVC: PinColorSelectorViewController = iPhoneViewControllerWithStoryboardId( storyboardId: STORYBOARD_ID_COLOR_SELECTOR ) as? PinColorSelectorViewController
        {
            changingColors = true
            
            pinColorSelectorVC.delegate         = self
            pinColorSelectorVC.originalPinColor = pinColor
            
            pinColorSelectorVC.modalPresentationStyle = .formSheet
            
            present( pinColorSelectorVC, animated: true, completion: nil )
            
            pinColorSelectorVC.popoverPresentationController?.delegate                 = self
            pinColorSelectorVC.popoverPresentationController?.permittedArrowDirections = .any
            pinColorSelectorVC.popoverPresentationController?.sourceRect               = view.frame
            pinColorSelectorVC.popoverPresentationController?.sourceView               = view
        }
        else
        {
            logTrace( "ERROR:  Unable to load PinColorSelectorViewController!" )
        }
    }
    

    func locationDetailsTableViewCell( locationDetailsTableViewCell: LocationDetailsTableViewCell,
                                       requestingShowPinOnMap: Bool )
    {
        logTrace()

        if name.isEmpty
        {
            logTrace( "ERROR:  Name field cannot be left blank!" )
            presentAlert( title:   NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                          message: NSLocalizedString( "AlertMessage.NameCannotBeBlank", comment: "Name field cannot be left blank" ) )
            return
        }
        
        if dataChanged()
        {
            updatePinCentral()
            
            savedPinBeforeShowingMap = true
            
            logVerbose( "indexOfSelectedPin[ %d ] = indexOfItemBeingEdited[ %d ]", PinCentral.sharedInstance.indexOfSelectedPin, indexOfItemBeingEdited )
            PinCentral.sharedInstance.indexOfSelectedPin = indexOfItemBeingEdited
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01 )
        {
            logTrace( "waiting for update from pinCentral" )
            self.delegate?.locationEditorViewController( locationEditorViewController: self,
                                                         wantsToCenterMapAt: CLLocationCoordinate2DMake( self.latitude, self.longitude ) )
        }
        
    }
    


    // MARK: LocationImageTableViewCellDelegate Methods
    
    func locationImageTableViewCell( locationImageTableViewCell: LocationImageTableViewCell,
                                     cameraButtonTouched: Bool )
    {
        logTrace()
        imageCell = locationImageTableViewCell

        if imageName.isEmpty
        {
            promptForImageSource()
        }
        else
        {
            promptForImageDispostion()
        }

    }
    
    
    
    // MARK: NSNotification Methods
    
    @objc func pinsUpdated( notification: NSNotification )
    {
        logTrace()
        
        // The reason we are using Notifications is because this view can be up in two different places on the iPad at the same time.
        // This approach allows a change in one to immediately be reflected in the other.
        
        if !imageAssigned
        {
            deleteImage()
        }
        
        initializeVariables()
        myTableView.reloadData()
        
        self.showSaveBarButtonItem(show: self.dataChanged())
   }
    
    
    
    // MARK: PinCentralDelegate Methods
    
    func pinCentral( pinCentral: PinCentral,
                     didOpenDatabase: Bool )
    {
        logVerbose( "[ %@ ]", stringFor( didOpenDatabase ) )
    }
    
    
    func pinCentralDidReloadPinArray( pinCentral: PinCentral )
    {
        logVerbose( "loaded [ %d ] pins", pinCentral.pinArray.count )
        
        if NEW_PIN == indexOfItemBeingEdited
        {
            logVerbose( "recovering pinIndex[ %d ]", pinCentral.newPinIndex )
            indexOfItemBeingEdited = pinCentral.newPinIndex
        }
        
        dismissView()
        
        delegate?.locationEditorViewController( locationEditorViewController: self,
                                                didEditLocationData: true )
    }
    
    
    
    // MARK: PinColorSelectorViewControllerDelegate Methods
    
    func pinColorSelectorViewController( pinColorSelectorVC: PinColorSelectorViewController,
                                         didSelect color: Int )
    {
        logVerbose( "[ %d ][ %@ ]", color, pinColorNameArray[color] )
        pinColor = Int16( color )
        
        self.detailsCell.initialize()
        
        changingColors = false
    }
    
    
    
    // MARK: Target/Action Methods
    
    @IBAction func cancelBarButtonTouched( sender: UIBarButtonItem )
    {
        logTrace()
        if dataChanged()
        {
            confirmIntentToDiscardChanges()
        }
        else
        {
            dismissView()
        }
        
    }
    
    
    @IBAction @objc func saveButtonTouched( barButtonItem: UIBarButtonItem )
    {
        logTrace()
        if name.isEmpty
        {
            logTrace( "ERROR:  Name field cannot be left blank!" )
            presentAlert( title:   NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                          message: NSLocalizedString( "AlertMessage.NameCannotBeBlank", comment: "Name field cannot be left blank" ) )
        }
        else if dataChanged()
        {
            updatePinCentral()
        }
        
    }
    
    

    // MARK: UIImagePickerControllerDelegate Methods
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController )
    {
        logTrace()
        if nil != presentedViewController
        {
            dismiss( animated: true, completion: nil )
        }
        
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any] )
    {
        logTrace()
        if nil != presentedViewController
        {
            dismiss( animated: true, completion: nil )
        }
        
        DispatchQueue.main.asyncAfter( deadline: ( .now() + 0.01 ) )
        {
            if let mediaType = info[UIImagePickerControllerMediaType] as? String
            {
                if "public.image" == mediaType
                {
                    var     imageToSave: UIImage? = nil
                    
                    
                    if let originalImage: UIImage = info[UIImagePickerControllerOriginalImage] as? UIImage
                    {
                        imageToSave = originalImage
                    }
                    else if let editedImage: UIImage = info[UIImagePickerControllerEditedImage] as? UIImage
                    {
                        imageToSave = editedImage
                    }
                    
                    if let myImageToSave = imageToSave
                    {
                        if .camera == picker.sourceType
                        {
                            UIImageWriteToSavedPhotosAlbum( myImageToSave, self, #selector( LocationEditorViewController.image(_ :didFinishSavingWithError:contextInfo: ) ), nil )
                        }
                        
                        
                        let     imageName = PinCentral.sharedInstance.saveImage( image: myImageToSave )
                        
                        
                        if ( imageName.isEmpty || imageName.isEmpty )
                        {
                            logTrace( "ERROR:  Image save FAILED!" )
                            self.presentAlert( title: NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                                               message: NSLocalizedString( "AlertMessage.ImageSaveFailed", comment: "We were unable to save the image you selected." ) )
                        }
                        else
                        {
                            self.imageAssigned = false
                            self.imageName     = imageName
                            
                            logVerbose( "Saved image as [ %@ ]", imageName )
                            
                            self.imageCell.initializeWith(imageName: self.imageName)

                            self.showSaveBarButtonItem(show: self.dataChanged())
                        }
                        
                    }
                    else
                    {
                        logTrace( "ERROR:  Unable to unwrap imageToSave!" )
                    }
                    
                }
                else
                {
                    logVerbose( "ERROR:  Invalid media type[ %@ ]", mediaType )
                    self.presentAlert( title: NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                                       message: NSLocalizedString( "AlertMessage.InvalidMediaType", comment: "We can't save the item you selected.  We can only save photos." ) )
                }
                
            }
            else
            {
                logTrace( "ERROR:  Unable to convert info[UIImagePickerControllerMediaType] to String" )
            }
            
        }
        
    }
    
    
    
    // MARK: UIImageWrite Completion Methods
    
    @objc func image(_ image: UIImage,
                     didFinishSavingWithError error: NSError?,
                     contextInfo: UnsafeRawPointer )
    {
        guard error == nil else
        {
            if let myError = error
            {
                logVerbose( "ERROR:  Save to photo album failed!  Error[ %@ ]", myError.localizedDescription )
            }
            else
            {
                logTrace( "ERROR:  Save to photo album failed!  Error[ Unknown ]" )
            }
            
            return
        }
        
        logTrace( "Image successfully saved to photo album" )
        self.showSaveBarButtonItem(show: self.dataChanged())
    }
    
    
    
    // MARK: UIPopoverPresentationControllerDelegate Methods
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.none
    }
    
    
    
    // MARK: UITableViewDataSource
    
    func tableView(_ tableView: UITableView,
                     numberOfRowsInSection section: Int) -> Int
    {
//        logTrace()
        return 2
    }
    
    
    func tableView(_ tableView: UITableView,
                     cellForRowAt indexPath: IndexPath) -> UITableViewCell
    {
//        logVerbose( "row[ %d ]", indexPath.row)
        let cell : UITableViewCell!
        
        if (indexPath.row == 0)
        {
            cell = loadImageViewCell()
        }
        else
        {
            cell = loadDetailsCell()
        }

        return cell
    }
    


    // MARK: Utility Methods
    
    private func confirmIntentToDiscardChanges()
    {
        logTrace()
        let     alert = UIAlertController.init( title: NSLocalizedString( "AlertTitle.AreYouSure", comment: "Are you sure you want to discard your changes?" ),
                                                message: nil,
                                                preferredStyle: .alert)
        
        let     yesAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Yes", comment: "Yes" ), style: .destructive )
        { ( alertAction ) in
            logTrace( "Yes Action" )
            
            self.dismissView()
        }
        
        let     noAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.No", comment: "No!" ), style: .cancel, handler: nil )
        
        
        alert.addAction( yesAction )
        alert.addAction( noAction  )
        
        present( alert, animated: true, completion: nil )
    }
    
    
    private func dataChanged() -> Bool
    {
        var     dataChanged  = false
        
        
        if ( ( name      != originalName      ) ||
             ( details   != originalDetails   ) ||
             ( altitude  != originalAltitude  ) ||
             ( imageName != originalImageName ) ||
             ( latitude  != originalLatitude  ) ||
             ( longitude != originalLongitude ) ||
             ( pinColor  != originalPinColor  ) )
        {
            dataChanged = true
        }
        
//        logVerbose( "[ %@ ]", stringFor( dataChanged ) )
        
        return dataChanged
    }
    
    
    private func deleteImage()
    {
        if !PinCentral.sharedInstance.deleteImageWith( name: imageName )
        {
            logVerbose( "ERROR: Unable to delete image[ %@ ]!", self.imageName )
            presentAlert( title: NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                          message: NSLocalizedString( "AlertMessage.UnableToDeleteImage", comment: "We were unable to delete the image you created." ) )
        }
        
        imageName     = String.init()
        imageAssigned = true
        
        self.showSaveBarButtonItem(show: self.dataChanged())
    }
    
    
    private func dismissView()
    {
        logTrace()
        if launchedFromDetailView
        {
            dismiss( animated: true, completion: nil )
        }
        else
        {
            navigationController?.popViewController( animated: true )
        }
        
    }
    
    
    private func doubleFrom( text: String?, defaultValue: Double ) -> Double
    {
        var     doubleValue = defaultValue
        
        
        if let myText = text
        {
            if !myText.isEmpty
            {
                let     trimmedString = myText.trimmingCharacters( in: .whitespaces )
                
                
                if !trimmedString.isEmpty
                {
                    if let newValue = Double( trimmedString )
                    {
                        doubleValue = newValue
                    }
                    else
                    {
                        logTrace( "ERROR:  Unable to convert text into a Double!  Returning defaultValue" )
                    }
                    
                }
                else
                {
                    logTrace( "ERROR:  Input string contained nothing but whitespace" )
                }
                
            }
            else
            {
                logTrace( "ERROR:  Input string isEmpty!" )
            }
            
        }
        else
        {
            logTrace( "ERROR:  Unable to unwrap text as String!  Returning defaultValue" )
        }
        
        return doubleValue
    }
    
    
    @objc private func editLatLongAndAlt(locationDetailsTableViewCell: LocationDetailsTableViewCell)
    {
        logTrace()
        let     pinCentral  = PinCentral.sharedInstance
        let     title       = String( format: "%@ in %@", NSLocalizedString( "AlertTitle.EditLatLongAndAlt", comment: "Edit latitude, longitude and altitude" ), pinCentral.displayUnits() )
        let     alert       = UIAlertController.init( title: title,
                                                      message: nil,
                                                      preferredStyle: .alert)
        
        let     saveAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Save", comment: "Save" ), style: .default )
        { ( alertAction ) in
            logTrace( "Save Action" )
            let     latitudeTextField  = alert.textFields![0] as UITextField
            let     longitudeTextField = alert.textFields![1] as UITextField
            let     altitudeTextField  = alert.textFields![2] as UITextField
            
            
            self.latitude  = self.doubleFrom( text: latitudeTextField .text!, defaultValue: self.latitude  )
            self.longitude = self.doubleFrom( text: longitudeTextField.text!, defaultValue: self.longitude )
            self.altitude  = self.doubleFrom( text: altitudeTextField .text!, defaultValue: self.altitude  )
            
            if DISPLAY_UNITS_FEET == pinCentral.displayUnits()
            {
                self.altitude = ( self.altitude / FEET_PER_METER )
            }
            
            locationDetailsTableViewCell.initialize()
        }
        
        let     useCurrentAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.UseCurrent", comment: "Use Current Location" ), style: .default )
        { ( alertAction ) in
            
            logTrace( "Use Current Location Action" )
            self.latitude  = pinCentral.currentLocation.latitude
            self.longitude = pinCentral.currentLocation.longitude
            self.altitude  = pinCentral.currentAltitude
            
            locationDetailsTableViewCell.initialize()
        }
        
        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel, handler: nil )
        
        
        alert.addTextField
            { ( textField ) in
                
                textField.text = String.init( format: "%7.4f", self.latitude )
                textField.keyboardType = .decimalPad
        }
        
        alert.addTextField
            { ( textField ) in
                
                textField.text = String.init( format: "%7.4f", self.longitude )
                textField.keyboardType = .decimalPad
        }
        
        alert.addTextField
            { ( textField ) in
                
                textField.text = ( ( DISPLAY_UNITS_FEET == pinCentral.displayUnits() ) ? String.init( format: "%7.1f", ( self.altitude * FEET_PER_METER ) ) : String.init( format: "%7.1f", self.altitude ) )
                textField.keyboardType = .decimalPad
        }
        
        if PinCentral.sharedInstance.locationEstablished
        {
            alert.addAction( useCurrentAction )
        }
        
        alert.addAction( saveAction   )
        alert.addAction( cancelAction )
        
        present( alert, animated: true, completion: nil )
    }
    
    
    @objc func editNameAndDetails(locationDetailsTableViewCell: LocationDetailsTableViewCell)
    {
        logTrace()
        let     alert = UIAlertController.init( title: NSLocalizedString( "AlertTitle.EditNameAndDetails", comment: "Edit name and details" ),
                                                message: nil,
                                                preferredStyle: .alert)
        
        let     saveAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Save", comment: "Save" ), style: .default )
        { ( alertAction ) in
            logTrace( "Save Action" )
            let     nameTextField    = alert.textFields![0] as UITextField
            let     detailsTextField = alert.textFields![1] as UITextField
            
            
            if let textString = nameTextField.text
            {
                self.name = textString
            }
            
            if let textString = detailsTextField.text
            {
                self.details = textString
            }
            
            self.initialize(locationDetailsTableViewCell: locationDetailsTableViewCell)
        }
        
        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel, handler: nil )
        
        
        alert.addTextField
            { ( textField ) in
                
                if self.name.isEmpty
                {
                    textField.placeholder = NSLocalizedString( "LabelText.Name", comment: "Name" )
                }
                else
                {
                    textField.text = self.name
                }
                
                textField.autocapitalizationType = .words
        }
        
        alert.addTextField
            { ( textField ) in
                
                if self.details.isEmpty
                {
                    textField.placeholder = NSLocalizedString( "LabelText.Details", comment: "Address / Description" )
                }
                else
                {
                    textField.text = self.details
                }
                
                textField.autocapitalizationType = .words
        }
        
        alert.addAction( saveAction   )
        alert.addAction( cancelAction )
        
        present( alert, animated: true, completion: nil )
    }
    
    
    private func initialize(locationDetailsTableViewCell: LocationDetailsTableViewCell)
    {
        logTrace()
        
        locationDetailsTableViewCell.altitude  = self.altitude
        locationDetailsTableViewCell.details   = self.details
        locationDetailsTableViewCell.latitude  = self.latitude
        locationDetailsTableViewCell.longitude = self.longitude
        locationDetailsTableViewCell.name      = self.name
        locationDetailsTableViewCell.pinColor  = self.pinColor
        
        locationDetailsTableViewCell.initialize()
        
        self.showSaveBarButtonItem(show: self.dataChanged())
    }


    private func initializeVariables()
    {
        logTrace()
        let         pinCentral = PinCentral.sharedInstance
        
        
        var         frame      = CGRect.zero
        frame.size.height = .leastNormalMagnitude
        myTableView.tableHeaderView = UIView(frame: frame)
        myTableView.tableFooterView = UIView(frame: frame)
        myTableView.contentInsetAdjustmentBehavior = .never
        
        if NEW_PIN == indexOfItemBeingEdited
        {
            altitude  = 0.0
            details   = String.init()
            imageName = String.init()
            name      = String.init()
            
            if useCenterOfMap
            {
                latitude  = centerOfMap.latitude
                longitude = centerOfMap.longitude
            }
            else if pinCentral.locationEstablished
            {
                altitude  = pinCentral.currentAltitude
                latitude  = pinCentral.currentLocation.latitude
                longitude = pinCentral.currentLocation.longitude
            }
            else
            {
                latitude  = 0.0
                longitude = 0.0
            }
            
            pinColor = PinColors.pinRed
        }
        else
        {
            let         pin = pinCentral.pinArray[indexOfItemBeingEdited]
            
            
            altitude    = pin.altitude
            details     = pin.details   ?? ""
            imageName   = pin.imageName ?? ""
            latitude    = pin.latitude
            longitude   = pin.longitude
            name        = pin.name      ?? ""
            pinColor    = pin.pinColor
        }
        
        originalAltitude    = altitude
        originalDetails     = details
        originalImageName   = imageName
        originalLatitude    = latitude
        originalLongitude   = longitude
        originalName        = name
        originalPinColor    = pinColor
        
        imageAssigned = true
    }
    
    
    func loadDetailsCell() -> UITableViewCell
    {
        guard let cell = myTableView.dequeueReusableCell( withIdentifier: CELL_ID_DETAILS ) else
        {
            logVerbose("We FAILED to dequeueReusableCell")
            return UITableViewCell.init()
        }
        
        logTrace()

        let detailsCell = cell as! LocationDetailsTableViewCell
        
        
        detailsCell.delegate = self
        
        initialize(locationDetailsTableViewCell: detailsCell)
        
        if firstTimeIn && ( NEW_PIN == indexOfItemBeingEdited )
        {
            firstTimeIn = false
            
            DispatchQueue.main.asyncAfter( deadline: ( .now() + 0.2 ) )
            {
                self.editNameAndDetails( locationDetailsTableViewCell: detailsCell )
            }
            
        }
        
        return cell
    }


    func loadImageViewCell() -> UITableViewCell
    {
        guard let cell = myTableView.dequeueReusableCell( withIdentifier: CELL_ID_IMAGE ) else
        {
            logVerbose("We FAILED to dequeueReusableCell")
            return UITableViewCell.init()
        }
        
        
        logTrace()
        let imageCell = cell as! LocationImageTableViewCell
        
        
        imageCell.delegate = self
        imageCell.initializeWith(imageName: imageName)
        
        return cell
    }
    
    
    func openImagePickerFor( sourceType: UIImagePickerControllerSourceType )
    {
        logVerbose( "[ %@ ]", ( ( .camera == sourceType ) ? "Camera" : "Photo Album" ) )
        let     imagePickerVC = UIImagePickerController.init()
        
        
        imagePickerVC.allowsEditing = false
        imagePickerVC.delegate      = self
        imagePickerVC.sourceType    = sourceType
        
        imagePickerVC.modalPresentationStyle = ( ( .camera == sourceType ) ? .overFullScreen : .popover )
        
        present( imagePickerVC, animated: true, completion: nil )
        
        imagePickerVC.popoverPresentationController?.permittedArrowDirections = .any
        imagePickerVC.popoverPresentationController?.sourceRect               = myTableView.frame
        imagePickerVC.popoverPresentationController?.sourceView               = myTableView
    }
    
    
    func promptForImageDispostion()
    {
        logTrace()
        let     alert = UIAlertController.init( title: NSLocalizedString( "AlertTitle.ImageDisposition", comment: "What would you like to do with this image?" ),
                                                message: nil,
                                                preferredStyle: .alert)
        
        let     deleteAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Delete", comment: "Delete" ), style: .default )
        { ( alertAction ) in
            logTrace( "Delete Action" )
            
            self.deleteImage()

            self.imageCell.initializeWith(imageName: self.imageName)
        }
        
        let     replaceAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Replace", comment: "Replace" ), style: .default )
        { ( alertAction ) in
            logTrace( "Replace Action" )
            
            self.deleteImage()
            
            self.imageCell.initializeWith(imageName: self.imageName)
            
            self.promptForImageSource()
        }
        
        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel, handler: nil )
        
        
        alert.addAction( deleteAction  )
        alert.addAction( replaceAction )
        alert.addAction( cancelAction  )
        
        present( alert, animated: true, completion: nil )
    }
    
    
    private func promptForImageSource()
    {
        logTrace()
        let     alert = UIAlertController.init( title: NSLocalizedString( "AlertTitle.SelectMediaSource", comment: "Select Media Source for Image" ),
                                                message: nil,
                                                preferredStyle: .alert)
        
        let     albumAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.PhotoAlbum", comment: "Photo Album" ), style: .default )
        { ( alertAction ) in
            logTrace( "Photo Album Action" )
            
            self.openImagePickerFor( sourceType: .photoLibrary )
        }
        
        let     cameraAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Camera", comment: "Camera" ), style: .default )
        { ( alertAction ) in
            logTrace( "Camera Action" )
            
            self.openImagePickerFor( sourceType: .camera )
        }
        
        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel, handler: nil )
        
        
        if UIImagePickerController.isSourceTypeAvailable( .camera )
        {
            alert.addAction( cameraAction )
        }
        
        alert.addAction( albumAction  )
        alert.addAction( cancelAction )
        
        present( alert, animated: true, completion: nil )
    }
    
    
    private func showSaveBarButtonItem( show: Bool)
    {
        if show
        {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem.init( barButtonSystemItem: .save,
                                                                           target: self,
                                                                           action: #selector( saveButtonTouched ) )
        }
        else
        {
            self.navigationItem.rightBarButtonItem = nil
        }

    }
    
    
    private func updatePinCentral()
    {
        logTrace()
        let     pinCentral = PinCentral.sharedInstance
        
        
        pinCentral.delegate = self
        
        if NEW_PIN == indexOfItemBeingEdited
        {
            pinCentral.addPin( name:      name,
                               details:   details,
                               latitude:  latitude,
                               longitude: longitude,
                               altitude:  altitude,
                               imageName: imageName,
                               pinColor:  Int16( pinColor ) )
        }
        else
        {
            let     pin = pinCentral.pinArray[indexOfItemBeingEdited]
            
            
            pin.altitude  = altitude
            pin.details   = details
            pin.imageName = imageName
            pin.latitude  = latitude
            pin.longitude = longitude
            pin.name      = name
            pin.pinColor  = Int16( pinColor )
            
            pinCentral.saveUpdatedPin( pin: pin )
        }
        
        imageAssigned = true
    }
    
    


}
