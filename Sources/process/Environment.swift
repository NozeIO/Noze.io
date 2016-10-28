//
//  Environment.swift
//  Noze.io
//
//  Created by Helge Heß on 4/27/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

public let argv = CommandLine.arguments

import class Foundation.ProcessInfo
  // extern char **environ; doesn't seem to be exposed

public var env : [ String : String ] {
  return ProcessInfo.processInfo.environment
}
