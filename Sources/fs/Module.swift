//
//  fs.swift
//  Noze.IO
//
//  Created by Helge Hess on 02/07/15.
//  Copyright © 2015 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import core
import streams

public class NozeFS : NozeModule {
  
  // A queue which is used by all FS functions to do async operations (not
  // covered by GCD)
  lazy var Q = xsys_get_default_global_queue()
}
public let module = NozeFS()


// MARK: - Common type aliases

public typealias DataCB   = ( Error?, [ UInt8 ]? ) -> Void
public typealias StringCB = ( Error?, String?    ) -> Void
public typealias ErrorCB  = ( Error?             ) -> Void


// MARK: - Watch Files or Directories. Get notified on changes.

public func watch(filename   : String,
                  persistent : Bool = true,
                  recursive  : Bool = false,
                  listener   : FSWatcherCB? = nil) -> FSWatcher
{
  assert(recursive == false, "unsupported")
    // need a special recursive watcher which traverses the filesystem and
    // subscribes each node
  
  return FSWatcher(filename, persistent: persistent,
                   listener: listener)
}

#if swift(>=3.0) // #swift3-1st-kwarg
public func watch(_ filename : String,
                  persistent : Bool = true,
                  recursive  : Bool = false,
                  listener   : FSWatcherCB? = nil) -> FSWatcher
{
  return watch(filename: filename, persistent: persistent, recursive: recursive,
               listener: listener)
}
#endif
