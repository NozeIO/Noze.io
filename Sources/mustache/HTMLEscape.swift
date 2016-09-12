//
//  HTMLEscape.swift
//  Noze.io
//
//  Created by Helge Heß on 6/7/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

private let lt    : [ UInt8 ] = [ 38, 108, 116, 59 ]
private let gt    : [ UInt8 ] = [ 38, 103, 116, 59 ]
private let amp   : [ UInt8 ] = [ 38,  97, 109, 112,  59 ]
private let quot  : [ UInt8 ] = [ 38, 113, 117, 111, 116, 59 ]
private let squot : [ UInt8 ] = [ 38,  35,  51,  57,  59 ]

public extension MustacheRenderingContext {
  
  func escape(string s: String) -> String {
    // FIXME: speed. only create out buffer on demand
    let utf8    = s.utf8
    let len     = utf8.count
    var newUTF8 = [ UInt8 ]()
    newUTF8.reserveCapacity(len)
    
    for c in utf8 {
      switch c {
        case 60: /* '<' */ newUTF8.append(contentsOf: lt)
        case 62: /* > */   newUTF8.append(contentsOf: gt)
        case 38: /* & */   newUTF8.append(contentsOf: amp)
        case 34: /* " */   newUTF8.append(contentsOf: quot)
        case 39: /* ' */   newUTF8.append(contentsOf: squot)
        
        default:
          newUTF8.append(c)
      }
    }
    
    if newUTF8.count == len { return s }
    
    newUTF8.append(0)
    
    return newUTF8.withUnsafeBufferPointer { bp in
      return String(cString: bp.baseAddress!)
    }
  }
  
}
