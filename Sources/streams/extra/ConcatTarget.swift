//
//  ConcatStream.swift
//  Noze.io
//
//  Created by Helge Hess on 22/04/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import core

/// Use the concat<T>() module function to get access to this.
public class ConcatTarget<ReadType> : GWritableTargetType {

  public typealias TargetElement = ReadType // #swift3-gen
  
  public static var defaultHighWaterMark : Int { return 1 }
  
  var allData = Array<TargetElement>()
  var doneCB  : (( [ TargetElement ] ) -> Void)? = nil
    // optional just to break retain cycles
  
  // MARK: - Init from a GeneratorType or a SequenceType
  
  public init(_ doneCB: @escaping ( [ TargetElement ] ) -> Void) {
    self.doneCB = doneCB
  }
  
  public func writev(queue q : DispatchQueueType,
                     chunks  : [ [ TargetElement ] ],
                     yield   : @escaping ( Error?, Int ) -> Void)
  {
    var count = 0
    for chunk in chunks {
      allData += chunk
      count += chunk.count
    }
    
    yield(nil, count)
  }

  public func closeTarget() {
    if let cb = doneCB {
      cb(allData)
      doneCB = nil
    }
    
    allData.removeAll()
  }

}
