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
  
  public typealias TransformCB = ( _ bucket: [ WriteType ],
                                   _ push: @escaping ( [ ReadType ]? ) -> Void,
                                   _ done: @escaping ( Error?, [ ReadType ]? ) -> Void
                                 ) -> Void
  
  var transform : TransformCB!
  
  public init(readHWM      : Int? = nil,
              writeHWM     : Int? = nil,
              queue        : DispatchQueueType = core.Q,
              enableLogger : Bool = false,
              transform    : @escaping TransformCB)
  {
    self.transform = transform
    
    super.init(readHWM: readHWM, writeHWM: writeHWM, queue: queue,
               enableLogger: enableLogger)
  }
  
  
  // MARK: - TransformStream overrides
  
  override public func _transform(bucket b : [ WriteType ],
                                  done     : @escaping ( Error?, [ ReadType ]? ) -> Void)
  {
    guard let transform = transform else { fatalError("no transform CB?") }
    transform(b, { self.push($0) }, done)
  }
  
  override public func _flush(done cb: @escaping ( Error?, [ ReadType ]? ) -> Void) {
    // TBD: support a flush callback?
    self.transform = nil // break cycles
    cb(nil, nil)
  }
}
