//
//  ErrorEmitter.swift
//  Noze.io
//
//  Created by Helge Heß on 5/8/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

public typealias ErrorCB = ( Error ) -> Void

public protocol ErrorEmitterType : EventEmitterType {

  @discardableResult func onError  (handler cb: @escaping ErrorCB) -> Self
  @discardableResult func onceError(handler cb: @escaping ErrorCB) -> Self
}

public protocol ErrorEmitTarget {
  
  func emit(error e: Error)
  
}


/// A reusable base class, given that almost any Noze object is an error
/// emitter ...
///
/// I think this can be usefully done as a protocol as we can't add the required
/// storage.
open class ErrorEmitter : ErrorEmitterType, ErrorEmitTarget {
  
  public init() {}
  
  // MARK: - ErrorEmitter
  
  public var errorListeners = EventListenerSet<Error>()
  
  public func emit(error e: Error) { errorListeners.emit(e) }
  
  @discardableResult
  public func onError(handler cb: @escaping ErrorCB) -> Self {
    errorListeners.add(handler: cb)
    return self
  }
  
  @discardableResult
  public func onceError(handler cb: @escaping ErrorCB) -> Self {
    errorListeners.add(handler: cb, once: true)
    return self
  }
  
}
