//
//  Storage.swift
//  Noze.io
//
//  Created by Helge Hess on 03/06/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

class VolatileStoreCollection<T> {

  var sequence = 1337

  // String key to make /:id/ easier, but we don't currently see this.
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
}
