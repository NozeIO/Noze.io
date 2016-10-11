//
//  Zenerator.swift
//  Noze.IO
//
//  Created by Helge Hess on 22/06/15.
//  Copyright © 2015 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import core

/// GReadableSourceType
///
/// Protocol for an object which can read data asynchronously.
///
/// NOTE: This is a generic protocol and the type of the data being read is
///       defined by the `Element` associated-type used in the next() function.
///       Eg in the case of GCDChannelSource, this is a UInt8 (aka a byte).
///
public protocol GReadableSourceType {
  
  associatedtype SourceElement
  
  /// Called by a Readable to ask a source for more data. The source can respond
  /// with one or more calls to yield() and signal EOF by a yield(null).
  ///
  /// The source can respond with less than count items, but it should not
  /// respond with more (otherwise the growth of the source buffer is out of
  /// control of the Readable).
  mutating func next(queue q : DispatchQueue,
                     count   : Int,
                     yield   : @escaping ( Error?, [ Self.SourceElement ]? )
                                           -> Void)
  
  /// Called by a Readable if it doesn't want to be fed additional data. Most
  /// commonly because its internal buffer is full.
  ///
  /// This is only relevant for asynchronous sources which may need to pause
  /// their underlying implementation (e.g. dispatch_source_suspend())
  ///
  /// Note: resume is done via a call to next()!
  func pause()
  
  /// This defines a sensible HWM for this kind of source. Eg it might be
  /// something like 1K for a file stream buffer.
  /// `Readable` uses this (G.defaultHWM) to define its internal buffer size if
  /// no specific size was assigned.
  static var defaultHighWaterMark : Int { get }
  
  /// Closing a source
  func closeSource()
}

public extension GReadableSourceType {
  func pause()       {} // noop default implementation
  func closeSource() {} // noop default implementation
}

// Note: cannot use a nice typealias in next():
//         typealias SourceYield = ( Error?, [ Self.Element ]? ) -> Void
//       this invalidates protocol conformance
