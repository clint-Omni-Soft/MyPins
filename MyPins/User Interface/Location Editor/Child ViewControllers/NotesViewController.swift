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
    var     editMode     = true
    var     originalText = ""


    @IBOutlet weak var nonEditibleTextView: UITextView!
    @IBOutlet weak var notesTextView      : UITextView!
    @IBOutlet weak var spacerView         : UIView!
    
    
    // MARK: Private Variables
    
    private var currentText            = ""
    private var greatestKeyboardHeight = 0.0
    private var notificationCenter     = NotificationCenter.default

      
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()
        navigationItem.title = editMode ? NSLocalizedString( "Title.NotesEditor", comment: "Notes Editor" ) : NSLocalizedString( "Title.Notes", comment: "Notes" )
        
        if editMode {
            navigationItem.rightBarButtonItem = UIBarButtonItem.init( barButtonSystemItem: .trash, target: self, action: #selector( trashBarButtonItemTouched(_:) ) )
        }
        else {
            configureBackBarButtonItem()
        }
 
        nonEditibleTextView.font = UIFont.systemFont(ofSize: 17.0 )
        notesTextView      .font = UIFont.systemFont(ofSize: 17.0 )
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        logTrace()
        super.viewWillAppear(animated)
        
        nonEditibleTextView.isHidden = editMode

        if editMode {
            notesTextView.text = originalText
            notesTextView.becomeFirstResponder()
            notificationCenter.addObserver( self, selector: #selector( keyboardWillShow(notification: ) ), name: UIResponder.keyboardDidShowNotification, object: nil )
        }
        else {
            nonEditibleTextView.text = originalText
        }

    }
    
    
    override func viewWillDisappear(_ animated: Bool) {
        logTrace()
        super.viewWillDisappear(animated)
        
        if editMode {
            currentText = notesTextView.text
            
            if currentText != originalText {
                delegate.notesViewControllerDidUpdateText( self, newText: currentText )
            }

        }
        
        notificationCenter.removeObserver( self )
    }
    
    

    // MARK: NSNotification Methods
    
    @objc func keyboardWillShow( notification: NSNotification ) {
//        logTrace()
        if notesTextView.text.count > 0 {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5 ) {
                self.notesTextView.scrollRangeToVisible( NSMakeRange( self.notesTextView.text.count - 1, 0 ) )
            }
            
        }

    }

    
    
    // MARK: Target/Action Methods
    
    @IBAction @objc func trashBarButtonItemTouched(_ sender: UIBarButtonItem ) {
        logTrace()
        currentText        = ""
        notesTextView.text = currentText
   }



}
