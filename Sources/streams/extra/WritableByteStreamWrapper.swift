//
//  WritableByteStreamWrapper.swift
//  Noze.io
//
//  Created by Helge Hess on 19/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import core
import events

/// A common base class for a byte stream which just wraps another byte stream.
/// Subclasses can selectively override the methods.
///
/// Careful with using this. It essentially side tracks `GWritableStreamType`.
///
open class WritableByteStreamWrapper
             : GWritableStreamType, WritableByteStreamType
{
  // FIXME: This is not quite the right thing. We essentially want to spool
  //        everything until the output stream becomes available.
  
  // TODO: this is more of a hack, see WritableByteStreamType
  /* TODO:
      enum ForwardingState {
        case Unassigned(ListBuffer<UInt8>)
        case Assigned(WritableByteStreamType)
      }
      var state = ForwardingState.Unassigned(...)
  */
  
  public var buffer : ListBuffer<UInt8>? = nil
  public var didEnd = 0
  
  public var stream : WritableByteStreamType? {
    didSet { _transferBuffer() }
  }
  
  public init(_ stream: WritableByteStreamType) {
    self.log    = stream.log
    self.stream = stream
  }
  public init() {
    self.log    = Logger(enabled: false)
    self.stream = nil
  }
  
  
  // MARK: - GWritableStreamType
  
  public func _transferBuffer() { // #linux-public
    guard let b = buffer else { return }
    guard let s = stream else { return }
    b.dequeueAll { brigade, doneCB in
      _ = s.writev(buckets: brigade, done: doneCB)
    }
    if didEnd > 0 { s.end() }
  }

  open func writev(buckets chunks: [ [ UInt8 ] ], done: DoneCB?) -> Bool {
    if let s = stream {
      return s.writev(buckets: chunks, done: done)
    }
    else {
      if buffer == nil { buffer = ListBuffer(highWaterMark: 1) }
      buffer!.enqueue(chunks, done: done)
      return true // as long as we have no onDrain handling ...
    }
  }
  
  open func end() {
    if let s = stream {
      didEnd = 0
      s.end()
    }
    else {
      didEnd += 1
    }
  }
  
  open func closeWriteStream() {
    stream?.closeWriteStream()
  }
  
  
  // MARK: - Events
  
  @discardableResult
  public func onDrain(handler cb: @escaping DrainCB) -> Self {
    _ = stream?.onDrain(handler: cb)
    return self
  }
  @discardableResult
  public func onceDrain(handler cb: @escaping DrainCB) -> Self {
    _ = stream?.onceDrain(handler: cb)
    return self
  }
  @discardableResult
  public func onFinish(handler cb: @escaping FinishCB) -> Self {
    _ = stream?.onFinish(handler: cb)
    return self
  }
  @discardableResult
  public func onceFinish(handler cb: @escaping FinishCB) -> Self {
    _ = stream?.onceFinish(handler: cb)
    return self
  }
  
  @discardableResult
  public func onClose(handler cb: @escaping CloseCB) -> Self {
    _ = stream?.onClose(handler: cb)
    return self
  }
  @discardableResult
  public func onceClose(handler cb: @escaping CloseCB) -> Self {
    _ = stream?.onceClose(handler: cb)
    return self
  }
  
  @discardableResult
  public func onPipe(handler cb: @escaping PipeCB) -> Self {
    _ = stream?.onPipe(handler: cb)
    return self
  }
  @discardableResult
  public func oncePipe(handler cb: @escaping PipeCB) -> Self {
    _ = stream?.oncePipe(handler: cb)
    return self
  }
  
  @discardableResult
  public func onUnpipe(handler cb: @escaping PipeCB) -> Self {
    _ = stream?.onUnpipe(handler: cb)
    return self
  }
  @discardableResult
  public func onceUnpipe(handler cb: @escaping PipeCB) -> Self {
    _ = stream?.onceUnpipe(handler: cb)
    return self
  }

  public func emit(pipe   src: ReadableStreamType) { stream?.emit(pipe:   src) }
  public func emit(unpipe src: ReadableStreamType) { stream?.emit(unpipe: src) }
  
  
  @discardableResult
  public func onError(handler cb: @escaping ErrorCB) -> Self {
    _ = stream?.onError(handler: cb);   return self
  }
  @discardableResult
  public func onceError(handler cb: @escaping ErrorCB) -> Self {
    _ = stream?.onceError(handler: cb); return self
  }
  public func emit(error e: Error) { stream?.emit(error: e) }
  
  
  
  // MARK: - Corking
  
  public var  isCorked : Bool { return stream?.isCorked ?? false }
  public func cork()   { stream?.cork()   }
  public func uncork() { stream?.uncork() }

  
  // MARK: - Logging
  
  public var log : Logger
  public var logStateInfo : String { return "s=\(stream)" }
}
