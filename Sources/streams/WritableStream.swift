//
//  WritableStream.swift
//  Noze.IO
//
//  Created by Helge Hess on 01/07/15.
//  Copyright © 2015 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import core
import events

// Swift3: this must be open ...
open class WritableStream<WriteType>
           : Stream, GWritableStreamType, PipeEmitTarget
{
  /*
  Notes: (TODO: update for split between WritableStream and Writable)
  - what is a WritableStream?
    - a WritableStream can buffer write input.
    - also always does the 'safe' write to the target
    - if the target couldn't write everything, the WritableStream *must* buffer
    - the client 'schedules' writes using this
  - the write() can always return 'false'
    - but remember, if it returns true, the WHOLE buffer has been written
    - if it returns false, a client will usually hook up an onDrain
      - but in Node it can continue to write
    - false says: "something had to be buffered"!
  - a write can be synchronous, if no other writes are happening in the
    background
  - in Node a Writable can be 'corked' (stopped). What is the use of this?
    - eg this is used by Socket to accept content before the socket is
      actually connected - TBD: but this is the case anyways?
      - is this just to emit drain's immediately?
  - what about error handling? some errors could be recoverable. The client
    needs to call end() in the error handler?
    - should we call end() if there are no error handlers?
  */
  
  public typealias WriteBucketType = [ WriteType ]
  public typealias Brigade         = [ WriteBucketType ]
  
  var buffer        : ListBuffer<WriteType>
  
  var inSink        = false // called 'sync' in Node
  var didSendFinish = false
  var calledEnd     = false
  var isWriting     = false
  var corkCount     = 0
  
  
  public var isCorked : Bool { return corkCount > 0 }
  
  
  // MARK: - Init
  
  public init(highWaterMark : Int?,
              queue         : DispatchQueue,
              enableLogger  : Bool)
  {
    buffer = ListBuffer<WriteType>(highWaterMark: highWaterMark)
    super.init(queue: queue, enableLogger: enableLogger)
  }
  
  
  // MARK: - Client API
  
  open func end() {
    log.enter(); defer { log.leave() }
    
    // happens. assert(!calledEnd || !_primaryCanEnd) // right?
    guard !calledEnd else { return }
    
    if _primaryCanEnd {
      calledEnd = true
      
      if buffer.isEmpty {
        // This doesn't mean anything. Maybe the buffer has been transferred to
        // the StreamTarget for processing.
        if !isWriting {
          finishWritable()
        }
      }
      // else: the buffer is still filled and the stream will continue to write
      //       until everything is written. Then it will call finishWritable
      //       (when calledEnd is set).
    }
    else {
      // TBD: Is it really true that stdout/err never end? Or is this just a
      //      practical choice? Eg. stdout could have been redirected to a
      //      file.
      // TBD: would we still want to send onFinish when the writing is done?
      //      after all the client called onEnd?
      //
      // TBD: Node has code like that in pipe()
      //         doEnd = pipeOpts.end !== false && dest !== process.stdout...
      
      log.debug("target never ends ...") // stdout/stderr
    }
  }
  
  /// Returns true if all chunks got written fully or enough buffer space was
  /// available. Return falls if the buffer space overflowed (but the chunks
  /// are still queued!)
  open func writev(buckets chunks: Brigade, done: DoneCB? = nil) -> Bool {
    log.enter(); defer { log.leave() }
    
    guard chunks.count > 0 && chunks[0].count > 0 else { return true }

    if !didRetainQ { // TBD: right place to do this? too late? too early? wrong?
      core.module.retain()
      didRetainQ = true
    }

    assert(!calledEnd)
    assert(!didSendClose)
    assert(!didSendFinish)

    if !buffer.isEmpty {
      assert(isWriting || isCorked, "buffer is not empty, but not writing?")
      
      buffer.enqueue(chunks, done: done)
      
      // TBD: Should return true for corked streams? Hm, no, why? Even if it is
      //      corked the sender side should stop writing when the buffer is 
      //      full.
      // return false // buffer still there, add to buffer
        // TBD: we should only return false if the buffer is full, right?
        //      Hm, or maybe not? Not sure. Probably.
      return buffer.availableBufferSpace > 0
        // only return false if the buffer is actually full
    }
    
    
    // First, the simple implementation. Enqueue buffer and schedule the write.
    // TODO: Later we should try to write synchronously.
    buffer.enqueue(chunks, done: done)
    
    if !isCorked {
      startWriting()
    }
    
    // TBD:  If corked, should we return false immediately?
    // TODO: this is not quite right. Eg if the user wrote 1K of data and the
    //       buffer is 1K of data, this returns false even though everything
    //       got written! Fix: attempt synchronous write?
    return buffer.availableBufferSpace > 0
  }
  
  open func cork() {
    log.enter(); defer { log.leave() }
    self.corkCount += 1
  }
  open func uncork() {
    log.enter(); defer { log.leave() }
    assert(self.corkCount > 0, "uncork called on an open stream ..")
    self.corkCount -= 1
    
    if !buffer.isEmpty {
      startWriting()
    }
  }
  
  
  // MARK: - Internals
  
  func startWriting() { // Q: main
    // called by `writev` if the buffer was empty and the stream is not corked,
    // or by `uncork`.
    log.enter(); defer { log.leave() }
    
    assert(!buffer.isEmpty)
    guard !buffer.isEmpty else { return }
    
    guard !isWriting else { log.debug("already writing"); return }
    isWriting = true
    
    writeNextBlock()
  }
  
  func writeNextBlock() {
    // called by startWriting (triggered by uncork or writev()),
    // and by afterPrimaryWrite (which is called by writeNextBlock)
    let log = self.log // avoid capturing self
    log.enter(); defer { log.leave() }
    
    // dequeue a block (the brigade and the optional associated done-callback!)
    // TODO: I don't like any of this, we should combine buffers to perform
    //       efficient bulk writes and such
    
    guard let ( brigade, cb ) = buffer.dequeue() else {
      return
    }
    
    let brigadeCount = brigade.reduce(0 /* start value */) { $0 + $1.count }
    
    // trigger a primary write in the target
    
    inSink = true // this is for the case where yield() is called synchronously
    
    _primaryWriteV(buckets: brigade) { error, writeCount in // Q: main
      log.enter(function: "writeNextBlock - handler"); defer { log.leave() }
      log.debug("wrote #\(writeCount) brigade #\(brigadeCount) \(error as Optional)")
      
      assert(writeCount <= brigadeCount)
      assert(error != nil || writeCount > 0) // right?
      
      if let error = error {
        /* this can happen if the remote closes early ...
        print("STREAM: \(self)")
        print("COULD NOT WRITE: \(brigade)")
        */
        self.catched(error: error)
      }
      else if brigadeCount == writeCount {
        if let cb = cb {
          log.debug("everything written, calling write-callback() ...")
          cb()
        }
        else {
          log.debug("whole block got written, but no CB registered.")
        }
      }
      else { // did not write everything, unshift
        let pendingBrigade = consumeFromBrigade(brigade, consumed: writeCount)
        
        log.debug("not everything got written, put remainder " +
                  "(#\(pendingBrigade.count)/\(countBrigade(pendingBrigade)))" +
                  " back into queue")
        
        // Note: the callback block is re-added for the reduced block
        self.buffer.enqueue(pendingBrigade, front: true, done: cb)
      }
      
      self.afterPrimaryWrite()
    }
    
    inSink = false
  }
  
  open func afterPrimaryWrite() { // Q: main
    // called by writeNextBlock() when it is done with one `_primaryWriteV`
    // call.
    log.enter(); defer { log.leave() }

    // TODO: for a drain the buffer doesn't have to be empty, it just needs to
    //       have space?
    
    assert(isWriting)
    
    if !buffer.isEmpty {
      log.debug("something left in buffer, continue writing ...")
      
      if inSink { // avoid recursion  TBD: why not? if it doesn't block?
        nextTick(handler: writeNextBlock)
      }
      else {
        writeNextBlock()
      }
      return
    }
    
    isWriting = false
    
    // OK, buffer is empty
    
    if calledEnd {
      log.debug("end was called, we are done. Emit finish.")
      finishWritable()
      return
    }
    
    // OK, buffer is empty, we did not call end(). So we a draining!
    // Note: no nextTick necessary, we already called the CB. right?
    log.debug("draining, notifying listeners: #\(drainListeners.count)")
    assert(buffer.availableBufferSpace > 0)
    drainListeners.emit()

    if didRetainQ {
      core.module.release()
      didRetainQ = false
    }
  }
  
  
  // MARK: - extension points for subclass

  open func _primaryWriteV(buckets chunks: Brigade,
                           done: @escaping ( Error?, Int ) -> Void)
  {
    log.enter(); defer { log.leave() }
    fatalError("subclass must override _primaryWriteV")
  }
  
  open var _primaryCanEnd : Bool { return true }
  
  private func finishWritable() {
    let log = self.log
    log.enter(); defer { log.leave() }
    
    // TODO: what about those, should those be empty?
    //  TBD: Careful, the blocks might retain stuff?
    drainListeners.removeAllListeners()
    errorListeners.removeAllListeners()
    
    closeWriteStream()
    
    emitFinish()
  }

  var didSendClose = false
  public func closeWriteStream() { // subclasses can override this
    if !didSendClose {
      didSendClose = true
      nextTick {
        self.closeListeners.emit()
        self.closeListeners.removeAllListeners()
      }
    }
  }
  
  // MARK: - Emit Events
  
  private func emitFinish() {
    let log = self.log
    log.enter(); defer { log.leave() }
    
    guard !didSendFinish else { return }
    didSendFinish = true
    
    nextTick {
      log.enter(function: "\(#function):tick"); defer { log.leave() }
      self.finishListeners.emit()
      self.finishListeners.removeAllListeners()
      
      if self.didRetainQ {
        core.module.release()
        self.didRetainQ = false
      }
    }
  }
  
  
  // MARK: - Event Handlers

  var drainListeners  = EventListenerSet<Void>(queueLength: 1, coalesce: true)
  var finishListeners = EventOnceListenerSet<Void>()
  var pipeListeners   = EventListenerSet<ReadableStreamType>()
  var unpipeListeners = EventListenerSet<ReadableStreamType>()
  
  @discardableResult
  public func onDrain(handler cb: @escaping DrainCB) -> Self {
    drainListeners.add(handler: cb)
    return self
  }
  @discardableResult
  public func onceDrain(handler cb: @escaping DrainCB) -> Self {
    drainListeners.add(handler: cb, once: true)
    return self
  }
  
  @discardableResult
  public func onFinish(handler cb: @escaping FinishCB) -> Self {
    finishListeners.add(handler: cb)
    return self
  }
  @discardableResult
  public func onceFinish(handler cb: @escaping FinishCB) -> Self {
    finishListeners.add(handler: cb, once: true)
    return self
  }
  
  @discardableResult
  public func onPipe(handler cb: @escaping PipeCB) -> Self {
    pipeListeners.add(handler: cb)
    return self
  }
  @discardableResult
  public func oncePipe(handler cb: @escaping PipeCB) -> Self {
    pipeListeners.add(handler: cb, once: true)
    return self
  }
  
  @discardableResult
  public func onUnpipe(handler cb: @escaping PipeCB) -> Self {
    unpipeListeners.add(handler: cb)
    return self
  }
  @discardableResult
  public func onceUnpipe(handler cb: @escaping PipeCB) -> Self {
    unpipeListeners.add(handler: cb, once: true)
    return self
  }

  public func emit(pipe   src: ReadableStreamType) { pipeListeners.emit(src)   }
  public func emit(unpipe src: ReadableStreamType) { unpipeListeners.emit(src) }

  
  // MARK: - Logging
  
  override open var logStateInfo : String {
    var s = super.logStateInfo
    
    s += " " + buffer.logStateInfo

    if buffer.availableBufferSpace < 1 { s += " FULL" }
    
    if isWriting     { s += " writing" }
    if inSink        { s += " in-sink" }
    if calledEnd     { s += " END" }
    if didSendFinish { s += " FINISHED" }
    
    if corkCount > 0 {
      s += " corked=#\(corkCount)"
    }
    
    return s
  }
}
