//
//  AppLog.swift
//  MyPins
//
//  Created by Clint Shank on 5/11/18.
//  Copyright © 2018 Omni-Soft, Inc. All rights reserved.
//

import Foundation



func appLogTrace( filename:   String = #file,
                  function:   String = #function,
                  lineNumber: Int    = #line )
{
    let         logFlag      = DDLogFlag          .init( rawValue: 16 )     // DDLogFlagVerbose
    let         logLevel     = DDLogLevel         .init( rawValue: 31 )     // All Levels
    let         logOptions   = DDLogMessageOptions.init( rawValue: 4  )     // DDLogMessageDontCopyMessage
    let         ddLogMessage = DDLogMessage.init( message:  "",
                                                  level:    logLevel!,
                                                  flag:     logFlag,
                                                  context:  0,
                                                  file:     filename,
                                                  function: function,
                                                  line:     UInt( lineNumber ),
                                                  tag:      nil,
                                                  options:  logOptions,  // Try DDLogMessageCopyFile, DDLogMessageCopyFunction and DDLogMessageDontCopyMessage
        timestamp: Date.init() )
    DDLog.log( asynchronous: true,
               message: ddLogMessage )
}


func appLogVerbose( filename:   String = #file,
                    function:   String = #function,
                    lineNumber: Int    = #line,
                    format:     String,
                    parameters: String... )
{
    let         logFlag      = DDLogFlag          .init( rawValue: 16 )     // DDLogFlagVerbose
    let         logLevel     = DDLogLevel         .init( rawValue: 31 )     // All Levels
    let         logOptions   = DDLogMessageOptions.init( rawValue: 4  )     // DDLogMessageDontCopyMessage
    let         message      = String.init( format: format, arguments: parameters )
    let         ddLogMessage = DDLogMessage.init( message:   message,
                                                  level:     logLevel!,
                                                  flag:      logFlag,
                                                  context:   0,
                                                  file:      filename,
                                                  function:  function,
                                                  line:      UInt( lineNumber ),
                                                  tag:       nil,
                                                  options:   logOptions,  // Try DDLogMessageCopyFile, DDLogMessageCopyFunction and DDLogMessageDontCopyMessage
        timestamp: Date.init() )
    DDLog.log( asynchronous: true,
               message: ddLogMessage )
}
