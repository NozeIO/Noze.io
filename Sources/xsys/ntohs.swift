//
//  ntohs.swift
//  Noze.io
//
//  Created by Helge Hess on 11/04/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

// FIXME: we now have .littleEndian, .bigEndian

public func ntohs(_ value: CUnsignedShort) -> CUnsignedShort {
  // hm, htons is not a func in OSX and the macro is not mapped
  return (value << 8) + (value >> 8);
}
public let htons = ntohs // same thing, swap bytes :-)
