//
//  GWritableStreamType.swift
//  NozeIO
//
//  Created by Helge Hess on 31/03/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

public typealias DoneCB   = ( Void ) -> Void
public typealias DrainCB  = () -> Void
public typealias FinishCB = () -> Void
public typealias PipeCB   = ( ReadableStreamType ) -> Void


/// A marker interface which can be used as a *type* (which
/// `GWritableStream` cannot as it is a generic type).
///
/// It isn't that useful since the primary method - writev() - is a generic ...
///
public protocol WritableStreamType : class, StreamType {
  
  /// Used by the client of the stream to tell the stream that no further data
  /// will be written.
  ///
  /// Note: There is also a convenience function `end([ WriteType ]...)` which
  ///       can be used to combine a write with the end.
  ///
  /// Careful: Calling `end()` doesn't close the stream immediately! The stream
  /// may still have data in-flight. It will write that data, and only then
  /// close the stream.
  func end()
  
  func closeWriteStream()
  
#if swift(>=3.0) // #swift3-discardable-result
  // MARK: - Events
  @discardableResult func onDrain   (handler cb: DrainCB)  -> Self
  @discardableResult func onFinish  (handler cb: FinishCB) -> Self
  @discardableResult func onceDrain (handler cb: DrainCB)  -> Self
  @discardableResult func onceFinish(handler cb: FinishCB) -> Self
  
  // MARK: - Support for Pipe Events. Maybe a little overkill.
  @discardableResult func onPipe    (handler cb: PipeCB)   -> Self
  @discardableResult func oncePipe  (handler cb: PipeCB)   -> Self
  @discardableResult func onUnpipe  (handler cb: PipeCB)   -> Self
  @discardableResult func onceUnpipe(handler cb: PipeCB)   -> Self
#else
  // MARK: - Events
  func onDrain   (handler cb: DrainCB)  -> Self
  func onFinish  (handler cb: FinishCB) -> Self
  func onceDrain (handler cb: DrainCB)  -> Self
  func onceFinish(handler cb: FinishCB) -> Self
  
  // MARK: - Support for Pipe Events. Maybe a little overkill.
  func onPipe    (handler cb: PipeCB)   -> Self
  func oncePipe  (handler cb: PipeCB)   -> Self
  func onUnpipe  (handler cb: PipeCB)   -> Self
  func onceUnpipe(handler cb: PipeCB)   -> Self
#endif
  
  // MARK: - Corking
  var  isCorked : Bool { get }
  func cork  ()
  func uncork()
  
}


/// GWritableStreamType
///
/// The key type all higher level code should work with.
///
///
/// ## Events
///
/// ### Drain
///
/// The `drain` event says that the stream is now ready to accept more data aka
/// writes. I.e. the producer should continue sending output to the stream.
///
/// ### Finish
///
/// The `finish` event is emitted when the stream received and end() call AND
/// all the data has actually been processed.
///
public protocol GWritableStreamType : class, WritableStreamType {
  
  associatedtype WriteType
  
  /// Returns true if all chunks got written fully or enough buffer space was
  /// available. Return falls if the buffer space overflowed (but the chunks
  /// are still queued!)
#if swift(>=3.0) // #swift3-discardable-result
  @discardableResult
  func writev(buckets b: [ [ WriteType ] ], done: DoneCB?) -> Bool
#else
  func writev(buckets b: [ [ WriteType ] ], done: DoneCB?) -> Bool
#endif
}

public protocol PipeEmitTarget {
  // the pipe itself only needs this, non-generic type
  
  func emit(pipe   src: ReadableStreamType)
  func emit(unpipe src: ReadableStreamType)
  
}


// MARK: - Wrappers for writev() methods

#if swift(>=3.0) // #swift3-1st-arg #swift3-discardable-result
  
public extension GWritableStreamType {

  @discardableResult
  public func write(_ chunk: [ WriteType ], done: DoneCB? = nil) -> Bool {
    return writev(buckets: [ chunk ], done: done )
  }
  
  public func end(_ chunk: [ WriteType ]? = nil, doneWriting: DoneCB? = nil) {
    if let chunk = chunk {
      _ = writev(buckets: [ chunk ]) {
        if let cb = doneWriting { cb() }
        self.end() // only end after everything has been written
      }
    }
    else {
      if let cb = doneWriting { cb() } // nothing to write, immediately done
      end()
    }
  }
}
  
#else // Swift 2.2

public extension GWritableStreamType {
  
  /// Returns true if the whole chunk got written. Returns false if something
  /// had to be buffered.
  public func write(chunk: [ WriteType ], done: DoneCB? = nil) -> Bool {
    return writev(buckets: [ chunk ], done: done )
  }
  
  public func end(chunk: [ WriteType ]? = nil, doneWriting: DoneCB? = nil) {
    if let chunk = chunk {
      writev(buckets: [ chunk ]) {
        if let cb = doneWriting { cb() }
        self.end() // only end after everything has been written
      }
    }
    else {
      if let cb = doneWriting { cb() } // nothing to write, immediately done
      end()
    }
  }
}

#endif // Swift 2.2


// TODO: What is a good way to adopt Swift's OutputStreamType? It would be
//       useful for a set of output streams.
/* Like this, but this doesn't work:
 
     extension WritableStream : OutputStreamType where WriteType == UInt8 {
        ..
     }
*/
