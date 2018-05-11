//
//  SettingsTableViewController.swift
//  MyPins
//
//  Created by Clint Shank on 5/2/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//

import UIKit

class SettingsTableViewController: UITableViewController
{
    let     CELL_IDENTIFIER             = "SettingsTableViewControllerCell"
    let     STORYBOARD_ID_HOW_TO_USE    = "HowToUseViewController"
    let     STORYBOARD_ID_SPLASH_SCREEN = "SplashScreenViewController"

    
    
    private var rowTitleArray   = [String].init()
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad()
    {
        appLogTrace()
        super.viewDidLoad()
        
        title = NSLocalizedString( "Title.Settings",  comment: "Settings"  )
        
        rowTitleArray = [ NSLocalizedString( "LabelText.About", comment: "About"      ),
                          NSLocalizedString( "Title.HowToUse",  comment: "How to Use" ) ]
    }
    
    
    override func didReceiveMemoryWarning()
    {
        appLogVerbose( format: "MEMORY WARNING!!!" )
        super.didReceiveMemoryWarning()
    }
    
    
    
    // MARK: UITableViewDataSource Methods
    
    override func tableView(_ tableView: UITableView,
                            cellForRowAt indexPath: IndexPath ) -> UITableViewCell
    {
        let cell = tableView.dequeueReusableCell( withIdentifier: CELL_IDENTIFIER,
                                                  for: indexPath)
        
        cell.textLabel?.text = rowTitleArray[indexPath.row]
        
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView,
                            numberOfRowsInSection section: Int ) -> Int
    {
        return rowTitleArray.count
    }
    
    
    
    // MARK: - UITableViewDelegate Methods
    
    override func tableView(_ tableView: UITableView,
                            didSelectRowAt indexPath: IndexPath )
    {
        appLogTrace()
        tableView.deselectRow( at: indexPath,
                               animated: false )
        
        switch indexPath.row
        {
        case 0:     showViewController( storyboardId: STORYBOARD_ID_SPLASH_SCREEN );      break
        case 1:     showViewController( storyboardId: STORYBOARD_ID_HOW_TO_USE    );      break
            
        default:    break
        }
        
    }
    
    
    
    // MARK: Utility Methods
    
    private func description() -> String
    {
        return "SettingsTableViewController"
    }
    
    
    private func showViewController( storyboardId: String )
    {
        let     viewController = iPhoneViewControllerWithStoryboardId( storyboardId: storyboardId )
        
        
        navigationController?.show( viewController, sender: self )
    }
    
    

    
}
