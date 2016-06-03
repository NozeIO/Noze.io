//
//  ntohs.swift
//  NozeIO
//
//  Created by Helge Hess on 11/04/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if swift(>=3.0)
public func ntohs(_ value: CUnsignedShort) -> CUnsignedShort {
  // hm, htons is not a func in OSX and the macro is not mapped
  return (value << 8) + (value >> 8);
}
#else
public func ntohs(value: CUnsignedShort) -> CUnsignedShort {
  // hm, htons is not a func in OSX and the macro is not mapped
  return (value << 8) + (value >> 8);
}
#endif
public let htons = ntohs // same thing, swap bytes :-)
