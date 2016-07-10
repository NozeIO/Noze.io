//
//  Environment.swift
//  Noze.io
//
//  Created by Helge Heß on 4/27/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

public let argv = Process.arguments

#if os(Linux)

// Separate source file

#else

#if swift(>=3.0) // #swift3-fd
import class Foundation.ProcessInfo
  // extern char **environ; doesn't seem to be exposed

public var environ : [ String : String ] {
  return ProcessInfo.processInfo().environment
}
#else
import class Foundation.NSProcessInfo
  // extern char **environ; doesn't seem to be exposed

public var environ : [ String : String ] {
  return NSProcessInfo.processInfo().environment
}
#endif
#endif
