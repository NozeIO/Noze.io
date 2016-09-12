//
//  Path.swift
//  Noze.io
//
//  Created by Helge Heß on 6/8/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if os(Linux)
  import Glibc
#else
  import Darwin
#endif

import core


public class PathModule : NozeModule {
  
  public func basename(_ path: String) -> String {
    // TODO: this doesn't deal proper with trailing slashes
    return path.withCString { cs in
      let sp = rindex(cs, 47 /* / */)
      guard sp != nil else { return path }
      let bn = sp! + 1
      return String(cString: bn)
    }
  }
  
  public func dirname(_ path: String) -> String {
    // TODO: this doesn't deal proper with trailing slashes
    return path.withCString { cs in
      let sp = UnsafePointer<CChar>(rindex(cs, 47 /* / */))
      guard sp != nil else { return path }
      let len = sp! - cs
      return String.fromCString(cs, length: len)!
    }
  }
  
}

public let path = PathModule()


// MARK: - CString

extension String {
  
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
