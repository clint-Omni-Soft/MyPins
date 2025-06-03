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
    
    func initializeWith(_ phAsset: PHAsset, index: Int, isSelected: Bool ) {
        myPhAsset = phAsset
        backgroundColor = isSelected ? .black : .white
        
        if myPhAsset.mediaType == .image {
            let targetSize = CGSize( width: myImageView.bounds.width, height: myImageView.bounds.height )
            
            DispatchQueue.main.async {
                self.pinCentral.getImageFrom( self.myPhAsset, targetSize: targetSize, isThumbnail: true, delegate: self )
            }
            
        }
        else if myPhAsset.mediaType == .video {
            let videoRequestOptions = PHVideoRequestOptions()
            
            videoRequestOptions.deliveryMode           = .automatic
            videoRequestOptions.isNetworkAccessAllowed = false
            
            myImageManager.requestPlayerItem(forVideo: myPhAsset, options: videoRequestOptions, resultHandler: { playerItem, info in
                // Create an AVPlayer and AVPlayerLayer with the AVPlayerItem.
                let player = AVPlayer(  playerItem: playerItem )
                
                self.playerLayer = AVPlayerLayer( player: player )
                
                // Since myImageView has constraints on it that will automatically reposition and resize itself,
                // we attach the playerLayer to it so it can just tag along for the ride
                self.playerLayer.videoGravity = AVLayerVideoGravity.resizeAspect
                self.playerLayer.frame        = self.myImageView.layer.bounds
                
                self.myImageView.layer.addSublayer( self.playerLayer )
            })
            
        }
        else {
            logVerbose( "ERROR!!! We don't support this style[ %@ ]", myPhAsset.stringForPlaybackStyle() )
        }
        
    }
    
    
    func setSelected(_ selected: Bool ) {
        self.backgroundColor = selected ? .black : .white
    }

    
}



// MARK: PinCentralDelegate Methods

extension MyPhotosCollectionViewCell: PinCentralDelegate {
    
    func pinCentral(_ pinCentral: PinCentral, didGetImage: Bool, from asset: PHAsset, image: UIImage ) {
//        logVerbose( "[ %@ ][ %d ][ %@ ]", stringFor( didGetImage ), myIndex, asset.descriptorString() )
        if didGetImage {
            myImageView.image = image
        }
        
    }

    
}


    
//    func extractThumbnailFrom(_ imageName: String, _ description: String ) -> (Bool, UIImage) {
//        let picturesDirectoryPath = pictureDirectoryPath()
//        var result                = ( false, UIImage.init() )
//
//        if picturesDirectoryPath.isEmpty {
//            logVerbose( "ERROR!  pictureDirectoryPath isEmpty!  [ %@ ][ %@ ]", imageName, description )
//            return result
//        }
//
//        let picturesDirectoryURL = URL.init( fileURLWithPath: picturesDirectoryPath )
//        let imageFileURL         = picturesDirectoryURL.appendingPathComponent( imageName )
//
//        if !fileManager.fileExists( atPath: imageFileURL.path ) {
//            logVerbose( "ERROR!  Image [ %@ ] for [ %@ ] does NOT exist!", imageName, description )
//            return result
//        }
//
//        guard let imageSource = CGImageSourceCreateWithURL( imageFileURL as CFURL, nil ) else {
//            logVerbose( "ERROR!  Could NOT create imageSource for [ %@ ][ %@ ]", imageName, description )
//            return result
//        }
//
//        let thumbnailOptions: [String: Any] = [ kCGImageSourceCreateThumbnailWithTransform     as String: true,
//                                                kCGImageSourceCreateThumbnailFromImageIfAbsent as String: true,
//                                                kCGImageSourceThumbnailMaxPixelSize            as String: 512 ]
//
//        if let cgImage = CGImageSourceCreateThumbnailAtIndex( imageSource, 0, thumbnailOptions as CFDictionary ) {
////          logVerbose( "Created thumbnail[ %d, %d ] for [ %@ ][ %@ ]", cgImage.width, cgImage.height, imageName, description )
//            result = ( true, UIImage( cgImage: cgImage ) )
//        }
//        else {
//            logVerbose( "ERROR!  Could NOT create thumbnail for[ %@ ][ %@ ]! ... [ %d ] imagesPresent", imageName, description, CGImageSourceGetCount( imageSource ) )
//        }
//
//        return result
//    }

    
