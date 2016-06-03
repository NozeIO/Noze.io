//
//  WritableByteStreamType.swift
//  Noze.io
//
//  Created by Helge Hess on 19/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import core
import events

/// A stream which just deals with bytes.
///
/// Careful with using this. It essentially side tracks `GWritableStreamType`.
///
public protocol WritableByteStreamType
                : WritableStreamType, ErrorEmitTarget, PipeEmitTarget
                , LameLogObjectType
             /* , GWritableStreamType */
{
  // TBD: what we really want is a way to materialize GWritableStreamType<UInt8>
  // See: ReadableByteStreamType for the issue.
  
  /// Returns true if all chunks got written fully or enough buffer space was
  /// available. Return falls if the buffer space overflowed (but the chunks
  /// are still queued!)
  func writev(buckets chunks: [ [ UInt8 ] ], done: DoneCB?) -> Bool
}


// MARK: - UTF8 support for UInt8 streams

/// Convenience - can write Strings to any Byte stream as UTF-8
public extension GWritableStreamType where WriteType == UInt8 {
  // TODO: UTF8View should be a BucketType ...
  
  public func write(chunk: String, done: DoneCB? = nil) -> Bool {
    let bucket = Array<UInt8>(chunk.utf8) // aaargh
    return writev(buckets: [ bucket ], done: done)
  }
  
  public func end(chunk: String, doneWriting: DoneCB? = nil) {
    let bucket = Array<UInt8>(chunk.utf8) // aaargh
    _ = writev(buckets: [ bucket ]) {
      if let cb = doneWriting { cb() }
      self.end()
    }
  }
  
#if swift(>=3.0) // #swift3-1st-arg #swift3-discardable-result
  @discardableResult
  public func write(_ chunk: String, done: DoneCB? = nil) -> Bool {
    let bucket = Array<UInt8>(chunk.utf8) // aaargh
    return writev(buckets: [ bucket ], done: done)
  }
  
  public func end(_ chunk: String, doneWriting: DoneCB? = nil) {
    let bucket = Array<UInt8>(chunk.utf8) // aaargh
    _ = writev(buckets: [ bucket ]) {
      if let cb = doneWriting { cb() }
      self.end()
    }
  }
#endif
}
