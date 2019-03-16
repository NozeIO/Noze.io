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

/// Unix timestamp. `time_t` has the Y2038 issue and its granularity is limited
/// to seconds.
/// Unix timestamps are counted in seconds starting Jan 1st 1970 00:00:00, UTC.
public extension time_t {
  
  /// Returns the current time.
  static var now : time_t { return xsys.time(nil) }
  
  /// Initialize the `time_t` value from Unix `tm` value (date components).
  /// Assumes the values are given in *local time*.
  /// Remember that the `time_t` itself is in UTC.
  init(_ tm: xsys.struct_tm) {
    self = tm.localTime
  }
  /// Initialize the `time_t` value from Unix `tm` value (date components).
  /// Assumes the values are given in *UTC time*.
  /// Remember that the `time_t` itself is in UTC.
  init(utc tm: xsys.struct_tm) {
    self = tm.utcTime
  }
  
  /// Converts the `time_t` timestamp into date components (`tz` struct) living
  /// in the UTC timezone.
  /// Remember that the `time_t` itself is in UTC.
  var componentsInUTC : xsys.struct_tm {
    var t  = self
    var tm = xsys.struct_tm()
    _ = xsys.gmtime_r(&t, &tm)
    return tm
  }
  
  /// Converts the `time_t` timestamp into date components (`tz` struct) living
  /// in the local timezone of the Unix environment.
  /// Remember that the `time_t` itself is in UTC.
  var componentsInLocalTime : xsys.struct_tm {
    var t  = self
    var tm = xsys.struct_tm()
    _ = xsys.localtime_r(&t, &tm)
    return tm
  }
  
  /// Example `strftime` format:
  ///   "%a, %d %b %Y %H:%M:%S GMT"
  ///
  /// This function converts the timestamp into UTC time components to format
  /// the value.
  ///
  /// Example call:
  ///
  ///     xsys.time(nil).format("%a, %d %b %Y %H:%M:%S %Z")
  ///
  func format(_ sf: String) -> String {
    return self.componentsInUTC.format(sf)
  }
}

/// The Unix `tm` struct is essentially NSDateComponents PLUS some timezone
/// information (isDST, offset, tz abbrev name).
public extension xsys.struct_tm {
  
  /// Create a Unix date components structure from a timestamp. This variant
  /// creates components in the local timezone.
  init(_ tm: time_t) {
    self = tm.componentsInLocalTime
  }
  
  /// Create a Unix date components structure from a timestamp. This variant
  /// creates components in the UTC timezone.
  init(utc tm: time_t) {
    self = tm.componentsInUTC
  }
  
  var utcTime : time_t {
    var tm = self
    return timegm(&tm)
  }
  var localTime : time_t {
    var tm = self
    return mktime(&tm)
  }
  
  /// Example `strftime` format (`man strftime`):
  ///   "%a, %d %b %Y %H:%M:%S GMT"
  ///
  func format(_ sf: String, defaultCapacity: Int = 100) -> String {
    var tm = self
    
    // Yes, yes, I know.
    let attempt1Capacity = defaultCapacity
    let attempt2Capacity = defaultCapacity > 1024 ? defaultCapacity * 2 : 1024
    var capacity = attempt1Capacity
    
    var buf = UnsafeMutablePointer<CChar>.allocate(capacity: capacity)
    #if swift(>=4.1)
      defer { buf.deallocate() }
    #else
      defer { buf.deallocate(capacity: capacity) }
    #endif
  
    let rc = xsys.strftime(buf, capacity, sf, &tm)
  
    if rc == 0 {
      #if swift(>=4.1)
        buf.deallocate()
      #else
        buf.deallocate(capacity: capacity)
      #endif
      capacity = attempt2Capacity
      buf = UnsafeMutablePointer<CChar>.allocate(capacity: capacity)
  
      let rc = xsys.strftime(buf, capacity, sf, &tm)
      assert(rc != 0)
      guard rc != 0 else { return "" }
    }
  
    return String(cString: buf);
  }
  
}
