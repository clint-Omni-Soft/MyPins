//
//  LocationEditorViewController.swift
//  MyPins
//
//  Created by Clint Shank on 6/24/19.
//  Copyright © 2019 Omni-Soft, Inc. All rights reserved.
//

import UIKit
import MapKit



protocol LocationEditorViewControllerDelegate: AnyObject {
    func locationEditorViewController(_ locationEditorViewController: LocationEditorViewController, didEditLocationData: Bool )
    
    func locationEditorViewController(_ locationEditorViewController: LocationEditorViewController, wantsToCenterMapAt coordinate: CLLocationCoordinate2D )
}



class LocationEditorViewController: UIViewController  {
    
    // MARK: Public Variables
    
    @IBOutlet weak var myTableView: UITableView!
    
    weak var delegate: LocationEditorViewControllerDelegate?
    
    var     centerOfMap:                CLLocationCoordinate2D!     // Only set by MapViewController when indexOfItemBeingEdited == GlobalConstants.newPin
    var     indexOfItemBeingEdited:     Int!                        // Set by delegate
    var     launchedFromDetailView    = false                       // Set by delegate
    var     useCenterOfMap            = false                       // Only set by MapViewController when indexOfItemBeingEdited == GlobalConstants.newPin
    
    
    // MARK: Private Variables
    
    private struct CellIds {
        static let details = "LocationDetailsTableViewCell"
        static let image   = "LocationImageTableViewCell"
    }

    private struct StoryboardIds {
        static let colorSelector = "PinColorSelectorViewController"
        static let imageViewer   = "ImageViewController"
    }
    
    private var     altitude                  = 0.0
    private var     changingColors            = false
    private var     details                   = String()
    private var     detailsCell               : LocationDetailsTableViewCell!   // Set in LocationDetailsTableViewCellDelegate Method
    private var     firstTimeIn               = true
    private var     imageAssigned             = false
    private var     imageCell                 : LocationImageTableViewCell!     // Set in LocationImageTableViewCellDelegate Method
    private var     imageName                 = String()
    private var     latitude                  = 0.0
    private var     loadingImageView          = false
    private var     longitude                 = 0.0
    private var     name                      = String()
    private var     originalAltitude          = 0.0
    private var     originalDetails           = String()
    private var     originalImageName         = String()
    private var     originalLatitude          = 0.0
    private var     originalLongitude         = 0.0
    private var     originalName              = String()
    private var     originalPinColor          : Int16!      // Set in initializeVariables()
    private let     pinCentral                = PinCentral.sharedInstance
    private var     pinColor                  : Int16!      // Set in initializeVariables()
    private var     savedPinBeforeShowingMap  = false
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()

        title = NSLocalizedString( "Title.PinEditor", comment: "Pin Editor" )
        preferredContentSize = CGSize( width: 320, height: 460 )
        
        initializeVariables()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        navigationItem.leftBarButtonItem  = UIBarButtonItem.init( title: ( launchedFromDetailView ? NSLocalizedString( "ButtonTitle.Done", comment: "Done" ) : NSLocalizedString( "ButtonTitle.Back", comment: "Back" ) ),
                                                                  style: .plain,
                                                                  target: self,
                                                                  action: #selector( doneBarButtonTouched ) )
        NotificationCenter.default.addObserver( self,
                                                selector: #selector( LocationEditorViewController.pinsUpdated( notification: ) ),
                                                name:     NSNotification.Name( rawValue: Notifications.pinsUpdated ),
                                                object:   nil )
        myTableView.reloadData()
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        logTrace()
        super.viewWillDisappear( animated )
        
        NotificationCenter.default.removeObserver( self )
        
        if !imageAssigned && !changingColors {
            deleteImage()
        }
        
    }
    
    
    override func didReceiveMemoryWarning() {
        logTrace( "MEMORY WARNING!!!" )
        super.didReceiveMemoryWarning()
    }
    
    

    // MARK: NSNotification Methods
    
    @objc func pinsUpdated( notification: NSNotification ) {
        logVerbose( "recovering pinIndex[ %d ] from pinCentral", pinCentral.newPinIndex )
        indexOfItemBeingEdited = pinCentral.newPinIndex

        // The reason we are using Notifications is because this view can be up in two different places on the iPad at the same time.
        // This approach allows a change in one to immediately be reflected in the other.
        
        if !imageAssigned {
            deleteImage()
        }
        
        initializeVariables()
        myTableView.reloadData()
   }
    
    
    
    // MARK: Target/Action Methods
    
    @IBAction func doneBarButtonTouched( sender: UIBarButtonItem ) {
        logTrace()
        dismissView()
    }
    
    

    // MARK: Utility Methods
    
    private func deleteImage() {
        if !pinCentral.deleteImageWith( name: imageName ) {
            logVerbose( "ERROR: Unable to delete image[ %@ ]!", self.imageName )
            presentAlert( title: NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                          message: NSLocalizedString( "AlertMessage.UnableToDeleteImage", comment: "We were unable to delete the image you created." ) )
        }
        
        imageName     = String.init()
        imageAssigned = true
        
        updatePinCentral()
   }
    
    
    private func dismissView() {
//        logTrace()
        if launchedFromDetailView {
            dismiss( animated: true, completion: nil )
        }
        else {
            navigationController?.popViewController( animated: true )
        }
        
    }
    
    
    private func initializeVariables() {
//        logTrace()
        var         frame = CGRect.zero
        
        frame.size.height = .leastNormalMagnitude
        myTableView.tableHeaderView = UIView(frame: frame)
        myTableView.tableFooterView = UIView(frame: frame)
        myTableView.contentInsetAdjustmentBehavior = .never
        
        if GlobalConstants.newPin == indexOfItemBeingEdited {
            altitude  = 0.0
            details   = String.init()
            imageName = String.init()
            name      = String.init()
            
            if useCenterOfMap {
                latitude  = centerOfMap.latitude
                longitude = centerOfMap.longitude
            }
            else if pinCentral.locationEstablished {
                altitude  = pinCentral.currentAltitude
                latitude  = pinCentral.currentLocation.latitude
                longitude = pinCentral.currentLocation.longitude
            }
            else {
                latitude  = 0.0
                longitude = 0.0
            }
            
            pinColor = PinColors.pinRed
        }
        else {
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
    
    
    private func updatePinCentral() {
        logTrace()
        pinCentral.delegate = self
        
        if GlobalConstants.newPin == indexOfItemBeingEdited {
            pinCentral.addPin( name:      name,
                               details:   details,
                               latitude:  latitude,
                               longitude: longitude,
                               altitude:  altitude,
                               imageName: imageName,
                               pinColor:  Int16( pinColor ) )
        }
        else {
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
    


// MARK: LocationDetailsTableViewCellDelegate Methods
    
extension LocationEditorViewController: LocationDetailsTableViewCellDelegate {
    
    func locationDetailsTableViewCell( locationDetailsTableViewCell: LocationDetailsTableViewCell, requestingEditOfNameAndDetails: Bool ) {
        logTrace()
        editNameAndDetails( locationDetailsTableViewCell )
    }

    
    
    func locationDetailsTableViewCell( locationDetailsTableViewCell: LocationDetailsTableViewCell, requestingEditOfLocation: Bool ) {
        logTrace()
        editLatLongAndAlt( locationDetailsTableViewCell )
    }
    
    
    func locationDetailsTableViewCell( locationDetailsTableViewCell: LocationDetailsTableViewCell, requestingEditOfPinColor: Bool ) {
        logTrace()
        detailsCell = locationDetailsTableViewCell
        
        if let  pinColorSelectorVC: PinColorSelectorViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.colorSelector ) as? PinColorSelectorViewController {
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
        else {
            logTrace( "ERROR:  Unable to load PinColorSelectorViewController!" )
        }
    }
    

    func locationDetailsTableViewCell( locationDetailsTableViewCell: LocationDetailsTableViewCell, requestingShowPinOnMap: Bool ) {
        logTrace()
        if name.isEmpty {
            logTrace( "ERROR:  Name field cannot be left blank!" )
            presentAlert( title:   NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                          message: NSLocalizedString( "AlertMessage.NameCannotBeBlank", comment: "Name field cannot be left blank" ) )
            return
        }
        
        if dataChanged() {
            updatePinCentral()
            
            savedPinBeforeShowingMap = true
            
            logVerbose( "indexOfSelectedPin[ %d ] = indexOfItemBeingEdited[ %d ]", pinCentral.indexOfSelectedPin, indexOfItemBeingEdited )
            pinCentral.indexOfSelectedPin = indexOfItemBeingEdited
        
            logTrace( "waiting for update from pinCentral" )
        }
        else {
            if .phone == UIDevice.current.userInterfaceIdiom {
                tabBarController?.selectedIndex = 1
                dismissView()
            }

        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01 ) {
            self.delegate?.locationEditorViewController( self, wantsToCenterMapAt: CLLocationCoordinate2DMake( self.latitude, self.longitude ) )
        }
        
    }
 
    
    
    // MARK: LocationDetailsTableViewCellDelegate Utility Methods
    
    private func dataChanged() -> Bool {
        var     dataChanged  = false

        if ( ( name      != originalName      ) || ( details   != originalDetails   ) || ( altitude  != originalAltitude  ) ||
             ( imageName != originalImageName ) || ( latitude  != originalLatitude  ) || ( longitude != originalLongitude ) || ( pinColor  != originalPinColor  ) ) {
            dataChanged = true
        }

//        logVerbose( "[ %@ ]", stringFor( dataChanged ) )
        return dataChanged
    }
    
    
    @objc private func editLatLongAndAlt(_ locationDetailsTableViewCell: LocationDetailsTableViewCell ) {
        logTrace()
        let     title = String( format: "%@ in %@", NSLocalizedString( "AlertTitle.EditLatLongAndAlt", comment: "Edit latitude, longitude and altitude" ), pinCentral.displayUnits() )
        let     alert = UIAlertController.init( title: title, message: nil, preferredStyle: .alert)
        
        let     saveAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Save", comment: "Save" ), style: .default )
        { ( alertAction ) in
            logTrace( "Save Action" )
            let     latitudeTextField  = alert.textFields![0] as UITextField
            let     longitudeTextField = alert.textFields![1] as UITextField
            let     altitudeTextField  = alert.textFields![2] as UITextField
            
            self.latitude  = self.doubleFrom( text: latitudeTextField .text!, defaultValue: self.latitude  )
            self.longitude = self.doubleFrom( text: longitudeTextField.text!, defaultValue: self.longitude )
            self.altitude  = self.doubleFrom( text: altitudeTextField .text!, defaultValue: self.altitude  )
            
            if DisplayUnits.feet == self.pinCentral.displayUnits() {
                self.altitude = ( self.altitude / GlobalConstants.feetPerMeter )
            }
            
            self.updatePinCentral()
        }
        
        let     useCurrentAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.UseCurrent", comment: "Use Current Location" ), style: .default )
        { ( alertAction ) in
            logTrace( "Use Current Location Action" )
            self.latitude  = self.pinCentral.currentLocation.latitude
            self.longitude = self.pinCentral.currentLocation.longitude
            self.altitude  = self.pinCentral.currentAltitude
            
            self.updatePinCentral()
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
            textField.text = ( ( DisplayUnits.feet == self.pinCentral.displayUnits() ) ? String.init( format: "%7.1f", ( self.altitude * GlobalConstants.feetPerMeter ) ) : String.init( format: "%7.1f", self.altitude ) )
            textField.keyboardType = .decimalPad
        }
        
        if pinCentral.locationEstablished {
            alert.addAction( useCurrentAction )
        }
        
        alert.addAction( saveAction   )
        alert.addAction( cancelAction )
        
        present( alert, animated: true, completion: nil )
    }
    
    
}


    // MARK: LocationImageTableViewCellDelegate Methods
    
extension LocationEditorViewController: LocationImageTableViewCellDelegate {
    
    func locationImageTableViewCell( locationImageTableViewCell: LocationImageTableViewCell, cameraButtonTouched: Bool ) {
        logTrace()
        imageCell = locationImageTableViewCell

        if imageName.isEmpty {
            promptForImageSource()
        }
        else {
            promptForImageDispostion()
        }

    }
    
    
    
    // MARK: LocationImageTableViewCellDelegate Utility Methods
    
    private func doubleFrom( text: String?, defaultValue: Double ) -> Double {
        var     doubleValue = defaultValue
        
        if let myText = text {
            if !myText.isEmpty {
                let     trimmedString = myText.trimmingCharacters( in: .whitespaces )
                
                if !trimmedString.isEmpty {
                    if let newValue = Double( trimmedString ) {
                        doubleValue = newValue
                    }
                    else {
                        logTrace( "ERROR:  Unable to convert text into a Double!  Returning defaultValue" )
                    }
                    
                }
                else {
                    logTrace( "ERROR:  Input string contained nothing but whitespace" )
                }
                
            }
            else {
                logTrace( "ERROR:  Input string isEmpty!" )
            }
            
        }
        else {
            logTrace( "ERROR:  Unable to unwrap text as String!  Returning defaultValue" )
        }
        
        return doubleValue
    }
    
    
    private func launchImageViewController() {
        guard let imageViewController: ImageViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.imageViewer ) as? ImageViewController else {
            logTrace( "ERROR: Could NOT load ImageViewController!" )
            return
        }
        
        logVerbose( "imageName[ %@ ]", imageName )
        imageViewController.imageName = imageName
        navigationController?.pushViewController( imageViewController, animated: true )
    }
    
    
    private func openImagePickerFor( sourceType: UIImagePickerController.SourceType ) {
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
    
    
    private func promptForImageDispostion() {
        logTrace()
        let     alert = UIAlertController.init( title: NSLocalizedString( "AlertTitle.ImageDisposition", comment: "What would you like to do with this image?" ), message: nil, preferredStyle: .alert)
        
        let     deleteAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Delete", comment: "Delete" ), style: .default )
        { ( alertAction ) in
            logTrace( "Delete Action" )
            
            self.deleteImage()
            self.imageCell.initializeWith( imageName: self.imageName, self )
        }
        
        let     replaceAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Replace", comment: "Replace" ), style: .default )
        { ( alertAction ) in
            logTrace( "Replace Action" )
            
            self.deleteImage()
            self.imageCell.initializeWith( imageName: self.imageName, self )
            
            self.promptForImageSource()
        }
        
        let     zoomAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.ZoomIn", comment: "Zoom In" ), style: .default )
        { ( alertAction ) in
            logTrace( "Zoom In Action" )
            
            if self.dataChanged() {
                self.loadingImageView = true
                self.updatePinCentral()
            }
            else {
                self.launchImageViewController()
            }

        }
        
        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel, handler: nil )
        
        alert.addAction( deleteAction  )
        alert.addAction( replaceAction )
        alert.addAction( zoomAction    )
        alert.addAction( cancelAction  )
        
        present( alert, animated: true, completion: nil )
    }
    
    
    private func promptForImageSource() {
        logTrace()
        let     alert       = UIAlertController.init( title: NSLocalizedString( "AlertTitle.SelectMediaSource", comment: "Select Media Source for Image" ), message: nil, preferredStyle: .alert)
        
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
        
        if UIImagePickerController.isSourceTypeAvailable( .camera ) {
            alert.addAction( cameraAction )
        }
        
        alert.addAction( albumAction  )
        alert.addAction( cancelAction )
        
        present( alert, animated: true, completion: nil )
    }


}
    
    
 

// MARK: PinCentralDelegate Methods

extension LocationEditorViewController: PinCentralDelegate {

    func pinCentral( pinCentral: PinCentral, didOpenDatabase: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didOpenDatabase ) )
    }
    
    
    func pinCentralDidReloadPinArray( pinCentral: PinCentral ) {
        logVerbose( "loaded [ %d ] pins ... indexOfItemBeingEdited[ %d ]", pinCentral.pinArray.count, indexOfItemBeingEdited )
        
//        if GlobalConstants.newPin == indexOfItemBeingEdited
//        {
            logVerbose( "recovering pinIndex[ %d ] from pinCentral", pinCentral.newPinIndex )
            indexOfItemBeingEdited = pinCentral.newPinIndex
//        }
        
        if loadingImageView {
            loadingImageView = false
            launchImageViewController()
        }
        else {
            self.myTableView.reloadData()
        }
        
    }
 
    
}
    
    
    
    // MARK: PinColorSelectorViewControllerDelegate Methods
    
extension LocationEditorViewController: PinColorSelectorViewControllerDelegate {
    
    func pinColorSelectorViewController( pinColorSelectorVC: PinColorSelectorViewController, didSelect color: Int ) {
        logVerbose( "[ %d ][ %@ ]", color, pinColorNameArray[color] )
        pinColor = Int16( color )
        
        detailsCell.initialize()
        changingColors = false

        updatePinCentral()
    }
    
    
}



    // MARK: UIImagePickerControllerDelegate Methods

extension LocationEditorViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController ) {
        logTrace()
        if nil != presentedViewController {
            dismiss( animated: true, completion: nil )
        }
        
    }
    
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any] ) {
        // Local variable inserted by Swift 4.2 migrator.
        let     info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        logTrace()
        if nil != presentedViewController {
            dismiss( animated: true, completion: nil )
        }
        
        DispatchQueue.main.asyncAfter( deadline: ( .now() + 0.01 ) ) {
            if let mediaType = info[self.convertFromUIImagePickerControllerInfoKey( .mediaType )] as? String {
                if "public.image" == mediaType {
                    var     imageToSave: UIImage? = nil
                    
                    if let originalImage: UIImage = info[self.convertFromUIImagePickerControllerInfoKey( .originalImage )] as? UIImage {
                        imageToSave = originalImage
                    }
                    else if let editedImage: UIImage = info[self.convertFromUIImagePickerControllerInfoKey( .editedImage )] as? UIImage {
                        imageToSave = editedImage
                    }
                    
                    if let myImageToSave = imageToSave {
                        if .camera == picker.sourceType {
                            UIImageWriteToSavedPhotosAlbum( myImageToSave, self, #selector( LocationEditorViewController.image(_ :didFinishSavingWithError:contextInfo: ) ), nil )
                        }
                        
                        let     imageName = self.pinCentral.saveImage( image: myImageToSave )
                        
                        if imageName.isEmpty {
                            logTrace( "ERROR:  Image save FAILED!" )
                            self.presentAlert( title: NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                                               message: NSLocalizedString( "AlertMessage.ImageSaveFailed", comment: "We were unable to save the image you selected." ) )
                        }
                        else {
                            self.imageAssigned = false
                            self.imageName     = imageName
                            
                            logVerbose( "Saved image as [ %@ ]", imageName )
                            
                            self.imageCell.initializeWith( imageName: self.imageName, self )

                            self.updatePinCentral()
                        }
                        
                    }
                    else {
                        logTrace( "ERROR:  Unable to unwrap imageToSave!" )
                    }
                    
                }
                else {
                    logVerbose( "ERROR:  Invalid media type[ %@ ]", mediaType )
                    self.presentAlert( title: NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                                       message: NSLocalizedString( "AlertMessage.InvalidMediaType", comment: "We can't save the item you selected.  We can only save photos." ) )
                }
                
            }
            else {
                logTrace( "ERROR:  Unable to convert info[UIImagePickerControllerMediaType] to String" )
            }
            
        }
        
    }
    
    
    
    // MARK: UIImageWrite Completion Methods
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer ) {
        guard error == nil else {
            if let myError = error {
                logVerbose( "ERROR:  Save to photo album failed!  Error[ %@ ]", myError.localizedDescription )
            }
            else {
                logTrace( "ERROR:  Save to photo album failed!  Error[ Unknown ]" )
            }
            
            return
        }
        
        logTrace( "Image successfully saved to photo album" )
    }
    
    
    
    // MARK: Helper function inserted by Swift 4.2 migrator.

    fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
        return Dictionary(uniqueKeysWithValues: input.map {key, value in (key.rawValue, value)})
    }

    fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
        return input.rawValue
    }

                
}



    // MARK: UIPopoverPresentationControllerDelegate Methods
    
extension LocationEditorViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    
}
    
    
    
// MARK: UITableViewDataSource Methods

extension LocationEditorViewController: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        logTrace()
        return 2
    }


    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        logVerbose( "row[ %d ]", indexPath.row)
        let cell : UITableViewCell!
        
        if indexPath.row == 0 {
            cell = loadImageViewCell()
        }
        else {
            cell = loadDetailsCell()
        }

        return cell
    }


    
// MARK: UITableViewDataSource Utility Methods

    @objc private func editNameAndDetails(_ locationDetailsTableViewCell: LocationDetailsTableViewCell ) {
        logTrace()
        let     alert = UIAlertController.init( title: NSLocalizedString( "AlertTitle.EditNameAndDetails", comment: "Edit name and details" ),
                                                message: nil,
                                                preferredStyle: .alert)
        
        let     saveAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Save", comment: "Save" ), style: .default )
        { ( alertAction ) in
            logTrace( "Save Action" )
            let     nameTextField    = alert.textFields![0] as UITextField
            let     detailsTextField = alert.textFields![1] as UITextField
            
            
            if var textStringName = nameTextField.text
            {
                textStringName = textStringName.trimmingCharacters( in: .whitespacesAndNewlines )
                
                if !textStringName.isEmpty {
                    logTrace( "We have a valid name" )
                    self.name = textStringName

                    if let textStringDetails = detailsTextField.text {
                        self.details = textStringDetails
                    }
                    
                    self.updatePinCentral()
                }
                else {
                    logTrace( "ERROR:  Name field cannot be left blank!" )
                    self.presentAlert( title:   NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                                       message: NSLocalizedString( "AlertMessage.NameCannotBeBlank", comment: "Name field cannot be left blank" ) )
                }

            }
            
        }
        
        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel, handler: nil )
        
        
        alert.addTextField
        { ( textField ) in
                
                if self.name.isEmpty {
                    textField.placeholder = NSLocalizedString( "LabelText.Name", comment: "Name" )
                }
                else {
                    textField.text = self.name
                }
                
                textField.autocapitalizationType = .words
        }
        
        alert.addTextField
        { ( textField ) in
                
                if self.details.isEmpty {
                    textField.placeholder = NSLocalizedString( "LabelText.Details", comment: "Address / Description" )
                }
                else {
                    textField.text = self.details
                }
                
                textField.autocapitalizationType = .words
        }
        
        alert.addAction( saveAction   )
        alert.addAction( cancelAction )
        
        present( alert, animated: true, completion: nil )
    }


    private func loadDetailsCell() -> UITableViewCell {
        guard let cell = myTableView.dequeueReusableCell( withIdentifier: CellIds.details ) else {
            logVerbose("We FAILED to dequeueReusableCell")
            return UITableViewCell.init()
        }
        
//        logTrace()
        let detailsCell = cell as! LocationDetailsTableViewCell
        
        detailsCell.delegate = self
        
        detailsCell.altitude  = self.altitude
        detailsCell.delegate  = self
        detailsCell.details   = self.details
        detailsCell.latitude  = self.latitude
        detailsCell.longitude = self.longitude
        detailsCell.name      = self.name
        detailsCell.pinColor  = self.pinColor
        
        detailsCell.initialize()

        if firstTimeIn && ( GlobalConstants.newPin == indexOfItemBeingEdited ) {
            firstTimeIn = false
            
            DispatchQueue.main.asyncAfter( deadline: ( .now() + 0.2 ) ) {
                self.editNameAndDetails( detailsCell )
            }
            
        }
        
        return cell
    }


    private func loadImageViewCell() -> UITableViewCell {
        guard let cell = myTableView.dequeueReusableCell( withIdentifier: CellIds.image ) else {
            logVerbose("We FAILED to dequeueReusableCell")
            return UITableViewCell.init()
        }
        
    //    logTrace()
        let imageCell = cell as! LocationImageTableViewCell
        
        imageCell.initializeWith(imageName: imageName, self)
        
        return cell
    }


}



