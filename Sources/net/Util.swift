//
//  Util.swift
//  Noze.io
//
//  Created by Helge Hess on 19/04/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import xsys


// Common code for getsockname()/getpeername()

typealias GetNameFN = ( Int32, UnsafeMutablePointer<xsys_sockaddr>,
                        UnsafeMutablePointer<socklen_t>) -> Int32

// TBD:
public func getasockname<T: SocketAddress>(fd: Int32, _ nfn: GetNameFN) -> T? {
  // FIXME: tried to encapsulate this in a sockaddrbuf which does all the
  //        ptr handling, but it ain't work (autoreleasepool issue?)
  var baddr    = T()
  var baddrlen = socklen_t(baddr.len)
  
  // Note: we are not interested in the length here, would be relevant
  //       for AF_UNIX sockets
  let rc = withUnsafeMutablePointer(to: &baddr) {
    ptr -> Int32 in
    // TODO: is this right, or is there a better way?
    return ptr.withMemoryRebound(to: xsys_sockaddr.self, capacity: 1) { bptr in
      return nfn(fd, bptr, &baddrlen)
    }
  }
  
  guard rc == 0 else { // TODO: make this a proper error
    print("Could not get sockname? \(rc)")
    return nil
  }
  
  // print("PORT: \(baddr.sin_port)")
  return baddr
}
