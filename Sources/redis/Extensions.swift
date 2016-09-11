//
//  Extensions.swift
//  Noze.io
//
//  Created by Helge Hess on 23/07/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if os(Linux)
  import func Glibc.isprint
#else
  import func Darwin.isprint
#endif

import core

extension Sequence where Iterator.Element == UInt8 {
  
  var debug : String {
    var s = ""
    for c in self {
      if isprint(Int32(c)) != 0 {
        s += " \(UnicodeScalar(c))"
      }
      else {
        s += " \\\(c)"
      }
    }
    return s
  }
}

extension String {
  
  static func decode<I: Collection>(utf8 ba: I) -> String?
                     where I.Iterator.Element == UInt8
  {
    return decode(units: ba, decoder: UTF8())
  }
  
  static func decode<Codec: UnicodeCodec, I: Collection>
                (units b: I, decoder d: Codec) -> String?
                     where I.Iterator.Element == Codec.CodeUnit
  {
    guard !b.isEmpty else { return "" }
    
    let minimumCapacity = 42 // what is a good tradeoff?
    var s = ""
    s.reserveCapacity(minimumCapacity)
    
    var decoder  = d
    var iterator = b.makeIterator()
    while true {
      switch decoder.decode(&iterator) {
        case .scalarValue(let scalar): s.append(String(scalar))
        case .emptyInput: return s
        case .error:      return nil
      }
    }
  }
  
}
