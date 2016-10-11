//
//  CharacterToUTF8.swift
//  Noze.io
//
//  Created by Helge Hess on 11/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import core

/// Consumes Characters and produces bytes in UTF-8 encoding from that.
class CharacterToUTF8: TransformStream<Character, UInt8> {
  
  override init(readHWM      : Int? = nil,
                writeHWM     : Int? = nil,
                queue        : DispatchQueue = core.Q,
                enableLogger : Bool = false)
  {
    super.init(readHWM: readHWM, writeHWM: writeHWM, queue: queue,
               enableLogger: enableLogger)
  }

  
  // MARK: - Transform
  
  override func _transform(bucket b: [ Character ],
                           done: @escaping ( Error?, [ UInt8 ]? ) -> Void)
  {
    guard !b.isEmpty else { done(nil, []); return }
    
    // FIXME: All this is lame and to much copying. It should be all redone for
    //        proper speed
    let bytes = Array<UInt8>(String(b).utf8)
    done(nil, bytes)
  }
}
