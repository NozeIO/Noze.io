//
//  Storage.swift
//  Noze.io
//
//  Created by Helge Hess on 03/06/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

/// The common asynchronous API for a todo-mvc sample store.
///
/// Currently we provide an in-memory and a Redis implementation of this API.
///
protocol CollectionStore {
  // Note: A real API should have proper error handling in the callbacks.
  
  associatedtype T
  
  func getAll(cb: ( [ T ] ) -> Void)
  func get(id key: Int, cb: ( T? ) -> Void)
  
  func deleteAll(cb: () -> Void)
  func delete(id key: Int, cb: () -> Void)
  func update(id key: Int, value v: T, cb: ( T ) -> Void)
  
  func nextKey(cb: ( Int ) -> Void)
  
}
