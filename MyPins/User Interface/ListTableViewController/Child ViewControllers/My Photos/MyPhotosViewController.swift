//
//  MyPhotosViewController.swift
//  MyPins
//
//  Created by Clint Shank on 4/2/25.
//  Copyright © 2025 Omni-Soft, Inc. All rights reserved.
//

import UIKit
import Photos



class MyPhotosViewController: UIViewController {
    
    
    // MARK: Public Variables
    
    var deviceAssetArray  = [PHAsset]()                 // Provided by ListTableVC
    var isOverFullScreen  = false
    var myParentVC        : MyPhotosViewController!     // Used for full-screen presentation
    var pin               : Pin!                        // Provided by ListTableVC
    var selectedIndexPath = IndexPath( row: 0, section: 0 )
    
    @IBOutlet weak var backArrrowButton      : UIButton!
    @IBOutlet weak var commentButton         : UIButton!
    @IBOutlet weak var downloadButton        : UIButton!
    @IBOutlet weak var forwardArrowButton    : UIButton!
    @IBOutlet weak var favoriteButton        : UIButton!
    @IBOutlet weak var myCollectionView      : UICollectionView!
    @IBOutlet weak var myImageView           : UIImageView!
    @IBOutlet      var panGestureRecognizer  : UIPanGestureRecognizer!
    @IBOutlet      var pinchGestureRecognizer: UIPinchGestureRecognizer!
    @IBOutlet      var tapGestureRecognizer  : UITapGestureRecognizer!
    
    
    
    // MARK: Private Variables
    
    private enum FavoriteAction {
        case add
        case comment
        case delete
        case none
    }
    
    private enum VideoStatus {
        case notLoaded
        case loaded
        case running
        case paused
        case ended
    }
    
    private struct Constants {
        static let cellID   = "MyPhotosCollectionViewCell"
        static let headerID = "MyPhotosSectionHeaderCollectionViewCell"
    }
    
    private struct StoryboardIds {
        static let myPhotos = "MyPhotosViewController"
    }
    
    private var favoriteAction     : FavoriteAction = .none
    private var fetchedMediaArray  = [( LocationPhoto, Data, Bool )]()
    private var imageNameArray     = [String]()
    private let myImageManager     = PHImageManager.default()
    private let notificationCenter = NotificationCenter.default
    private var section0Open       = true
    private var section1Open       = false
    private var originalAssetArray = [PHAsset]()
    private let pinCentral         = PinCentral.sharedInstance
    private var playerLayer        : AVPlayerLayer!
    private var videoStatus        = VideoStatus.loaded
    private let userDefaults       = UserDefaults.standard
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString( "Title.MyPhotos", comment: "My Photos" )
        
        myCollectionView.layer.borderColor = UIColor.black.cgColor
        myCollectionView.layer.borderWidth = 3.0
        
        myImageView.isUserInteractionEnabled = true
        
        commentButton.isHidden = true
        commentButton.setTitleColor( .blue, for: .normal )
        
        downloadButton.isHidden = !onDevDevice
        favoriteButton.isHidden = !onDevDevice
        favoriteButton.setImage( UIImage( systemName: "heart" ), for: .normal )
        
        panGestureRecognizer  .delegate = self
        pinchGestureRecognizer.delegate = self
        tapGestureRecognizer  .delegate = self
        
        originalAssetArray = deviceAssetArray
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        reloadDataArrays()
        loadBarButtonItems()

        DispatchQueue.main.asyncAfter(wallDeadline: .now() + 0.5 ) {
            self.populateMyImageViewUsing( self.selectedIndexPath )
            self.myCollectionView.reloadData()

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
//                self.myCollectionView.scrollToItem(at: self.selectedIndexPath, at: .centeredHorizontally, animated: true )
            }
            
        }
        
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        logTrace()
        super.viewWillDisappear(animated)
        
        notificationCenter.removeObserver( self )
    }
    
    
    override func viewWillTransition(to size: CGSize, with coordinator: any UIViewControllerTransitionCoordinator) {
        logTrace()
        if playerLayer != nil {
            playerLayer.removeFromSuperlayer()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                self.playerLayer.frame = self.myImageView.layer.bounds
                self.myImageView.layer.addSublayer( self.playerLayer )
            }
            
        }
        
    }
    
    
    
    // MARK: NSNotification Methods
    
    @objc func playerDidFinishPlaying( notification: NSNotification ) {
        logTrace()
        videoStatus = .ended
        loadBarButtonItems()
    }
    
    
    
    // MARK: Target / Action Methods
    
    @IBAction func backArrowButtonTouched(_ sender: UIButton) {
//        logTrace()
        var senderIsHidden = false
        
        if selectedIndexPath.section == 0 {  // Photo Assets
            if selectedIndexPath.row > 1 {
                changeSelectedCellTo( IndexPath( row: selectedIndexPath.row - 1, section: 0 ) )
                populateMyImageViewUsing( selectedIndexPath )
                forwardArrowButton.isHidden = false
                senderIsHidden = ( selectedIndexPath.row == 1 )
           }
            else {
                senderIsHidden = true
            }

        }
        else {  // Favorites
            if selectedIndexPath.row > 1 {
                changeSelectedCellTo( IndexPath( row: selectedIndexPath.row - 1, section: 1 ) )
                populateMyImageViewUsing( selectedIndexPath )
                forwardArrowButton.isHidden = false
                senderIsHidden = ( selectedIndexPath.row == 1 )
            }
            else if deviceAssetArray.count > 1 {
                changeSelectedCellTo( IndexPath( row: deviceAssetArray.count - 1, section: selectedIndexPath.section - 1 ) )
                populateMyImageViewUsing( selectedIndexPath )
                forwardArrowButton.isHidden = false
                senderIsHidden = ( selectedIndexPath.row == 1 )
            }
            else {
                senderIsHidden = true
            }

        }

        sender.isHidden = senderIsHidden
    }
    
    
    @IBAction func commentButtonTouched(_ sender: UIButton) {
        logTrace()
        promptForUpdateToCommentForFavorite()       // Only avaiable for Favorites
    }
    
    
    @IBAction func downloadButtonTouched(_ sender: UIButton) {
        logTrace()
        promptToSaveToPhotoAlbum()
    }
    
    
    @IBAction func doubleTapGestureRecognizerFired(_ sender: UITapGestureRecognizer) {
        logTrace()
        populateMyImageViewUsing( selectedIndexPath )
    }
    
    
    @IBAction func favoriteButtonTouched(_ sender: UIButton) {
        logTrace()
        if favoriteAction != .none {
            logTrace( "we're busy right now ... do nothing" )
            return
        }
        
        if selectedIndexPath.section == 0 {
            promptForCommentForNewFavorite()
        }
        else {
            promptToRemoveFromFavorites()
        }
        
    }
    
    
    @IBAction func forwardArrowButtonTouched(_ sender: UIButton) {
//        logTrace()
        var senderIsHidden = false
        
        if selectedIndexPath.section == 0 {     // Device Assets
            if selectedIndexPath.row + 1 < deviceAssetArray.count {
                changeSelectedCellTo( IndexPath( row: selectedIndexPath.row + 1, section: selectedIndexPath.section ) )
                populateMyImageViewUsing( selectedIndexPath )
                backArrrowButton.isHidden = false
                senderIsHidden = ( selectedIndexPath.row == deviceAssetArray.count - 1 )
            }
            else if fetchedMediaArray.count > 1 {
                changeSelectedCellTo( IndexPath( row: 1, section: 1 ) )
                populateMyImageViewUsing( selectedIndexPath )
                backArrrowButton.isHidden = false
            }
            else {
                backArrrowButton.isHidden = false
                senderIsHidden = true
            }

        }
        else {      // Favorites
            if selectedIndexPath.row + 1 < fetchedMediaArray.count {
                changeSelectedCellTo( IndexPath( row: selectedIndexPath.row + 1, section: selectedIndexPath.section ) )
                populateMyImageViewUsing( selectedIndexPath )
                backArrrowButton.isHidden = false
                senderIsHidden = ( selectedIndexPath.row == fetchedMediaArray.count - 1 )
           }
            else {
                senderIsHidden = true
            }

        }
        
        sender.isHidden = senderIsHidden
    }
    
    
    @IBAction func fullScreenBarButtonTouched(_ sender : UIBarButtonItem ) {
        logTrace()
        if isOverFullScreen {
            myParentVC.selectedIndexPath = selectedIndexPath
            dismiss( animated: true )
        }
        else {
            presentMyselfFullscreen()
        }
        
    }
    
    
    @IBAction func backBarButtonTouched(_ sender: UIBarButtonItem ) {
        logTrace()
        if isOverFullScreen {
            myParentVC.selectedIndexPath = selectedIndexPath
            dismiss( animated: true )
        }
        else {
            navigationController?.popViewController(animated: true )
        }
        
    }
    
    
    @IBAction func panGestureRecognizerTouched(_ sender: UIPanGestureRecognizer) {
        let translation = sender.translation(in: self.view)
        
        // Move the image view's center based on the translation
        if let viewToMove = sender.view {
            viewToMove.center = CGPoint( x: viewToMove.center.x + translation.x, y: viewToMove.center.y + translation.y )
        }
        
        // Reset the translation to zero to prevent compounding movements
        sender.setTranslation(CGPoint.zero, in: self.view)
    }
    
    
    @IBAction func pinchGestureRecognizerTouched(_ gestureRecognizer: UIPinchGestureRecognizer) {
        if gestureRecognizer.state == .began || gestureRecognizer.state == .changed {
            gestureRecognizer.view?.transform = ( gestureRecognizer.view?.transform.scaledBy( x: gestureRecognizer.scale, y: gestureRecognizer.scale ) )!
            gestureRecognizer.scale           = 1.0
        }
        
    }
    
    
    @IBAction func playPauseBarButtonItemTouched(_ sender: UIBarButtonItem ) {
        logTrace()
        if videoStatus == .running {
            playerLayer.player?.pause()
            videoStatus = .paused
        }
        else {
            playerLayer.player?.play()
            videoStatus = .running
        }
        
        loadBarButtonItems()
    }
    
    
    @IBAction func rewindBarButtonItemTouched(_ sender: UIBarButtonItem ) {
        logTrace()
        playerLayer.player?.seek(to: .zero )    // rewinds
        
        videoStatus = .loaded
        loadBarButtonItems()
    }
    
    
    
    // MARK: Utility Methods
    
    private func adjustSetupOnDevDevice() {
        // This method is called after we have inserted header placeholder cells at the beginning of arrays which are NOT empty
        section0Open = !deviceAssetArray .isEmpty
        section1Open = !fetchedMediaArray.isEmpty
        
        if section1Open {
            section0Open = false
        }
        
        if section0Open {
            if favoriteAction == .delete {     // We just deleted the last favorite
                selectedIndexPath = IndexPath( row: 1, section: 0 )
            }
            else if selectedIndexPath.row == 0 {
                selectedIndexPath = IndexPath( row: 1, section: 0 )
            }
            
        }
        else if section1Open {
            if favoriteAction == .add {         // New favorites are added at the end of the array
                selectedIndexPath = IndexPath( row: fetchedMediaArray.count - 1, section: 1 )
            }
            else if favoriteAction == .delete {
                let adjacentRow = ( selectedIndexPath.row == 1 ) ? 1 : ( selectedIndexPath.row - 1 )
                
                selectedIndexPath = IndexPath( row: adjacentRow, section: 1 )
            }
            else if selectedIndexPath.row == 0 {
                selectedIndexPath = IndexPath( row: 1, section: 1 )
            }
            
        }

        backArrrowButton.isHidden = false
        
        if selectedIndexPath.section == 0 {
            backArrrowButton  .isHidden = selectedIndexPath.row == 1                                // the header for favorites will not be present if there are no favorites
            forwardArrowButton.isHidden = ( selectedIndexPath.row == deviceAssetArray.count - 1 ) && fetchedMediaArray.count == 0
        }
        else {
            backArrrowButton  .isHidden = selectedIndexPath.row == 1  && deviceAssetArray.count == 1
            forwardArrowButton.isHidden = selectedIndexPath.row == fetchedMediaArray.count - 1
        }
        
        logVerbose( "section0 is %@[ %d ]  section1 is %@[ %d ]  selectedIndexPath[ %@ ]", ( section0Open ? "Open" : "Closed" ), deviceAssetArray.count,
                    ( section1Open ? "Open" : "Closed" ), fetchedMediaArray.count, stringFor( selectedIndexPath ) )
    }
    
    
    private func loadBarButtonItems() {
//        logTrace()
        var leftBarButtonItems  = [UIBarButtonItem]()
        var rightBarButtonItems = [UIBarButtonItem]()
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            let imageName = isOverFullScreen ? "exitFullScreen" : "enterFullScreen"
            
            rightBarButtonItems.append( UIBarButtonItem.init( image: UIImage(named: imageName ), style: .plain, target: self, action: #selector( fullScreenBarButtonTouched(_:) ) ) )
        }
        
        leftBarButtonItems.append( backBarButtonItem( #selector( backBarButtonTouched(_:) ) ) )
        
        if let _ = playerLayer {
            switch videoStatus {
            case .ended:            leftBarButtonItems .append( UIBarButtonItem(barButtonSystemItem: .rewind, target: self, action: #selector( rewindBarButtonItemTouched(_:   ) ) ) )
            case .loaded, .paused:  rightBarButtonItems.append( UIBarButtonItem(barButtonSystemItem: .play,   target: self, action: #selector( playPauseBarButtonItemTouched(_:) ) ) )
            case .running:          rightBarButtonItems.append( UIBarButtonItem(barButtonSystemItem: .pause,  target: self, action: #selector( playPauseBarButtonItemTouched(_:) ) ) )
            default:                break
            }
            
        }
        
        navigationItem.leftBarButtonItems  = leftBarButtonItems
        navigationItem.rightBarButtonItems = rightBarButtonItems
    }
    
    
    private func populateMyImageViewUsing(_ indexPath: IndexPath ) {
        if indexPath.section == 0 {
            populateMyImageViewUsingAssetAt( indexPath )
        }
        else {
            populateMyImageViewUsingMediaAt( indexPath )
        }
        
    }
    
    
    private func populateMyImageViewUsingAssetAt(_ indexPath: IndexPath ) {
//        logVerbose( "[ %@ ]", stringFor( indexPath ) )
        let row     = indexPath.row
        let phAsset = deviceAssetArray[row]
        
        setCurrentCellSelection( indexPath )
        
        if let _ = playerLayer {
            playerLayer.removeFromSuperlayer()
            playerLayer  = nil
        }
        
        commentButton .isHidden = true
        downloadButton.isHidden = true
        
        myImageView.image     = UIImage()
        myImageView.transform = .identity
        videoStatus           = .notLoaded
        
        notificationCenter.removeObserver( self )
        
        if phAsset.mediaType == .image {
            let targetSize = CGSize( width: myImageView.bounds.width, height: myImageView.bounds.height )
            
            pinCentral.getImageFrom( phAsset, targetSize: targetSize, isThumbnail: false, delegate: self )
            favoriteButton.setImage( UIImage( systemName: "heart" ), for: .normal )
        }
        else if phAsset.mediaType == .video {
            let videoRequestOptions = PHVideoRequestOptions()
            
            videoRequestOptions.deliveryMode           = .automatic
            videoRequestOptions.isNetworkAccessAllowed = false
            
            myImageManager.requestPlayerItem(forVideo: phAsset, options: videoRequestOptions, resultHandler: { playerItem, info in
                let player = AVPlayer( playerItem: playerItem )
                
                self.playerLayer = AVPlayerLayer( player: player )
                
                // Since myImageView has constraints on it that will automatically reposition and resize itself,
                // we attach the playerLayer to it so it can just tag along for the ride
                self.playerLayer.videoGravity = AVLayerVideoGravity.resizeAspect
                self.playerLayer.frame        = self.myImageView.layer.bounds
                
                self.myImageView.layer.addSublayer( self.playerLayer )
                self.videoStatus = .loaded
                self.notificationCenter.addObserver(self, selector: #selector( self.playerDidFinishPlaying( notification: ) ), name: AVPlayerItem.didPlayToEndTimeNotification, object: playerItem)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 ) {
                    self.loadBarButtonItems()
                }
                
            })
            
            favoriteButton.setImage( UIImage( systemName: "heart" ), for: .normal )
        }
        else {
            logVerbose( "ERROR!!! We don't support this style[ %@ ]", phAsset.stringForPlaybackStyle() )
        }
        
    }
    
    
    private func populateMyImageViewUsingMediaAt(_ indexPath: IndexPath ) {
        let mediaTuple    = fetchedMediaArray[indexPath.row]
        let locationPhoto = mediaTuple.0
        let mediaData     = mediaTuple.1
        let dataLoaded    = mediaTuple.2
        
//        logVerbose( "[ %@ ] - [ %@ ] was loaded [ %@ ]", stringFor( indexPath ), locationPhoto.filename!, stringFor( dataLoaded ) )
        setCurrentCellSelection( indexPath )
        
        if let _ = playerLayer {
            playerLayer.removeFromSuperlayer()
            playerLayer  = nil
        }
        
        myImageView.image     = UIImage( named: GlobalConstants.noImage )
        myImageView.transform = .identity
        videoStatus           = .notLoaded
        
        notificationCenter.removeObserver( self )
        
        if !dataLoaded {
            myImageView.image = UIImage( named: GlobalConstants.missingImage )
            logVerbose( "ERROR!!!  No data for [ %@ ]", locationPhoto.filename! )
            return
        }
        
        if locationPhoto.isVideo  {
            let fileManager          = FileManager.default
            let picturesDirectoryUrl = URL( string: pinCentral.pictureDirectoryPath() )!
            let tempFileName         = UUID().uuidString
            let currentVideoUrl      = picturesDirectoryUrl.appendingPathComponent( tempFileName )
            let player               = AVPlayer(url: URL( fileURLWithPath: currentVideoUrl.path ) )
            let playerLayer          = AVPlayerLayer( player: player )
            let videoCached          = fileManager.createFile( atPath: currentVideoUrl.path, contents: mediaData, attributes: nil )
            
            // Since myImageView has constraints on it that will automatically reposition and resize itself,
            // we attach the playerLayer to it so it can just tag along for the ride
            playerLayer.videoGravity = AVLayerVideoGravity.resizeAspect
            playerLayer.frame        = myImageView.layer.bounds
            
            myImageView.layer.addSublayer( playerLayer )
            
            if videoCached {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 ) {
                    do {
                        try fileManager.removeItem(at: currentVideoUrl )
//                        logTrace( "deleted temporary file",  )
                    }
                    catch let error as NSError {
                        logVerbose( "ERROR!!!  [ %@ ]\n    [ %@ ]", error.localizedDescription, currentVideoUrl.path )
                    }
                    
                }
                
            }
            else {
                logVerbose( "ERROR!!!  could not cache video[ %@ ]", currentVideoUrl.path )
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 ) {
                self.loadBarButtonItems()
            }
            
        }
        else {  // Image file
            let result       = self.pinCentral.fetchFromDiskImageFileNamed( locationPhoto.filename! )
            let imageLoaded  = result.0

//            logVerbose( "imageLoaded[ %@ ] named[ %@ ]", stringFor( imageLoaded ), locationPhoto.filename! )
            myImageView.image = imageLoaded ? UIImage(data: result.1 ) : UIImage( named: GlobalConstants.missingImage )
        }
        
        let photoComment = locationPhoto.comment ?? ""
        let buttonTitle  = ( photoComment != "" ) ? photoComment : NSLocalizedString( "ButtonTitle.Comments", comment: "Comments" )

        commentButton .setTitle( buttonTitle, for: .normal )
        commentButton .isHidden = false
        downloadButton.isHidden = false

        favoriteButton.setImage( UIImage( systemName: "heart.fill" ), for: .normal )
    }
    
    
    private func presentMyselfFullscreen() {
        guard let myPhotosViewController: MyPhotosViewController = self.iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.myPhotos ) as? MyPhotosViewController else {
            logTrace( "ERROR: Could NOT load MyPhotosViewController!" )
            return
        }
        
        logTrace()
        myPhotosViewController.deviceAssetArray     = originalAssetArray
        myPhotosViewController.selectedIndexPath    = selectedIndexPath
        myPhotosViewController.isOverFullScreen     = true
        myPhotosViewController.myParentVC           = self
        myPhotosViewController.view.backgroundColor = .lightGray
        
        let navigationController = UINavigationController.init(rootViewController: myPhotosViewController )
        
        navigationController.modalPresentationStyle        = .fullScreen
        navigationController.navigationBar.backgroundColor = .lightGray
        
        present( navigationController, animated: true )
    }
    
    
    private func processSwipeOnDevDevice(_ sender: UISwipeGestureRecognizer ) {
        var needToUpdate = true
        
        if sender.direction == .left {      // Swipe Left
            if selectedIndexPath.section == 0 {
                if selectedIndexPath.row + 1 < deviceAssetArray.count {
                    selectedIndexPath = IndexPath( row: selectedIndexPath.row + 1, section: selectedIndexPath.section )
                }
                else {  // Finished with section 0...
                    if fetchedMediaArray.count > 0 {
                        selectedIndexPath = IndexPath(row: 1, section: selectedIndexPath.section + 1 )
                    }
                    else {
                        needToUpdate = false
                    }
                    
                }
                
            }
            else {      // Section 1
                if selectedIndexPath.row + 1 < fetchedMediaArray.count {
                    selectedIndexPath = IndexPath( row: selectedIndexPath.row + 1, section: selectedIndexPath.section )
                }
                else {
                    needToUpdate = false
                }
                
            }
                
        }
        else {      // Swipe Right
            if selectedIndexPath.row - 1 > 0 {
                selectedIndexPath = IndexPath( row: selectedIndexPath.row - 1, section: selectedIndexPath.section )
            }
            else if selectedIndexPath.section == 1 {
                selectedIndexPath = IndexPath( row: deviceAssetArray.count - 1, section: 0 )
                section0Open = true
            }
            else {
                needToUpdate = false
            }
                
        }
        
        if needToUpdate {
            let currentlySelectedCell = myCollectionView.cellForItem( at: selectedIndexPath )
            
            populateMyImageViewUsing( selectedIndexPath )
            currentlySelectedCell?.isSelected = false
            myCollectionView.reloadData()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 ) {
                self.myCollectionView.scrollToItem(at: self.selectedIndexPath, at: .centeredHorizontally, animated: true )
            }
                
        }

    }
    
    
    private func promptForCommentForNewFavorite() {
        logTrace()
        let     alert = UIAlertController.init( title: NSLocalizedString( "AlertTitle.EnterCommentForFavorite", comment: "What would you like to remember about this favorite?" ), message: nil, preferredStyle: .alert )
        
        let saveAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Save", comment: "Save" ), style: .default )
        { ( alertAction ) in
            logTrace( "Save Action" )
            let commentTextField = alert.textFields![0] as UITextField
            let commentText      = commentTextField.text ?? ""
            let selectedAsset    = self.deviceAssetArray[self.selectedIndexPath.row]
            
            self.favoriteAction = .add
            self.pinCentral.addAssetMediaTo( self.pin, phAsset: selectedAsset, comment: commentText, self )
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
    
    
    private func promptToSaveToPhotoAlbum() {
        let     alert = UIAlertController.init( title: NSLocalizedString( "AlertTitle.SaveToPhotoLibrary", comment: "Would you like to save this image to your Photo Library?" ), message: nil, preferredStyle: .alert )
        
        let     yesAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Yes", comment: "Yes" ), style: .default )
        { ( alertAction ) in
            logTrace( "Yes Action" )
            let imageToSave = self.myImageView.image!
            
            UIImageWriteToSavedPhotosAlbum( imageToSave, self, #selector( MyPhotosViewController.image(_ :didFinishSavingWithError:contextInfo: ) ), nil )
        }
        
        let     noAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.No", comment: "No!" ), style: .cancel, handler: nil )
        
        alert.addAction( yesAction )
        alert.addAction( noAction  )
        
        present( alert, animated: true, completion: nil )
    }
    
    
    private func promptForUpdateToCommentForFavorite() {
        logTrace()
        let mediaTuple    = self.fetchedMediaArray[self.selectedIndexPath.row]
        let locationPhoto = mediaTuple.0

        let alert = UIAlertController.init( title: NSLocalizedString( "AlertTitle.EnterCommentForFavorite", comment: "What would you like to remember about this favorite?" ), message: nil, preferredStyle: .alert )
        
        let saveAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Save", comment: "Save" ), style: .default )
        { ( alertAction ) in
            logTrace( "Save Action" )
            let commentTextField = alert.textFields![0] as UITextField
            let commentText      = commentTextField.text ?? ""
            
            locationPhoto.comment = commentText
            self.favoriteAction   = .comment
            
            self.pinCentral.saveUpdated( locationPhoto, self )
        }
        
        let cancelAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), style: .cancel )
        { ( alertAction ) in
            logTrace( "Cancel Action" )
        }
        
        alert.addTextField
        { ( textField ) in
            if locationPhoto.comment!.isEmpty {
                textField.placeholder = NSLocalizedString( "LabelText.Comment", comment: "Comment" )
            }
            else {
                textField.text = locationPhoto.comment
            }
            
        }
        
        alert.addAction( saveAction   )
        alert.addAction( cancelAction )
        
        present( alert, animated: true, completion: nil )
    }
    
    
    private func promptToRemoveFromFavorites() {
        logTrace()
        let     alert = UIAlertController.init( title: NSLocalizedString( "AlertTitle.RemoveFromFavorites", comment: "Are you sure you want to reemove this favorite?" ), message: nil, preferredStyle: .alert )
        
        let yesAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.Yes", comment: "Yes" ), style: .default )
        { ( alertAction ) in
            logTrace( "Yes Action" )
            let mediaTuple    = self.fetchedMediaArray[self.selectedIndexPath.row]
            let locationPhoto = mediaTuple.0
            
            self.favoriteAction = .delete
            self.pinCentral.deleteLocationPhotoFrom( self.pin, locationPhoto: locationPhoto, self )
        }
        
        let noAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.No", comment: "No" ), style: .cancel )
        { ( alertAction ) in
            logTrace( "No Action" )
        }
        
        alert.addAction( yesAction )
        alert.addAction( noAction  )
        
        present( alert, animated: true, completion: nil )
    }
    
    
    private func reloadDataArrays() {
        deviceAssetArray = originalAssetArray
        
        if onDevDevice {
            var assetsRemoved = 0
            
            fetchedMediaArray = pinCentral.fetchLocationPhotosDataForPin( pin )
            
            for localPhotoTuple in fetchedMediaArray {
                let imageRead  = localPhotoTuple.2
                let localPhoto = localPhotoTuple.0
                let imageName  = localPhoto.filename!
                
                if !imageRead {
                    if pinCentral.dataStoreLocation == .device {
                        logVerbose( "Unable to read image named[ %@ ]", imageName )
                    }
                    else {
                        let _ = pinCentral.imageNamed( imageName, descriptor: imageName, self )
                    }
                    
                }
                
                for index in 0..<deviceAssetArray.count {
                    let phAsset = deviceAssetArray[ index ]
                    
                    if phAsset.localIdentifier == localPhoto.localIdentifier {
                        deviceAssetArray.remove(at: index )
                        assetsRemoved += 1
                        break
                    }
                    
                }
                
            }
            
            // Insert placeholders for header cells for arrays that contain at least one element
            logVerbose( "assets[ %d ] photos[ %d ] ... filtered out [ %d ] assets", deviceAssetArray.count, fetchedMediaArray.count, assetsRemoved )

            deviceAssetArray.insert( PHAsset(), at: 0 )     // The asset header must always be present or we might not show the fetchedMedia
            
            if fetchedMediaArray.count != 0 {
                fetchedMediaArray.insert( fetchedMediaArray[0], at: 0 )
            }
            
            adjustSetupOnDevDevice()
        }
        
    }
    
    
    private func setCurrentCellSelection(_ newIndexPath: IndexPath ) {
        if let collectionViewCell = myCollectionView.cellForItem(at: selectedIndexPath ) {
            let oldSelectedCell = collectionViewCell as! MyPhotosCollectionViewCell
            
            oldSelectedCell.setSelected( false )
        }
        
        if let collectionViewCell = myCollectionView.cellForItem(at: newIndexPath )  {
            let newSelectedCell = collectionViewCell as! MyPhotosCollectionViewCell
            
            newSelectedCell.setSelected( true  )
            
            myCollectionView.scrollToItem(at: newIndexPath, at: .centeredHorizontally, animated: true )
        }
        
        selectedIndexPath = newIndexPath
    }
    
    
}



// MARK: MyPhotosSectionHeaderCollectionViewCellDelegate Methods

extension MyPhotosViewController: MyPhotosSectionHeaderCollectionViewCellDelegate {
    
    func myPhotosSectionHeaderCollectionViewCell(_ cell: MyPhotosSectionHeaderCollectionViewCell, didRequestToggleForSection section: Int, isOpen: Bool) {
        if section == 0 {
            if deviceAssetArray.count > 1 {     // We don't need to do anything if all we have in the deviceAssetArray is the header
                logTrace()
                section0Open = !section0Open
                myCollectionView.reloadData()
            }
            
        }
        else {
            logTrace()
            section1Open = !section1Open
            myCollectionView.reloadData()
        }
        
    }
    

}



// MARK: PinCentralDelegate Methods

extension MyPhotosViewController: PinCentralDelegate {
    
    func pinCentral(_ pinCentral: PinCentral, didFetchImage: Bool, filename: String, image: UIImage) {
//        logVerbose( "[ %@ ] [ %@ ]", stringFor( didFetchImage ), filename )
        if didFetchImage {
            reloadDataArrays()
            
            DispatchQueue.main.asyncAfter(wallDeadline: .now() + 0.5 ) {
                self.populateMyImageViewUsing( self.selectedIndexPath )
                self.myCollectionView.reloadData()
            }

        }
        
    }
    
    
    func pinCentral(_ pinCentral: PinCentral, didGetImage: Bool, from asset: PHAsset, image: UIImage ) {
//        logVerbose( "[ %@ ]", stringFor(  didGetImage ) )
        if didGetImage {
            myImageView.image = image
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 ) {
            self.loadBarButtonItems()
        }

    }
    
    
    func pinCentral(_ pinCentral: PinCentral, didUpdateInAppPhotos: Bool) {
        logVerbose( "[ %@ ]", stringFor( didUpdateInAppPhotos ) )
        
        if didUpdateInAppPhotos {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                self.reloadDataArrays()
                
                if self.favoriteAction == .delete {
                    if self.deviceAssetArray.count == 0 && self.fetchedMediaArray.count == 0 {
                        logTrace( "We don't have anything to show... exiting" )
                        if self.isOverFullScreen {
                            self.dismiss( animated: true )
                        }
                        else {
                            self.navigationController?.popViewController(animated: true )
                        }
                        
                        return
                    }
                    
                }

                self.populateMyImageViewUsing( self.selectedIndexPath )
                self.myCollectionView.reloadData()
                self.favoriteAction = .none
            }
            
        }
        else {
            self.favoriteAction = .none
        }

    }

    
}



// MARK: UICollectionViewDataSource Methods

extension MyPhotosViewController: UICollectionViewDataSource {
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        if !onDevDevice {
            return 1
        }
        
        let numberOfSections = 1 + ( fetchedMediaArray.count > 0 ? 1 : 0 )
        
        return numberOfSections
    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        var numberOfItems = 0
        
        if !onDevDevice {
            numberOfItems = deviceAssetArray.count
        }
        else {
            if section == 0 {
                numberOfItems = section0Open ? deviceAssetArray.count : 1
            }
            else if fetchedMediaArray.count > 1  {
                numberOfItems = section1Open ? fetchedMediaArray.count : 1
            }

        }
        
//        logVerbose( "section[ %d ] numberOfItems[ %d ]", section, numberOfItems )
        return numberOfItems
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let isSelected = ( indexPath == selectedIndexPath )
        
//        logVerbose( "[ %@ ]", stringFor( indexPath ) )
        if onDevDevice && indexPath.row == 0 {
            // Header cells
            let cell   = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.headerID, for: indexPath ) as! MyPhotosSectionHeaderCollectionViewCell
            let isOpen = ( indexPath.section == 0 ) ? section0Open : section1Open
            
            cell.initializeForSection( indexPath.section, isOpen: isOpen, self )
            return cell
        }
        
        // Normal cells
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.cellID, for: indexPath ) as! MyPhotosCollectionViewCell
        
        if indexPath.section == 0 {
            cell.initializeWith( deviceAssetArray[indexPath.row], isSelected: isSelected )
        }
        else {
            cell.initializeWith( fetchedMediaArray[indexPath.row], isSelected: isSelected )
        }
        
        return cell
    }
    
    
}



// MARK: UICollectionViewDataSource Methods

extension MyPhotosViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        logVerbose( "[ %@ ]", stringFor( indexPath ) )
        changeSelectedCellTo( indexPath )
        populateMyImageViewUsing( indexPath )
    }
    
    
    private func changeSelectedCellTo(_ indexPath: IndexPath ) {
        let currentlySelectedCell = myCollectionView.cellForItem( at: selectedIndexPath ) as! MyPhotosCollectionViewCell
        let newSelectedCell       = myCollectionView.cellForItem( at: indexPath         ) as! MyPhotosCollectionViewCell

        if indexPath.section == 0 {
            currentlySelectedCell.initializeWith( deviceAssetArray[selectedIndexPath.row], isSelected: false )
            newSelectedCell      .initializeWith( deviceAssetArray[        indexPath.row], isSelected: true  )
        }
        else {
            currentlySelectedCell.initializeWith( fetchedMediaArray[selectedIndexPath.row], isSelected: false )
            newSelectedCell      .initializeWith( fetchedMediaArray[        indexPath.row], isSelected: true  )
        }
        
        selectedIndexPath = indexPath
    }
    
    
}



// MARK: - UIGestureRecognizerDelegate method

extension MyPhotosViewController: UIGestureRecognizerDelegate {
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Return true to allow both to work at the same time
        return true
    }
    
    
}



// MARK: UIImageWrite Completion Methods

extension MyPhotosViewController {

    @objc func image(_ image: UIImage, didFinishSavingWithError error: NSError?, contextInfo: UnsafeRawPointer ) {
        let message = error == nil ? NSLocalizedString( "AlertMessage.PhotoSaved",      comment: "Image saved to photo album"  ) :
                                     NSLocalizedString( "AlertMessage.PhotoSaveFailed", comment: "Save to photo album failed!" )
        let title   = error == nil ? NSLocalizedString( "AlertTitle.Success", comment: "Success!" ) : NSLocalizedString( "AlertTitle.Error", comment: "Error!" )
        
        presentAlert(title: title, message: message )
    }



    // MARK: Helper functions inserted by Swift 4.2 migrator.

    fileprivate func convertFromUIImagePickerControllerInfoKeyDictionary(_ input: [UIImagePickerController.InfoKey: Any]) -> [String: Any] {
        return Dictionary( uniqueKeysWithValues: input.map { key, value in (key.rawValue, value) } )
    }


    fileprivate func convertFromUIImagePickerControllerInfoKey(_ input: UIImagePickerController.InfoKey) -> String {
        return input.rawValue
    }

                
}



// MARK: - UIPopoverPresentationControllerDelegate method

extension MyPhotosViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    
}
