//
//  ReadableByteStreamType.swift
//  Noze.io
//
//  Created by Helge Hess on 19/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import core
import events

/// A stream which just deals with bytes.
///
/// Careful with using this. It essentially side tracks `GReadableStreamType`.
///
public protocol ReadableByteStreamType : ReadableStreamType
                                       , ErrorEmitTarget, LameLogObjectType
                                    /* , GReadableStreamType */
{
  // TBD: what we really want is a way to materialize GReadableStreamType<UInt8>
  //
  // Which kinda works, but adding `GReadableStreamType`
  // in Swift 0.2.2: later crashes the compiler in the `net` module
  // in Swift 0.3-2016-05-09: `DuplexByteStreamType` is considered generic
  
  func read(count c: Int?) -> [ UInt8 ]?
  
  /// push data (or EOF) to the stream buffer, this will result in an onReadable
  /// event eventually.
  func push   (_ b: [ UInt8 ]?)
  
  /// Like `push`, but this put the data into the front of the buffer. It is
  /// useful if a consuming stream could not handle all data, and wants to wait
  /// for more.
  func unshift(_ b: [ UInt8 ])
}


// MARK: - UTF8 support for UInt8 streams

/// Convenience - can write Strings to any Byte stream as UTF-8
public extension GReadableStreamType where ReadType == UInt8 {
  // TODO: UTF8View should be a BucketType ...
  
  public func push(_ chunk: String, done: DoneCB? = nil) {
    let bucket = Array<UInt8>(chunk.utf8) // aaargh
    push(bucket)
  }
  public func unshift(_ chunk: String, done: DoneCB? = nil) {
    let bucket = Array<UInt8>(chunk.utf8) // aaargh
    unshift(bucket)
  }
  
}
