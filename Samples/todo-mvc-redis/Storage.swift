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
  
  func getAll(cb: @escaping ( [ T ] ) -> Void)
  func get(id key: Int, cb: @escaping ( T? ) -> Void)
  
  func deleteAll(cb: @escaping () -> Void)
  func delete(id key: Int, cb: @escaping () -> Void)
  func update(id key: Int, value v: T, cb: @escaping ( T ) -> Void)
  
  func nextKey(cb: @escaping ( Int ) -> Void)
  
}
