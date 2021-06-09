//
//  Logger.swift
//  Chefbook
//
//  Created by Clint Shank on 4/6/20.
//  Copyright © 2020 Omni-Soft, Inc. All rights reserved.
//

import UIKit


// MARK: AppDelegate Methods

func setupLogging() {
    // NOTE: This should be called from application(_ application, didFinishLaunchingWithOptions )
    let     dateFormatter  = DateFormatter.init()
    let     infoDictionary = Bundle.main.infoDictionary!
    let     runCounterKey  = "RUNCOUNTER"
    let     userDefaults   = UserDefaults.standard
    var     runCounter     = userDefaults.integer(forKey: runCounterKey )
    let     vendorId       = UIDevice.current.identifierForVendor?.uuidString ?? "Unknown"

    runCounter += 1
    userDefaults.set( runCounter, forKey: runCounterKey )
    userDefaults.synchronize()
    
    dateFormatter.dateFormat = "MM-dd-YYYY HH:mm:ss:SSS z"
    
    let     output = String( format : """
                                      >>> Starting OSI Error and Warning Logging <<<
                                      Application    %@
                                      Current Time   %@
                                      Device Name    %@
                                      Device UUID    %@
                                      OS Version     %@
                                      Build Version  %@
                                      Environment    %@
                                      Launch Counter %d\n
                                      """,
                             infoDictionary["CFBundleName"] as! String,
                             dateFormatter.string( from : Date() ),
                             UIDevice.current.name,
                             vendorId,
                             UIDevice.current.systemVersion,
                             infoDictionary["CFBundleShortVersionString"] as! String,
                             UIDevice.current.model,
                             runCounter );
    log( output )
}



// MARK: Logging Methods (Public)

func logTrace( filename   : String = #file,
               function   : String = #function,
               lineNumber : Int    = #line,
               _ message  : String = "" ) {
    var     output = stringTimeAndLocation( filename, function, lineNumber )
 
    if !message.isEmpty {
        output += " - " + message
    }

    log( output )
}


func logVerbose( filename   : String = #file,
                 function   : String = #function,
                 lineNumber : Int    = #line,
                 _ format   : String,
                 _ args     : CVarArg... ) {
//    var     message = String( format: format, args )    // NOTE: This doesn't work with multiple args yet ... maybe in a future version of Swift
    let     message = populateFormat( format, args )
    var     output  = stringTimeAndLocation( filename, function, lineNumber )

    if !message.isEmpty {
        output += " - " + ( message as String )
    }

    log( output )
}



// MARK: Utility Methods (Private)

fileprivate func log(_ message : String ){
    print( message )
    
    // TODO: Later ... log this to disk
}


fileprivate func populateFormat(_ format : String, _ argArray : [CVarArg] ) -> String {
    var     argIndex         = 0
    var     componentIndex   = 0
    let     formatComponents = format.components(separatedBy: "%" )
    var     outputString     = ""
    
    for component in formatComponents {
        if componentIndex == 0 {
            outputString += component
        }
        else {
            let     formatString    = "%" + component
            let     populatedString = String( format: formatString, argArray[argIndex] )
                
            outputString += populatedString
            argIndex += 1
        }
        
        componentIndex += 1
    }
    
    return outputString
}


fileprivate func stringTimeAndLocation(_ filename   : String,
                                       _ function   : String,
                                       _ lineNumber : Int ) -> String {
    let     dateFormatter    = DateFormatter.init()
    let     fileUrl          = URL( fileURLWithPath: filename )
    let     lastUrlComponent = fileUrl.lastPathComponent
    let     fileComponents   = lastUrlComponent.components(separatedBy: "." )
    var     rootFilename     = lastUrlComponent
    
    if fileComponents.count == 2 {
        rootFilename = fileComponents[0]
    }
    
    dateFormatter.dateFormat = "MM-dd-YYYY HH:mm:ss:SSS z"

    return String( format : "%@ %@::%@[ %d ]", dateFormatter.string( from : Date() ), rootFilename, function, lineNumber )
}




