//
//  PinColorSelectorViewController.swift
//  MyPins
//
//  Created by Clint Shank on 4/9/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit



protocol PinColorSelectorViewControllerDelegate: class
{
    func pinColorSelectorViewController( pinColorSelectorVC: PinColorSelectorViewController,
                                         didSelect color: Int )
}



class PinColorSelectorViewController: UIViewController,
                                      UIPickerViewDataSource,
                                      UIPickerViewDelegate
{
    @IBOutlet weak var titleLabel:      UILabel!
    @IBOutlet weak var pickerView:      UIPickerView!
    @IBOutlet weak var saveButton:      UIButton!
    @IBOutlet weak var cancelButton:    UIButton!
    
    
    
    weak var delegate: PinColorSelectorViewControllerDelegate?
    
    var     originalPinColor:  Int16!             // Set by delegate
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad()
    {
        logTrace()
        super.viewDidLoad()
        
        titleLabel.text = NSLocalizedString( "Title.SelectPinColor", comment: "Select Pin Color" )
        
        cancelButton.setTitle( NSLocalizedString( "ButtonTitle.Cancel", comment: "Cancel" ), for: .normal )
        saveButton  .setTitle( NSLocalizedString( "ButtonTitle.Save",   comment: "Save"   ), for: .normal )

        preferredContentSize = CGSize( width: 280, height: 260 )
    }
    
    
    override func viewWillAppear(_ animated: Bool)
    {
        logTrace()
        super.viewWillAppear( animated )
        
        pickerView.reloadComponent( 0 )
        pickerView.selectRow( Int( originalPinColor ),
                              inComponent: 0,
                              animated: true )
    }

    
    override func didReceiveMemoryWarning()
    {
        logTrace()
        super.didReceiveMemoryWarning()
    }
    

    
    //MARK: Target/Action Methods
    
    @IBAction func cancelButtonTouched(_ sender: UIButton )
    {
        logTrace()
        dismiss( animated: true, completion: nil )
    }
    
    
    @IBAction func saveButtonTouched(_ sender: UIButton )
    {
        let     colorSelected = pickerView.selectedRow( inComponent: 0 )
        
        
        logVerbose( "selected color[ %d ][ %@ ]",colorSelected, pinColorNameArray[colorSelected] )
       
        if colorSelected != originalPinColor
        {
            delegate?.pinColorSelectorViewController( pinColorSelectorVC: self,
                                                      didSelect: colorSelected )
        }
        
        dismiss( animated: true, completion: nil )
    }
    
    
    
    // MARK: UIPickerViewDataSource Methods
    
    func numberOfComponents( in pickerView: UIPickerView ) -> Int
    {
//        logTrace()
        return 1
    }
    
    
    func pickerView(_ pickerView: UIPickerView,
                      numberOfRowsInComponent component: Int) -> Int
    {
//        logTrace()
        return pinColorNameArray.count
    }

    
    
    // MARK: UIPickerViewDelegate Methods
    
    func pickerView(_ pickerView: UIPickerView,
                      titleForRow row: Int,
                      forComponent component: Int) -> String?
    {
//        logTrace()
        return pinColorNameArray[row]
    }
    
    
    func pickerView(_ pickerView: UIPickerView,
                      didSelectRow row: Int,
                      inComponent component: Int)
    {
//        logTrace()
    }
    
    
    
    

    
    
    
    
}
