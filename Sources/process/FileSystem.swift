//
//  FileSystem.swift
//  Noze.io
//
//  Created by Helge Heß on 4/27/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if os(Linux)
  import Glibc
#else
  import Darwin
  // importing this from xsys doesn't seem to work
  import Foundation // this is for POSIXError : Error
#endif

import xsys

public func chdir(path: String) throws {
  let rc = xsys.chdir(path)
  guard rc == 0 else { throw POSIXErrorCode(rawValue: xsys.errno)! }
}

public func cwd() -> String {
  let rc = xsys.getcwd(nil /* malloc */, 0)
  assert(rc != nil, "process has no cwd??")
  defer { free(rc) }
  guard rc != nil else { return "" }
  
#if swift(>=3.0) // #swift3-cstr #swift3-ptr
  let s = String(validatingUTF8: rc!)
#else
  let s = String.fromCString(rc)
#endif
  assert(s != nil, "could not convert cwd to String?!")
  return s!
}

// TODO: umask
