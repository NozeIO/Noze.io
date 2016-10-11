//
//  NumberGenerator.swift
//  Noze.IO
//
//  Created by Helge Heß on 21/06/15.
//  Copyright © 2015 ZeeZide GmbH. All rights reserved.
//

import XCTest
import Dispatch
@testable import core
@testable import streams

class NumberGenerator : IteratorProtocol {
  // this is just a basic number generator ... It is used in the
  // AsyncNumberGenerator below
  
  let log = Logger(enabled: false)
  
  var current = 1
  let max     : Int
  
  init(max: Int = 10) {
    self.max = max
  }
  
  func next() -> Int? {
    // we just do one and ignore count
    log.enter(); defer { log.leave() }
    
    print("GGG NumberGenerator \(self): \(current)")
    
    guard current <= max else { return nil }
    
    current += 1
    return current
  }
}
  

class AsyncNumberGenerator : NumberGenerator, GReadableSourceType {
  
  static var defaultHighWaterMark : Int { return 5 }
  let delayInMS : Int
  
  init(max: Int = 10, delay: Int = 0) {
    self.delayInMS = delay
    super.init(max: max)
  }
  
  func next(queue _: DispatchQueue, count: Int = 1,
            yield: @escaping ( Error?, [Int]? )-> Void)
  {
    let log = self.log
    log.enter(function: "AsyncNumGen::\(#function)")
    defer { log.leave() }
    
    let block : (Void) -> Void = {
      log.enter(function: "AsyncNumGen::\(#function) - delayed CB")
      defer { log.leave() }
      
      print("GGG AsyncNumGen \(self): \(self.current) [asked for \(count)]")
      
      guard self.current <= self.max else {
        yield(nil, nil)
        return
      }
      
      yield(nil, [ self.current ])
      self.current += 1
    }
    
    if delayInMS < 1 {
      nextTick(handler: block)
    }
      
    else {
      setTimeout(delayInMS, block)
    }
  }
}
