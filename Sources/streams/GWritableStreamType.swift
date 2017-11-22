//
//  GWritableStreamType.swift
//  Noze.io
//
//  Created by Helge Hess on 31/03/16.
//  Copyright © 2016-2017 ZeeZide GmbH. All rights reserved.
//

public typealias DoneCB   = () -> Void
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
  
  // MARK: - Events
  @discardableResult func onDrain   (handler cb: @escaping DrainCB)  -> Self
  @discardableResult func onFinish  (handler cb: @escaping FinishCB) -> Self
  @discardableResult func onceDrain (handler cb: @escaping DrainCB)  -> Self
  @discardableResult func onceFinish(handler cb: @escaping FinishCB) -> Self
  
  // MARK: - Support for Pipe Events. Maybe a little overkill.
  @discardableResult func onPipe    (handler cb: @escaping PipeCB)   -> Self
  @discardableResult func oncePipe  (handler cb: @escaping PipeCB)   -> Self
  @discardableResult func onUnpipe  (handler cb: @escaping PipeCB)   -> Self
  @discardableResult func onceUnpipe(handler cb: @escaping PipeCB)   -> Self
  
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
public protocol GWritableStreamType : WritableStreamType {
  
  associatedtype WriteType
  
  /// Returns true if all chunks got written fully or enough buffer space was
  /// available. Return falls if the buffer space overflowed (but the chunks
  /// are still queued!)
  @discardableResult
  func writev(buckets b: [ [ WriteType ] ], done: DoneCB?) -> Bool
}

public protocol PipeEmitTarget {
  // the pipe itself only needs this, non-generic type
  
  func emit(pipe   src: ReadableStreamType)
  func emit(unpipe src: ReadableStreamType)
  
}


// MARK: - Wrappers for writev() methods

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


// TODO: What is a good way to adopt Swift's OutputStreamType? It would be
//       useful for a set of output streams.
/* Like this, but this doesn't work:
 
     extension WritableStream : OutputStreamType where WriteType == UInt8 {
        ..
     }
*/
