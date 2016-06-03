//
//  time.swift
//  Noze.io
//
//  Created by Helge Hess on 19/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if os(Linux)
  import Glibc

  public typealias struct_tm = Glibc.tm
  public typealias time_t    = Glibc.time_t
  
  public let time          = Glibc.time
  public let gmtime_r      = Glibc.gmtime_r
  public let localtime_r   = Glibc.localtime_r
  public let strftime      = Glibc.strftime
  
#else
  import Darwin
  
  public typealias struct_tm = Darwin.tm
  public typealias time_t    = Darwin.time_t

  public let time          = Darwin.time
  public let gmtime_r      = Darwin.gmtime_r
  public let localtime_r   = Darwin.localtime_r
  public let strftime      = Darwin.strftime
#endif


// MARK: - Time Helpers

public extension time_t {
  
  public init(_ tm: xsys.struct_tm) {
    self = tm.localTime
  }
  
  public var componentsInUTC : xsys.struct_tm {
    var t  = self
    var tm = xsys.struct_tm()
    _ = xsys.gmtime_r(&t, &tm)
    return tm
  }
  public var componentsInLocalTime : xsys.struct_tm {
    var t  = self
    var tm = xsys.struct_tm()
    _ = xsys.localtime_r(&t, &tm)
    return tm
  }
  
  /// Example `strftime` format:
  ///   "%a, %d %b %Y %H:%M:%S GMT"
  ///
  public func format(sf: String) -> String {
    return self.componentsInUTC.format(sf)
  }
}

public extension xsys.struct_tm {
  
  public init(_ tm: time_t) {
    self = tm.componentsInLocalTime
  }
  
  public var utcTime : time_t {
    var tm = self
    return timegm(&tm)
  }
  public var localTime : time_t {
    var tm = self
    return mktime(&tm)
  }
  
  /// Example `strftime` format (`man strftime`):
  ///   "%a, %d %b %Y %H:%M:%S GMT"
  ///
  public func format(sf: String, defaultCapacity: Int = 100) -> String {
    var tm = self
    
    // Yes, yes, I know.
    let attempt1Capacity = defaultCapacity
    let attempt2Capacity = defaultCapacity > 1024 ? defaultCapacity * 2 : 1024
    var capacity = attempt1Capacity
    
#if swift(>=3.0) // #swift3-cstr #swift3-ptr
    var buf = UnsafeMutablePointer<CChar>(allocatingCapacity: capacity)
    defer { buf.deallocateCapacity(capacity) }
  
    let rc = xsys.strftime(buf, capacity, sf, &tm)
  
    if rc == 0 {
      buf.deallocateCapacity(capacity)
      capacity = attempt2Capacity
      buf = UnsafeMutablePointer<CChar>(allocatingCapacity: capacity)
  
      let rc = xsys.strftime(buf, capacity, sf, &tm)
      assert(rc != 0)
      guard rc != 0 else { return "" }
    }
  
    return String(cString: buf);
#else // Swift 2.2
    var buf = UnsafeMutablePointer<CChar>.alloc(capacity)
    defer { buf.dealloc(capacity) }
  
    let rc = xsys.strftime(buf, capacity, sf, &tm)
  
    if rc == 0 {
      buf.dealloc(capacity)
      capacity = attempt2Capacity
      buf = UnsafeMutablePointer<CChar>.alloc(capacity)
      
      let rc = xsys.strftime(buf, capacity, sf, &tm)
      assert(rc != 0)
      guard rc != 0 else { return "" }
    }
  
    let s = String.fromCString(buf);
    assert(s != nil)
    return s ?? ""
#endif
  }
  
}

#if swift(>=3.0) // #swift3-1st-kwarg
public extension time_t {
  public func format(_ sf: String) -> String { return self.format(sf: sf) }
}
public extension xsys.struct_tm {
  public func format(_ sf: String) -> String { return self.format(sf: sf) }
}
#endif
