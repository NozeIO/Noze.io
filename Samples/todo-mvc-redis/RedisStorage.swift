//
//  RedisStorage.swift
//  Noze.io
//
//  Created by Helge Heß on 7/24/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import console
import redis

#if os(Linux)
  import func Glibc.strtol
#else
  import func Darwin.strtol
#endif


/// A collection store which just stores the data in a Redis server.
///
/// Data Model:
/// - records are stored under the `todo:id` key as hashes, e.g. `todo:1337`
///   - remember that Redis hashes are [String:String]
/// - ids are generated using the atomic Redis increment, the key is
///   `todo:sequence`
///
class RedisCollectionStore<T: RedisHashObject> : CollectionStore {
  
  let prefix = "io.noze.todo.v1:"
  let redis  : RedisClient
  
  init(_ redis: RedisClient) {
    self.redis = redis
  }
  
  
  // MARK: - Key Generation & Parsing
  
  func nextKey(cb: ( Int ) -> Void) {
    redis.incr("\(prefix)sequence") { err, value in cb(value!) }
  }
  
  func parse(key k: String) -> Int? {
    // String(io.noze.todo.v1:1337) => Int(1337)
    
    let id : Int = k.withCString { cs in
      let csp = cs + prefix.characters.count // skip prefix
      return strtol(csp, nil, 10)            // parse number
    }
    // This makes use of the fact that id's start at 1
    return id > 0 ? id : nil
  }
  func parse(keys k: [String]) -> [Int] {
    // [String(io.noze.todo.v1:1337)] => [Int(1337)]
    var ids = [ Int ]()
    ids.reserveCapacity(k.count)
    for key in k {
      guard let id = self.parse(key: key) else {
        console.error("could not parse key: \(key)")
        continue
      }
      ids.append(id)
    }
    return ids
  }
  
  
  // MARK: - Bulk Fetch Keys
  
  func get(ids keys: [Int], cb: ( [ T ] ) -> Void) {
    // check for empty results
    guard !keys.isEmpty else { cb([]); return }
    
    // grab all todos
    // Note: we just queue all gets in bulk. No back-pressure support.
    var pendingCount = keys.count
    var result       = [ T ]()
    result.reserveCapacity(pendingCount)
    
    for id in keys {
      self.get(id: id) { object in
        pendingCount -= 1
        
        if let object = object {
          result.append(object)
        }
        else {
          console.error("could not retrieve id: \(id)")
        }
        
        if pendingCount == 0 { // we are done, return results
          cb(result)
        }
      }
    }
  }
  
  
  // MARK: - Regular API
  
  func getAll(cb: ( [ T ] ) -> Void) {
    // TODO: here we just use keys, do not do this in PROD, use SCAN instead
    redis.keys("\(prefix)[0-9]*") { err, keys in
      guard let keys = keys else { cb([]); return }
      self.get(ids: self.parse(keys: keys.map({$0.stringValue!})), cb: cb)
    }
  }
  
  func get(id key: Int, cb: ( T? ) -> Void) {
    redis.hgetall("\(prefix)\(key)") { err, value in
      guard let hash = value else {
        console.error("got no hash for key \(key)")
        cb(nil)
        return
      }
      
      let object = T(key: key, stringDict: hash)
      cb(object)
    }
  }
  
  func delete(id key: Int, cb: () -> Void) {
    redis.del("\(prefix)\(key)") { err, value in
      cb()
    }
  }
  
  func update(id key: Int, value v: T, cb: ( T ) -> Void) {
    redis.hmset("\(prefix)\(key)", v.redisHash) { err, value in
      cb(v)
    }
  }
  
  func deleteAll(cb: () -> Void) {
    let redis = self.redis
    
    redis.keys("\(prefix)[0-9]*") { err, keys in
      guard let keys = keys else {
        console.error("failed to get keys: ", err)
        cb()
        return
      }
      
      // convert the keys (`RedisValue`s) to strings
      let skeys = keys.map { $0.stringValue! }
      
      // Not sure whether that is technically sound. Probably not, presumably
      // there is a limit on the number of keys.
      redis.del(keys: skeys) { err, value in
        cb()
      }
    }
  }
}


import Freddy

/// A Redis hash can only store string values, not int's or bool's etc.
///
/// Note: Another storage option would be to just persist the JSON. But hey,
///       why take the easy route?! ;-)
///
protocol RedisHashObject {
  
  init(key: Int, stringDict: [ String : String ])
  
  var redisHash : [ String : String ] { get }
  
}


// MARK: - Todo support for Redis persistence

extension Todo : RedisHashObject {
  // We cannot abuse JSONDecodable here because Freddy is picky about data
  // types :-) (i.e. a JSON string doesn't convert to Int even if it is a valid
  // int, same for bool)
  
  init(key: Int, stringDict: [ String : String ]) {
    // well, to many `!`, do proper error handling in real apps ;-)
    id        = key
    title     = stringDict["title"]      ?? "<no title>"
    order     = Int(stringDict["order"]  ?? "0") ?? 0
    completed = (stringDict["completed"] ?? "no") == "yes"
  }
  
  var redisHash : [ String : String ] {
    return [
      "title":     title,
      "order":     "\(order)",
      "completed": completed ? "yes" : "no"
    ]
  }
}
