//
//  Writer.swift
//  Noze.IO
//
//  Created by Helge Heß on 20/06/15.
//  Copyright © 2015 ZeeZide GmbH. All rights reserved.
//

import XCTest
import Dispatch
@testable import streams

class NumberPrinter : streams.SinkType, GWritableTargetType {

#if swift(>=3.0)
  func put(_ x: Int) {
    print("NP: value: \(x)")
  }
#else
  func put(x: Int) {
    print("NP: value: \(x)")
  }
#endif
  
  static var defaultHighWaterMark : Int { return 2 }
  
  func writev(queue q : dispatch_queue_t,
              chunks  : [ [ Int ] ],
              yield   : ( ErrorType?, Int ) -> Void)
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
