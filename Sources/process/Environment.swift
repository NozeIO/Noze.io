//
//  Environment.swift
//  NozeIO
//
//  Created by Helge Heß on 4/27/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

public let argv = Process.arguments

#if os(Linux)

// Separate source file

#else

import class Foundation.NSProcessInfo
  // extern char **environ; doesn't seem to be exposed

public var environ : [ String : String ] {
  return NSProcessInfo.processInfo().environment
}
#endif
