//
//  UTF8toCharacter.swift
//  Noze.io
//
//  Created by Helge Heß on 5/1/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import core

/// Consumes bytes and produces Characters from that.
public class UTF8ToCharacter: TransformStream<UInt8, Character> {
  
  override init(readHWM      : Int? = nil,
                writeHWM     : Int? = nil,
                queue        : DispatchQueueType = core.Q,
                enableLogger : Bool = false)
  {
    super.init(readHWM: readHWM, writeHWM: writeHWM, queue: queue,
               enableLogger: enableLogger)
  }

  
  // MARK: - Transform
  
  var allData = Array<UInt8>() // super lame implementation

  public override func _flush(done cb: ( Error?, [ Character ]? ) -> Void) {
    
    // copy, sigh
    if !allData.isEmpty {
      allData.append(0) // make it a cString
      let so : String? = allData.withUnsafeBufferPointer { ptr in
        // FIXME: throw conversion error
#if swift(>=3.0) // #swift3-ptr #swift3-str
        return String(cString: ptr.baseAddress!)
#else
        let cp = UnsafePointer<CChar>(ptr.baseAddress)
        return String.fromCString(cp)
#endif
      }
      
      allData.removeAll()
      
      // and yet another copy, dbl-sigh ;-)
      if let s = so {
        push(bucket: Array(s.characters))
      }
      else {
        catched(error: EncodingError.CouldNotDecodeCString)
      }
    }
    
    push(bucket: nil) // EOF
    cb(nil, nil /* nil doesn't mean EOF here but don't push */) // done
  }
  
  public override func _transform(bucket b: [ UInt8 ], done: TransformDoneCB) {
    // This is still lame, but at least we don't spool up for plain ASCII
    if allData.isEmpty {
#if swift(>=3.0) // #swift3-fd
      let idxOrNot = b.index(where: { ((highBit & $0) == highBit) })
#else
      let idxOrNot = b.indexOf({ ((highBit & $0) == highBit) })
#endif
      if let idx = idxOrNot {
        // found a high byte
        if idx > 0 {
          // TODO: this should be a func: Array<UInt8>.asASCIICharacters
#if swift(>=3.0) // #swift3-fd
          push(bucket: b[0..<idx].map { Character(UnicodeScalar(Int($0))!)})
#else
          push(bucket: b[0..<idx].map { Character(UnicodeScalar(Int($0)))})
#endif
          allData.append(contentsOf: b[idx..<b.count])
        }
        else {
          allData.append(contentsOf: b)
        }
        done(nil, nil)
      }
      else { // whole bucket was ASCII
#if swift(>=3.0) // #swift3-fd
        done(nil, b.map { Character(UnicodeScalar(Int($0))!) })
#else
        done(nil, b.map { Character(UnicodeScalar(Int($0))) })
#endif
      }
    }
    else { // already spooled up stuff
      allData.append(contentsOf: b)
      done(nil, nil)
    }
  }
}

private let highBit = UInt8(0x80)
