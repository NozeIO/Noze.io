//
//  Writer.swift
//  Noze.IO
//
//  Created by Helge Heß on 20/06/15.
//  Copyright © 2015 ZeeZide GmbH. All rights reserved.
//

import XCTest
import Dispatch
import core
@testable import streams

class NumberPrinter : streams.SinkType, GWritableTargetType {

  func put(_ x: Int) {
    print("NP: value: \(x)")
  }
  
  static var defaultHighWaterMark : Int { return 2 }
  
  func writev(queue q : DispatchQueueType,
              chunks  : [ [ Int ] ],
              yield   : @escaping ( Error?, Int ) -> Void)
  {
    var count = 0
    
    print("NP: brigade #\(chunks.count):")
    for bucket in chunks {
      print("NP:   bucket: #\(bucket.count) ..")
      for value in bucket {
        print("NP:     value: \(value)")
        count += 1
      }
    }
    
    yield(nil, count) // we are never full
  }
  
}
