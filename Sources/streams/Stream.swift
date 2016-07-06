//
//  Stream.swift
//  Noze.IO
//
//  Created by Helge Hess on 30/06/15.
//  Copyright © 2015 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import core
import events

public typealias CloseCB = () -> Void

public protocol StreamType : ErrorEmitterType {
  
  func onClose  (handler cb: CloseCB) -> Self
  func onceClose(handler cb: CloseCB) -> Self
  
}

/// Abstract superclass for Readable and Writable.
///
/// TODO: document more
///
public class Stream : ErrorEmitter, StreamType, LameLogObjectType {
  // TODO: improve buffer implementation. Ideas:
  // - bucket as a class / linked list with 'next' pointer
  // - bucket has fix UnmanagedPointer buffer
  // - bucket stores how much has been read from that buffer
  //   - as a replacement for the non-Array slice()
  //   - empty buckets should be reused (thread safe pool?)
  // - would be cool if buckets themselves could be generators
  // - would be cool if buckets could be file-descriptors
  //   - so that we can do sendfile(from, to) where applicable
  
  public let log : Logger
  public let Q   : DispatchQueueType // TBD: drop this, always use core.Q
  public var didRetainQ : Bool = false
  
  
  // MARK: - Init
  
  public init(queue: DispatchQueueType = core.Q, enableLogger: Bool = false) {
    self.Q   = queue
    self.log = Logger(enabled: enableLogger)
    
    super.init()
    
    log.onAfterEnter  = { [unowned self] log in self.logState() }
    log.onBeforeLeave = { [unowned self] log in self.logState() }
  }
  deinit {
    if didRetainQ {
      core.module.release()
      didRetainQ = false
    }
  }

  
  // MARK: - Queue Integration
  
  final func nextTick(handler cb: () -> Void) {
    log.debug("Tick CB ..")
    //dispatch_async(Q, cb) // hm, really allow them to have an own queue?
    core.nextTick(handler: cb)
  }
  
  // MARK: - ErrorEmitter
  
  public func catched(error e: ErrorProtocol) {
    log.enter(); defer { log.leave() }
    // TODO: throw if there are no listeners!!!
    if self.errorListeners.isEmpty {
      print("ERROR: no error listeners, catched: \(e)")
    }
    self.errorListeners.emit(e)
  }
  
  
  // MARK: - Close Events
  
  public var closeListeners =
               EventListenerSet<Void>(queueLength: 1, coalesce: true)
  
  public func onClose(handler cb: CloseCB) -> Self {
    log.enter(); defer { log.leave() }
    closeListeners.add(handler: cb, once: false)
    return self
  }
  public func onceClose(handler cb: CloseCB) -> Self {
    log.enter(); defer { log.leave() }
    closeListeners.add(handler: cb, once: true)
    return self
  }
  
  
  // MARK: - Logging
  
  public var logStateInfo : String {
    return ""
  }
}
