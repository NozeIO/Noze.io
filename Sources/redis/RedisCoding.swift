//
//  RedisCoding.swift
//  Noze.io
//
//  Created by Helge Heß on 6/26/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import core

public protocol RedisEncodable {
  
  func toRedis() -> RedisValue
  
}

extension Int : RedisEncodable {
  
  public func toRedis() -> RedisValue {
    return RedisValue.Integer(self)
  }
  
}

extension String : RedisEncodable {
  
  public func toRedis() -> RedisValue {
    return RedisValue.BulkString(Array<UInt8>(self.utf8))
  }
  
}

extension Array where Element: RedisEncodable {
  // Note: This doesn't make `Array` itself a RedisEncodable!
  
  public func toRedis() -> RedisValue {
    let arrayOfRedisValues = self.map { $0.toRedis() }
    return .Array(arrayOfRedisValues)
  }
  
}

extension Array: RedisEncodable {
  
  public func toRedis() -> RedisValue {
    let array : [ RedisValue ] = self.map { v in
      if let rv = (v as? RedisEncodable) {
        return rv.toRedis()
      }
      else { // hm, hm
        return String(describing: v).toRedis()
      }
    }
    return .Array(array)
  }
}

// MARK: - RedisDecodable

enum RedisDecodingError : Error {
  case ValueNotConvertible     (value: RedisValue, to: Any.Type)
  case ByteStringNotConvertible(value: [UInt8]?,   to: Any.Type)
}

protocol RedisDecodable {
  
  init?(redisValue v: RedisValue) throws
  
}

extension String : RedisDecodable {
  
  init?(redisValue v: RedisValue) throws {
    switch v {
      case .Integer(let v):
        self = String(v)
      
      case .BulkString(let v):
        guard let ba = v else { return nil }
        guard let s  = String.decode(utf8: ba) else {
          throw RedisDecodingError.ByteStringNotConvertible(value: v,
                                                          to: Swift.String.self)
        }
        self = s
      
      case .SimpleString(let v):
        guard let s  = String.decode(utf8: v) else {
          throw RedisDecodingError.ByteStringNotConvertible(value: v,
                                                          to: Swift.String.self)
        }
        self = s

      default:
        throw RedisDecodingError.ValueNotConvertible(value: v,
                                                     to: Swift.String.self)
    }
  }
}

extension Int : RedisDecodable {
  
  init?(redisValue v: RedisValue) throws {
    switch v {
      case .Integer(let v):
        self = v
      
      case .BulkString(let byteArray):
        guard let iv = try? Int.from(byteStringArray: byteArray) else {
          throw RedisDecodingError.ValueNotConvertible(value: v,
                                                       to: Swift.Int.self)
        }
        self = iv
      
      case .SimpleString(let byteArray):
        guard let iv = try? Int.from(byteStringArray: byteArray) else {
          throw RedisDecodingError.ValueNotConvertible(value: v,
                                                       to: Swift.Int.self)
        }
        self = iv

      default:
        throw RedisDecodingError.ValueNotConvertible(value: v,
                                                     to: Swift.Int.self)
    }
  }
  
  private static func from(byteStringArray v: [UInt8]?) throws -> Int {
    guard let ba = v else {
      throw RedisDecodingError.ByteStringNotConvertible(value: v,
                                                        to: Swift.Int.self)
    }
    guard let s = String.decode(utf8: ba) else {
      throw RedisDecodingError.ByteStringNotConvertible(value: v,
                                                        to: Swift.Int.self)
    }
    
    guard let iv = Int(s) else {
      throw RedisDecodingError.ByteStringNotConvertible(value: v,
                                                        to: Swift.Int.self)
    }
    return iv
  }
}
