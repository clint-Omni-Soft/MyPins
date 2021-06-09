//
//  SettingsTableViewController.swift
//  MyPins
//
//  Created by Clint Shank on 5/2/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController {

    // MARK: Private Variables
    
    private struct Constants {
        static let cellId = "SettingsTableViewControllerCell"
    }
    
    private struct StoryboardIds {
        static let howToUse     = "HowToUseViewController"
        static let splashScreen = "SplashScreenViewController"
    }
    
    private let     pinCentral = PinCentral.sharedInstance
    private var     rowTitleArray: [String] = []
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        
        title = NSLocalizedString( "Title.Settings",  comment: "Settings"  )
        
        rowTitleArray = [ NSLocalizedString( "LabelText.About", comment: "About"      ),
                          NSLocalizedString( "Title.HowToUse",  comment: "How to Use" ),
                          NSLocalizedString( "Title.ReduceImageSize",  comment: "Reduce Image Size" ) ]
    }
    
    
    override func didReceiveMemoryWarning() {
        logTrace( "MEMORY WARNING!!!" )
        super.didReceiveMemoryWarning()
    }
    
    
    
    // MARK: UITableViewDataSource Methods
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath ) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell( withIdentifier: Constants.cellId, for: indexPath)
        
        cell.textLabel?.text = rowTitleArray[indexPath.row]
        
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int ) -> Int {
        return rowTitleArray.count
    }
    
    
    
    // MARK: - UITableViewDelegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath ) {
        logTrace()
        tableView.deselectRow( at: indexPath, animated: false )
        
        switch indexPath.row {
        case 0:     showViewController( storyboardId: StoryboardIds.splashScreen )
        case 1:     showViewController( storyboardId: StoryboardIds.howToUse     )
        case 2:     reduceImageSize()
        default:    break
        }
        
    }
    
    
    
    // MARK: Utility Methods
    
    private func description() -> String {
        return "SettingsTableViewController"
    }
    
    
    private func reduceImageSize() {
        logTrace()
        for pin in pinCentral.pinArray {
            if let imageName = pin.imageName {
                if !imageName.isEmpty {
                    let result = pinCentral.imageWith(name: imageName )
                    
                    if result.0 && result.2 > 500000 {
                        pinCentral.replaceImage(imageName, with: result.1 )
                    }
                    
                }
                
            }
            
        }
        
    }
    
    
    private func showViewController( storyboardId: String ) {
        let     viewController = iPhoneViewControllerWithStoryboardId( storyboardId: storyboardId )
        
        navigationController?.show( viewController, sender: self )
    }
    
    

    
}
