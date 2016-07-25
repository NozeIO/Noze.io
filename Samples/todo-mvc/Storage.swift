//
//  Storage.swift
//  Noze.io
//
//  Created by Helge Hess on 03/06/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

/// A collection store which just stores everything in memory. Data added will
/// be gone when the process is stopped.
///
/// Note: The operations in here are all synchronous for simplicity. This is not 
///       how a regular store would usually work.
///       Check out todo-mvc-redis for a store with async operations.
///
class VolatileStoreCollection<T> {

  var sequence = 1337

  var objects = [ Int : T ]()

  init() {
  }
  
  func nextKey() -> Int {
    sequence += 1
    return sequence
  }
  
  func getAll() -> [ T ] {
    return Array(objects.values)
  }
  
  func get(id key: Int) -> T? {
    return objects[key]
  }
  
  func delete(id key: Int) {
    objects.removeValue(forKey: key)
  }
  
  func update(id key: Int, value v: T) {
    objects[key] = v // value type!
  }
  
  func deleteAll() {
    objects.removeAll()
  }
}
