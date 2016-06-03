//
//  Module.swift
//  NozeIO
//
//  Created by Helge Heß on 4/3/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

@_exported import core

public class NozeChildProcess: NozeModule {
}

public var module = NozeChildProcess()


#if os(Linux)
#else
  // importing this from xsys doesn't seem to work
  import Foundation // this is for POSIXError : ErrorType
#endif
