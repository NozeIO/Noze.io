//
//  PosixWrappers.swift
//  NozeIO
//
//  Created by Helge Heß on 5/8/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if swift(>=3.0)
#else // Swift 2.2
import Dispatch

import xsys
#if os(Linux)
#else
  import enum Foundation.POSIXError
#endif

import core

public let F_OK = Int(xsys.F_OK)
public let R_OK = Int(xsys.R_OK)
public let W_OK = Int(xsys.W_OK)
public let X_OK = Int(xsys.X_OK)


// MARK: - Async functions, Unix functions are dispatched to a different Q

/// Check whether we have access to the given path in the given mode.
public func access(path: String, _ mode: Int = F_OK, cb: ErrorCB) {
  module.Q.evalAsync(accessSync, (path, mode), cb)
}

public func stat(path: String, cb: ( ErrorType?, xsys.stat_struct? ) -> Void) {
  module.Q.evalAsync(statSync, path, cb)
}
public func lstat(path: String, cb: ( ErrorType?, xsys.stat_struct? ) -> Void) {
  module.Q.evalAsync(lstatSync, path, cb)
}


// MARK: - Synchronous wrappers

// If you do a lot of FS operations in sequence, you might want to use a single
// (async) GCD call, instead of using the convenience async functions.
//
// Example:
//   dispatch_async(module.Q) {
//     statSync(...)
//     accessSync(...)
//     readdirSync(..)
//     dispatch(core.Q) { cb() }
//   }

public func accessSync(path: String, mode: Int = F_OK) throws {
  let rc = xsys.access(path, Int32(mode))
  if rc != 0 { throw POSIXError(rawValue: xsys.errno)! }
}

public func statSync(path: String) throws -> xsys.stat_struct {
  var info = xsys.stat_struct()
  let rc   = xsys.stat(path, &info)
  if rc != 0 { throw POSIXError(rawValue: xsys.errno)! }
  return info
}
public func lstatSync(path: String) throws -> xsys.stat_struct {
  var info = xsys.stat_struct()
  let rc   = xsys.lstat(path, &info)
  if rc != 0 { throw POSIXError(rawValue: xsys.errno)! }
  return info
}
#endif // Swift 2.2
