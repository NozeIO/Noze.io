//
//  ErrorEmitter.swift
//  NozeIO
//
//  Created by Helge Heß on 5/8/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if swift(>=3.0)
public typealias ErrorType = ErrorProtocol
#endif

public typealias ErrorCB = ( ErrorType ) -> Void

public protocol ErrorEmitterType : EventEmitterType {

  func onError  (handler cb: ErrorCB) -> Self
  func onceError(handler cb: ErrorCB) -> Self
  
}

public protocol ErrorEmitTarget {
  
  func emit(error e: ErrorType)
  
}


/// A reusable base class, given that almost any Noze object is an error
/// emitter ...
///
/// I think this can be usefully done as a protocol as we can't add the required
/// storage.
public class ErrorEmitter : ErrorEmitterType, ErrorEmitTarget {
  
  public init() {}
  
  // MARK: - ErrorEmitter
  
  public var errorListeners = EventListenerSet<ErrorType>()
  
  public func emit(error e: ErrorType) { errorListeners.emit(e) }
  
  public func onError(handler cb: ErrorCB) -> Self {
    errorListeners.add(handler: cb)
    return self
  }
  public func onceError(handler cb: ErrorCB) -> Self {
    errorListeners.add(handler: cb, once: true)
    return self
  }
  
}
