//
//  timeval_any.swift
//  Noze.io
//
//  Created by Helge Hess on 21/07/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if os(Linux)
import func Glibc.gettimeofday
#else
import func Darwin.gettimeofday
#endif


/// Stuff common to any of the three(?) Unix time value structures:
/// - timeval_t  (sec/microsec granularity)
/// - timespec_t (sec/nanosec  granularity)
/// - time_t     (sec          granularity)
///
/// The values in this protocol are not components (as they are stored in tv_
/// like struct fields), but they overflow.
/// E.g.
///
///   timeval(seconds: 10, milliseconds: 2000)
///
/// Will create a value of 12 seconds.
///
public protocol timeval_any {
  
  static var now : Self { get }
  
  init()
  init(seconds: Int, milliseconds: Int)
  
  var seconds      : Int { get }
  var milliseconds : Int { get }
  
  var componentsInUTC       : xsys.struct_tm { get }
  var componentsInLocalTime : xsys.struct_tm { get }

  static func -(left: Self, right: Self) -> Self
}

public extension timeval_any {

  var componentsInUTC : xsys.struct_tm {
    return time_t(seconds).componentsInUTC
  }
  var componentsInLocalTime : xsys.struct_tm {
    return time_t(seconds).componentsInLocalTime
  }
}


extension time_t : timeval_any {
  
  public init(seconds: Int, milliseconds: Int = 0) {
    assert(milliseconds == 0) // just print a warning, the user should know
    self = seconds
  }
  
  public var seconds      : Int { return self }
  public var milliseconds : Int { return self * 1000 }
}


extension timeval : timeval_any {
  
  public static var now : timeval {
    var now = timeval()
    _ = gettimeofday(&now, nil)
    return now
  }

  public init(_ ts: timespec) {
    #if swift(>=4.1)
      self.init()
    #endif
    tv_sec  = ts.seconds
#if os(Linux)
    tv_usec = ts.tv_nsec / 1000
#else
    tv_usec = Int32(ts.tv_nsec / 1000)
#endif
  }
  
  public init(seconds: Int, milliseconds: Int = 0) {
    #if swift(>=4.1)
      self.init()
    #endif
    tv_sec  = seconds + (milliseconds / 1000)
#if os(Linux)
    tv_usec = (milliseconds % 1000) * 1000
#else
    tv_usec = Int32(milliseconds % 1000) * 1000
#endif
  }
  
  public var seconds : Int {
    // TBD: rounding on tv_usec?
    return Int(tv_sec)
  }
  
  public var milliseconds : Int {
    return (tv_sec * 1000) + (Int(tv_usec) / 1000)
  }
  
}

extension timespec : timeval_any {
  
  public static var now : timespec { return timespec(timeval.now) }

  public init(_ tv: timeval) {
    #if swift(>=4.1)
      self.init()
    #endif
    tv_sec  = tv.seconds
    tv_nsec = Int(tv.tv_usec) * 1000
  }
  
  public init(seconds: Int, milliseconds: Int = 0) {
    #if swift(>=4.1)
      self.init()
    #endif
    tv_sec  = seconds + (milliseconds / 1000)
    tv_nsec = (milliseconds % 1000) * 1000000
  }
  
  public var seconds : Int {
    // TBD: rounding on tv_nsec?
    return tv_sec
  }
  
  public var milliseconds : Int {
    return (tv_sec * 1000) + (tv_nsec / 1000000)
  }
  
}
