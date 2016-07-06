//
//  StringToUTF8.swift
//  NozeIO
//
//  Created by Helge Hess on 11/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import core

/// Consumes Characters and produces bytes in UTF-8 encoding from that.
public class StringToUTF8: TransformStream<String, UInt8> {
  
  override init(readHWM      : Int? = nil,
                writeHWM     : Int? = nil,
                queue        : DispatchQueueType = core.Q,
                enableLogger : Bool = false)
  {
    super.init(readHWM: readHWM, writeHWM: writeHWM, queue: queue,
               enableLogger: enableLogger)
  }

  
  // MARK: - Transform
  
  public override func _transform(bucket b : [ String ],
                                  done     : ( ErrorProtocol?, [ UInt8 ]? ) -> Void)
  {
    guard !b.isEmpty else { done(nil, []); return }

    for s in b {
      // FIXME: All this is lame and to much copying. It should be all redone
      //        for proper speed
      let bytes = Array<UInt8>(s.utf8)
      push(bucket: bytes)
    }
    
    done(nil, nil)
  }
}
