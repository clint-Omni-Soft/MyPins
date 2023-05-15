//
//  LogViewController.swift
//  ClubLengths
//
//  Created by Clint Shank on 2/20/23.
//

import UIKit


class LogViewController: UIViewController {
    
    // MARK: Public Variables
    
    @IBOutlet weak var myTextView: UITextView!

    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()

        navigationItem.title = NSLocalizedString( "Title.LogViewer", comment: "Log Viewer" )
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        myTextView.layoutManager.allowsNonContiguousLayout = false
        myTextView.text = logContents()
        
        loadBarButtonItems()
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0, execute: {
            self.myTextView.scrollRangeToVisible( NSRange( location: self.myTextView.text.count - 1, length: 1 ) )
        })

    }
    
    

    // MARK: Target / Action Methods
    
    @IBAction func backBarButtonTouched(_ sender : UIBarButtonItem ) {
        logTrace()
        navigationController?.popViewController( animated: true )
    }

    
    @IBAction func doneBarButtonTouched(_ sender : UIBarButtonItem ) {
        logTrace()
        dismiss(animated: true )
    }

    

    // MARK: Utility Methods
    
    private func loadBarButtonItems() {
//        logTrace()
        if UIDevice.current.userInterfaceIdiom == .pad {
            navigationItem.leftBarButtonItem = UIBarButtonItem.init( title: NSLocalizedString( "ButtonTitle.Done", comment: "Done" ), style : .plain, target: self, action: #selector( doneBarButtonTouched(_:) ) )
        }
        else {
            navigationItem.leftBarButtonItem = UIBarButtonItem.init( title: NSLocalizedString( "ButtonTitle.Back", comment: "Back" ), style : .plain, target: self, action: #selector( backBarButtonTouched(_:) ) )
        }
    }

    
}
