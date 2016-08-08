//
//  UTF8toLines.swift
//  Noze.io
//
//  Created by Helge Heß on 5/1/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import core

/// Consumes UTF-8 bytes termined with a NL (10) and produces Strings from
/// that.
///
/// The stream can be accessed as:
///
///     streams.readlines
///
public class UTF8ToLines: TransformStream<UInt8, String> {
  // TODO: rewrite using UTF8 codec
  
  public var removeCR  : Bool
  public let splitChar : UInt8 = 10 // NL
  
  public init(removeCR     : Bool = true,
              readHWM      : Int? = nil,
              writeHWM     : Int? = nil,
              queue        : DispatchQueueType = core.Q,
              enableLogger : Bool = false)
  {
    self.removeCR = removeCR
    
    super.init(readHWM: readHWM, writeHWM: writeHWM, queue: queue,
               enableLogger: enableLogger)
  }
  
  // MARK: - Transform
  
  var pendingData = Array<UInt8>() // super lame implementation

  public override func _flush(done cb: ( Error?, [ String ]? ) -> Void) {
    // copy, sigh
    if !pendingData.isEmpty {
      let s = makeLine(bytebuf: pendingData)
      pendingData.removeAll()
      
      guard let line = s else {
        cb(EncodingError.CouldNotDecodeCString, nil)
        return
      }
      
      push(bucket: [ line ])
    }
    
    push(bucket: nil) // EOF
    cb(nil, nil /* nil doesn't mean EOF here but don't push */) // done
  }
  
  public override func _transform(bucket b : [ UInt8 ],
                                  done     : ( Error?, [ String ]? )
                       -> Void)
  {
    let bucket = b
    guard !bucket.isEmpty else {
      done(nil, nil)
      return
    }
    
    // NL abc NL NL def
    
    var hasPending = !pendingData.isEmpty
    var lastStart  = bucket.startIndex
    var lines      = Array<String>()
    
    for i in 0..<bucket.count {
      let c = bucket[i]
      
      if c == splitChar {
        let byteLine : [ UInt8 ]
        
        if hasPending {
          byteLine   = pendingData + bucket[lastStart..<i]
          hasPending = false
          pendingData.removeAll() // consumed
        }
        else {
          byteLine = Array(bucket[lastStart..<i]) // tooo many copies
        }
        
        if let line = makeLine(bytebuf: byteLine) {
          lines.append(line)
        }
        else {
          if !lines.isEmpty { push(bucket: lines) }
          done(EncodingError.CouldNotDecodeCString, nil)
          return // early exit
        }
        
#if swift(>=3.0) // #swift3-fd
        lastStart = i + 1
#else
        lastStart = i.advancedBy(1)
#endif
      }
    }
    
    if lastStart < bucket.endIndex {
      // add remaining data
      pendingData.append(contentsOf: bucket[lastStart..<bucket.endIndex])
    }
    
    if !lines.isEmpty { push(bucket: lines) }
    done(nil, nil)
  }
  
  final func makeLine(bytebuf line : [ UInt8 ]) -> String? {
    if line.isEmpty { return "" }
    
    var t0 = line // TODO: this is all bad and too much copying
    
    if removeCR {
      let count = t0.count
      if t0[count - 1] == 13 {
        if count == 1 { return "" }
        t0.remove(at: count - 1)
      }
    }
    
    t0.append(0) // zero terminate line
    
    let s : String? = t0.withUnsafeBufferPointer { ptr in
      let cp = UnsafePointer<CChar>(ptr.baseAddress)
#if swift(>=3.0) // #swift3-ptr #swift3-cstr
      return String(cString: cp!)
#else
      return String.fromCString(cp) // fails on empty string in 2.2?
#endif
    }
    
    return s
  }
}
