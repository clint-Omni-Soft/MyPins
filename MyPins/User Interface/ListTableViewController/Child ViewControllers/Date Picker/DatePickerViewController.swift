//
//  DatePickerViewController.swift
//  MyPins
//
//  Created by Clint Shank on 4/2/25.
//  Copyright © 2025 Omni-Soft, Inc. All rights reserved.
//

import UIKit


protocol DatePickerViewControllerDelegate {
    func datePickerViewControllerDidSelect(_ datePickerViewController: DatePickerViewController, startingDate: Date, duration: Int )
}



class DatePickerViewController: UIViewController {

    
    // MARK: Public Variables

    var delegate    : DatePickerViewControllerDelegate!
    var lastModified: Date!
    
    @IBOutlet weak var cancelButton      : UIButton!
    @IBOutlet weak var durationLabel     : UILabel!
    @IBOutlet weak var durationPickerView: UIPickerView!
    @IBOutlet weak var okButton          : UIButton!
    @IBOutlet weak var startingDateLabel : UILabel!
    @IBOutlet weak var startingDatePicker: UIDatePicker!
    @IBOutlet weak var titleLabel        : UILabel!
    
    
    
    // MARK: Private Variables
    
    private var duration      = 1
    private let durationArray = [ "1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "11", "12", "13", "14" ]
    private var startingDate  : Date!
    
    
    
    // MARK: UIViewController Lifecycle Methods
    
    override func viewDidLoad() {
        logTrace()
        super.viewDidLoad()

        configurePopoverViewBorder( view )
        
        configureControlViewBorder( durationPickerView )

        durationLabel    .text = NSLocalizedString( "LabelText.NumberOfDays", comment: "Number of Days"  )
        startingDateLabel.text = NSLocalizedString( "LabelText.StartingDate", comment: "Starting Date"   )
        titleLabel       .text = NSLocalizedString( "Title.SetTimePeriod",    comment: "Set Time Period" )
        
        expandImageToFit( cancelButton )
        expandImageToFit( okButton     )
        
        startingDate = lastModified
        
        startingDatePicker.maximumDate = Date()
        startingDatePicker.minimumDate = Date.distantPast
        
        preferredContentSize = CGSize(width: 375, height: 296 )
  }
    
    
    override func viewDidAppear(_ animated: Bool) {
        logTrace()
        super.viewDidAppear( animated )
        
        startingDatePicker.date = startingDate
        durationPickerView.selectRow( 0, inComponent: 0, animated: true )
    }

    
    
    // MARK: Target / Action Methods
    
    @IBAction func cancelButtonTouched(_ sender: UIButton) {
        logTrace()
        dismiss( animated: true, completion: nil )
    }
    
    
    @IBAction func okButtonTouched(_ sender: UIButton) {
        logVerbose( "startingDate[ %@ ] duration[ %d ]", stringFor( startingDate ), duration )
        delegate.datePickerViewControllerDidSelect( self, startingDate: startingDate, duration: duration )
        
        dismiss( animated: true, completion: nil )
    }
    
    
    @IBAction func startingDatePickerValueChanged(_ picker: UIDatePicker) {
        startingDate = picker.date
    }
    
    
}



    // MARK: UIPickerViewDelegate Methods

extension DatePickerViewController: UIPickerViewDelegate {
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        duration = row + 1
    }
    
    
    func pickerView(_ pickerView: UIPickerView, rowHeightForComponent component: Int) -> CGFloat {
        return 32.0
    }
    
    // I had to add the method below this because this one uses a larger default font than the StartingDate picker
//    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
//        return durationArray[row]
//    }
    
    
    func pickerView(_ pickerView: UIPickerView, viewForRow row: Int, forComponent component: Int, reusing view: UIView? ) -> UIView {
        var label = UILabel()
        
        if let reusedView = view as? UILabel {
            label = reusedView
        }
            
        label.font          = UIFont.systemFont(ofSize: 16 )
        label.text          = durationArray[row]
        label.textAlignment = .center
        
        return label
    }
    
    
    func pickerView(_ pickerView: UIPickerView, widthForComponent component: Int) -> CGFloat {
        return 40.0
    }
    
    
}



// MARK: UIPickerViewDataSource Methods

extension DatePickerViewController: UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return durationArray.count
    }
    
    
}
