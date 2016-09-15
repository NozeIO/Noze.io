//
//  Module.swift
//  Noze.io
//
//  Created by Helge Heß on 4/10/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

@_exported import core

public class NozeCrypto : NozeModule {
}
public let module = NozeCrypto()

public func createHash(_ hash: String) -> Hash? {
  switch hash {
    case "md5": return MD5Hash()
    default:    return nil
  }
}


import CryptoSwift

public extension Collection where Iterator.Element == UInt8 {
  // this is kinda simulating the Buffer object `toString` method. Maybe it
  // should be moved to core.
  
  func toString(_ format: String) -> String? {
    switch format {
      case "hex": return self.hexString
      default:    return nil
    }
  }
  
}
