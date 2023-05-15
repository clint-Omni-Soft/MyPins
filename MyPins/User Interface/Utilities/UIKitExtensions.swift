//
//  UIKitExtensionsViewController.swift
//  WineStock
//
//  Created by Clint Shank on 1/3/20.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//


import UIKit



// MARK: UIViewController Methods


struct HeaderViewTagOffsets {
    static let down = 200
    static let up   = 100
}


extension UIViewController {
    
    func headerViewFor(_ tableView : UITableView, _ section : Int, with title : String, arrowUp : Bool ) -> UIView {
        // NOTE: This method is no longer used
        let     button     = UIButton.init( type: .system )
        let     tableWidth = tableView.frame.size.width
        let     headerView = UIView .init( frame: CGRect.init( x:  0, y:  0, width: tableWidth,      height: 44 ) )
        let     labelView  = UILabel.init( frame: CGRect.init( x: 10, y: 11, width: tableWidth - 40, height: 22 ) )

        button.setImage( UIImage( named: arrowUp ? "arrowUp" : "arrowDown" ), for: .normal )
        button.frame     = CGRect.init( x: tableWidth - 45, y: 7.0, width: 30.0, height: 30.0 )
        button.tag       = section + ( arrowUp ? HeaderViewTagOffsets.up : HeaderViewTagOffsets.down )
        button.tintColor = .blue

        headerView.backgroundColor = .lightGray
        
        labelView.text      = title
        labelView.textColor = .white
        
        headerView.addSubview( button )
        headerView.addSubview( labelView  )

        return headerView
    }
    
    
    func iPhoneViewControllerWithStoryboardId( storyboardId: String ) -> UIViewController {
//        logVerbose( "[ %@ ]", storyboardId )
        let     storyboardName = "Main_iPhone"
        let     storyboard     = UIStoryboard.init( name: storyboardName, bundle: nil )
        let     viewController = storyboard.instantiateViewController( withIdentifier: storyboardId )
        
        return viewController
    }
    
    
    func presentAlert( title: String, message: String ) {
        logVerbose( "[ %@ ]\n    [ %@ ]", title, message )
        let         alert    = UIAlertController.init( title: title, message: message, preferredStyle: .alert )
        let         okAction = UIAlertAction.init( title: NSLocalizedString( "ButtonTitle.OK", comment: "OK" ), style: .default, handler: nil )
        
        alert.addAction( okAction )
        
        present( alert, animated: true, completion: nil )
    }

    
    func runningInSimulator() -> Bool{
        var     simulator = false

        #if targetEnvironment(simulator)
        simulator = true
        #endif
        
        return simulator
    }
    
    
    func flagIsPresentInUserDefaults(_ key : String ) -> Bool {
        var     flagIsPresent = false
        
        if let _ = UserDefaults.standard.string( forKey: key ) {
            flagIsPresent = true
        }
        
        return flagIsPresent
    }
    
    
    func removeFlagFromUserDefaults(_ key: String ) {
        UserDefaults.standard.removeObject(forKey: key )
        UserDefaults.standard.synchronize()
    }
    
    
    func saveFlagInUserDefaults(_ key: String ) {
        UserDefaults.standard.set( key, forKey: key )
        UserDefaults.standard.synchronize()
    }
    
    
    func viewControllerWithStoryboardId( storyboardId: String ) -> UIViewController {
//        logVerbose( "[ %@ ]", storyboardId )
        let     storyboardName = ( ( .pad == UIDevice.current.userInterfaceIdiom ) ? "Main_iPad" : "Main_iPhone" )
        let     storyboard     = UIStoryboard.init( name: storyboardName, bundle: nil )
        let     viewController = storyboard.instantiateViewController( withIdentifier: storyboardId )
        
        return viewController
    }
    
    
}



// MARK: String Methods

extension String {
    
    func heightWithConstrainedWidth( width: CGFloat, font: UIFont ) -> CGFloat {
        let constraintRect = CGSize( width: width, height: .greatestFiniteMagnitude )
        let boundingBox    = self.boundingRect( with        : constraintRect,
                                                options     : [.usesLineFragmentOrigin, .usesFontLeading],
                                                attributes  : [NSAttributedString.Key.font: font],
                                                context     : nil)
        return boundingBox.height
    }
    
    
}



// MARK: Image Methods

extension UIImage {
    
    func alpha(_ value:CGFloat) -> UIImage {
        UIGraphicsBeginImageContextWithOptions(size, false, scale)
        draw(at: CGPoint.zero, blendMode: .normal, alpha: value)
        
        let newImage = UIGraphicsGetImageFromCurrentImageContext()
        
        UIGraphicsEndImageContext()
        
        return newImage!
    }
    
    
    func resized( withPercentage percentage: CGFloat, isOpaque: Bool = true ) -> UIImage? {
        let canvas = CGSize( width: size.width * percentage, height: size.height * percentage )
        let format = imageRendererFormat
        
        format.opaque = isOpaque
        
        return UIGraphicsImageRenderer( size: canvas, format: format ).image {
            _ in
            
            draw( in: CGRect( origin: .zero, size: canvas ) )
        }
        
    }
    
    
    func resized( toWidth width: CGFloat, isOpaque: Bool = true ) -> UIImage? {
        let canvas = CGSize( width: width, height: CGFloat( ceil( width/size.width * size.height ) ) )
        let format = imageRendererFormat
        
        format.opaque = isOpaque
        
        return UIGraphicsImageRenderer( size: canvas, format: format ).image {
            _ in
            
            draw( in: CGRect( origin: .zero, size: canvas ) )
        }
        
    }
    
    
}



// MARK: Global Methods

func dateFrom(_ dateString: String ) -> Date {
    let     dateComponentArray = dateString.components(separatedBy: "-" )
    var     date = Date.distantFuture
    
    if dateComponentArray.count == 3 {
        let     formatter = DateFormatter()
        
        formatter.locale     = .current
        formatter.dateFormat = "yyyy-MM-dd"
        
        date = formatter.date(from: dateString)!
    }
    
    return date
}


func stringFor(_ boolValue: Bool ) -> String {
    return ( boolValue ? "true" : "false" )
}


func stringFor(_ date: Date ) -> String {
    let     calendar = Calendar.current
    let     year     = calendar.component( .year,  from: date )
    let     month    = calendar.component( .month, from: date )
    let     day      = calendar.component( .day,   from: date )
    
    return String( format: "%4d-%02d-%02d", year, month, day )
}


func stringFor(_ decimalValue: NSDecimalNumber, withCurrencySymbol: Bool ) -> String {
    var     amountString = ""
    let     formatter    = NumberFormatter()
    
    formatter.locale      = .current
    formatter.numberStyle = withCurrencySymbol ? .currency : .decimal
    
    if let string = formatter.string( from: decimalValue ) {
        amountString = string
    }
    
    return amountString
}


func stringFor(_ rect: CGRect ) -> String {
    return String( format: "[ %3.1f, %3.1f ][ %3.1f, %3.1f ]", rect.origin.x, rect.origin.y, rect.size.width, rect.size.height )
}


