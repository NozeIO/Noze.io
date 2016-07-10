//
//  SocketAddress.swift
//  Noze.io
//
//  Created by Helge Hess on 12/04/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if os(Linux)
  import Glibc
#else
  import Darwin
#endif

public protocol SocketAddress {
  
  static var domain: Int32 { get }
  
  init() // create empty address, to be filled by eg getsockname()
  
  var len: __uint8_t { get }
}
