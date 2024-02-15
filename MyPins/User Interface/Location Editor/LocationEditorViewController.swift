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
}



class LocationEditorViewController: UIViewController  {
    
    // MARK: Public Variables
    
    @IBOutlet weak var myTableView: UITableView!
    
    weak var delegate: LocationEditorViewControllerDelegate?
    
    var     centerOfMap:                CLLocationCoordinate2D!     // Only set by MapViewController when indexOfItemBeingEdited == GlobalConstants.newPin
    var     indexPathOfItemBeingEdited: IndexPath!                  // Set by delegate
    var     launchedFromDetailView    = false                       // Set by delegate
    var     useCenterOfMap            = false                       // Only set by MapViewController when indexOfItemBeingEdited == GlobalConstants.newPin
    
    
    // MARK: Private Variables
    
    private struct CellIds {
        static let details = "LocationDetailsTableViewCell"
        static let image   = "LocationImageTableViewCell"
        static let notes   = "LocationNotesTableViewCell"
    }

    private struct RowHeights {
        static let details  = CGFloat( 165.0 )
        static let image    = CGFloat( 240.0 )
        static let notes    = CGFloat( 240.0 )
    }
    
    private struct StoryboardIds {
        static let colorSelector = "PinColorSelectorViewController"
        static let imageViewer   = "ImageViewController"
        static let notes         = "NotesViewController"
    }
    
    private var     altitude                  = 0.0
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
    private var     notes                     = String()
    private var     originalAltitude          = 0.0
    private var     originalDetails           = String()
    private var     originalImageName         = String()
    private var     originalLatitude          = 0.0
    private var     originalLongitude         = 0.0
    private var     originalName              = String()
    private var     originalNotes             = String()
    private var     originalPinColor          : Int16!      // Set in initializeVariables()
    private let     pinCentral                = PinCentral.sharedInstance
    private var     pinColorIndex             : Int16!      // Set in initializeVariables()
    private var     savedPinBeforeShowingMap  = false
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString( "Title.PinEditor", comment: "Pin Editor" )
        preferredContentSize = CGSize( width: 400, height: 600 )
        
        // I'm not sure why but without the following 2 lines, the navBar is Black
        edgesForExtendedLayout = .all
        navigationController?.navigationBar.isTranslucent = true
        
        initializeVariables()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        loadBarButtonItems()
        myTableView.reloadData()
    }
    
    
    override func didReceiveMemoryWarning() {
        logTrace( "MEMORY WARNING!!!" )
        super.didReceiveMemoryWarning()
    }
    
    

    // MARK: NSNotification Methods
    
    @objc func pinsUpdated( notification: NSNotification ) {
        logVerbose( "pinCentral.newPinIndexPath[ %@ ]", stringFor( pinCentral.newPinIndexPath ) )
   }
    
    
    
    // MARK: Target/Action Methods
    
    @IBAction func cancelBarButtonTouched( sender: UIBarButtonItem ) {
        logTrace()
        if dataChanged() {
            promptToDiscardChanges()
        }
        else {
            dismissView()
        }
        
    }
    
    
    @IBAction func saveBarButtonTouched( sender: UIBarButtonItem ) {
       logTrace()
        if dataChanged() {
            updatePinCentral()
        }
        
       dismissView()
    }
    
    

    // MARK: Utility Methods
    
    private func dataChanged() -> Bool {
        var     dataChanged  = false

        if ( ( name      != originalName      ) || ( details   != originalDetails   ) || ( altitude  != originalAltitude  ) ||
             ( imageName != originalImageName ) || ( latitude  != originalLatitude  ) || ( longitude != originalLongitude ) ||
             ( notes     != originalNotes     ) || ( pinColorIndex != originalPinColor  ) ) {
            dataChanged = true
        }

//        logVerbose( "[ %@ ]", stringFor( dataChanged ) )
        return dataChanged
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
    
    
    @objc private func editNameAndDetails(_ locationDetailsTableViewCell: LocationDetailsTableViewCell ) {
//        logTrace()
        let     alert = UIAlertController.init( title: NSLocalizedString( "AlertTitle.EditNameAndDetails", comment: "Edit name and details" ), message: nil, preferredStyle: .alert)
        
        let     saveAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Save", comment: "Save" ), style: .default )
        { ( alertAction ) in
            logTrace( "Save Action" )
            let     nameTextField    = alert.textFields![0] as UITextField
            let     detailsTextField = alert.textFields![1] as UITextField
            
            
            if var textStringName = nameTextField.text {
                textStringName = textStringName.trimmingCharacters( in: .whitespacesAndNewlines )
                
                if !textStringName.isEmpty {
                    logVerbose( "Location name[ %@ ]" , textStringName )
                    self.name = textStringName
                    
                    if let textStringDetails = detailsTextField.text {
                        logVerbose( "Location details[ %@ ]" , textStringDetails )
                        self.details = textStringDetails
                    }
                    
                    self.myTableView.reloadData()
                    self.loadBarButtonItems()
                }
                else {
                    logTrace( "ERROR:  Name field cannot be left blank!" )
                    self.presentAlert( title:   NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                                       message: NSLocalizedString( "AlertMessage.NameCannotBeBlank", comment: "Name field cannot be left blank" ) )
                }
                
            }
            
        }
        
        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel )
        { ( alertAction ) in
            logTrace( "Cancel Action" )
        }
        
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
    
    
    private func initializeVariables() {
        logTrace()
        var         frame = CGRect.zero
        
        frame.size.height = .leastNormalMagnitude
        myTableView.tableHeaderView = UIView(frame: frame)
        myTableView.tableFooterView = UIView(frame: frame)
        myTableView.contentInsetAdjustmentBehavior = .never
        
        if GlobalConstants.newPin == indexPathOfItemBeingEdited.section {
            altitude  = 0.0
            details   = ""
            imageName = ""
            name      = ""
            
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
            
            pinColorIndex = PinColors.pinRed
        }
        else {
            let     pin = pinCentral.pinAt( indexPathOfItemBeingEdited )
            
            saveStringInUserDefaults( UserDefaultKeys.lastAccessedPinsGuid, value: pin.guid! )
            
            altitude        = pin.altitude
            details         = pin.details   ?? ""
            imageName       = pin.imageName ?? ""
            latitude        = pin.latitude
            longitude       = pin.longitude
            name            = pin.name      ?? ""
            notes           = pin.notes     ?? ""
            pinColorIndex   = pin.pinColor
        }
        
        originalAltitude    = altitude
        originalDetails     = details
        originalImageName   = imageName
        originalLatitude    = latitude
        originalLongitude   = longitude
        originalName        = name
        originalNotes       = notes
        originalPinColor    = pinColorIndex
    }
    
    
    private func loadBarButtonItems() {
        logTrace()
        navigationItem.leftBarButtonItem  = UIBarButtonItem.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .plain, target: self, action: #selector( cancelBarButtonTouched ) )
        navigationItem.rightBarButtonItem = nil
        
        if dataChanged() {
            navigationItem.rightBarButtonItem = UIBarButtonItem.init( title: NSLocalizedString( "ButtonTitle.Save",   comment: "Save"   ), style: .plain, target: self, action: #selector( saveBarButtonTouched   ) )
        }
    
    }
    
    
    private func promptToDiscardChanges() {
        let     alert     = UIAlertController.init( title: NSLocalizedString( "AlertTitle.DiscardChanges", comment: "Do you want to discard your changes?" ), message: nil, preferredStyle: .alert)
        
        let     yesAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Yes", comment: "Yes" ), style: .destructive )
        { ( alertAction ) in
            logTrace( "Yes Action" )

            self.dismissView()
        }
        
        let     noAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.No", comment: "No" ), style: .cancel )
        { ( alertAction ) in
            logTrace( "No Action" )
        }

        alert.addAction( yesAction  )
        alert.addAction( noAction )
        
        present( alert, animated: true, completion: nil )
    }


    private func updatePinCentral() {
        logTrace()
        if GlobalConstants.newPin == indexPathOfItemBeingEdited.section {
            pinCentral.addPinNamed( name, details: details, latitude: latitude, longitude: longitude, altitude: altitude, imageName: imageName, pinColor: Int16( pinColorIndex ), notes: notes, self )
        }
        else {
            let     pin = pinCentral.pinAt( indexPathOfItemBeingEdited )
            
            pin.altitude  = altitude
            pin.details   = details
            pin.imageName = imageName
            pin.latitude  = latitude
            pin.longitude = longitude
            pin.name      = name
            pin.notes     = notes
            pin.pinColor  = Int16( pinColorIndex )
            
            pinCentral.saveUpdated( pin, self )
        }
        
    }
        
    
}
    


// MARK: LocationDetailsTableViewCellDelegate Methods
    
extension LocationEditorViewController: LocationDetailsTableViewCellDelegate {
    
    func locationDetailsTableViewCell(_ locationDetailsTableViewCell: LocationDetailsTableViewCell, requestingEditOfNameAndDetails: Bool ) {
        logTrace()
        editNameAndDetails( locationDetailsTableViewCell )
    }

    
    
    func locationDetailsTableViewCell(_ locationDetailsTableViewCell: LocationDetailsTableViewCell, requestingEditOfLocation: Bool ) {
        logTrace()
        editLatLongAndAlt( locationDetailsTableViewCell )
    }
    
    
    func locationDetailsTableViewCell(_ locationDetailsTableViewCell: LocationDetailsTableViewCell, requestingEditOfPinColor: Bool ) {
        logTrace()
        detailsCell = locationDetailsTableViewCell
        
        if let  pinColorSelectorVC: PinColorSelectorViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.colorSelector ) as? PinColorSelectorViewController {
            pinColorSelectorVC.delegate = self
            
            navigationController?.pushViewController( pinColorSelectorVC, animated: true )
        }
        else {
            logTrace( "ERROR:  Unable to load PinColorSelectorViewController!" )
        }
    }
    

    
    // MARK: LocationDetailsTableViewCellDelegate Utility Methods
    
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
            
            self.myTableView.reloadData()
            self.loadBarButtonItems()
        }
        
        let     useCurrentAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.UseCurrent", comment: "Use Current Location" ), style: .default )
        { ( alertAction ) in
            logTrace( "Use Current Location Action" )
            self.latitude  = self.pinCentral.currentLocation.latitude
            self.longitude = self.pinCentral.currentLocation.longitude
            self.altitude  = self.pinCentral.currentAltitude
            
            self.myTableView.reloadData()
            self.loadBarButtonItems()
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
    
    func locationImageTableViewCell(_ locationImageTableViewCell: LocationImageTableViewCell, cameraButtonTouched: Bool ) {
        logTrace()
        imageCell = locationImageTableViewCell

        if imageCell.imageState == ImageState.noName {
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
        
        imagePickerVC.modalPresentationStyle = .overFullScreen // ( ( .camera == sourceType ) ? .overFullScreen : .popover )
        
        present( imagePickerVC, animated: true, completion: nil )
        
        imagePickerVC.popoverPresentationController?.delegate                 = self
        imagePickerVC.popoverPresentationController?.permittedArrowDirections = .any
        imagePickerVC.popoverPresentationController?.sourceRect               = myTableView.frame
        imagePickerVC.popoverPresentationController?.sourceView               = myTableView
    }
    
    
    private func promptForImageDispostion() {
        logTrace()
        let     alert    = UIAlertController.init( title: NSLocalizedString( "AlertTitle.ImageDisposition", comment: "What would you like to do with this image?" ), message: nil, preferredStyle: .alert)
        let     onDevice = pinCentral.dataStoreLocation == .device

        let     inspectImageAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.InspectImage", comment: "Inspect Image" ), style: .default )
        { ( alertAction ) in
            logTrace( "Inspect Image Action" )
            
            if self.dataChanged() {
                self.loadingImageView = true
            }
            else {
                self.launchImageViewController()
            }

        }
        
        let     reloadImageAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.ReloadImage", comment: "Reload Image" ), style: .default )
        { ( alertAction ) in
            logTrace( "Reload Image Action" )
            let result      = self.pinCentral.imageNamed( self.imageCell.imageName, descriptor: "Reloading image", self )
            let imageLoaded = result.0
            
            self.imageCell.imageState              = imageLoaded ? ImageState.loaded : ImageState.missing
            self.imageCell.locationImageView.image = imageLoaded ? result.1 : UIImage( named: GlobalConstants.missingImage )
        }
        
        let     saveImageAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.SaveImageToLibrary", comment: "Save Image to Photo Library" ), style: .default )
        { ( alertAction ) in
            logTrace( "Save Image Action" )
            let     thisImage = self.imageCell.locationImageView.image!
            
            UIImageWriteToSavedPhotosAlbum( thisImage, self, #selector( LocationEditorViewController.image(_ :didFinishSavingWithError:contextInfo: ) ), nil )
        }

        let     replaceAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Replace", comment: "Replace" ), style: .destructive )
        { ( alertAction ) in
            logTrace( "Replace Action" )
            
            self.promptForImageSource()
        }
        
        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel, handler: nil )
        
        if imageCell.imageState == ImageState.loaded {
            alert.addAction( inspectImageAction )
            alert.addAction( saveImageAction )
        }
        
        if !onDevice && imageCell.imageState == ImageState.missing {
            alert.addAction( reloadImageAction )
        }
        
        alert.addAction( replaceAction )
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
        
        let     cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel )
        { ( alertAction ) in
            logTrace( "Cancel Action" )
        }

        if UIImagePickerController.isSourceTypeAvailable( .camera ) {
            alert.addAction( cameraAction )
        }
        
        alert.addAction( albumAction  )
        alert.addAction( cancelAction )
        
        present( alert, animated: true, completion: nil )
    }


}
    
    

// MARK: LocationNotesTableViewCellDelegate Methods

extension LocationEditorViewController: LocationNotesTableViewCellDelegate {
    
    func locationNotesTableViewCellWantsToEdit(_ LocationNotesTableViewCell: LocationNotesTableViewCell) {
        logTrace()
        launchNotesViewController()
    }

    
    
    // MARK: LocationNotesTableViewCellDelegate Utility Methods

    private func launchNotesViewController() {
        guard let notesViewController: NotesViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.notes ) as? NotesViewController else {
            logTrace( "ERROR: Could NOT load NotesViewController!" )
            return
        }
        
        notesViewController.delegate     = self
        notesViewController.originalText = notes
        
        navigationController?.pushViewController( notesViewController, animated: true )
    }

    
}



// MARK: NotesViewControllerDelegate Methods

extension LocationEditorViewController: NotesViewControllerDelegate {
    
    func notesViewControllerDidUpdateText(_ notesViewController: NotesViewController, newText: String) {
        logTrace()
        notes = newText
        loadBarButtonItems()
    }
    
    
}



// MARK: PinCentralDelegate Methods

extension LocationEditorViewController: PinCentralDelegate {

    func pinCentral(_ pinCentral: PinCentral, didOpenDatabase: Bool ) {
        logVerbose( "[ %@ ]", stringFor( didOpenDatabase ) )
    }
    
    
    func pinCentralDidReloadPinArray(_ pinCentral: PinCentral ) {
        if UIDevice.current.userInterfaceIdiom == .pad  {
            self.myTableView.reloadData()
            return
        }
        
        logVerbose( "loaded [ %d ] pins ... indexPathOfItemBeingEdited[ %@ ]", pinCentral.numberOfPinsLoaded, stringFor( indexPathOfItemBeingEdited ) )
        
        if GlobalConstants.newPin == indexPathOfItemBeingEdited.section {
            logVerbose( "recovering new pinIndex[ %@ ] from pinCentral", stringFor( pinCentral.newPinIndexPath ) )
            indexPathOfItemBeingEdited = pinCentral.newPinIndexPath
        }
        
        let pin = pinCentral.pinAt( indexPathOfItemBeingEdited )
        
        saveStringInUserDefaults( UserDefaultKeys.lastAccessedPinsGuid, value: pin.guid! )
        
        if loadingImageView {
            loadingImageView = false
            launchImageViewController()
        }
        else {
            myTableView.reloadData()
            loadBarButtonItems()
        }
        
    }
 
    
}
    
    
    
    // MARK: PinColorSelectorViewControllerDelegate Methods
    
extension LocationEditorViewController: PinColorSelectorViewControllerDelegate {
    
    func pinColorSelectorViewController(_ pinColorSelectorVC: PinColorSelectorViewController, didSelectColorAt index: Int ) {
        let pinColor = pinCentral.colorArray[Int( index )]
        let title    = pinColor.name! + " - " + pinColor.descriptor!
        
        logVerbose( "[ %d ] %@", index, title )
        pinColorIndex = Int16( index )
        
        detailsCell.initialize()

        myTableView.reloadData()
        loadBarButtonItems()
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
                        
                        // Uncomment the following 3 lines if you want to save images to the photo album
                        // but just be aware that we already use PinCentral to save them in our app
                        
//                        if .camera == picker.sourceType {
//                            UIImageWriteToSavedPhotosAlbum( myImageToSave, self, #selector( LocationEditorViewController.image(_ :didFinishSavingWithError:contextInfo: ) ), nil )
//                        }
                        
                        let     imageName = self.pinCentral.saveImage( myImageToSave, compressed: true )
                        
                        if imageName.isEmpty {
                            logTrace( "ERROR:  Image save FAILED!" )
                            self.presentAlert( title:   NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                                               message: NSLocalizedString( "AlertMessage.ImageSaveFailed", comment: "We were unable to save the image you selected." ) )
                        }
                        else {
                            logVerbose( "Saved image as [ %@ ]", imageName )
                            if !self.pinCentral.createThumbnailFrom( imageName ) {
                                logTrace( "ERROR:  Thumbnail create FAILED!" )
                                self.presentAlert( title:   NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                                                   message: NSLocalizedString( "AlertMessage.ThumbnailCreateFailed", comment: "We were unable to create a thumbnail for the image you selected." ) )
                            }
                            else {
                                if !self.flagIsPresentInUserDefaults( UserDefaultKeys.usingThumbnails ) {
                                    self.saveFlagInUserDefaults( UserDefaultKeys.usingThumbnails )
                                }
                                
                            }
                            
                            logVerbose( "Saved image as [ %@ ]", imageName )
                            
                            self.imageName = imageName
                            self.imageCell.initializeWith( self.imageName, self )
                            self.loadBarButtonItems()
                        }
                        
                    }
                    else {
                        logTrace( "ERROR:  Unable to unwrap imageToSave!" )
                    }
                    
                }
                else {
                    logVerbose( "ERROR:  Invalid media type[ %@ ]", mediaType )
                    self.presentAlert( title:   NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
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
        let message = error == nil ? NSLocalizedString( "AlertMessage.PhotoSaved",      comment: "Image saved to photo album"  ) :
                                     NSLocalizedString( "AlertMessage.PhotoSaveFailed", comment: "Save to photo album failed!" )
        let title   = error == nil ? NSLocalizedString( "AlertTitle.Success", comment: "Success!" ) : NSLocalizedString( "AlertTitle.Error", comment: "Error!" )
        
        presentAlert(title: title, message: message )
    }
    
    
    
    // MARK: Helper function inserted by Swift 4.2 migrator.

    fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
        return Dictionary( uniqueKeysWithValues: input.map { key, value in (key.rawValue, value) } )
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
        return 3
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell : UITableViewCell!
        
        switch indexPath.row {
        case 0:     cell = loadImageViewCell()
        case 1:     cell = loadDetailsCell()
        default:    cell = loadNotesCell()
        }
        
        return cell
    }
    
    
    
    // MARK: UITableViewDataSource Utility Methods
    
    private func loadDetailsCell() -> UITableViewCell {
        guard let cell = myTableView.dequeueReusableCell( withIdentifier: CellIds.details ) else {
            logVerbose("We FAILED to dequeueReusableCell")
            return UITableViewCell.init()
        }
        
//      logTrace()
        let detailsCell = cell as! LocationDetailsTableViewCell
        
        detailsCell.delegate = self
        
        detailsCell.altitude   = self.altitude
        detailsCell.delegate   = self
        detailsCell.details    = self.details
        detailsCell.latitude   = self.latitude
        detailsCell.longitude  = self.longitude
        detailsCell.name       = self.name
        detailsCell.colorIndex = self.pinColorIndex
        
        detailsCell.initialize()
        
        if firstTimeIn && ( GlobalConstants.newPin == indexPathOfItemBeingEdited.section ) {
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
        
//      logTrace()
        let imageCell = cell as! LocationImageTableViewCell
        
        imageCell.initializeWith( imageName, self)
        
        return cell
    }
    
    
    private func loadNotesCell() -> UITableViewCell {
        guard let cell = myTableView.dequeueReusableCell( withIdentifier: CellIds.notes ) else {
            logVerbose("We FAILED to dequeueReusableCell")
            return UITableViewCell.init()
        }
        
//      logTrace()
        let notesCell = cell as! LocationNotesTableViewCell
        
        notesCell.initializeWith( notes, self )
        
        return cell
    }
    
    
}



// MARK: UITableViewDataSource Methods

extension LocationEditorViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        var     rowHeight = CGFloat( 0.0 )
        
        switch indexPath.row {
        case 0:     rowHeight = RowHeights.image
        case 1:     rowHeight = RowHeights.details
        default:    let notesHeight = tableView.frame.size.height - RowHeights.image - RowHeights.details
                    rowHeight = notesHeight > 0.0 ? notesHeight : RowHeights.notes
        }
        
        return rowHeight
    }
    
}


