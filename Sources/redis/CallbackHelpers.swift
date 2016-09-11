//
//  CallbackHelpers.swift
//  Noze.io
//
//  Created by Helge Hess on 24/07/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import core

/// This checks whether the reply is an array. If it is, the array is returned
/// as one, else an error is returned.
///
func makeArrayReplyHelper(callback cb: @escaping RedisArrayReplyCB)
     -> RedisReplyCB
{
  return { err, vals in
    guard let vals = vals else { return cb(err, nil) }
    
    switch vals {
      case .Array(let members):
        cb(err, members)
      default:
        cb(RedisClientError.UnexpectedReplyType(vals), nil)
    }
  }
}

/// This checks whether the reply is an array, more precisely an array with an
/// even number of elements. Which in turn can be converted to a String.
/// If it is, the array is converted to a [String:String] dictionary and
/// returned to the callback.
/// If not, an error is returned.
///
func makeHashReplyHelper(callback cb: @escaping RedisHashReplyCB)
     -> RedisReplyCB
{
  return { err, vals in
    guard let vals = vals else { return cb(err, nil) }
    
    if case .Array(let members) = vals {
      guard let members = members else {
        cb(nil, nil) // weird case, nil array
        return
      }
      
      guard members.count % 2 == 0 else {
        cb(RedisClientError.UnexpectedReplyType(vals), nil)
        return
      }
      
      var hash = Dictionary<String, String>()
      
      for i in stride(from: 0, to: members.count, by: 2) {
        guard let key   = members[i].stringValue,
              let value = members[i + 1].stringValue
        else {
          cb(RedisClientError.UnexpectedReplyType(vals), nil)
          return
        }
        
        hash[key] = value
      }
      
      cb(nil, hash)
    }
    else {
      cb(RedisClientError.UnexpectedReplyType(vals), nil)
    }
  }
}

/// This checks whether the reply is an array, more precisely an array with an
/// even number of elements. Which in turn can be converted to a `String`, or in
/// the case of values are `nil`.
/// If it is, the array is converted to a [String:String?] dictionary and
/// returned to the callback.
/// If not, an error is returned.
///
func makeOHashReplyHelper(keys ks: [String],
                          callback cb: @escaping RedisOHashReplyCB)
     -> RedisReplyCB
{
  return { err, vals in
    guard let vals = vals else { return cb(err, nil) }
    
    if case .Array(let members) = vals {
      guard let members = members else {
        cb(nil, nil) // weird case, nil array
        return
      }
      
      guard members.count == ks.count else {
        cb(RedisClientError.UnexpectedReplyType(vals), nil)
        return
      }
      
      var hash = Dictionary<String, String?>()
      
      for i in 0..<ks.count {
        let key   = ks[i]
        let value = members[i]
        
        print("KEYS: \(key) value: \(value)")
        
        switch value {
          case .Array, .Error:
            cb(RedisClientError.UnexpectedReplyType(vals), nil)
            return
          
          case .Integer(let value):
            hash[key] = String(value)
          
          case .BulkString(let bytes):
            if bytes == nil { // the only situation which is a valid `nil`
              // Note: cannot use `hash[key] = nil` here
              hash.updateValue(nil, forKey: key)
            }
            else {
              guard let value = value.stringValue else {
                cb(RedisClientError.UnexpectedReplyType(vals), nil)
                return
              }
              
              hash[key] = value
            }

          case .SimpleString:
            guard let value = value.stringValue else {
              cb(RedisClientError.UnexpectedReplyType(vals), nil)
              return
            }
            
            hash[key] = value
        }
      }
      
      cb(nil, hash)
    }
    else {
      cb(RedisClientError.UnexpectedReplyType(vals), nil)
    }
  }
}

func makeIntReplyHelper(callback cb: @escaping RedisIntReplyCB) -> RedisReplyCB{
  return { err, vals in
    guard let vals = vals else { return cb(err, nil) }
    
    guard let iv = vals.intValue else {
      cb(RedisClientError.UnexpectedReplyType(vals), nil)
      return
    }
    
    cb(nil, iv)
  }
}

