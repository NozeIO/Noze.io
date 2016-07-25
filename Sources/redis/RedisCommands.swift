//
//  RedisCommands.swift
//  Noze.io
//
//  Created by Helge Hess on 21/07/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

/// This extension contains convenience methods to create and enqueue Redis
/// commands.
/// They just create a `RedisCommand` instance and enqueue that for execution.

public protocol RedisCommandTarget {
  
  func enqueue(command cmd: RedisCommand)
  
}

// MARK: - Regular Keys GET, SET, KEYS etc
public extension RedisCommandTarget {
  
  public func get(key: String, _ cb: RedisReplyCB) {
    let cmd = RedisCommand(command: "GET", RedisValue(bulkString: key),
                           callback: cb)
    enqueue(command: cmd)
  }
  
  
  public func keys(pattern: String = "*", _ cb: RedisArrayReplyCB) {
    // TBD: should this return `[String]?`?
    //      and for people not using String keys, add a `rawKeys`?
    // Workaround: `keys.map { $0.stringValue! }`
    let cmd = RedisCommand(command: "KEYS",
                           RedisValue(simpleString: pattern),
                           callback: makeArrayReplyHelper(callback: cb))
    enqueue(command: cmd)
  }
  
  public func set(key: String, _ value: RedisValue, _ cb: RedisReplyCB? = nil) {
    let cmd = RedisCommand(command: "SET",
                           RedisValue(bulkString: key),
                           value, callback: cb)
    enqueue(command: cmd)
  }
  
  public func set(key: String, _ value: String, _ cb: RedisReplyCB? = nil) {
    set(key, RedisValue(bulkString: value), cb)
  }
  public func set(key: String, _ value: Int,    _ cb: RedisReplyCB? = nil) {
    set(key, RedisValue(value), cb)
  }
  
  public func del(keys ks: [String], _ cb: RedisReplyCB? = nil) {
    var values : [ RedisValue ] = []
    values.append(RedisValue(bulkString: "DEL"))
    for key in ks { values.append(RedisValue(bulkString: key)) }
    
    let cmd = RedisCommand(command: values, callback: cb)
    enqueue(command: cmd)
  }
}


// MARK: - Hashes HSET, HKEYS, etc
public extension RedisCommandTarget {
  
  public func hset(hashKey: String, _ key: String, _ value: RedisValue,
                   _ cb: RedisReplyCB? = nil)
  {
    let cmd = RedisCommand(command: "HSET",
                           RedisValue(bulkString: hashKey),
                           RedisValue(bulkString: key),
                           value, callback: cb)
    enqueue(command: cmd)
  }
  
  public func hset(hashKey: String, _ key: String, _ value: String,
                   _ cb: RedisReplyCB? = nil)
  {
    hset(hashKey, key, RedisValue(bulkString: value))
  }
  
  public func hkeys(hashKey: String, _ cb: RedisArrayReplyCB) {
    let cmd = RedisCommand(command: "HKEYS",
                           RedisValue(bulkString: hashKey),
                           callback: makeArrayReplyHelper(callback: cb))
    enqueue(command: cmd)
  }
  
  public func hgetall(hashKey: String, _ cb: RedisHashReplyCB) {
    let cmd = RedisCommand(command: "HGETALL",
                           RedisValue(bulkString: hashKey),
                           callback: makeHashReplyHelper(callback: cb))
    enqueue(command: cmd)
  }
  
  func _hmget(hashKey hk: String, keys: [String], _ cb: RedisOHashReplyCB) {
    var values : [ RedisValue ] = []
    values.append(RedisValue(bulkString: "HMGET"))
    values.append(RedisValue(bulkString: hk))
    for key in keys { values.append(RedisValue(bulkString: key)) }
    
    let cmd = RedisCommand(command: values,
                           callback:
                             makeOHashReplyHelper(keys: keys, callback: cb))
    enqueue(command: cmd)
  }
  public func hmget(hashKey: String, _ k: String..., _ cb: RedisOHashReplyCB) {
    _hmget(hashKey: hashKey, keys: k, cb)
  }
  
  public func hmset(hashKey: String, _ hash: [ String : String ],
                    _ cb: RedisReplyCB? = nil)
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
}


// MARK: - INCR/DECR etc
public extension RedisCommandTarget {
  
  func _enqueue(intByCommand scmd: String, key: String, by: Int,
                _ cb: RedisIntReplyCB)
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
  
  public func incr(key: String, by: Int = 1, _ cb: RedisIntReplyCB) {
    _enqueue(intByCommand: "INCR", key: key, by: by, cb)
  }
  public func decr(key: String, by: Int = 1, _ cb: RedisIntReplyCB) {
    _enqueue(intByCommand: "DECR", key: key, by: by, cb)
  }

}


// MARK: - PubSub
public extension RedisCommandTarget {
  
  public func publish(channel: String, _ message: String) {
    let cmd = RedisCommand(command: "PUBLISH",
                           RedisValue(bulkString: channel),
                           RedisValue(bulkString: message),
                           callback: nil)
    enqueue(command: cmd)
  }
  
}


#if swift(>=3.0) // #swift3-1st-kwarg

public extension RedisCommandTarget {
  public func get(_ key: String, _ cb: RedisReplyCB) {
    get(key: key, cb)
  }
  
  public func set(_ k: String, _ value: RedisValue, _ cb: RedisReplyCB? = nil) {
    set(key: k, value, cb)
  }
  public func set(_ k: String, _ value: String, _ cb: RedisReplyCB? = nil) {
    set(key: k, value, cb)
  }
  public func set(_ k: String, _ value: Int, _ cb: RedisReplyCB? = nil) {
    set(key: k, value, cb)
  }
  
  public func del(_ keys: String..., _ cb: RedisReplyCB? = nil) {
    del(keys: keys, cb)
  }
  
  public func hset(_ hashKey: String, _ key: String, _ value: RedisValue,
                   _ cb: RedisReplyCB? = nil)
  {
    hset(hashKey: hashKey, key, value, cb)
  }
  public func hset(_ hashKey: String, _ key: String, _ value: String,
                   _ cb: RedisReplyCB? = nil)
  {
    hset(hashKey: hashKey, key, value, cb)
  }
  public func hkeys(_ hashKey: String, _ cb: RedisArrayReplyCB) {
    hkeys(hashKey: hashKey, cb)
  }
  
  public func hgetall(_ hashKey: String, _ cb: RedisHashReplyCB) {
    hgetall(hashKey: hashKey, cb)
  }
  public func hmget(_ hk: String, _ k: String..., _ cb: RedisOHashReplyCB) {
    _hmget(hashKey: hk, keys: k, cb)
  }
  public func hmset(_ hk: String, _ hash: [ String : String ],
                    _ cb: RedisReplyCB? = nil)
  {
    hmset(hashKey: hk, hash, cb)
  }
  
  public func keys(_ pattern: String = "*", _ cb: RedisArrayReplyCB) {
    keys(pattern: pattern, cb)
  }
  
  public func incr(_ key: String, by: Int = 1, _ cb: RedisIntReplyCB) {
    _enqueue(intByCommand: "INCR", key: key, by: by, cb)
  }
  public func decr(_ key: String, by: Int = 1, _ cb: RedisIntReplyCB) {
    _enqueue(intByCommand: "DECR", key: key, by: by, cb)
  }
  
  public func publish(_ channel: String, _ message: String) {
    publish(channel: channel, message)
  }
}

#else // Swift 2.2

public extension RedisCommandTarget {

  public func del(keys: String..., _ cb: RedisReplyCB? = nil) {
    // Note: This has been moved here because the Swift3c crashes otherwise.
    //       Presumably due to the overload with the non-varargs version.
    del(keys: keys, cb)
  }
}

#endif // Swift 2.2
