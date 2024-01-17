//
//  ListTableViewController.swift
//  MyPins
//
//  Created by Clint Shank on 3/12/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit
import MapKit



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
        static let imageViewer      = "ImageViewController"
        static let locationEditor   = "LocationEditorViewController"
        static let map              = "MapViewController"
        static let sortOptions      = "SortOptionsViewController"
    }
    
    private let deviceAccessControl = DeviceAccessControl.sharedInstance
    private let pinCentral          = PinCentral.sharedInstance
    private var sectionIndexTitles  : [String] = []
    private var sectionTitleIndexes : [Int]    = []
    private var showAllSections     = true
    private let sortOptions         = [SortOptions.byDateLastModified,     SortOptions.byName,     SortOptions.byType    ]
    private let sortOptionNames     = [SortOptionNames.byDateLastModified, SortOptionNames.byName, SortOptionNames.byType]
    private let userDefaults        = UserDefaults.standard
    
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
        logTrace()
        // We get these when we fail to load an image... no action is required
    }


    
    // MARK: Target / Action Methods
    
    @IBAction @objc func addBarButtonItemTouched( barButtonItem: UIBarButtonItem ) {
        logTrace()
        launchLocationEditorForPinAt( GlobalIndexPaths.newPin )
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
        
        sortButton.setTitle( title, for: .normal )
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
        let sortDescriptor = pinCentral.sortDescriptor
        let sortType       = sortDescriptor.0
        
        if sortType == SortOptions.byType {
            navigationItem.leftBarButtonItem = UIBarButtonItem.init( image: UIImage(named: showAllSections ? "arrowUp" : "arrowDown" ), style: .plain, target: self, action: #selector( showAllBarButtonTouched(_:) ) )
        }
        else {
            navigationItem.leftBarButtonItem = nil
        }
        
        navigationItem.rightBarButtonItem = UIBarButtonItem.init( barButtonSystemItem: .add, target: self, action: #selector( addBarButtonItemTouched ) )
    }
    
    
    private func presentSortOptions() {
        guard let sortOptionsVC: SortOptionsViewController = iPhoneViewControllerWithStoryboardId(storyboardId: StoryboardIds.sortOptions ) as? SortOptionsViewController else {
            logTrace( "ERROR: Could NOT load SortOptionsViewController!" )
            return
        }
        
        sortOptionsVC.delegate = self
        
        sortOptionsVC.modalPresentationStyle = .popover
        sortOptionsVC.popoverPresentationController!.delegate                 = self
        sortOptionsVC.popoverPresentationController?.permittedArrowDirections = .any
        sortOptionsVC.popoverPresentationController?.sourceRect               = sortButton.frame
        sortOptionsVC.popoverPresentationController?.sourceView               = sortButton
        
        present( sortOptionsVC, animated: true, completion: nil )
    }
    
    
    private func registerForNotifications() {
        logTrace()
        NotificationCenter.default.addObserver( self, selector: #selector( self.pinsUpdated( notification: ) ), name: NSNotification.Name( rawValue: Notifications.pinsArrayReloaded ), object: nil )
        NotificationCenter.default.addObserver( self, selector: #selector( self.ready(       notification: ) ), name: NSNotification.Name( rawValue: Notifications.ready             ), object: nil )
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
            else if indexPath.section == selectedSection + 1 {
                myTableView.scrollToRow(at: indexPath, at: .top, animated: true )
            }
            
//            logVerbose( "showAllSections[ %@ ]  section[ %d / %d ]", stringFor( showAllSections ), indexPath.section, selectedSection )
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
        buildSectionTitleIndex()
        configureSortButtonTitle()
        loadBarButtonItems()

        myTableView.reloadData()

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) {
            self.scrollToLastSelectedItem()
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



// MARK: - UIPopoverPresentationControllerDelegate method

extension ListTableViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    
}



// MARK: - UITableViewDataSource Methods

extension ListTableViewController: UITableViewDataSource {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return pinCentral.numberOfPinsLoaded == 0 ? 0 : pinCentral.pinArrayOfArrays.count
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
        
        return cell
    }
    
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if pinCentral.numberOfPinsLoaded == 0 {
            return 0
        }
        
        let adjustedSection = section - 1
        var numberOfRows    = 0
        let sortType        = pinCentral.sortDescriptor.0

        if sortType == SortOptions.byType {
            if showAllSections || ( selectedSection == adjustedSection ) {
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
        if section == 0 {
            return CGFloat.leastNormalMagnitude
        }
        
        let sortType = pinCentral.sortDescriptor.0
        
        return sortType == SortOptions.byType ? Constants.sectionHeaderHeight : tableView.sectionHeaderHeight
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
        return titleForHeaderIn( section )
    }
    
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section == 0 {
            logTrace( "Ignorning table header" )
            
            return UIView()
        }
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Constants.sectionHeaderID ) else {
            logTrace( "We FAILED to dequeueReusableCell!" )
            return UITableViewCell.init()
        }
        
        let adjustedSection = section - 1
        let isOpen          = selectedSection == section
        let headerCell      = cell as! ListTableViewSectionCell
        
        headerCell.initializeFor( adjustedSection, with: titleForHeaderIn( section ), isOpen: isOpen, self )
        
        return headerCell
    }
    
    
    
    // MARK: UITableViewDelegate Utility Methods

    private func launchImageViewControllerFor(_ imageName: String ) {
        guard let imageViewController: ImageViewController = iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.imageViewer ) as? ImageViewController else {
            logTrace( "ERROR: Could NOT load ImageViewController!" )
            return
        }
        
        logVerbose( "imageName[ %@ ]", imageName )
        imageViewController.imageName = imageName
        navigationController?.pushViewController( imageViewController, animated: true )
    }
    
    
    private func promptForActionOnCellAt(_ indexPath: IndexPath ) {
        logTrace()
        let     cell      = myTableView.cellForRow(at: indexPath ) as! ListTableViewControllerCell
        var     imageName = ""
        let     onDevice  = pinCentral.dataStoreLocation == .device
        let     pin       = pinCentral.pinAt( indexPath )
        var     thumbnail = GlobalConstants.thumbNailPrefix

        let     alert     = UIAlertController.init( title: NSLocalizedString( "AlertTitle.ActionForEntry", comment: "What would you like to do with this entry?" ), message: nil, preferredStyle: .alert)
        
        let editAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Edit", comment: "Edit" ), style: .default )
        { ( alertAction ) in
            logTrace( "Edit Action" )
            self.launchLocationEditorForPinAt( indexPath )
        }
        
        let inspectImageAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.InspectImage", comment: "Inspect Image" ), style: .default )
        { ( alertAction ) in
            guard let imageViewController: ImageViewController = self.iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.imageViewer ) as? ImageViewController else {
                logTrace( "ERROR: Could NOT load ImageViewController!" )
                return
            }
            
            logVerbose( "Inspect Image Action ... [ %@ ]", imageName )
            imageViewController.imageName = imageName
            self.navigationController?.pushViewController( imageViewController, animated: true )
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
        
        let     saveImageAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.SaveImageToLibrary", comment: "Save Image to Photo Library" ), style: .default )
        { ( alertAction ) in
            logTrace( "Save Image Action" )
            let     thisImage = cell.myImageView.image!
            
            UIImageWriteToSavedPhotosAlbum( thisImage, self, #selector( self.image(_ :didFinishSavingWithError:contextInfo: ) ), nil )
        }

        let uploadAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.UploadImage", comment: "Upload Image" ), style: .default )
        { ( alertAction ) in
            logTrace( "Upload Action" )
            self.pinCentral.uploadImageNamed( imageName, self )
            self.pinCentral.uploadImageNamed( thumbnail, self )
        }
        
        let cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel )
        { ( alertAction ) in
            logTrace( "Cancel Action" )
        }

        alert.addAction( editAction      )
        alert.addAction( showOnMapAction )

        if cell.imageState == ImageState.loaded  {
            alert.addAction( inspectImageAction )
            alert.addAction( saveImageAction    )

            if !onDevice {
                if let name = pin.imageName {
                    imageName  = name
                    thumbnail += name
                    
                    alert.addAction( uploadAction )
                }
                    
            }
            
        }
        
        alert.addAction( cancelAction )
        
        present( alert, animated: true, completion: nil )
    }
    

    private func titleForHeaderIn(_ section: Int ) -> String {
        if section == 0 {
            return ""       // Table Header
        }
        
        let adjustedSection = section - 1
        let sortDescriptor  = pinCentral.sortDescriptor
        let sortAscending   = sortDescriptor.1
        let targetSection   = sortAscending ? adjustedSection : ( ( pinCentral.colorArray.count - 1 ) - adjustedSection )
        
        return pinCentral.colorArray[targetSection].descriptor!
    }
    
    
    
    // MARK: UIImageWrite Completion Methods
    
    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer ) {
        let message = error == nil ? NSLocalizedString( "AlertMessage.PhotoSaved",      comment: "Image saved to photo album"  ) :
                                     NSLocalizedString( "AlertMessage.PhotoSaveFailed", comment: "Save to photo album failed!" )
        let title   = error == nil ? NSLocalizedString( "AlertTitle.Success", comment: "Success!" ) : NSLocalizedString( "AlertTitle.Error", comment: "Error!" )
        
        presentAlert(title: title, message: message )
    }


}
