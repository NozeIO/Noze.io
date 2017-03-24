//
//  RedisPrint.swift
//  Noze.io
//
//  Created by Helge Heß on 7/24/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import core

// TODO: print for Hash/OHash variants

public func print(error err: Error?, value: RedisValue?) {
  assert(err != nil || value != nil, "Neither error nor value in Redis result?")
  
  if let error = err {
    print("ERROR: \(error)")
  }

  if let value = value {
    switch value {
      case .Array(let values):
        print(error: nil, values: values)
      case .Error(let error):
        print(error: error, value: nil)
      
      case .Integer(let value):
        print("Reply \(value)")
      
      case .SimpleString(let value):
        // TODO: only attempt to decode up to some size
        if let s = String.decode(utf8: value) {
          print("Reply \(s)")
        }
        else {
          print("Reply \(value)")
        }
      
      case .BulkString(let value):
        if let value = value {
          // TODO: only attempt to decode up to some size
          if let s = String.decode(utf8: value) {
            print("Reply \(s)")
          }
          else {
            print("Reply \(value)")
          }
        }
        else {
          print("Reply null")
        }
    }
  }
}

public func print(error err: Error?, values: [RedisValue]?) {
  assert(err != nil || values != nil, "Neither error nor vals in Redis result?")
  
  if let error = err {
    print("ERROR: \(error)")
  }
  
  if let values = values {
    print("Reply #\(values.count) values:")
    for i in 0..<values.count {
      let prefix = "  [\(i)]: "
      switch values[i] {
        case .Array(let values):
          print("\(prefix)\(values as Optional)")
        
        case .Error(let error):
          print("\(prefix)ERROR \(error)")
        
        case .Integer(let value):
          print("\(prefix)\(value)")
        
        case .SimpleString(let value):
          // TODO: only attempt to decode up to some size
          if let value = String.decode(utf8: value) {
            print("\(prefix)\(value)")
          }
          else {
            print("\(prefix)\(value)")
          }
        
        case .BulkString(let value):
          if let value = value {
            // TODO: only attempt to decode up to some size
            if let value = String.decode(utf8: value) {
              print("\(prefix)\(value)")
            }
            else {
              print("\(prefix)\(value)")
            }
          }
          else {
            print("\(prefix)  null")
          }
      }
    }
  }
}
