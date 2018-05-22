//
//  Logger.swift
//  MyPins
//
//  Created by Clint Shank on 5/11/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//

import Foundation


// NOTES: This class invokes the DDLogMessage Objective-C method in ZLogKit and is intended to be used by Swift files
//        For Objective-C files use the MACROS ZLog.h (ZLogTrace & ZLogVerbose)
//        This class must be copied into each project because Swift classes inside a framework are not visible to Swift files in the calling project


// TODO: logOptions - Try DDLogMessageCopyFile, DDLogMessageCopyFunction and DDLogMessageDontCopyMessage

func logTrace( filename:   String = #file,
               function:   String = #function,
               lineNumber: Int    = #line,
               _ message:  String = "" )
{
    let         logFlag      = DDLogFlag          .init( rawValue: 16 )     // DDLogFlagVerbose
    let         logLevel     = DDLogLevel         .init( rawValue: 31 )     // All Levels
    let         logOptions   = DDLogMessageOptions.init( rawValue: 4  )     // DDLogMessageDontCopyMessage
    let         ddLogMessage = DDLogMessage.init( message:   message,
                                                  level:     logLevel!,
                                                  flag:      logFlag,
                                                  context:   0,
                                                  file:      filename,
                                                  function:  function,
                                                  line:      UInt( lineNumber ),
                                                  tag:       nil,
                                                  options:   logOptions,
                                                  timestamp: Date.init() )
    
    DDLog.log( asynchronous: true,
               message:      ddLogMessage )
}


func logVerbose( filename:   String = #file,
                 function:   String = #function,
                 lineNumber: Int    = #line,
                 _ format:   String,
                 _ args:     CVarArg... )
{
    let         logFlag      = DDLogFlag          .init( rawValue: 16 )     // DDLogFlagVerbose
    let         logLevel     = DDLogLevel         .init( rawValue: 31 )     // All Levels
    let         logOptions   = DDLogMessageOptions.init( rawValue: 4  )     // DDLogMessageDontCopyMessage
    let         message      = String.init( format: format, arguments: args )
    let         ddLogMessage = DDLogMessage.init( message:   message,
                                                  level:     logLevel!,
                                                  flag:      logFlag,
                                                  context:   0,
                                                  file:      filename,
                                                  function:  function,
                                                  line:      UInt( lineNumber ),
                                                  tag:       nil,
                                                  options:   logOptions,
                                                  timestamp: Date.init() )
    DDLog.log( asynchronous: true,
               message:      ddLogMessage )
}


func stringFor(_ boolValue: Bool ) -> String
{
    return ( boolValue ? "true" : "false" )
}
