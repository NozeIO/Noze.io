//
//  ErrorEmitter.swift
//  Noze.io
//
//  Created by Helge Heß on 5/8/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if swift(>=3.0)
#else
public typealias ErrorProtocol = ErrorType
#endif

public typealias ErrorCB = ( ErrorProtocol ) -> Void

public protocol ErrorEmitterType : EventEmitterType {

#if swift(>=3.0) // #swift3-discardable-result
  @discardableResult func onError  (handler cb: ErrorCB) -> Self
  @discardableResult func onceError(handler cb: ErrorCB) -> Self
#else
  func onError  (handler cb: ErrorCB) -> Self
  func onceError(handler cb: ErrorCB) -> Self
#endif  
}

public protocol ErrorEmitTarget {
  
  func emit(error e: ErrorProtocol)
  
}


/// A reusable base class, given that almost any Noze object is an error
/// emitter ...
///
/// I think this can be usefully done as a protocol as we can't add the required
/// storage.
public class ErrorEmitter : ErrorEmitterType, ErrorEmitTarget {
  
  public init() {}
  
  // MARK: - ErrorEmitter
  
  public var errorListeners = EventListenerSet<ErrorProtocol>()
  
  public func emit(error e: ErrorProtocol) { errorListeners.emit(e) }
  
  public func onError(handler cb: ErrorCB) -> Self {
    errorListeners.add(handler: cb)
    return self
  }
  public func onceError(handler cb: ErrorCB) -> Self {
    errorListeners.add(handler: cb, once: true)
    return self
  }
  
}
