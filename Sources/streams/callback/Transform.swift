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
  
  #if swift(>=3.0) // #swift3-escape
  public typealias TransformDoneCB = @escaping ( Error?, [ ReadType ]? ) -> Void
  
  public typealias TransformCB = @escaping ( _ bucket: [ WriteType ],
                                   _ push: @escaping ( [ ReadType ]? ) -> Void,
                                   _ done: TransformDoneCB
                                 ) -> Void
  #else // Swift 2.x
  public typealias TransformDoneCB = ( Error?, [ ReadType ]? ) -> Void
  
  public typealias TransformCB = ( _ bucket: [ WriteType ],
                                   _ push: ( [ ReadType ]? ) -> Void,
                                   _ done: ( Error?, [ ReadType ]? ) -> Void
                                 ) -> Void
  #endif // Swift 2.x
  
  
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
                                  done     : TransformDoneCB)
  {
    transform(bucket: b, push: { self.push(bucket: $0) }, done: done)
  }
  
  override public func _flush(done cb: ( Error?, [ ReadType ]? ) -> Void) {
    // TBD: support a flush callback?
    self.transform = nil // break cycles
    cb(nil, nil)
  }
}
