//
//  Transform.swift
//  Noze.io
//
//  Created by Helge Heß on 5/15/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import core

/// This is the same like TransformStream, but it takes a closure to do the
/// actual transform ...
public class Transform<WriteType, ReadType>
             : TransformStream<WriteType, ReadType>
{
  
  public typealias TransformCB = ( bucket: [ WriteType ],
                                   push: ( [ ReadType ]? ) -> Void,
                                   done: ( ErrorType?, [ ReadType ]? ) -> Void
                                 ) -> Void
  
  var transform : TransformCB!
  
  public init(readHWM      : Int? = nil,
              writeHWM     : Int? = nil,
              queue        : DispatchQueueType = core.Q,
              enableLogger : Bool = false,
              transform    : TransformCB)
  {
    self.transform = transform
    
    super.init(readHWM: readHWM, writeHWM: writeHWM, queue: queue,
               enableLogger: enableLogger)
  }
  
  
  // MARK: - TransformStream overrides
  
  override public func _transform(bucket b : [ WriteType ],
                                  done     : ( ErrorType?, [ ReadType ]? )
                       -> Void)
  {
    transform(bucket: b, push: { self.push(bucket: $0) }, done: done)
  }
  
  override public func _flush(done cb: ( ErrorType?, [ ReadType ]? ) -> Void) {
    // TBD: support a flush callback?
    self.transform = nil // break cycles
    cb(nil, nil)
  }
}
