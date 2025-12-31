//
//  MyPhotosCollectionViewCell.swift
//  MyPins
//
//  Created by Clint Shank on 4/2/25.
//  Copyright © 2025 Omni-Soft, Inc. All rights reserved.
//

import UIKit
import Photos



class MyPhotosCollectionViewCell: UICollectionViewCell {

    var imageState = ImageState.noName

    @IBOutlet weak var myImageView: UIImageView!
    
    
    
    // MARK: Private Variables
    
    private let cachingImageManager = PHCachingImageManager()
    private let myImageManager      = PHImageManager.default()
    private var myPhAsset           : PHAsset!
    private var myThumbnail         : UIImage!
    private let pinCentral          = PinCentral.sharedInstance
    private var playerLayer         : AVPlayerLayer!
    
    
    
    // MARK: UITableViewCell Lifecycle Methods
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    
    override func prepareForReuse() {
        super.prepareForReuse()
        
        if let _ = playerLayer {
            playerLayer.removeFromSuperlayer()
            playerLayer = nil
        }
        
        myImageView.image = UIImage()
        myPhAsset         = nil
        myThumbnail       = nil
    }
    
    

    // MARK: Pubic Interfaces
    
    func initializeWith(_ phAsset: PHAsset, isSelected: Bool ) {
        myPhAsset       = phAsset
        backgroundColor = isSelected ? .black : .white
        
        myImageView.image = UIImage( named: GlobalConstants.noImage )
        
//        logVerbose( "loading[ %@ ]", phAsset.descriptorString() )
        if myPhAsset.mediaType == .image {
            let targetSize = CGSize( width: myImageView.bounds.width, height: myImageView.bounds.height )

            self.pinCentral.getImageFrom( self.myPhAsset, targetSize: targetSize, isThumbnail: true, delegate: self )
        }
        else if myPhAsset.mediaType == .video {
            let videoRequestOptions = PHVideoRequestOptions()
            
            videoRequestOptions.deliveryMode           = .automatic
            videoRequestOptions.isNetworkAccessAllowed = false
            
            myImageManager.requestPlayerItem(forVideo: myPhAsset, options: videoRequestOptions, resultHandler: { playerItem, info in
                // Create an AVPlayer and AVPlayerLayer with the AVPlayerItem.
                let player = AVPlayer( playerItem: playerItem )
                
                self.playerLayer = AVPlayerLayer( player: player )
                
                // Since myImageView has constraints on it that will automatically reposition and resize itself,
                // we attach the playerLayer to it so it can just tag along for the ride
                self.playerLayer.videoGravity = AVLayerVideoGravity.resizeAspect
                self.playerLayer.frame        = self.myImageView.layer.bounds
                
                self.myImageView.layer.addSublayer( self.playerLayer )
                self.imageState = ImageState.loaded
            })
            
        }
        else {
            logVerbose( "ERROR!!! We don't support this style[ %@ ]", myPhAsset.stringForPlaybackStyle() )
            imageState = ImageState.noName
        }
        
    }
    
    
    func initializeWith(_ tuple: ( LocationPhoto, Data, Bool ), isSelected: Bool ) {
        let locationPhoto = tuple.0
        let mediaData     = tuple.1
        let dataLoaded    = tuple.2

        backgroundColor = isSelected ? .black : .white
        myImageView.image = UIImage( named: GlobalConstants.noImage )
        
        if !dataLoaded {
            myImageView.image = UIImage( named: GlobalConstants.missingImage )
            logVerbose( "ERROR!!!  No data for [ %@ ]", locationPhoto.filename! )
            return
        }
        
        if locationPhoto.isVideo {
            let fileManager          = FileManager.default
            let picturesDirectoryUrl = URL( fileURLWithPath: pinCentral.pictureDirectoryPath() )
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
            imageState = ImageState.loaded
            
            if videoCached {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.2 ) {
                    do {
                        try fileManager.removeItem(at: currentVideoUrl )
                        logTrace( "deleted temporary file",  )
                    }
                    catch let error as NSError {
                        logVerbose( "ERROR!!!  [ %@ ]\n    [ %@ ]", error.localizedDescription, currentVideoUrl.path )
                    }

                }

            }
            else {
                logVerbose( "ERROR!!!  could not cache video[ %@ ]", currentVideoUrl.path )
            }

        }
        else {  // we have an image
            DispatchQueue.main.async {
                let result       = self.pinCentral.extractThumbnailFrom( locationPhoto.filename!, "locationPhotoThumbnail" )
                let imageLoaded  = result.0
                
                self.imageState        = imageLoaded ? ImageState.loaded : ImageState.missing
                self.myImageView.image = imageLoaded ? result.1 : UIImage( named: GlobalConstants.missingImage )
            }
            
        }
            
    }
    
    
    func setSelected(_ selected: Bool ) {
        self.backgroundColor = selected ? .black : .white
    }

    
}



// MARK: PinCentralDelegate Methods

extension MyPhotosCollectionViewCell: PinCentralDelegate {
    
    func pinCentral(_ pinCentral: PinCentral, didGetImage: Bool, from asset: PHAsset, image: UIImage ) {
        if didGetImage {
            myImageView.image = image
            imageState = ImageState.loaded
        }

    }

    
}


    
