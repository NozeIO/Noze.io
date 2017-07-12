//
//  RedisCommands.swift
//  Noze.io
//
//  Created by Helge Hess on 21/07/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import console

/// This extension contains convenience methods to create and enqueue Redis
/// commands.
/// They just create a `RedisCommand` instance and enqueue that for execution.

public protocol RedisCommandTarget {
  
  func enqueue(command cmd: RedisCommand)
  
}

// MARK: - Regular Keys GET, SET, KEYS etc
public extension RedisCommandTarget {
  
  public func get(_ key: String, _ cb: @escaping RedisReplyCB) {
    let cmd = RedisCommand(command: "GET", RedisValue(bulkString: key),
                           callback: cb)
    enqueue(command: cmd)
  }
  
  
  public func keys(_ pattern: String = "*", _ cb: @escaping RedisArrayReplyCB) {
    // TBD: should this return `[String]?`?
    //      and for people not using String keys, add a `rawKeys`?
    // Workaround: `keys.map { $0.stringValue! }`
    let cmd = RedisCommand(command: "KEYS",
                           RedisValue(simpleString: pattern),
                           callback: makeArrayReplyHelper(callback: cb))
    enqueue(command: cmd)
  }
  
  public func set(_ key: String, _ value: RedisValue,
                  _ cb: @escaping RedisReplyCB)
  {
    let cmd = RedisCommand(command: "SET",
                           RedisValue(bulkString: key),
                           value, callback: cb)
    enqueue(command: cmd)
  }
  public func set(_ key: String, _ value: RedisValue) {
    set(key, value) { err, value in
      if let err = err {
        console.error("could not set key", key, value, err)
      }
    }
  }
  
  public func set(_ key: String, _ value: String, _ cb: @escaping RedisReplyCB) {
    set(key, RedisValue(bulkString: value), cb)
  }
  public func set(_ key: String, _ value: String) {
    set(key, RedisValue(bulkString: value))
  }
  
  public func set(_ key: String, _ value: Int, _ cb: @escaping RedisReplyCB) {
    set(key, RedisValue(value), cb)
  }
  public func set(_ key: String, _ value: Int) {
    set(key, RedisValue(value))
  }
  
  public func del(keys ks: [String], _ cb: @escaping RedisReplyCB) {
    var values : [ RedisValue ] = []
    values.append(RedisValue(bulkString: "DEL"))
    for key in ks { values.append(RedisValue(bulkString: key)) }
    
    let cmd = RedisCommand(command: values, callback: cb)
    enqueue(command: cmd)
  }
  public func del(keys ks: [String]) {
    del(keys: ks) { err, _ in
      if let err = err {
        console.error("could not delete keys", ks, err)
      }
    }
  }
  public func del(_ keys: String..., cb: @escaping RedisReplyCB) {
    del(keys: keys, cb)
  }
  public func del(_ keys: String...) {
    del(keys: keys)
  }
}


// MARK: - Hashes HSET, HKEYS, etc
public extension RedisCommandTarget {
  
  public func hset(_ hashKey: String, _ key: String, _ value: RedisValue,
                   _ cb: @escaping RedisReplyCB)
  {
    let cmd = RedisCommand(command: "HSET",
                           RedisValue(bulkString: hashKey),
                           RedisValue(bulkString: key),
                           value, callback: cb)
    enqueue(command: cmd)
  }
  public func hset(_ hashKey: String, _ key: String, _ value: RedisValue) {
    hset(hashKey, key, value) { err, _ in
      if let err = err {
        console.error("could not hset key", hashKey, key, value, err)
      }
    }
  }
  
  public func hset(_ hashKey: String, _ key: String, _ value: String,
                   _ cb: @escaping RedisReplyCB)
  {
    hset(hashKey, key, RedisValue(bulkString: value), cb)
  }
  public func hset(_ hashKey: String, _ key: String, _ value: String) {
    hset(hashKey, key, RedisValue(bulkString: value))
  }
  
  public func hkeys(_ hashKey: String, _ cb: @escaping RedisArrayReplyCB) {
    let cmd = RedisCommand(command: "HKEYS",
                           RedisValue(bulkString: hashKey),
                           callback: makeArrayReplyHelper(callback: cb))
    enqueue(command: cmd)
  }
  
  public func hgetall(_ hashKey: String, _ cb: @escaping RedisHashReplyCB) {
    let cmd = RedisCommand(command: "HGETALL",
                           RedisValue(bulkString: hashKey),
                           callback: makeHashReplyHelper(callback: cb))
    enqueue(command: cmd)
  }
  
  func _hmget(hashKey hk: String, keys: [String],
              _ cb: @escaping RedisOHashReplyCB)
  {
    var values : [ RedisValue ] = []
    values.append(RedisValue(bulkString: "HMGET"))
    values.append(RedisValue(bulkString: hk))
    for key in keys { values.append(RedisValue(bulkString: key)) }
    
    let cmd = RedisCommand(command: values,
                           callback:
                             makeOHashReplyHelper(keys: keys, callback: cb))
    enqueue(command: cmd)
  }
  public func hmget(_ hashKey: String, _ k: String...,
                    cb: @escaping RedisOHashReplyCB)
  {
    _hmget(hashKey: hashKey, keys: k, cb)
  }
  
  public func hmset(_ hashKey: String, _ hash: [ String : String ],
                    _ cb: @escaping RedisReplyCB)
  {
    // TODO: hmset which takes an array of key/value pairs instead of a dict
    var values : [ RedisValue ] = []
    values.append(RedisValue(bulkString: "HMSET"))
    values.append(RedisValue(bulkString: hashKey))
    
    for (key, value) in hash {
      values.append(RedisValue(bulkString: key))
      values.append(RedisValue(bulkString: value))
    }
    
    let cmd = RedisCommand(command: values, callback:cb)
    enqueue(command: cmd)
  }
  public func hmset(_ hashKey: String, _ hash: [ String : String ]) {
    hmset(hashKey, hash) { err, _ in
      if let err = err {
        console.error("could not hmset", hashKey, hash, err)
      }
    }
  }
}


// MARK: - INCR/DECR etc
public extension RedisCommandTarget {
  
  func _enqueue(intByCommand scmd: String, key: String, by: Int,
                _ cb: @escaping RedisIntReplyCB)
  {
    let cmd : RedisCommand
    if by == 1 {
      cmd = RedisCommand(command: scmd, RedisValue(bulkString: key),
                         callback: makeIntReplyHelper(callback: cb))
    }
    else {
      cmd = RedisCommand(command: scmd + "BY",
                         RedisValue(bulkString: key), RedisValue(by),
                         callback: makeIntReplyHelper(callback: cb))
    }
    enqueue(command: cmd)
  }
  
  public func incr(_ key: String, by: Int = 1, _ cb: @escaping RedisIntReplyCB){
    _enqueue(intByCommand: "INCR", key: key, by: by, cb)
  }
  public func decr(_ key: String, by: Int = 1, _ cb: @escaping RedisIntReplyCB){
    _enqueue(intByCommand: "DECR", key: key, by: by, cb)
  }

}


// MARK: - PubSub
public extension RedisCommandTarget {
  
  public func publish(_ channel: String, _ message: String) {
    let cmd = RedisCommand(command: "PUBLISH",
                           RedisValue(bulkString: channel),
                           RedisValue(bulkString: message)) {
      err, value in
      if let err = err {
        console.error("could not publish", channel, message, err)
      }
    }
    enqueue(command: cmd)
  }
  
}
