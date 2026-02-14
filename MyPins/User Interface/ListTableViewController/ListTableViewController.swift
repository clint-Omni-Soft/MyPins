//
//  ListTableViewController.swift
//  MyPins
//
//  Created by Clint Shank on 3/12/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit
import MapKit
import Photos



class ListTableViewController: UIViewController {
    
    // MARK: Public Variables
    
    @IBOutlet weak var myTableView: UITableView!
    @IBOutlet weak var sortButton : UIButton!
    
    
    // MARK: Private Variables
    
    private struct Constants {
        static let cellID              = "ListTableViewControllerCell"
        static let lastItemsGuidKey    = "LastItemsGuid"
        static let lastSectionKey      = "ListLastSection"
        static let rowHeight           = CGFloat.init( 72.0 )
        static let sectionHeaderHeight = CGFloat( 44.0 )
        static let sectionHeaderID     = "ListTableViewSectionCell"
    }
    
    private struct StoryboardIds {
        static let datePicker       = "DatePickerViewController"
        static let imageViewer      = "ImageViewController"
        static let locationEditor   = "LocationEditorViewController"
        static let map              = "MapViewController"
        static let myPhotos         = "MyPhotosViewController"
        static let notes            = "NotesViewController"
        static let settings         = "SettingsViewController"
        static let sortOptions      = "SortOptionsViewController"
    }
    
    private let appDelegate             = UIApplication.shared.delegate as! AppDelegate
    private let customDelegate          = CustomTransitioningDelegate( CGRect(x: 0, y: 0, width: 1, height: 1) )
    private let deviceAccessControl     = DeviceAccessControl.sharedInstance
    private let pinCentral              = PinCentral.sharedInstance
    private var pinForPhoto             : Pin!
    private var sectionIndexTitles      = [String]()
    private var sectionTitleIndexes     = [Int]()
    private var selectedPinIndexPath    = GlobalIndexPaths.noSelection  // Used by promptForActionOnCellAt to inform the datePickerViewControllerDidSelect() delegate method
    private var showAllSections         = true
    private let sortOptions             = [SortOptions.byDateLastModified,     SortOptions.byName,     SortOptions.byType    ]
    private let sortOptionNames         = [SortOptionNames.byDateLastModified, SortOptionNames.byName, SortOptionNames.byType]
    private let userDefaults            = UserDefaults.standard
    
    // This is used only when we are sorting on Type
    private var selectedSection: Int {
        get {
            var     section = GlobalConstants.noSelection
            
            if let lastSection = userDefaults.string(forKey: Constants.lastSectionKey ) {
                let thisSection = Int( lastSection ) ?? GlobalConstants.noSelection
                
                section = ( thisSection < myTableView.numberOfSections ) ? thisSection : GlobalConstants.noSelection
            }
            
            return section
        }
        
        set ( section ) {
            userDefaults.set( String( format: "%d", section ), forKey: Constants.lastSectionKey )
        }
        
    }
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString( "Title.PinList", comment: "Pin List" )
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        configureSortButtonTitle()
        loadBarButtonItems()
        
        if !pinCentral.didOpenDatabase {
            pinCentral.openDatabaseWith( self )
        }
        else {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                self.buildSectionTitleIndex()

                self.myTableView.reloadData()
                
                if self.pinCentral.numberOfPinsLoaded != 0 {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) {
                        self.scrollToLastSelectedItem()
                    }
                    
                }
                
            }
            
        }
        
        registerForNotifications()
    }
    
    
    override func viewDidAppear(_ animated: Bool) {
        logTrace()
        super.viewDidAppear( animated )
        
        PHPhotoLibrary.requestAuthorization(for: .readWrite ) { (status) in
            if PHPhotoLibrary.authorizationStatus() != .authorized {
                self.presentAlert( title  : NSLocalizedString( "AlertTitle.AuthorizationRequired",       comment: "Authorization Required!" ),
                                   message: NSLocalizedString( "AlertMessage.PhotoLibraryNotAuthorized", comment: "This app requires your authorization to access the photo library on this device.  Please update Settings to allow us to view your photos." ) )
            }
            
        }

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
        configureSortButtonTitle()
        loadBarButtonItems()

        myTableView.reloadData()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) {
            self.scrollToLastSelectedItem()
        }

    }
    
    
    @objc func ready( notification: NSNotification ) {
        if pinCentral.resigningActive {
            logTrace( "resigningActive" )
            return
        }

        // We get this one when (a) the pin array is reloaded and (b) when we fail to load an image
        logTrace()
        loadBarButtonItems()
        myTableView.reloadData()
    }


    
    // MARK: Target / Action Methods
    
    @IBAction @objc func addBarButtonItemTouched( barButtonItem: UIBarButtonItem ) {
        logTrace()
        launchLocationEditorForPinAt( GlobalIndexPaths.newPin )
    }
    
    
    @IBAction func hidePrimaryBarButtonTouched(_ sender: UIBarButtonItem ) {
        logTrace()
        appDelegate.hidePrimaryView( true )
    }

    
    @IBAction @objc func navBarTitleButtonTouched(_ sender: UIButton ) {
        logTrace()
        promptForNavigationAction()
    }
    
    
    @IBAction func settingsBarButtonTouched(_ sender : UIBarButtonItem ) {
        launchSettingsViewController()
    }
    
        
    @IBAction func showAllBarButtonTouched(_ sender : UIBarButtonItem ) {
        logVerbose( "[ %@ ]", stringFor( showAllSections ) )
        selectedSection = GlobalConstants.noSelection
        showAllSections = !showAllSections
        
        buildSectionTitleIndex()
        configureSortButtonTitle()
        loadBarButtonItems()

        myTableView.reloadData()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) {
            self.scrollToLastSelectedItem()
        }

    }
    
    
    @IBAction func sortButtonTouched(_ sender: Any) {
        logTrace()
        presentSortOptions()
    }
    
    

    // MARK: Utility Methods
    
    private func buildSectionTitleIndex() {
        var     currentTitle = ""
        var     index        = 0
        
        sectionIndexTitles .removeAll()
        sectionTitleIndexes.removeAll()
        
        let sortDescriptor = pinCentral.sortDescriptor
        let sortType       = sortDescriptor.0
        
        if sortType != SortOptions.byName {
//            logTrace( "Sort by type is NOT by name so don't populate the section index" )
            return
        }
        
        let pinArray = pinCentral.pinArrayOfArrays[0]   // When sorting by name, we know that our pins will always be in the first element
        
        for pin in pinArray {
            let     nameStartsWith: String = ( pin.name?.prefix(1).uppercased() )!
            
            if nameStartsWith != currentTitle {
                currentTitle = nameStartsWith
                sectionTitleIndexes.append( index )
                sectionIndexTitles .append( nameStartsWith )
            }
            
            index += 1
        }
        
    }
    
    
    private func configureSortButtonTitle() {
//        logTrace()
        let sortDescriptor = pinCentral.sortDescriptor
        let sortAscending  = sortDescriptor.1
        let sortType       = sortDescriptor.0
        let sortTypeName   = pinCentral.nameForSortType( sortType )
        let title          = NSLocalizedString( "LabelText.SortedOn", comment: "Sorted on: " ) + sortTypeName + ( sortAscending ? GlobalConstants.sortAscending : GlobalConstants.sortDescending )
        
        customizeButton( sortButton, with: title )
    }
    
    
    private func launchLocationEditorForPinAt(_ indexPath: IndexPath ) {
//        logVerbose( "[ %@ ]", stringFor( indexPath ) )
        if let locationEditorVC: LocationEditorViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.locationEditor ) as? LocationEditorViewController {

            locationEditorVC.delegate                   = self
            locationEditorVC.indexPathOfItemBeingEdited = indexPath
            locationEditorVC.launchedFromDetailView     = false
            
            navigationController?.pushViewController( locationEditorVC, animated: true )
        }
        else {
            logTrace( "ERROR: Could NOT load LocationEditorViewController!" )
        }
        
    }
    
    
    private func launchSettingsViewController() {
        guard let settingsVC: SettingsViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.settings ) as? SettingsViewController else {
            logTrace( "Error!  Unable to load SettingsViewController!" )
            return
        }

        logTrace()
        navigationController?.pushViewController( settingsVC, animated: true )
    }

    
    private func lastAccessedPin() -> IndexPath {
        guard let lastPinsGuid = userDefaults.object(forKey: UserDefaultKeys.lastAccessedPinsGuid ) as? String else {
            return GlobalIndexPaths.noSelection
        }
        
        for section in 0...pinCentral.pinArrayOfArrays.count - 1 {
            let sectionArray = pinCentral.pinArrayOfArrays[section]
            
            if !sectionArray.isEmpty {
                for row in 0...sectionArray.count - 1 {
                    let pin = sectionArray[row]
                    
                    if pin.guid == lastPinsGuid {
                        return IndexPath(row: row, section: section )
                    }
                    
                }
                
            }
            
        }
        
        return GlobalIndexPaths.noSelection
    }
    
    
    private func loadBarButtonItems() {
//        logTrace()
        var leftBarButtonItems : [UIBarButtonItem] = []
        var rightBarButtonItems: [UIBarButtonItem] = []
        let sortDescriptor     = pinCentral.sortDescriptor
        let sortType           = sortDescriptor.0
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            leftBarButtonItems.append( UIBarButtonItem.init( barButtonSystemItem: .close, target: self, action: #selector( hidePrimaryBarButtonTouched(_: ) ) ) )
        }

        if sortType == SortOptions.byType {
            leftBarButtonItems.append( UIBarButtonItem.init( image: UIImage(named: showAllSections ? "arrowUp" : "arrowDown" ), style: .plain, target: self, action: #selector( showAllBarButtonTouched(_:) ) ) )
        }

        navigationItem.leftBarButtonItems = leftBarButtonItems

        if UIDevice.current.userInterfaceIdiom == .pad {
            rightBarButtonItems.append( UIBarButtonItem.init( image: UIImage(named: "gear" ), style: .plain, target: self, action: #selector( settingsBarButtonTouched(_:) ) ) )
        }
        
        rightBarButtonItems.append( UIBarButtonItem.init( barButtonSystemItem: .add, target: self, action: #selector( addBarButtonItemTouched ) ) )

        navigationItem.rightBarButtonItems = rightBarButtonItems
    }
    
    
    private func presentSortOptions() {
        guard let sortOptionsVC: SortOptionsViewController = iPhoneViewControllerWithStoryboardId(storyboardId: StoryboardIds.sortOptions ) as? SortOptionsViewController else {
            logTrace( "ERROR: Could NOT load SortOptionsViewController!" )
            return
        }
        
        sortOptionsVC.delegate = self
        
        let customSize = CGSize(width: myTableView.frame.width - 20, height: ViewFrameHeights.sortOptions )
        let x          = (view.bounds.width  - customSize.width ) / 2
        let y          = (view.bounds.height - customSize.height) / 2
        
        customDelegate.customFrame = CGRect(x: x, y: y, width: customSize.width, height: customSize.height )
        
        sortOptionsVC.modalPresentationStyle = .custom
        sortOptionsVC.transitioningDelegate  = customDelegate

        present( sortOptionsVC, animated: true, completion: nil )
    }
    
    
    private func promptForCommentForNewFavorite( _ pin: Pin, image: UIImage ) {
        let     alert = UIAlertController.init( title: NSLocalizedString( "AlertTitle.EnterCommentForFavorite", comment: "What would you like to remember about this favorite?" ), message: nil, preferredStyle: .alert )
        
        let saveAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Save", comment: "Save" ), style: .default )
        { ( alertAction ) in
            logTrace( "Save Action" )
            let commentTextField = alert.textFields![0] as UITextField
            let commentText      = commentTextField.text ?? ""
            
            logVerbose( "Saving image with comment[ %@ ]", commentText )
            self.pinCentral.addPhotoToPin( pin, image: image, comment: commentText, self )
        }
        
        let cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel )
        { ( alertAction ) in
            logTrace( "Cancel Action" )
        }
        
        alert.addTextField
        { ( textField ) in
            textField.placeholder = NSLocalizedString( "LabelText.Comment", comment: "Comment" )
        }
        
        alert.addAction( saveAction   )
        alert.addAction( cancelAction )
        
        present( alert, animated: true, completion: nil )
    }
    
    
    private func promptForNavigationAction() {
        logTrace()
        let alert = UIAlertController.init( title: NSLocalizedString( "ButtonTitle.ShowSettings", comment: "Show Settings?" ), message: nil, preferredStyle: .alert )
        
        let settingsAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.OK", comment: "OK" ), style: .default )
        { ( alertAction ) in
            logTrace( "Settings Action" )
            self.launchSettingsViewController()
        }

        let cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel )
        { ( alertAction ) in
            logTrace( "Cancel Action" )
        }

        alert.addAction( settingsAction )
        alert.addAction( cancelAction   )

        present( alert, animated: true, completion: nil )
    }


    private func registerForNotifications() {
        logTrace()
        NotificationCenter.default.addObserver( self, selector: #selector( pinsUpdated( notification: ) ), name: NSNotification.Name( rawValue: Notifications.pinsArrayReloaded ), object: nil )
        NotificationCenter.default.addObserver( self, selector: #selector( ready(       notification: ) ), name: NSNotification.Name( rawValue: Notifications.ready             ), object: nil )
    }
    
    
    private func scrollToLastSelectedItem() {
        let indexPath = lastAccessedPin()
        let sortType  = pinCentral.sortDescriptor.0
        
        if indexPath != GlobalIndexPaths.noSelection {
            if myTableView.numberOfRows(inSection: indexPath.section ) == 0 {
//                logVerbose( "Do nothing! The selected row is in a section[ %d ] that is closed!", indexPath.section )
                return
            }
            
            if sortType != SortOptions.byType {
                myTableView.scrollToRow(at: indexPath, at: .top, animated: true )
            }
            else if showAllSections {
                myTableView.scrollToRow(at: indexPath, at: .top, animated: true )
            }
            else if indexPath.section == selectedSection {
                myTableView.scrollToRow(at: indexPath, at: .top, animated: true )
            }
            
//            logVerbose( "showAllSections[ %@ ]  section[ %d / %d ]", stringFor( showAllSections ), indexPath.section, selectedSection )
        }
        
    }
    
    
}



// MARK: DatePickerViewControllerDelegate Methods

extension ListTableViewController: DatePickerViewControllerDelegate {
    
    func datePickerViewControllerDidSelect(_ datePickerViewController: DatePickerViewController, startingDate: Date, duration: Int ) {
        logVerbose( "startingDate[ %@ ] duration[ %d ]", stringFor( startingDate ), duration )

        var deviceAssetArray = [PHAsset]()
        let endingDate       = Calendar.current.date(byAdding: .day, value: duration, to: startingDate )!
        let fetchOptions     = PHFetchOptions()
        var phAssetArray     = [PHAsset]()

        fetchOptions.sortDescriptors = [ NSSortDescriptor( key: GlobalConstants.sortByCreationDate, ascending: true ) ]
        
        let fetchedAssets = PHAsset.fetchAssets(with: fetchOptions )
        
        fetchedAssets.enumerateObjects { ( phAsset, count, stop ) in
            phAssetArray.append( phAsset )
        }
        
        for asset in phAssetArray {
            if asset.sourceType == .typeUserLibrary {
                if let creationDate = asset.creationDate {
                    let dateCreated = stringFor( creationDate )
                    let dateEnding  = stringFor( endingDate   )
                    let dateStart   = stringFor( startingDate )

                    if dateStart <= dateCreated && dateCreated <= dateEnding {
                        deviceAssetArray.append( asset )
                    }

                }

            }
            
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
            let pin                = self.pinCentral.pinAt( self.selectedPinIndexPath )
            let locationPhotoArray = pin.locationPhotos?.allObjects as! [LocationPhoto]

            self.selectedPinIndexPath = GlobalIndexPaths.noSelection
            
            if deviceAssetArray.count == 0 && locationPhotoArray.count == 0 {
                self.presentAlert( title  : NSLocalizedString( "AlertTitle.NoPhotosFound",   comment: "No Photos Found!" ),
                                   message: NSLocalizedString( "AlertMessage.NoPhotosFound", comment: "There are no photos in your library that were created during that timeframe.  Please try a different starting date/duration." ) )
            }
            else {
                guard let myPhotosViewController: MyPhotosViewController = self.iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.myPhotos ) as? MyPhotosViewController else {
                    logTrace( "ERROR: Could NOT load MyPhotosViewController!" )
                    return
                }
                
                myPhotosViewController.deviceAssetArray = deviceAssetArray
                myPhotosViewController.pin              = pin
                
                self.navigationController?.pushViewController( myPhotosViewController, animated: true )
            }

        }
        
    }

    
}



// MARK: ListTableViewSectionCellDelegate Methods

extension ListTableViewController: ListTableViewSectionCellDelegate {
    
    func listTableViewSectionCell(_ listTableViewSectionCell: ListTableViewSectionCell, section: Int, isOpen: Bool ) {
//        logVerbose( "[ %d ]  isOpen[ %@ ]", section, stringFor( isOpen ) )
        selectedSection = ( selectedSection == section ) ? GlobalConstants.noSelection : section
        showAllSections = false

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            self.buildSectionTitleIndex()
            self.configureSortButtonTitle()
            self.loadBarButtonItems()
            
            self.myTableView.reloadData()

            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) {
                self.scrollToLastSelectedItem()
            }

        }

    }
    
    
}



// MARK: LocationEditorViewControllerDelegate Methods

extension ListTableViewController: LocationEditorViewControllerDelegate {
    
    func locationEditorViewController(_ locationEditorViewController: LocationEditorViewController, didEditLocationData: Bool) {
        logTrace()
    }
    
    
}



// MARK: PinCentralDelegate Methods

extension ListTableViewController: PinCentralDelegate {
    
    func pinCentral(_ pinCentral: PinCentral, didAddPhoto: Bool, to pin: Pin) {
        logVerbose( "[ %@ ]", stringFor( didAddPhoto ) )
        
        if didAddPhoto {
            let formatString = NSLocalizedString( "AlertTitle.PhotoAddedToPin", comment: "Photo added to %@ pin" )
            
            presentAlert( title: String( format: formatString, pin.name! ), message: "" )
        }
        else {
            self.presentAlert( title:   NSLocalizedString( "AlertTitle.Error", comment: "Error!" ),
                               message: NSLocalizedString( "AlertMessage.ImageSaveFailed", comment: "We were unable to save the image you selected." ) )
        }

    }
    
    
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
        logVerbose( "loaded [ %d ] pins", pinCentral.numberOfPinsLoaded )

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {        // Increased delay to allow PinCentral more time to complete the re-sort of all pins.
            self.buildSectionTitleIndex()
            self.configureSortButtonTitle()
            self.loadBarButtonItems()

            self.myTableView.reloadData()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                self.scrollToLastSelectedItem()
            }

        }

    }


}



// MARK: SortOptionsViewControllerDelegate Methods

extension ListTableViewController: SortOptionsViewControllerDelegate {
    
    func sortOptionsViewController(_ sortOptionsViewController: SortOptionsViewController, didSelectNewSortOption: Bool) {
        logTrace()
        let sortType = pinCentral.sortDescriptor.0

        if sortType == SortOptions.byType {
            showAllSections = true
            selectedSection = GlobalConstants.noSelection
        }
        
        configureSortButtonTitle()
        pinCentral.fetchPinsWith( self )
    }
    
    
}



// MARK: UIImagePickerControllerDelegate Methods

extension ListTableViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController ) {
        logTrace()
        if nil != presentedViewController {
            dismiss( animated: true, completion: nil )
        }
        
    }


    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any] ) {
        // Local variable inserted by Swift 4.2 migrator.
        let     info = convertFromUIImagePickerControllerInfoKeyDictionary(info)

        if nil != presentedViewController {
            dismiss( animated: true, completion: nil )
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01 ) {
            if let mediaType = info[self.convertFromUIImagePickerControllerInfoKey( .mediaType )] as? String {
                if "public.image" == mediaType {
                    var     imageToSave: UIImage? = nil
                    
                    if let originalImage: UIImage = info[self.convertFromUIImagePickerControllerInfoKey( .originalImage )] as? UIImage {
                        logTrace( "Found original image" )
                        imageToSave = originalImage
                    }
                    else if let editedImage: UIImage = info[self.convertFromUIImagePickerControllerInfoKey( .editedImage )] as? UIImage {
                        logTrace( "Found edited image" )
                       imageToSave = editedImage
                    }
                    
                    if let myImageToSave = imageToSave {
                        self.promptForCommentForNewFavorite( self.pinForPhoto, image: myImageToSave )
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



    // MARK: Helper function inserted by Swift 4.2 migrator.

    fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
        return Dictionary( uniqueKeysWithValues: input.map { key, value in (key.rawValue, value) } )
    }


    fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
        return input.rawValue
}

            
}



// MARK: - UIPopoverPresentationControllerDelegate method

extension ListTableViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    
}



// MARK: - UITableViewDataSource Methods

extension ListTableViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return ( pinCentral.numberOfPinsLoaded == 0 ) ? 0 : pinCentral.pinArrayOfArrays.count
    }
    
    
    func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        return sectionIndexTitles
    }
    
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell( withIdentifier: Constants.cellID ) else {
            logTrace( "We FAILED to dequeueReusableCell!" )
            return UITableViewCell.init()
        }
        
        let     pinListCell = cell as! ListTableViewControllerCell
        let     pin         = pinCentral.pinAt( indexPath )
        
        pinListCell.initializeWith( pin )
        
        if !pinCentral.stayOffline && pinCentral.dataStoreLocation != .device && pinListCell.imageState == ImageState.missing {
            let descriptor = pinCentral.shortDescriptionFor( pin )
            let _          = pinCentral.fetchMissingDeviceImages( pinListCell.imageName, descriptor, self )
        }
        
        return cell
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if pinCentral.numberOfPinsLoaded == 0 {
            return 0
        }
        
        var numberOfRows = 0
        let sortType     = pinCentral.sortDescriptor.0

        if sortType == SortOptions.byType {
            if showAllSections || ( selectedSection == section ) {
                numberOfRows = pinCentral.pinArrayOfArrays[section].count
            }

        }
        else {
            numberOfRows = pinCentral.pinArrayOfArrays[section].count
        }
        
        return  numberOfRows
    }
    
    
}



    // MARK: UITableViewDelegate Methods

extension ListTableViewController: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return deviceAccessControl.byMe
    }
    
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            logVerbose( "delete pin at row [ %@ ]", stringFor( indexPath ) )
            pinCentral.deletePinAt( indexPath, self )
        }
        
    }
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        logTrace()
        if deviceAccessControl.byMe {
            promptForActionOnCellAt( indexPath )
        }
        
    }
    
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        let sortType = pinCentral.sortDescriptor.0
        
        return sortType == SortOptions.byType ? Constants.sectionHeaderHeight : CGFloat.leastNormalMagnitude
    }
    
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return Constants.rowHeight
    }
    
    
    func tableView(_ tableView: UITableView, sectionForSectionIndexTitle title: String, at index: Int) -> Int {
        let     row = sectionTitleIndexes[index]
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
            tableView.scrollToRow(at: IndexPath(row: row, section: 0), at: .middle , animated: true )
        }
        
        return row
    }
    
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return pinCentral.sectionTitleArray[ section ]
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.sectionHeaderID ) else {
            logTrace( "We FAILED to dequeueReusableCell!" )
            return UITableViewCell.init()
        }
        
        let isOpen     = selectedSection == section
        let headerCell = cell as! ListTableViewSectionCell
        
        headerCell.initializeFor( section, with: pinCentral.sectionTitleArray[ section ], isOpen: isOpen, self )

        return headerCell
    }
    
    
    
    // MARK: UITableViewDelegate Utility Methods

    private func launchImageViewControllerFor(_ imageName: String ) {
        guard let imageViewController: ImageViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.imageViewer ) as? ImageViewController else {
            logTrace( "ERROR: Could NOT load ImageViewController!" )
            return
        }
        
        logVerbose( "[ %@ ]", imageName )
        imageViewController.imageName = imageName
        
        if UIDevice.current.userInterfaceIdiom == .phone {
            navigationController?.pushViewController( imageViewController, animated: true )
        }
        else {
            let navController = UINavigationController(rootViewController: imageViewController )
            
            navController.modalPresentationStyle = .overFullScreen
            present( navController, animated: true )
        }
            
    }
    
    
    private func launchNotesViewController(_ notes: String ) {
        guard let notesViewController: NotesViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.notes ) as? NotesViewController else {
            logTrace( "ERROR: Could NOT load NotesViewController!" )
            return
        }
        
        logTrace()
        notesViewController.editMode     = false
        notesViewController.originalText = notes
        
        navigationController?.pushViewController( notesViewController, animated: true )
    }
    
    
    private func launchPhotoCaptureFor(_ pin: Pin ) {
        logTrace()
        let     imagePickerVC = UIImagePickerController.init()
        
        imagePickerVC.allowsEditing = false
        imagePickerVC.delegate      = self
        imagePickerVC.sourceType    = .camera
        
        imagePickerVC.modalPresentationStyle = .overFullScreen // ( ( .camera == sourceType ) ? .overFullScreen : .popover )
        pinForPhoto = pin

        present( imagePickerVC, animated: true, completion: nil )
        
        imagePickerVC.popoverPresentationController?.delegate                 = self
        imagePickerVC.popoverPresentationController?.permittedArrowDirections = .any
        imagePickerVC.popoverPresentationController?.sourceRect               = myTableView.frame
        imagePickerVC.popoverPresentationController?.sourceView               = myTableView
    }

    
    private func presentDatePickerViewController(_ lastModified: Date ) {
        guard let datePickerViewController: DatePickerViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.datePicker ) as? DatePickerViewController else {
            logTrace( "ERROR: Could NOT load DatePickerViewController!" )
            return
        }
        
        datePickerViewController.delegate     = self
        datePickerViewController.lastModified = lastModified
        
        let customSize     = CGSize(width: ViewFrameWidths.datePicker, height: ViewFrameHeights.datePicker )
        let x              = (view.bounds.width  - customSize.width ) / 2
        let y              = (view.bounds.height - customSize.height) / 2
        let customFrame    = CGRect(x: x, y: y, width: customSize.width, height: customSize.height)
        let customDelegate = CustomTransitioningDelegate( customFrame )
        
        datePickerViewController.modalPresentationStyle = .custom
        datePickerViewController.transitioningDelegate  = customDelegate

        present( datePickerViewController, animated: true, completion: nil )
    }
    
    
    private func promptForActionOnCellAt(_ indexPath: IndexPath ) {
        logTrace()
        let     cell      = myTableView.cellForRow(at: indexPath ) as! ListTableViewControllerCell
        var     imageName = ""
        let     onDevice  = pinCentral.dataStoreLocation == .device
        let     pin       = pinCentral.pinAt( indexPath )
        
        selectedPinIndexPath = indexPath

        let     alert     = UIAlertController.init( title: NSLocalizedString( "AlertTitle.ActionForEntry", comment: "What would you like to do with this entry?" ), message: nil, preferredStyle: .alert )
        
        let editAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Edit", comment: "Edit" ), style: .default )
        { ( alertAction ) in
            logTrace( "Edit Action" )
            self.launchLocationEditorForPinAt( indexPath )
        }
        
        let inspectImageAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.InspectImage", comment: "Inspect Image" ), style: .default )
        { ( alertAction ) in
            logTrace( "Inspect Image Action" )
            self.launchImageViewControllerFor( imageName )
        }
        
        let addPhotoAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.AddPhoto", comment: "Add Photo" ), style: .default )
        { ( alertAction ) in
            logTrace( "Add Photo Action" )
            self.launchPhotoCaptureFor( pin )
        }
        
        let showMyPhotosAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.ShowMyPhotos", comment: "Show My Photos" ), style: .default )
        { ( alertAction ) in
            logTrace( "Show My Photos Action" )
            
            if PHPhotoLibrary.authorizationStatus() != .authorized {
                self.presentAlert( title  : NSLocalizedString( "AlertTitle.AuthorizationRequired",       comment: "Authorization Required!" ),
                                   message: NSLocalizedString( "AlertMessage.PhotoLibraryNotAuthorized", comment: "This app requires your authorization to access the photo library on this device.  Please update Settings to allow us to view your photos." ) )
            }
            else {
                DispatchQueue.main.asyncAfter(deadline: .now() ) {
                    self.presentDatePickerViewController( pin.lastModified! )
                }
                
            }

        }
        
        let showNotesAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.ShowNotes", comment: "Show Notes" ), style: .default )
        { ( alertAction ) in
            logTrace( "Show Notes Action" )
            self.launchNotesViewController( pin.notes! )
        }
        
        let showOnMapAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.ShowOnMap", comment: "Show on Map" ), style: .default )
        { ( alertAction ) in
            logTrace( "Show on Map Action" )
            let     userInfoDictionary = [ UserInfo.latitude: pin.latitude, UserInfo.longitude: pin.longitude ]
            
            
            if .phone == UIDevice.current.userInterfaceIdiom {
                self.tabBarController?.selectedIndex = 1
            }
            
            DispatchQueue.main.asyncAfter( deadline: ( .now() + 0.1 ) ) {
                NotificationCenter.default.post( name: NSNotification.Name( rawValue: Notifications.centerMap ), object: self, userInfo: userInfoDictionary )
            }
            
        }
        
        let cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel )
        { ( alertAction ) in
            logTrace( "Cancel Action" )
        }

        alert.addAction( editAction )
        
        if cell.imageState == ImageState.loaded  {
            alert.addAction( inspectImageAction )

            if !onDevice {
                if let name = pin.imageName {
                    imageName = name
                }
                    
            }
            
        }
        
        if onDevDevice {
            alert.addAction( addPhotoAction )

            if let _ = pin.lastModified {
                alert.addAction( showMyPhotosAction )
            }

        }
        
        if let _ = pin.notes {
            alert.addAction( showNotesAction )
        }
        
        alert.addAction( showOnMapAction )
        alert.addAction( cancelAction    )
        
        present( alert, animated: true, completion: nil )
    }
    

    
    // MARK: UIImageWrite Completion Methods
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer ) {
        let message = error == nil ? NSLocalizedString( "AlertMessage.PhotoSaved",      comment: "Image saved to photo album"  ) :
                                     NSLocalizedString( "AlertMessage.PhotoSaveFailed", comment: "Save to photo album failed!" )
        let title   = error == nil ? NSLocalizedString( "AlertTitle.Success", comment: "Success!" ) : NSLocalizedString( "AlertTitle.Error", comment: "Error!" )
        
        presentAlert(title: title, message: message )
    }


}
