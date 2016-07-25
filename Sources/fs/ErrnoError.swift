//
//  ErrnoError.swift
//  Noze.IO
//
//  Created by Helge Hess on 25/06/15.
//  Copyright © 2015 ZeeZide GmbH. All rights reserved.
//

#if os(Linux)
import Glibc
import xsys
#else
import Darwin
#endif

public extension POSIXError {

  var errorString : String? {
    let errno = self.rawValue
    guard errno != 0 else { return nil }
#if swift(>=3.0) // #swift3-fd
    return String(cString: strerror(errno))
#else
    return String.fromCString(strerror(errno))
#endif
  }
  
}

extension POSIXError : CustomStringConvertible {
  
  public var description : String {
    if self.rawValue == 0 {
      return "<POSIXError: OK>"
    }
    if let s = errorString {
      return "<POSIXError: \(rawValue) '\(s)'>"
    }
    return "<POSIXError: \(rawValue)>"
  }
  
}

import core

public extension ErrorProtocol {
  
  var isWouldBlockError : Bool {
    guard let posixError = self as? POSIXError else {
      return false // a non-Posix error
    }
    
    return posixError == POSIXError.EAGAIN
  }
  
}
