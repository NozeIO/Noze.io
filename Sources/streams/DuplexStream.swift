//
//  DuplexStream.swift
//  Noze.io
//
//  Created by Helge Heß on 4/10/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import core
import events

/// A stream which is both, a GReadableStreamType and a GWritableStreamType.
///
/// This is an abstract superclass, a subclass needs to override:
///
///   _primaryRead()
///   [optionally _primaryPause]
/// and
///   _primaryWriteV()
///
/// Internally this class just uses the `ReadableStream` and `WritableStream`
/// implementations (and have them deal with events and buffers).
///
open class DuplexStream<ReadType, WriteType>
           : Stream, GReadableStreamType, GWritableStreamType, PipeEmitTarget
{  
  // NOTE: TODO: those are NOT really optionals, the streams need to be setup
  //             after init() returns, so that people can hook up event handlers
  //       TODO: does this imply the DuplexStream should be a Source/Target?
  //             (so that we can create a Readable+Writable with a proper
  //              source?)
  // TODO: fix this. in/out are wrong terminologies here. Eg in a Transform, the
  //       Writable is the 'in' stream and the Readable is the 'out'.
  public var readStream  : ReadableStream<ReadType>!
  public var writeStream : WritableStream<WriteType>!
  
  public init(readHWM      : Int? = nil,
              writeHWM     : Int? = nil,
              queue        : DispatchQueue = core.Q,
              enableLogger : Bool = false)
  {
    super.init(queue: queue, enableLogger: enableLogger)
    
    // TBD: should those get setup as lazy vars? After all they might allocate
    //      a significant buffer, potentially before it is even clear the
    //      buffer is going to be used (or should the buffer be lazy? :-).
    readStream  = _DuplexReadStream (self, highWaterMark: readHWM)
    writeStream = _DuplexWriteStream(self, highWaterMark: writeHWM)
  }
  
  
  // MARK: - extension points for subclass
  
  func _primaryRead(count howMuchToRead: Int) {
    fatalError("Subclass must override _primaryRead()")
  }
  public func _primaryPause() { // #linux-public
  }
  
  public func _primaryWriteV(buckets chunks : [ [ WriteType ] ],
                             done           : @escaping ( Error?, Int ) -> Void)
  { // #linux-public
    log.enter(); defer { log.leave() }
    fatalError("subclass must override _primaryWriteV")
  }
  
  public var _primaryCanEnd : Bool { return true } // #linux-public
  
  
  // MARK: - Closing
  
  public var didSendClose : Bool = false
  public var openCount = 2
  
  public func _sendCloseEvent() { // #linux-public
    openCount -= 1
    if openCount == 0 && !didSendClose {
      didSendClose = true
      nextTick {
        self.closeListeners.emit(())
        self.closeListeners.removeAllListeners()
      }
    }
  }
  
  public func closeReadStream() { // subclasses can override this
    _sendCloseEvent()
  }
  public func closeWriteStream() { // subclasses can override this
    _sendCloseEvent()
  }
  
  
  // MARK: - ReadableStream
  
  public func read  (count c: Int?) -> [ ReadType ]? {
    return readStream.read(count: c)
  }
  public func pause () { readStream.pause()  }
  public func resume() { readStream.resume() }
  
  @discardableResult
  public func onReadable(handler cb: @escaping () -> Void) -> Self {
    _ = readStream.onReadable(handler: cb);   return self
  }
  
  @discardableResult
  public func onceReadable(handler cb: @escaping () -> Void) -> Self {
    _ = readStream.onceReadable(handler: cb); return self
  }
  
  @discardableResult
  public func onEnd(handler cb: @escaping () -> Void) -> Self {
    _ = readStream.onEnd(handler: cb);   return self
  }
  
  @discardableResult
  public func onceEnd(handler cb: @escaping () -> Void) -> Self {
    _ = readStream.onceEnd(handler: cb); return self
  }
  
  public var hitEOF : Bool {
    guard let readStream = readStream else { return true }
    return readStream.hitEOF
  }
  
  
  // MARK: - WritableStream
  
  public func writev(buckets chunks: [ [ WriteType ] ], done: DoneCB?) -> Bool {
    guard let writeStream = writeStream else { return false }
    return writeStream.writev(buckets: chunks, done: done)
  }
  
  public func end() {
    writeStream.end()
  }
  
  
  // MARK: - WritableStream Events
  
  @discardableResult
  public func onDrain(handler cb: @escaping DrainCB) -> Self {
    _ = writeStream.onDrain(handler: cb);    return self
  }
  @discardableResult
  public func onceDrain(handler cb: @escaping DrainCB) -> Self {
    _ = writeStream.onceDrain(handler: cb);  return self
  }
  
  @discardableResult
  public func onFinish(handler cb: @escaping FinishCB) -> Self {
    _ = writeStream.onFinish(handler: cb);   return self
  }
  @discardableResult
  public func onceFinish(handler cb: @escaping FinishCB) -> Self {
    _ = writeStream.onceFinish(handler: cb); return self
  }
  
  @discardableResult
  public func onPipe(handler cb: @escaping PipeCB) -> Self {
    _ = writeStream.onPipe(handler: cb);     return self
  }
  @discardableResult
  public func oncePipe(handler cb: @escaping PipeCB) -> Self {
    _ = writeStream.oncePipe(handler: cb);   return self
  }
  
  @discardableResult
  public func onUnpipe(handler cb: @escaping PipeCB) -> Self {
    _ = writeStream.onUnpipe(handler: cb);   return self
  }
  @discardableResult
  public func onceUnpipe(handler cb: @escaping PipeCB) -> Self {
    _ = writeStream.onceUnpipe(handler: cb); return self
  }
  
  public func emit(pipe   src: ReadableStreamType) {
    _ = writeStream.emit(pipe: src)
  }
  public func emit(unpipe src: ReadableStreamType) {
    _ = writeStream.emit(unpipe: src)
  }
  
  
  // MARK: - Corking
  
  public var isCorked : Bool {
    guard let writeStream = writeStream else { return false }
    return writeStream.isCorked
  }
  public func cork()   { writeStream.cork()   }
  public func uncork() { writeStream.uncork() }
  
  
  // MARK: - Shared
  
  // TBD: should remove, doesn't belong here. It depends on a concrete
  //      implementation
  public var highWaterMark : Int {
    get {
      guard let readStream = readStream else { return -1 }
      return readStream.highWaterMark
    }
    set {
      readStream.highWaterMark = newValue
    }
  }
  
  
  // MARK: - ReadableStream intern
  
  public func push(_ b: [ ReadType ]?) {
    readStream.push(b)
  }
  public func unshift(_ b: [ ReadType ]) {
    readStream.unshift(b)
  }
  
  public func maybeGenerateMore() { // not really public
    readStream.maybeGenerateMore()
  }

  // MARK: - Logging
  
  override open var logStateInfo : String {
    let ri = readStream? .description ?? "-"
    let wi = writeStream?.description ?? "-"
    return super.logStateInfo + " in=\(ri) out=\(wi)"
  }
}


// MARK: - Duplex Read/Write-Stream Trampolines

private class _DuplexReadStream<TI, TO> : ReadableStream<TI> {
  
  unowned let parent : DuplexStream<TI, TO>
  
  init(_ parent : DuplexStream<TI, TO>, highWaterMark : Int? = nil) {
    self.parent = parent
    super.init(highWaterMark: highWaterMark, // crash in init: ?? parent.hwm
               queue: parent.Q, enableLogger: parent.log.enabled)
  }
  
  override func _primaryRead(count howMuchToRead: Int) {
    parent._primaryRead(count: howMuchToRead)
  }
  override func _primaryPause() {
    parent._primaryPause()
  }
  
  override func closeReadStream() { // subclasses can override this
    parent.closeReadStream()
  }
}

private class _DuplexWriteStream<TI, TO> : WritableStream<TO> {
  
  unowned let parent : DuplexStream<TI, TO>
  
  init(_ parent : DuplexStream<TI, TO>, highWaterMark : Int? = nil) {
    self.parent = parent
    super.init(highWaterMark: highWaterMark ?? parent.highWaterMark,
               queue: parent.Q, enableLogger: parent.log.enabled)
  }
  
  override func _primaryWriteV(buckets c: [ [ TO ] ], 
                               done: @escaping ( Error?, Int ) -> Void)
  {
    parent._primaryWriteV(buckets: c, done: done)
  }
  
  override func closeWriteStream() { // subclasses can override this
    parent.closeWriteStream()
  }
}


// MARK: - Byte Streams

public protocol DuplexByteStreamType
                : ReadableByteStreamType, WritableByteStreamType
{
}
