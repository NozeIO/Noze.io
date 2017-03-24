//
//  TransformStream.swift
//  Noze.io
//
//  Created by Helge Hess on 22/04/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import xsys
import core

// TODO: flush



/// TransformStream
///
/// DuplexStream (aka a GReadableStreamType & GWritableStreamType at the same
/// time).
///
/// Samples: zlib, crypto stream, hash stream
///
/// Output doesn't have to be the same size like the input, and
/// Output doesn't have to be generated 'synchronously' (the output bucket
/// does not need to be written when the input bucket arrived).
///
/// Careful: The Writable of the transform is the INPUT (this is how data is
///          being pushed into the transform) and the Readable is the OUTPUT
///          (this is how the transformed data is consumed by other ends!)
///
open class TransformStream<WriteType, ReadType>
           : DuplexStream<ReadType, WriteType>, GTransformStreamType
{
  // Note that WriteType and ReadType are reversed for TransformStream to make
  // it less confusing ;-)
  
  override public init(readHWM      : Int? = nil,
                       writeHWM     : Int? = nil,
                       queue        : DispatchQueue = core.Q,
                       enableLogger : Bool = false)
  {
    super.init(readHWM: readHWM, writeHWM: writeHWM, queue: queue,
               enableLogger: enableLogger)
  }
  
  
  // MARK: - Writable (the INPUT!)
  override open func writev(buckets c: [ [WriteType] ], done: DoneCB?)
                -> Bool
  {
    // Returning `false` makes a behaving writer stop writing and install an
    // `onDrain` handler.
    let wroteAll = super.writev(buckets: c, done: done)
    
    if wroteAll { // protect against greedyness.
      // this is like a builtin-reverse pipe
      
      guard readStream != nil else {
        assert(readStream != nil,
               "writing to a transform, but there is no read stream anymore?")
        emit(error: POSIXErrorCode.EPIPE)
        return false // Note: drain will never be called
      }
      
      if readStream.availableBufferSpace < 1 || readStream.isPaused {
        // How do we know that someone 'drained' the read buffer? Well, he
        // called `read`. Which we override below.
        // does not pass tests yet
        if enableDrain {
          drainCount += 1
          if doCork { cork() }
          return false
        }
        else {
          return true
        }
      }
    }
    
    return wroteAll
  }
  
  public var drainCount  = 0 // #linux-public
  let enableDrain = true
  let doCork      = false
  
  override open func _primaryWriteV(buckets c: [ [ WriteType ] ],
                                    done: @escaping ( Error?, Int ) -> Void)
  { // #linux-public
    // called by WritableStream.writeNextBlock() (which in turn is triggered by
    // DuplexStream.writev().
    //
    // FIXME: ICH WERDE NIE SATT, ICH WERDE NIE SATT, ES IST BESSER, WENN MANN
    //        MEHR HAT!
    // - probably writev has to inspect how much the read-buffer is filled and
    //   return false. Plus: support drain?
    // - or we delay the _transform call if the read-buffer is full. if the
    //   primaryWriteV is hanging, the outer writev imp will fill the buffer and
    //   then return false
    let log = self.log
    log.enter(); defer { log.leave() }
    
    // TODO: I hate this. But it'll do for now.
    let bigChunk = Array(c.joined())
    
    _transform(bucket: bigChunk) { error, data in
      log.debug("done: \(error as Optional) \(data as Optional)")
      // Note: invoking done(nil, nil) doesn't do EOF! It just doesn't push
      //       anything.
      if let data = data { self.push(data) }
      done(error, bigChunk.count) // this unblocks the WritableStream
    }
  }
  
  override open func closeWriteStream() { // subclasses can override this
    log.enter(); defer { log.leave() }
    _flush() { error, data in
      if !self.hitEOF { // _flush may have called this already
        if let data = data {
          self.push(data)
        }
        self.push(nil /* EOF */)
      }
      else {
        assert(data == nil || data!.isEmpty,
               "Attempt to push data to a stream which hit EOF")
      }
    }
    super.closeWriteStream()
  }
  
  
  // MARK: - Readable (the OUTPUT!)

  override open func _primaryRead(count howMuchToRead: Int) { // #linux-public
    log.enter(); defer { log.leave() }
    
    //fatalError("should not be called in transform streams")
    // => but it is called.
    
    // TBD:
    // I don't think this is ever called in our setup? `transform`
    // pushes into the buffer (which emits the `onReadable`), there
    // is no 'on-demand' pulling of data (possible, because the write
    // part is push based too - if no one is writing to us, we can't
    // push to the readable).
  }
  
  override open func read(count c: Int?) -> [ ReadType ]? {
    let bucket = super.read(count: c)
    
    if drainCount > 0 {
      // TBD: what about `paused`?
      if readStream.availableBufferSpace > 0 {
        drainCount = 0
        if doCork { uncork() }
        nextTick { // TBD: else we nest
          self.writeStream.drainListeners.emit()
        }
      }
    }
    
    return bucket
  }
  
  
  // MARK: - Transform
  
  open func _transform(bucket b: [ WriteType ],
                       done: @escaping ( Error?, [ ReadType ]? ) -> Void)
  {
    fatalError("Subclass must override transform()")
    
    // the CB essentially calls the `yield` of the write stream marking the
    // bucket as written. Also does a 'push' if there is push data.
    // done(nil, nil)
  }
  open func _flush(done cb: @escaping ( Error?, [ ReadType ]? ) -> Void) {
    cb(nil, nil)
  }
}

public protocol GTransformStreamType : class {
  
  associatedtype WriteType
  associatedtype ReadType

  func _transform(bucket b: [ WriteType ], 
                  done: @escaping ( Error?, [ ReadType ]? ) -> Void)
  func _flush    (done cb: @escaping ( Error?, [ ReadType ]? ) -> Void)
  
}


#if os(Linux)
#else
  // importing this from xsys doesn't seem to work
import Foundation // this is for POSIXError : Error
#endif

