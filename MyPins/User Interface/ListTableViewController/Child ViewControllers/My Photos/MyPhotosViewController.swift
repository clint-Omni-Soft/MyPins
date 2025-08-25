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
    
    var currentImageIndex = 0
    var deviceAssetArray  = [PHAsset]()
    var isOverFullScreen  = false
    var myParentVC        : MyPhotosViewController!
    
    @IBOutlet      var leftSwipeGestureRecognizer : UISwipeGestureRecognizer!
    @IBOutlet weak var myCollectionView           : UICollectionView!
    @IBOutlet weak var myImageView                : UIImageView!
    @IBOutlet      var pinchGestureRecognizer     : UIPinchGestureRecognizer!
    @IBOutlet      var rightSwipeGestureRecognizer: UISwipeGestureRecognizer!
    
    
    
    // MARK: Private Variables
    
    private enum VideoStatus {
        case notLoaded
        case loaded
        case running
        case paused
        case ended
    }
    
    private struct Constants {
        static let cellID = "MyPhotosCollectionViewCell"
    }
    
    private struct StoryboardIds {
        static let myPhotos = "MyPhotosViewController"
    }
    
    private var imageNameArray     = [String]()
    private let myImageManager     = PHImageManager.default()
    private let notificationCenter = NotificationCenter.default
    private let pinCentral         = PinCentral.sharedInstance
    private var playerLayer        : AVPlayerLayer!
    private var videoStatus        = VideoStatus.loaded
    private let userDefaults       = UserDefaults.standard
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        navigationItem.title = NSLocalizedString( "Title.MyPhotos", comment: "My Photos" )
        
        view.backgroundColor = .lightGray
        myCollectionView.layer.borderColor = UIColor.black.cgColor
        myCollectionView.layer.borderWidth = 3.0
        
        myImageView.isUserInteractionEnabled = true
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear( animated )
        
        loadBarButtonItems()
        
        DispatchQueue.main.asyncAfter(wallDeadline: .now() + 0.5 ) {
            self.populateMyImageViewWithImageAt( self.currentImageIndex )
            self.myCollectionView.reloadData()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                self.myCollectionView.scrollToItem(at: IndexPath(item: self.currentImageIndex, section: 0 ), at: .centeredHorizontally, animated: true )
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
    
    @IBAction func fullScreenBarButtonTouched(_ sender : UIBarButtonItem ) {
        logTrace()
        if isOverFullScreen {
            myParentVC.currentImageIndex = currentImageIndex
            dismiss( animated: true )
        }
        else {
            presentMyselfFullscreen()
        }
        
    }
    
    
    @IBAction func imageSwiped(_ sender: UISwipeGestureRecognizer ) {
//        logTrace()
        if sender.direction == .left {
            if currentImageIndex + 1 <= deviceAssetArray.count - 1 {
                populateMyImageViewWithImageAt( currentImageIndex + 1 )
            }
            
        }
        else {
            if currentImageIndex - 1 >= 0 {
                populateMyImageViewWithImageAt( currentImageIndex - 1 )
            }
            
        }
        
    }
    
    
    @IBAction func leftBarButtonTouched(sender : UIBarButtonItem ) {
        logTrace()
        if isOverFullScreen {
            myParentVC.currentImageIndex = currentImageIndex
            dismiss( animated: true )
        }
        else {
            navigationController?.popViewController(animated: true )
        }
        
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
    
    private func loadBarButtonItems() {
//        logTrace()
        var leftBarButtonItems  = [UIBarButtonItem]()
        var rightBarButtonItems = [UIBarButtonItem]()
        
        if UIDevice.current.userInterfaceIdiom == .pad {
            let imageName = isOverFullScreen ? "exitFullScreen" : "enterFullScreen"
            
            rightBarButtonItems.append( UIBarButtonItem.init( image: UIImage(named: imageName ), style: .plain, target: self, action: #selector( fullScreenBarButtonTouched(_:) ) ) )
        }
        
        leftBarButtonItems.append( UIBarButtonItem.init( title: NSLocalizedString( "ButtonTitle.Back", comment: "Back" ), style: .plain, target: self, action: #selector( leftBarButtonTouched ) ) )
        
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
    
    
    private func populateMyImageViewWithImageAt(_ index: Int ) {
        let phAsset = deviceAssetArray[index]
        
        setCurrentCellSelection( index )
        
        if let _ = playerLayer {
            playerLayer.removeFromSuperlayer()
            playerLayer  = nil
        }
        
        myImageView.image     = UIImage()
        myImageView.transform = .identity
        videoStatus           = .notLoaded
        
        notificationCenter.removeObserver( self )
        
        if phAsset.mediaType == .image {
            let targetSize = CGSize( width: myImageView.bounds.width, height: myImageView.bounds.height )
            
            pinCentral.getImageFrom( phAsset, targetSize: targetSize, isThumbnail: false, delegate: self )
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
            
        }
        else {
            logVerbose( "ERROR!!! We don't support this style[ %@ ]", phAsset.stringForPlaybackStyle() )
        }
        
    }
    
    
    private func presentMyselfFullscreen() {
        guard let myPhotosViewController: MyPhotosViewController = self.iPhoneViewControllerWithStoryboardId( storyboardId: StoryboardIds.myPhotos ) as? MyPhotosViewController else {
            logTrace( "ERROR: Could NOT load MyPhotosViewController!" )
            return
        }
        
        logTrace()
        myPhotosViewController.deviceAssetArray     = deviceAssetArray
        myPhotosViewController.currentImageIndex    = currentImageIndex
        myPhotosViewController.isOverFullScreen     = true
        myPhotosViewController.myParentVC           = self
        myPhotosViewController.view.backgroundColor = .lightGray
        
        let navigationController = UINavigationController.init(rootViewController: myPhotosViewController )
        
        navigationController.modalPresentationStyle        = .fullScreen
        navigationController.navigationBar.backgroundColor = .lightGray
        
        present( navigationController, animated: true )
    }
    
    
    private func setCurrentCellSelection(_ newIndex: Int ) {
        if let collectionViewCell = myCollectionView.cellForItem(at: IndexPath(item: currentImageIndex, section: 0 ) ) {
            let oldSelectedCell = collectionViewCell as! MyPhotosCollectionViewCell
            
            oldSelectedCell.setSelected( false )
        }
        
        if let collectionViewCell = myCollectionView.cellForItem(at: IndexPath(item: newIndex, section: 0 ) )  {
            let newSelectedCell = collectionViewCell as! MyPhotosCollectionViewCell
            
            newSelectedCell.setSelected( true  )
            
            myCollectionView.scrollToItem(at: IndexPath(item: newIndex, section: 0 ), at: .centeredHorizontally, animated: true )
        }
        
        currentImageIndex = newIndex
    }
    
    
}



// MARK: PinCentralDelegate Methods

extension MyPhotosViewController: PinCentralDelegate {
    
    func pinCentral(_ pinCentral: PinCentral, didGetImage: Bool, from asset: PHAsset, image: UIImage ) {
//        logVerbose( "[ %@ ][ %@ ]", stringFor( didGetImage ), asset.descriptorString() )
        if didGetImage {
            myImageView.image = image
        }
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1 ) {
            self.loadBarButtonItems()
        }

    }

    
}



// MARK: UICollectionViewDataSource Methods

extension MyPhotosViewController: UICollectionViewDataSource {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return deviceAssetArray.count
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Constants.cellID, for: indexPath ) as! MyPhotosCollectionViewCell

        cell.initializeWith( deviceAssetArray[indexPath.row], index: indexPath.row, isSelected: ( indexPath.row == currentImageIndex ) )
        
        return cell
    }
    
    
}



// MARK: UICollectionViewDataSource Methods

extension MyPhotosViewController: UICollectionViewDelegate {
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        logVerbose( "[ %@ ]", stringFor( indexPath ) )
        populateMyImageViewWithImageAt( indexPath.row )
    }
    
    
}



// MARK: - UIPopoverPresentationControllerDelegate method

extension MyPhotosViewController: UIPopoverPresentationControllerDelegate {
    
    func adaptivePresentationStyle(for controller: UIPresentationController, traitCollection: UITraitCollection) -> UIModalPresentationStyle {
        return UIModalPresentationStyle.none
    }
    
    
}
