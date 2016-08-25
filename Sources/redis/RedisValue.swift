//
//  RedisValue.swift
//  Noze.io
//
//  Created by Helge Heß on 6/25/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import core

public struct RedisError : Error {
  let code    : String
  let message : String
}

public enum RedisValue {
  case SimpleString([UInt8])
  case BulkString  ([UInt8]?)
  case Integer     (Int)
  case Array       ([RedisValue]?)
  case Error       (RedisError)
}


// MARK: - Initializers

public extension RedisValue {
  
  public init(_ v: Int) {
    self = .Integer(v)
  }
  
  public init(bulkString s: String?) {
    if let s = s {
      self = .BulkString(Swift.Array<UInt8>(s.utf8))
    }
    else {
      self = .BulkString(nil)
    }
  }
  
  public init(simpleString s: String) {
    self = .SimpleString(Swift.Array<UInt8>(s.utf8))
  }
  
  public var stringValue : String? {
    switch self {
      case .SimpleString(let cs):
        guard let s = String.decode(utf8: cs) else { return nil }
        return s
      
      case .BulkString(let cs):
        guard let cs = cs                     else { return nil }
        guard let s = String.decode(utf8: cs) else { return nil }
        return s
      
      case .Integer(let i):
        return String(i)
      
      default: return nil
    }
  }
  
  public var intValue : Int? {
    switch self {
      // TBD: convert strings?
      case .Integer(let i): return i
      default: return nil
    }
  }
}

public func ==(lhs: RedisValue, rhs: String) -> Bool {
  switch lhs {
    case .SimpleString(let cs):
      guard let s = String.decode(utf8: cs) else { return false }
      return s == rhs
    
    case .BulkString(let cs):
      guard let cs = cs                     else { return false }
      guard let s = String.decode(utf8: cs) else { return false }
      return s == rhs
    
    default:
      return false
  }
}


// MARK: - Parse Literals

extension RedisValue : ExpressibleByIntegerLiteral {
  public init(integerLiteral value: IntegerLiteralType) {
    self = .Integer(value)
  }
}

extension RedisValue : ExpressibleByStringLiteral {
  
  public init(stringLiteral value: String) {
    self = .BulkString(Swift.Array(value.utf8))
  }
  public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
    self = .BulkString(Swift.Array(value.utf8))
  }
  public init(unicodeScalarLiteral value: StringLiteralType) {
    self = .BulkString(Swift.Array(value.utf8))
  }
  
}


// MARK: - Convert to String

extension RedisValue : CustomStringConvertible {
  
  public var description : String {
    switch self {
      case .SimpleString(let cs):
        return String.decode(utf8: cs) ?? "\(cs)"
      
      case .BulkString(let cs):
        if let cs = cs {
          return String.decode(utf8: cs) ?? "\(cs)"
        }
        else {
          return "<nil-str>"
        }
      case .Integer(let i):
        return String(i)
      
      case .Array(let members):
        if let members = members {
          return members.description
        }
        else {
          return "<nil-array>"
        }
      
      case .Error(let e):
        return "<Error: \(e)>"
    }
  }

}
