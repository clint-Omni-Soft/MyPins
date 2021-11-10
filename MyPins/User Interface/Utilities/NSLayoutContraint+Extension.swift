//
//  NSLayoutContraint+Extension.swift
//  MyPins
//
//  Created by Clint Shank on 4/9/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//

import UIKit



extension NSLayoutConstraint {
    
    func description() -> String {
        return String.init( format: "[ %@ ] = [ %f ]", self.identifier!, self.constant )
    }
    
}
