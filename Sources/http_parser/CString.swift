//
//  CString.swift
//  HTTPParser
//
//  Created by Helge Heß on 4/26/16.
//  Copyright © 2016 Always Right Institute. All rights reserved.
//
#if os(Linux)
  import Glibc
#else
  import Darwin
#endif

// Those are mostly dirty hacks to get what I need :-)
// I would be very interested in better way to do those things, W/O using
// Foundation.

extension String {
  
  func makeCString() -> UnsafePointer<CChar> {
    let mp = self.withCString { cstr in strdup(cstr) }
    return UnsafePointer<CChar>(mp!)
      // a non-opt string always results in at least ""
  }
  
  static func fromCString(_ cs: UnsafePointer<CChar>, length olength: Int?)
              -> String?
  {
    guard let length = olength else { // no length given, use \0 std imp
      return String(validatingUTF8: cs)
    }
    
    let buflen = length + 1
    let buf    = UnsafeMutablePointer<CChar>.allocate(capacity: buflen)
    memcpy(buf, cs, length)
    buf[length] = 0 // zero terminate

    let s = String(validatingUTF8: buf)
    buf.deallocate(capacity: buflen)

    return s
  }
}
