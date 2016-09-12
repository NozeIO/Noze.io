//
//  UniqueRandomArray.swift
//  Noze.io
//
//  Created by Helge Heß on 27/06/2016.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import xsys
import core

func uniqueRandomArray<T>(_ array: [ T ]) -> () -> T {
  let ura = UniqueRandomArray(array)
  return { return ura.next() }
}

class UniqueRandomArray<T> {
  
  let originalArray  : [ T ]
  var remainingItems : [ T ]
  
  init(_ original: [ T ]) {
    self.originalArray  = original
    self.remainingItems = self.originalArray
  }

  func next() -> T {
    if remainingItems.isEmpty {
      remainingItems = originalArray // all consumed, reset
    }
    
    let idx = Int(xsys.arc4random_uniform(UInt32(remainingItems.count)))
    return remainingItems.remove(at: idx)
  }
}
