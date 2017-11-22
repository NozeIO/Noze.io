//
//  _ArrayType+Extensions.swift
//  CryptoSwift
//
//  Created by Marcin Krzyzanowski on 08/10/15.
//  Copyright © 2015 Marcin Krzyzanowski. All rights reserved.
//

// HH: only want toHexString :-)

public extension Sequence where Iterator.Element == UInt8 {
    var hexString : String {
        return self.lazy.reduce("") {
            var s = String($1, radix: 16)
            #if swift(>=3.2)
              if s.count == 1 {
                s = "0" + s
              }
            #else
              if s.characters.count == 1 {
                  s = "0" + s
              }
            #endif
            return $0 + s
        }
    }
}
