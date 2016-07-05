//
//  Writable.swift
//  Noze.IO
//
//  Created by Helge Hess on 30/06/15.
//  Copyright © 2015 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import core

/// A GCD based Writable stream. Similar but not exactly the same like a Node.JS
/// streams2 Writable object.
///
/// TODO
///
/// Differences to Node.JS:
/// - This Writable doesn't actually implement the underlying _write()
///   implementation, but defers that to a 'WritableTargetType'
/// - The WritableTargetType primary method is writev() and returns a count of
///   objects actually written
///   - in Node the _write only returns when everything passed in has been
///     written
/// - The Writable can deal with sets of any type (not just bytes, but e.g.
///   lines, or records as well). While Node.JS also has an 'object mode',
///   this works on a 'per item' basis.
///
public class TargetStream<T : GWritableTargetType>
           : WritableStream<T.TargetElement>
{
  
  public var target : T
  
  // MARK: - Init
  
  init(target       : T, highWaterMark: Int? = nil,
       queue        : DispatchQueueType = core.Q,
       enableLogger : Bool = false)
  {
    self.target = target
    
    super.init(highWaterMark : highWaterMark ?? T.defaultHighWaterMark,
               queue         : queue,
               enableLogger  : enableLogger)
    
    module.newWritableListeners.emit(self)
  }
  
  
  // MARK: - extension points for subclass
  
  override func _primaryWriteV(buckets c : Brigade,
                               done      : ( ErrorType?, Int ) -> Void)
  {
    log.enter(); defer { log.leave() }
    target.writev(queue: Q, chunks: c, yield: done)
  }

  
  // MARK: - Closing
  
  override public func closeWriteStream() {
    target.closeTarget()
    super.closeWriteStream()
  }
  

  override var _primaryCanEnd : Bool { return target.canEnd }
}

public extension GWritableTargetType {
  
  public func writable(hwm v: Int = Self.defaultHighWaterMark)
              -> TargetStream<Self>
  {
    return TargetStream(target: self, highWaterMark: v)
  }
  
}
