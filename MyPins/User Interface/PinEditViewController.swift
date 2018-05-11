//
//  PinEditViewController.swift
//  MyPins
//
//  Created by Clint Shank on 4/8/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//

import UIKit
import MapKit



protocol PinEditViewControllerDelegate: class
{
    func pinEditViewController( pinEditViewController: PinEditViewController,
                                didEditPinData: Bool )
    
    func pinEditViewController( pinEditViewController: PinEditViewController,
                                wantsToCenterMapAt coordinate: CLLocationCoordinate2D )
}



class PinEditViewController: UIViewController,
                             PinCentralDelegate,
                             PinColorSelectorViewControllerDelegate,
                             UIImagePickerControllerDelegate,
                             UINavigationControllerDelegate,  // Required for UIImagePickerControllerDelegate
                             UIPopoverPresentationControllerDelegate
{
    let STORYBOARD_ID_COLOR_SELECTOR = "PinColorSelectorViewController"

    
    @IBOutlet weak var locationImageView:   UIImageView!
    @IBOutlet weak var cameraButton:        UIButton!
    @IBOutlet weak var nameButton:          UIButton!
    @IBOutlet weak var detailsButton:       UIButton!
    @IBOutlet weak var locationButton:      UIButton!
    @IBOutlet weak var unitsButton:         UIButton!
    @IBOutlet weak var pinColorButton:      UIButton!
    @IBOutlet weak var showOnMapButton:     UIButton!
    
    
    weak var delegate: PinEditViewControllerDelegate?
    
    var     centerOfMap:                CLLocationCoordinate2D!     // Only set by MapViewController when indexOfItemBeingEdited == NEW_PIN
    var     indexOfItemBeingEdited:     Int!                        // Set by delegate
    var     launchedFromDetailView    = false                       // Set by delegate
    var     useCenterOfMap            = false                       // Only set by MapViewController when indexOfItemBeingEdited == NEW_PIN

    private var     altitude                  = 0.0
    private var     changingColors            = false
    private var     details                   = String()
    private var     firstTimeIn               = true
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
    private var     originalPinColor:           Int16!
    private var     pinColor:                   Int16!
    private var     unassignedImage           = false
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad()
    {
        appLogTrace()
        super.viewDidLoad()

        title = NSLocalizedString( "Title.PinEditor", comment: "Pin Editor" )
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem.init( barButtonSystemItem: .save,
                                                                       target: self,
                                                                       action: #selector( saveButtonTouched ) )
        preferredContentSize = CGSize( width: 320, height: 460 )
        
        initializeVariables()
    }
    
    
    override func viewWillAppear(_ animated: Bool)
    {
        appLogTrace()
        super.viewWillAppear( animated )
        
        navigationItem.leftBarButtonItem  = UIBarButtonItem.init( title: ( launchedFromDetailView ? NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ) :
                                                                                                    NSLocalizedString( "ButtonTitle.Back",   comment: "Back"   ) ),
                                                                  style: .plain,
                                                                  target: self,
                                                                  action: #selector( cancelBarButtonTouched ) )
        loadButtonTitles()
        configurePhotoControls()
        
        NotificationCenter.default.addObserver( self,
                                                selector: #selector( PinEditViewController.pinsUpdated( notification: ) ),
                                                name:     NSNotification.Name( rawValue: PinCentral.sharedInstance.NOTIFICATION_PINS_UPDATED ),
                                                object:   nil )
        
        if firstTimeIn && ( PinCentral.sharedInstance.NEW_PIN == indexOfItemBeingEdited )
        {
            firstTimeIn = false
            
            DispatchQueue.main.asyncAfter( deadline: ( .now() + 0.5 ) )
            {
                self.editNameAndDetails()
            }
            
        }

    }
    
    
    override func viewWillDisappear(_ animated: Bool)
    {
        appLogTrace()
        super.viewWillDisappear( animated )
        
        NotificationCenter.default.removeObserver( self )
        
        if unassignedImage && !changingColors
        {
            deleteImage()
        }
        
    }
    
    
    override func didReceiveMemoryWarning()
    {
        appLogVerbose( format: "MEMORY WARNING!!!" )
        super.didReceiveMemoryWarning()
    }
    
    
    
    // MARK: NSNotification Methods
    
    @objc func pinsUpdated( notification: NSNotification )
    {
        appLogTrace()
        
        // The reason we are using Notifications is because this view can be up in two different places on the iPad at the same time.
        // This approach allows a change in one to immediately be reflected in the other.
        
        if unassignedImage
        {
            deleteImage()
        }
        
        initializeVariables()
        loadButtonTitles()
        configurePhotoControls()
    }
    
    
    
    // MARK: PinCentralDelegate Methods
    
    func pinCentral( pinCentral: PinCentral,
                     didOpenDatabase: Bool )
    {
        appLogVerbose( format: "didOpenDatabase[ %@ ]", parameters: String( didOpenDatabase ) )
    }
    
    
    func pinCentralDidReloadPinArray( pinCentral: PinCentral )
    {
        appLogVerbose( format: "loaded [ %@ ] pins", parameters: String( pinCentral.pinArray!.count ) )
        delegate?.pinEditViewController( pinEditViewController: self, didEditPinData: true )

        dismissView()
    }
    
    
    
    // MARK: PinColorSelectorViewControllerDelegate Methods
    
    func pinColorSelectorViewController( pinColorSelectorVC: PinColorSelectorViewController,
                                         didSelect color: Int )
    {
        appLogVerbose( format: "[ %@ ][ %@ ]", parameters: String( color ), pinColorNameArray[color] )
        pinColor = Int16( color )
        
        loadButtonTitles()
        configurePhotoControls()
        changingColors = false
    }
    
    
    
    // MARK: Target/Action Methods
    
    @IBAction func cameraButtonTouched(_ sender: UIButton)
    {
        appLogTrace()
        if imageName.isEmpty
        {
            promptForImageSource()
        }
        else
        {
            promptForImageDispostion()
        }
        
    }
    
    
    @IBAction func cancelBarButtonTouched( sender: UIBarButtonItem )
    {
        appLogTrace()
        if dataChanged()
        {
            confirmIntentToDiscardChanges()
        }
        else
        {
            dismissView()
        }
        
    }
    
    
    @IBAction func nameOrDetailsButtonTouched(_ sender: UIButton )
    {
        appLogTrace()
        editNameAndDetails()
    }
    
    
    @IBAction func locationButtonTouched(_ sender: UIButton )
    {
        appLogTrace()
        editLatLongAndAlt()
    }
    
    
    @IBAction func pinColorButtonTouched(_ sender: UIButton )
    {
        appLogTrace()
        let         pinColorSelectorVC: PinColorSelectorViewController = iPhoneViewControllerWithStoryboardId( storyboardId: STORYBOARD_ID_COLOR_SELECTOR ) as! PinColorSelectorViewController


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
    
    
    @IBAction @objc func saveButtonTouched( barButtonItem: UIBarButtonItem )
    {
        appLogTrace()
        if name.isEmpty
        {
            appLogVerbose( format: "ERROR!  Name field cannot be left blank" )
            presentAlert( title:   NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                          message: NSLocalizedString( "AlertMessage.NameCannotBeBlank", comment: "Name field cannot be left blank" ) )
        }
        else if dataChanged()
        {
            updatePinCentral()
        }
        
    }
    
    
    @IBAction func showOnMapButtonTouched(_ sender: UIButton)
    {
        appLogTrace()
        if name.isEmpty
        {
            appLogVerbose( format: "ERROR!  Name field cannot be left blank" )
            presentAlert( title:   NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                          message: NSLocalizedString( "AlertMessage.NameCannotBeBlank", comment: "Name field cannot be left blank" ) )
            return
        }
        
        if dataChanged()
        {
            updatePinCentral()
            
            PinCentral.sharedInstance.indexOfSelectedPin = indexOfItemBeingEdited
        }
        
        delegate?.pinEditViewController( pinEditViewController: self,
                                         wantsToCenterMapAt: CLLocationCoordinate2DMake( latitude, longitude ) )
    }
    
    
    @IBAction func unitsButtonTouched(_ sender: UIButton)
    {
        appLogTrace()
        toggleDisplayUnits()
        loadButtonTitles()
    }
    
    
    
    
    // MARK: UIImagePickerControllerDelegate Methods
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController )
    {
        appLogTrace()
        if nil != presentedViewController
        {
            dismiss( animated: true, completion: nil )
        }
        
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController,
                                 didFinishPickingMediaWithInfo info: [String : Any] )
    {
        appLogTrace()
        if nil != presentedViewController
        {
            dismiss( animated: true, completion: nil )
        }
        
        DispatchQueue.main.asyncAfter( deadline: ( .now() + 0.01 ) )
        {
            let         mediaType = info[UIImagePickerControllerMediaType] as! String
            
            
            if "public.image" == mediaType
            {
                let     originalImage: UIImage? = info[UIImagePickerControllerOriginalImage] as? UIImage
                let     editedImage:   UIImage? = info[UIImagePickerControllerEditedImage  ] as? UIImage
                let     imageToSave             = ( ( nil != editedImage ) ? editedImage : originalImage )
                
                
                if .camera == picker.sourceType
                {
                    UIImageWriteToSavedPhotosAlbum( imageToSave!, self, #selector( PinEditViewController.image(_ :didFinishSavingWithError:contextInfo: ) ), nil )
//                    UIImageWriteToSavedPhotosAlbum( imageToSave!, nil, nil, nil )
                }
                
                
                let     imageName = PinCentral.sharedInstance.saveImage( image: imageToSave! )
                
                
                if ( imageName.isEmpty || ( "" == imageName ) )
                {
                    appLogVerbose( format: "Image save FAILED!" )
                    self.presentAlert( title: NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                                       message: NSLocalizedString( "AlertMessage.ImageSaveFailed", comment: "We were unable to save the image you selected." ) )
                }
                else
                {
                    self.imageName       = imageName
                    self.unassignedImage = true
                    
                    appLogVerbose( format: "Saved image as [ %@ ]", parameters: imageName )
                    self.configurePhotoControls()
                }
                
            }
            else
            {
                appLogVerbose( format: "Invalid media type[ %@ ]", parameters: mediaType )
                self.presentAlert( title: NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                                   message: NSLocalizedString( "AlertMessage.InvalidMediaType", comment: "We can't save the item you selected.  We can only save photos." ) )
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
            appLogVerbose( format: "Save to photo album failed!  Error[ %@ ]", parameters: error!.localizedDescription )
            return
        }
        
        appLogVerbose( format: "Image successfully saved to photo album" )
    }
    
    
    
    // MARK: UIPopoverPresentationControllerDelegate Methods
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle
    {
        return UIModalPresentationStyle.none
    }
    
    
    
    // MARK: Utility Methods
    
    private func configurePhotoControls()
    {
        appLogVerbose( format: "[ %@ ]", parameters: imageName )
        locationImageView.image = ( imageName.isEmpty ? nil : PinCentral.sharedInstance.imageWith( name: imageName ) )
        
        cameraButton.setImage( ( imageName.isEmpty ? UIImage.init( named: "camera" ) : nil ),
                               for: .normal )
        cameraButton.backgroundColor = ( imageName.isEmpty ? .white : .clear )
    }
    
    
    private func confirmIntentToDiscardChanges()
    {
        appLogTrace()
        let     alert = UIAlertController.init( title: NSLocalizedString( "AlertTitle.AreYouSure", comment: "Are you sure you want to discard your changes?" ),
                                                message: nil,
                                                preferredStyle: .alert)
        
        let     yesAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Yes", comment: "Yes" ), style: .destructive )
        { ( alertAction ) in
            appLogVerbose( format: "Yes Action" )
            
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
        
        appLogVerbose( format: "[ %@ ]", parameters: String( dataChanged ) )
        
        return dataChanged
    }
    
    
    private func deleteImage()
    {
        if !PinCentral.sharedInstance.deleteImageWith( name: imageName )
        {
            appLogVerbose( format: "Unable to delete image[ %@ ]!", parameters: self.imageName )
            presentAlert( title: NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                          message: NSLocalizedString( "AlertMessage.UnableToDeleteImage", comment: "We were unable to delete the image you created." ) )
        }
        
        imageName       = String.init()
        unassignedImage = false
    }
    
    
    private func dismissView()
    {
        appLogTrace()
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
        
        
        if !( text?.isEmpty )!
        {
            let     trimmedString = text?.trimmingCharacters( in: .whitespaces )
            
            
            if let newValue = Double( trimmedString! )
            {
                doubleValue = newValue
            }
            
        }
        
        return doubleValue
    }


    private func editLatLongAndAlt()
    {
        appLogTrace()
        let     pinCentral  = PinCentral.sharedInstance
        let     title       = String( format: "%@ in %@", NSLocalizedString( "AlertTitle.EditLatLongAndAlt", comment: "Edit latitude, longitude and altitude" ), pinCentral.displayUnits() )
        let     alert       = UIAlertController.init( title: title,
                                                      message: nil,
                                                      preferredStyle: .alert)
        
        let     saveAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Save", comment: "Save" ), style: .default )
        { ( alertAction ) in
            appLogVerbose( format: "Save Action" )
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
            
            self.loadButtonTitles()
        }
        
        let     useCurrentAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.UseCurrent", comment: "Use Current Location" ), style: .default )
        { ( alertAction ) in
            appLogVerbose( format: "Use Current Location Action" )
            self.latitude  = ( pinCentral.currentLocation?.latitude  )!
            self.longitude = ( pinCentral.currentLocation?.longitude )!
            self.altitude  = ( pinCentral.currentAltitude )!
            
            self.loadButtonTitles()
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

        alert.addAction( saveAction        )
        alert.addAction( cancelAction      )
        
        present( alert, animated: true, completion: nil )
    }
    
    
    private func editNameAndDetails()
    {
        appLogTrace()
        let     alert = UIAlertController.init( title: NSLocalizedString( "AlertTitle.EditNameAndDetails", comment: "Edit name and details" ),
                                                message: nil,
                                                preferredStyle: .alert)
        
        let     saveAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Save", comment: "Save" ), style: .default )
        { ( alertAction ) in
            appLogVerbose( format: "Save Action" )
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
            
            self.loadButtonTitles()
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
    
    
    func initializeVariables()
    {
        appLogTrace()
        let         pinCentral = PinCentral.sharedInstance
        
        
        if pinCentral.NEW_PIN == indexOfItemBeingEdited
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
                altitude  = pinCentral.currentAltitude!
                latitude  = pinCentral.currentLocation!.latitude
                longitude = pinCentral.currentLocation!.longitude
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
            let         pin = pinCentral.pinArray![indexOfItemBeingEdited]
            
            
            altitude    = pin.altitude
            details     = pin.details!
            imageName   = pin.imageName!
            latitude    = pin.latitude
            longitude   = pin.longitude
            name        = pin.name!
            pinColor    = pin.pinColor
        }
        
        originalAltitude    = altitude
        originalDetails     = details
        originalImageName   = imageName
        originalLatitude    = latitude
        originalLongitude   = longitude
        originalName        = name
        originalPinColor    = pinColor

        unassignedImage   = false
    }
    
    
    func loadButtonTitles()
    {
        appLogTrace()
        let         units                  = PinCentral.sharedInstance.displayUnits()
        let         altitudeInDesiredUnits = ( ( DISPLAY_UNITS_METERS == units ) ? altitude : ( altitude * FEET_PER_METER ) )

        
        detailsButton  .setTitle( ( details.isEmpty ? NSLocalizedString( "LabelText.Details", comment: "Address / Description" ) : details ), for: .normal )
        nameButton     .setTitle( ( name   .isEmpty ? NSLocalizedString( "LabelText.Name",    comment: "Name"                  ) : name    ), for: .normal )
        locationButton .setTitle( String( format: "[ %7.4f, %7.4f ] at %7.1f", latitude, longitude, altitudeInDesiredUnits ), for: .normal )
        pinColorButton .setTitle( String( format: "%@ [ %@ ]", NSLocalizedString( "ButtonTitle.PinColor",  comment: "Pin Color"   ), pinColorNameArray[Int( pinColor )] ), for: .normal )
        showOnMapButton.setTitle( NSLocalizedString( "ButtonTitle.ShowOnMap", comment: "Show on Map" ), for: .normal )
        unitsButton    .setTitle( units, for: .normal )
    }
    
    
    func openImagePickerFor( sourceType: UIImagePickerControllerSourceType )
    {
        appLogVerbose( format: "[ %@ ]", parameters: ( ( .camera == sourceType ) ? "Camera" : "Photo Album" ) )
        let     imagePickerVC = UIImagePickerController.init()
        
        
        imagePickerVC.allowsEditing = false
        imagePickerVC.delegate      = self
        imagePickerVC.sourceType    = sourceType
        
        imagePickerVC.modalPresentationStyle = ( ( .camera == sourceType ) ? .overFullScreen : .popover )
        
        present( imagePickerVC, animated: true, completion: nil )
        
        imagePickerVC.popoverPresentationController?.permittedArrowDirections = .any
        imagePickerVC.popoverPresentationController?.sourceRect               = cameraButton.frame
        imagePickerVC.popoverPresentationController?.sourceView               = cameraButton
    }
    
    
    func promptForImageDispostion()
    {
        appLogTrace()
        let     alert = UIAlertController.init( title: NSLocalizedString( "AlertTitle.ImageDisposition", comment: "What would you like to do with this image?" ),
                                                message: nil,
                                                preferredStyle: .alert)
        
        let     deleteAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Delete", comment: "Delete" ), style: .default )
        { ( alertAction ) in
            appLogVerbose( format: "Delete Action" )
            
            self.deleteImage()
            self.configurePhotoControls()
        }
        
        let     replaceAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Replace", comment: "Replace" ), style: .default )
        { ( alertAction ) in
            appLogVerbose( format: "Replace Action" )
            
            self.deleteImage()
            self.configurePhotoControls()
            
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
        appLogTrace()
        let     alert = UIAlertController.init( title: NSLocalizedString( "AlertTitle.SelectMediaSource", comment: "Select Media Source for Image" ),
                                                message: nil,
                                                preferredStyle: .alert)
        
        let     albumAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.PhotoAlbum", comment: "Photo Album" ), style: .default )
        { ( alertAction ) in
            appLogVerbose( format: "Photo Album Action" )
            
            self.openImagePickerFor( sourceType: .photoLibrary )
        }
        
        let     cameraAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Camera", comment: "Camera" ), style: .default )
        { ( alertAction ) in
            appLogVerbose( format: "Camera Action" )
            
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
    
    
    private func toggleDisplayUnits()
    {
        var     units = PinCentral.sharedInstance.displayUnits()
        
        
        units = ( ( DISPLAY_UNITS_METERS == units ) ? DISPLAY_UNITS_FEET : DISPLAY_UNITS_METERS )
        
        UserDefaults.standard.set( units, forKey: PinCentral.sharedInstance.DISPLAY_UNITS_ALTITUDE )
        UserDefaults.standard.synchronize()
    }
    
    
    private func updatePinCentral()
    {
        appLogTrace()
        let     pinCentral = PinCentral.sharedInstance
        
        
        pinCentral.delegate = self
        
        if indexOfItemBeingEdited == PinCentral.sharedInstance.NEW_PIN
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
            let     pin = pinCentral.pinArray![indexOfItemBeingEdited]
            
            
            pin.altitude  = altitude
            pin.details   = details
            pin.imageName = imageName
            pin.latitude  = latitude
            pin.longitude = longitude
            pin.name      = name
            pin.pinColor  = Int16( pinColor )
            
            pinCentral.saveUpdatedPin( pin: pin )
        }
        
        unassignedImage = false
    }
    
    
    
    
    
    
    

}
