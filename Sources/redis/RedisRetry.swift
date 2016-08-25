//
//  RedisRetry.swift
//  Noze.io
//
//  Created by Helge Hess on 21/07/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import xsys
import core


/// A callback which defines the connect-retry strategy.
public typealias RedisRetryStrategyCB = ( RedisRetryInfo ) -> RedisRetryResult


/// Object passed to the RetryStrategy callback. Contains information on the
/// number of tries etc.
public struct RedisRetryInfo {
  
  var attempt         : Int            = 0
  var totalRetryTime  : timeval        = timeval()
  var timesConnected  : Int            = 0
  var lastSocketError : Error? = nil
  
  mutating func registerSuccessfulConnect() {
    self.timesConnected  += 1
    self.totalRetryTime  = timeval.now
    self.lastSocketError = nil
    self.attempt         = 0
  }
}

public enum RedisRetryResult {
  case RetryAfter(milliseconds: Int)
  case Error(SwiftError)
  case Stop
}

/// This way the callback can do a simple:
///
///     return 250
///
/// instead of
///
///     return .RetryAfter(milliseconds: 250)
///
/// To retry after 250ms. Makes it more similar
/// to the original API.
///
extension RedisRetryResult : ExpressibleByIntegerLiteral {
  
  public init(integerLiteral value: Int) {
    self = .RetryAfter(milliseconds: value)
  }
  
}
