//
//  GWritableTarget.swift
//  Noze.IO
//
//  Created by Helge Hess on 30/06/15.
//  Copyright © 2015 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import core

/// A writable endpoint. Like a file or socket, or a SinkType.
///
/// This is meant to encapsulate the writev implementation - instead of 
/// subclassing WritableStream, the idea is that you use the generic `Writable`
/// which does all the buffering and eventing etc.
/// The task of the actual writing is then done by a `GWritableTargetType`. 
/// Which is only responsible for doing the write, not buffering/events or 
/// whatsoever.
///
public protocol GWritableTargetType {
  
  associatedtype TargetElement
  
  /// The yield returns an error and/or the number of elements
  /// written (NOT the number of buckets!).
  /// The queue is the queue in which the yield must be run.
  mutating func writev(queue q : DispatchQueueType,
                       chunks  : [ [ Self.TargetElement ] ],
                       yield   : @escaping ( Error?, Int ) -> Void)

  // TODO: need an 'end' (which then closes the target)
  
  
  // This should define a sensible default buffer size of the target. E.g. it
  // could be something like 1K for a file stream.
  // It is used as the default buffer size of a Writable.
  static var defaultHighWaterMark : Int { get }
  
  
  // Intended for targets which never really end, like interactive stdout.
  // TBD: does this really make sense?
  var canEnd : Bool { get }

  
  /// Closing a target
  func closeTarget()
}

extension GWritableTargetType {
  
  public static var defaultHighWaterMark : Int  { return 1024 }
  public        var canEnd               : Bool { return true }
  
  public func closeTarget() {} // noop default imp
}
