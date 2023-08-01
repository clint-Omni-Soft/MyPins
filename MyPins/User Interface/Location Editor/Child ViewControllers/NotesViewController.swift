//
//  NotesViewController.swift
//  MyPins
//
//  Created by Clint Shank on 11/28/22.
//  Copyright © 2022 Omni-Soft, Inc. All rights reserved.
//

import UIKit


protocol NotesViewControllerDelegate: AnyObject {
    func notesViewControllerDidUpdateText(_ notesViewController: NotesViewController, newText: String )
}



class NotesViewController: UIViewController {
    
    // MARK: Public Variables
    
    var     delegate: NotesViewControllerDelegate!
    var     originalText = ""


    @IBOutlet weak var notesTextView: UITextView!
    
    
    // MARK: Private Variables
    
    private var currentText = ""
    
      
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        navigationItem.title = NSLocalizedString( "Title.NotesEditor", comment: "Notes Editor" )
        
        navigationItem.rightBarButtonItem = UIBarButtonItem.init( barButtonSystemItem: .trash, target: self, action: #selector( trashBarButtonItemTouched(_:) ) )
        notesTextView.font = UIFont.systemFont(ofSize: 17.0 )
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        notesTextView.text = originalText
    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        logTrace()
        super.viewWillDisappear(animated)
        currentText = notesTextView.text
        
        if currentText != originalText {
            delegate.notesViewControllerDidUpdateText( self, newText: currentText )
        }
        
    }
    
    
    
    // MARK: Target/Action Methods
    
    @IBAction @objc func trashBarButtonItemTouched(_ sender: UIBarButtonItem ) {
        logTrace()
        currentText        = ""
        notesTextView.text = currentText
   }



}
