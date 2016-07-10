//
//  ReadableStream.swift
//  Noze.IO
//
//  Created by Helge Hess on 30/06/15.
//  Copyright © 2015 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import xsys
import core
import events

/// An abstract base class for implementing a `Readable`, see the
/// `GReadableStreamType` more information.
/// It implements all the buffering, event handlers, etc - a subclass just has
/// to implement the `_primaryRead()` function.
///
/// This is a generic class and can handle/buffer buckets of arbitrary objects
/// (ReadType), not just bytes. (unlike Node which seems to switch to single-
/// step mode when in object-mode)
///
/// There are three common subclasses of this:
/// - `SourceStream` essentially adds the concept of a `ReadableSource`. Which
///   is just another object producing data
/// - `Readable` is using a closure to implement `_primaryRead`. This way you
///   can avoid a custom subclass
/// - a custom subclass overriding `_primaryRead`
///
/// It is inheriting from Stream. Stream only provides a Q, a logger and the 
/// onError CB, not any real functionality.
///
/// This class 
/// - has a buffer, which is a BucketBrigade aka an [ [ T ] ]
/// - has a config option 'highWaterMark' which is the suggested maximum size.
/// - the buffer has a totalCount
/// - hence an 'availableBufferSpace' which is HWM-totalCount
///
public class ReadableStream<ReadType> : Stream, GReadableStreamType {
  // FIXME: this has 'evolved' and needs a cleanup :-)
  // In the `Readable` subclass, <ReadType> is the ReadableSourceType.Element.
  
  public var highWaterMark : Int
  public var hitEOF        = false
  
  public var buffer        = ArrayBuffer<ReadType>() // a Noze buffer
  
  /// This says that we emitted an onReadable event are waiting for the client
  /// to call `read`.
  public var readPending   = false
  
  public var availableBufferSpace : Int {
    return (buffer.totalCount >= highWaterMark)
      ? 0
      : (highWaterMark - buffer.totalCount)
  }

  
  // MARK: - Init
  
  public init(highWaterMark : Int?,
              queue         : DispatchQueueType = core.Q,
              enableLogger  : Bool = false)
  {
    self.highWaterMark = highWaterMark ?? 1
    super.init(queue         : queue,
               enableLogger  : enableLogger)
  }
  

  // MARK: - Consumer read() interface
  
  /// Reads up to `count` items from the buffer. If no `count` is specified
  /// (the common option) the whole buffer is returned (and emptied) and the
  /// caller can wait for the next `onReadable` event.
  ///
  /// *Important*: If a `count` is specified, the caller needs to loop until
  /// `read` returns nil. The `onReadable` event is only emitted once! In this
  /// case a caller may need to check `hitEOF` to figure out whether `nil` was
  /// returned because of EOF.
  ///
  public func read(count c: Int?) -> [ ReadType ]? {
    // This should only be called by the consumer, not internally.
    // If the consumer specifies a size, he needs to loop until nil and
    // check for a size.
    log.enter(); defer { log.leave() }
    
    readPending = false
    
    
    // Case where we sent a Readable event, but due to EOF - the buffer is empty
    
    if buffer.isEmpty { // buffers are empty
      if hitEOF {
        log.debug("EOF, return nil")
        _endReadable() // buffers are empty, and we hit EOF -> End.
        return nil
      }
      
      // TODO: this should never happen in a readable event, right?
      // TODO: This is hit when we synchronously call read(), i.e.:
      //         let src = "Hello".utf8.readableSource().readable()
      //         while let bucket = src.read() { }
      // I think this probably means we need to start generating synchrously?!
      //assert(hitEOF, "buffer is empty, but EOF not hit?")
      //log.debug("buffer is empty, return nil")

      log.enter(); defer { log.leave() }
      
      maybeGenerateMore() // see whether we can generate something synchronously
      
      if buffer.isEmpty && !hitEOF { // buffers is still empty
        //assert(hitEOF, "buffer is empty, but EOF not hit?")
        // This is fine. It also happens if we are looping in the onReadable
        // handler.
        return nil
      }
      
      // recurse
      return self.read(count: c)
    }
    
    
    // Case where the consumer specified an amount of items to read. In this 
    // case the consumer needs to continue calling read() until he receives
    // nil. Only after that new Readable events are (supposed to be) emitted.
    
    if let count = c {
      // the consumer requested more than our max buffer size, bump our buffer
      // size to avoid reallocs
      if count > highWaterMark {
        log.debug("bumping HWM, request \(count) vs \(highWaterMark)")
        highWaterMark = roundUpToNextPowerOfTwo(count)
      }
      
      // Case where the consumer asked for MORE than what is available. In this
      // situation we return nil and the consumer needs to wait for the next
      // Readable event.
      if !hitEOF && buffer.totalCount < count { // don't have that much
        log.debug("read is bigger than what we have " +
                  "(\(buffer.totalCount) < \(count)")
        maybeGenerateMore()
        return nil
      }
    }
    
    
    // OK, either the consumer didn't specify a size, or the requested size is
    // already available in the buffer. Return a bucket.
    
    let bucket = _dequeue(count: c ?? buffer.totalCount)
    
    
    // TBD: in here or in push? or in both?
    // TBD: why is this even in here? It doesn't seem to make sense flow-wise?
    //      maybe to pick up an EOF?
    maybeGenerateMore()
    
    // OK, so the buffer is empty and we hit EOF.
    if buffer.isEmpty && hitEOF {
      emitReadable() // make it pick up the EOF
        // TBD: Do endReadable right away? the emitReadable should trigger a
        // subsequent read, which then triggers the hitEOF logic?
    }
    
    log.debug("returning bucket \(bucket)")
    return bucket
  }
  
  
  // MARK: - Read from source
  
  public var internalPauseCount = 0 // #linux-public
  
  public func maybeGenerateMore() { // TODO: not really public
    // this is called by read()
    // TBD: this can't be private, why?
    log.enter(); defer { log.leave() }
    
    guard !hitEOF else {
      log.debug("hit EOF, nothing more to read ...")
      return
    }
    
    guard availableBufferSpace > 0 else {
      log.debug("buffer is full, pausing ...")
      internalPauseCount += 1
      if internalPauseCount == 1 {
        _pause()
      }
      return
    }
    
    if isPaused {
      log.debug("was paused, resuming ...")
      internalPauseCount = 0
      _resume() // this also triggers a generate
    }
    else { // not paused, we have more space
      startGenerating()
    }
  }
  
  public var inGenerator : Bool = false
    // this is True if _primaryRead() is being run. I think the purpose is to
    // tell other functions that they can't emit signals inline, but rather
    // queue up notifications until the reading is done.
  
  public func startGenerating() { // TBD: document
    // Called by `maybeGenerateMore` (which is invoked by `read`) or
    // `startFillingBuffers`, which is called by `_resume`.
    //
    // This seems to wrap `_primaryRead()`, which is going to trigger the
    // source in the subclass.
    // It is called when the consumer needs more data.
    log.enter(); defer { log.leave() }
    
    assert(!hitEOF) // right?
    
    if !didRetainQ { // TBD: right place to do this? too late? too early? wrong?
      core.module.retain()
      didRetainQ = true
    }
    
    let howMuchToRead = self.availableBufferSpace
    if howMuchToRead < 1 {
      if !isPaused {
        log.debug("buffer full, pausing.")
        internalPauseCount += 1
        if internalPauseCount == 1 {
          _pause()
        }
      }
      else {
        log.debug("buffer full, already paused")
      }
      return
    }
    
    assert(inGenerator == false, "already generating!")
    inGenerator = true
    do {
      log.debug("generate, call next(\(howMuchToRead)):")
      _primaryRead(count: howMuchToRead)
    }
    inGenerator = false
  }
  
  public func _startFillingBuffers() { // TBD: document
    // Called by _resume() only
    //
    // I think this activates the source in the subclass to read more data /
    // fill the buffer.
    log.enter(); defer { log.leave() }
    
    guard buffer.isEmpty else {
      log.debug("buffer still contains items, not reading ...")
      // TBD: but should we emit onReadable? Probably!
      return
    }
    
    log.debug("trigger generator ...")
    startGenerating()
  }
  
  
  // MARK: - Pushing and Unshifting
  
  public func push(bucket b: [ ReadType ]?) {
    // Pushing nil means EOF
    if let lBucket = b {
      assert(!hitEOF, "cannot push, already hit EOF")
      guard !hitEOF else {
        emit(error: POSIXError.EBADF) // TODO: better error
        return
      }
      _enqueue(bucket: lBucket) // add to buffer and emitReadable
    }
    else if !hitEOF {
      hitEOF = true
      
      if buffer.isEmpty {
        _endReadable()
      }
      else {
        //print("ReadableStream: FILLED, READABLE: \(self)")
        emitReadable() // Note: we could still have something in the queue!
      }
    }
    else {
      log.debug("NOTE: stream, extra EOF push: \(self)")
      // assert(!hitEOF, "duplicate EOF push")
    }
  }
  
  public func unshift(bucket b: [ ReadType ]) {
    // TBD: should unshift emit readable? The consumer just rejected the bucket
    //      and is probably waiting for more?
    /*
      - unshift should NOT emit readable event, wait for next read operation
        - eg a subsequent parser which did the unshift, would still not have
      enough data
      - sample: [byte] to [String] converter which is waiting for the
        end of a UTF-8 sequence
     */
    _enqueue(bucket: b, front: true, shouldEmitReadable: false)
  }

  public final func _enqueue(bucket b: [ ReadType ], front: Bool = false,
                             shouldEmitReadable: Bool = true)
  {
    // called by push() and unshift()
    buffer.enqueue(bucket: b, front: front)
    if shouldEmitReadable {
      emitReadable() // added something to read
    }
  }
  
  public final func _dequeue(count c: Int) -> [ ReadType ] {
    // TBD: document, who calls this?
    log.enter(); defer { log.leave() }
    assert(!buffer.isEmpty)
    log.debug("dequeue \(c) total is \(buffer.totalCount)")
    
    return buffer.dequeue(count: c)
  }
  
  
  // MARK: - extension points for subclass
  
  public func _primaryRead(count howMuchToRead: Int) {
    // Note: Nope, subclasses do not necessarily do an actual read. They might
    //       also just push() out of band.
    // fatalError("Subclass must override _primaryRead()")
  }
  public func _primaryPause() {
  }
  
  
  // MARK: - Emit Events
  
  public var scheduledReadable : Bool = false
  public var pendingReadable   : Int  = 0
  
  public func emitReadable() {
    let log = self.log
    log.enter(); defer { log.leave() }
    
    //print("EMIT: \(self)")
    
    guard !scheduledReadable else {
      log.debug("readable is already scheduled ...")
      return
    }
    guard !readableListeners.isEmpty else {
      // Well, yes, BUT. Doesn't the EventListenerSet already deal with this?
      // TBD
      pendingReadable += 1
      log.debug("stream has no Readable listeners " +
                "(calls #\(pendingReadable)) ...")
      return
    }
    guard !readPending else {
      // essentially, if the consumer chose to not read synchronously from
      // within the readable callback, he is responsible for calling read()
      // in a loop until nil (and potentially EOF).
      log.debug("notified consumber, but a read is still pending ...")
      return
    }
    
    /* TBD: This wrecks other stuff. The source is paused, let it continue.
    if isPaused {
      log.debug("stream is paused, not emitting onReadable ...")
      pendingReadable += 1 // later
      return
    }
    */
    
    scheduledReadable = true
    
    // TODO: is a synchronous mode possible?
    let block : ( ) -> Void = {
      log.enter(function: "emitReadable - handler")
      defer { log.leave(function: "emitReadable - handler") }
      
      self.scheduledReadable = false
      
      if self.buffer.isEmpty && !self.hitEOF {
        log.debug("buffer is empty, not emitting.")
      }
      else {
        /* TBD: This wrecks other stuff. The source is paused, let it continue.
        if self.isPaused {
          log.debug("stream is paused, not emitting event.")
          self.pendingReadable += 1
          return
        }
        */
        log.debug("emitting event ..")
        self.readPending     = true
        self.pendingReadable = 0
        self.readableListeners.emit()
      }
    }
    
    if inGenerator {
      nextTick(handler: block)
    }
    else {
      // TODO: inline call doesn't quite work
      //       - please elaborate ... ;-)
      nextTick(handler: block)
    }
  }

  public var didSendEnd   : Bool = false
  public var didSendClose : Bool = false
  
  public func _endReadable() {
    // called by read() -> nil or push(nil)
    let log = self.log
    log.enter(); defer { log.leave() }
    guard !didSendEnd else { log.debug("already ended."); return }
    
    assert(buffer.isEmpty, "Attempt to end a Readable with buffered contents.")
    guard buffer.isEmpty else { return }

    didSendEnd = true
    
    readableListeners.removeAllListeners()
    errorListeners.removeAllListeners()
    
    closeReadStream()
    
    // TBD: to tick or not to tick
    nextTick {
      self.endListeners.emit()
      self.endListeners.removeAllListeners()
      
      if self.didRetainQ {
        self.didRetainQ = false
        core.module.release()
      }
    }
  }
  
  public func closeReadStream() { // subclasses can override this
    if !didSendClose {
      didSendClose = true
      nextTick {
        self.closeListeners.emit()
        self.closeListeners.removeAllListeners()
      }
    }
  }
  
  
  // MARK: - Pause/Resume
  
  public var pauseCounter = 1
  public var isPaused : Bool { return pauseCounter > 0 }
  
  public func _pause() {
    log.enter(); defer { log.leave() }
    
    if pauseCounter == 0 {
      log.debug("pausing source ..")
      _primaryPause()
    }
    pauseCounter += 1
  }
  
  public func _resume() {
    log.enter(); defer { log.leave() }
    
    pauseCounter -= 1
    
    if pauseCounter == 0 {
      log.nest()
      
      log.debug("resuming pausable by filling buffers ..")
      
      // OK, so DO we start pulling data or not?
      // preferably not. Yes, we have to. But we
      // don't push it right away to the listener
      if !hitEOF {
        _startFillingBuffers()
      }
      else {
        // TBD: nextTick required?
        pendingReadable += 1 // to have people pick up the EOF?
      }
      
      if pendingReadable > 0 {
        pendingReadable = 0
        emitReadable()
      }
      
      log.unnest()
    }
  }
  
  
  // MARK: - Readable is a ReadableSource itself
  
  public func next(queue q : DispatchQueueType, count: Int,
                   yield   : ( ErrorProtocol?, [ ReadType ]? ) -> Void)
  {
    // dispatching yield on queue, though it should be the same (main) queue?
    
    guard !hitEOF else {
      q.async { yield(nil, nil) }
      return
    }
    
    // TODO: not quite sure this is right :-)
    
    // only one happens, the other one will stay (retain cycle?)
    // well, at least a dead object? Unless we clear all handlers on EOF?
    _ = onceError { error in
      q.async { yield(error, nil) }
    }
    
    _ = onceReadable { [weak self] in
      guard let stream = self else { return }
      
      if let bucket = stream.read(count: count) {
        q.async { yield(nil, bucket) }
      }
      else {
        q.async { yield(nil, nil) } // EOF
      }
    }
  }
  
  public func resume() {
    _resume()
  }
  public func pause() {
    _pause()
  }
  

  // MARK: - Event Handlers
  
  public var readableListeners =
               EventListenerSet<Void>(queueLength: 1, coalesce: true)
  public var endListeners      =
               EventListenerSet<Void>(queueLength: 1, coalesce: true)
  
  public var didResumeOnFirst = false // #linux-public
  public func _resumeOnFirstReadableListener() {
    // really, for regular pull streams there should be only one
    //assert(readableListeners.count == 1)
    
    guard !didResumeOnFirst else { return }
    
    // Careful here. This is ONLY meant to balance the very first pause!
    if readableListeners.count == 1 {
      didResumeOnFirst = true
      _resume() // start reading
    }
  }

  public func _installOnReadableHandler(handler cb: ReadableCB, once: Bool)
              -> Self
  {
    readableListeners.add(handler: cb, once: once)

    _resumeOnFirstReadableListener()
    
    if pendingReadable > 0 {
      pendingReadable = 0
      emitReadable()
    }
    
    return self
  }
  public func _installOnEndHandler(handler cb: ReadableCB, once: Bool) -> Self {
    endListeners.add(handler: cb, once: once)
    return self
  }
  public func _installOnCloseHandler(handler cb: ReadableCB, once: Bool)
              -> Self
  {
    closeListeners.add(handler: cb, once: once)
    return self
  }
  
  public func onReadable(handler cb: ReadableCB) -> Self {
    log.enter(); defer { log.leave() }
    return _installOnReadableHandler(handler: cb, once: false)
  }
  public func onceReadable(handler cb: ReadableCB) -> Self {
    log.enter(); defer { log.leave() }
    return _installOnReadableHandler(handler: cb, once: true)
  }
  
  public func onEnd(handler cb: EndCB) -> Self {
    log.enter(); defer { log.leave() }
    return _installOnEndHandler(handler: cb, once: false)
  }
  public func onceEnd(handler cb: EndCB) -> Self {
    log.enter(); defer { log.leave() }
    return _installOnEndHandler(handler: cb, once: true)
  }
  
  
  // MARK: - Logging
  
  public override var logStateInfo : String {
    var s = buffer.logStateInfo
    
    if availableBufferSpace < 1 { s += " FULL" }
    
    if isPaused {
      s += " paused"
      if pauseCounter > 1 { s += "\(pauseCounter)" }
    }
    else {
      s += " running"
    }
    
    if scheduledReadable   { s += " event-pending" }
    if pendingReadable > 0 { s += " wants-readable=\(pendingReadable)" }
    if hitEOF              { s += " EOF" }
    if inGenerator         { s += " generating.." }
    if readPending         { s += " notified-waiting-for-read" }
    if didSendEnd          { s += " ENDED" }
    
    return s
  }
}


// Don't raise the hwm > 128M items (Node.JS)
let MAX_HWM = 0x800000;

private func roundUpToNextPowerOfTwo(n: Int) -> Int {
  // Port of the Node pow2
  guard n < MAX_HWM else { return MAX_HWM }

  // Get the next highest power of 2
  var ln = n - 1
  var p  = 1
  while p < 32 {
    ln |= ln >> p
    p <<= 1
  }
  ln += 1

  return ln
}
#if swift(>=3.0) // #swift3-1st-kwarg
private func roundUpToNextPowerOfTwo(_ n: Int) -> Int {
  return roundUpToNextPowerOfTwo(n: n)
}
#endif
