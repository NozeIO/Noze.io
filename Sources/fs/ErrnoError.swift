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

public extension POSIXErrorCode {

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

extension POSIXErrorCode : CustomStringConvertible {
  
  public var description : String {
    if self.rawValue == 0 {
      return "<POSIXErrorCode: OK>"
    }
    if let s = errorString {
      return "<POSIXErrorCode: \(rawValue) '\(s)'>"
    }
    return "<POSIXErrorCode: \(rawValue)>"
  }
  
}

import core

public extension Error {
  
  var isWouldBlockError : Bool {
    guard let posixError = self as? POSIXErrorCode else {
      return false // a non-Posix error
    }
    
    return posixError == POSIXErrorCode.EAGAIN
  }
  
}
