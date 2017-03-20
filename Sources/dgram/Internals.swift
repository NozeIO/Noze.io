//
//  Module.swift
//  Noze.io
//
//  Created by https://github.com/lichtblau
//

import xsys
import fs

func recvfrom<AT: SocketAddress>(_ fd: FileDescriptor,
                                 count: Int = 65535)
     -> ( Error?, [ UInt8 ]?, AT?)
{
  // TODO: inefficient init. Also: reuse buffers.
  var buf = [ UInt8 ](repeating: 0, count: count)

  // synchronous

  var address = AT()
  var addrlen = socklen_t(address.len)
  let readCount = withUnsafeMutablePointer(to: &address) { ptr in
    ptr.withMemoryRebound(to: xsys_sockaddr.self, capacity: 1) { bptr in
      return xsys.recvfrom(fd.fd, &buf, count, 0, bptr, &addrlen)
    }
  }
  
  guard readCount >= 0 else {
    return ( POSIXErrorCode(rawValue: xsys.errno)!, nil, nil )
  }

  // TODO: super inefficient. how to declare sth which works with either?
  buf = Array(buf[0..<readCount]) // TODO: slice to array, lame
  return ( nil, buf, address )
}

func sendto(_ fd: FileDescriptor, data: [UInt8], to: SocketAddress) -> Error? {
  // synchronous

  var data      = data
  var toAddress = to
  let addrlen   = socklen_t(toAddress.len)
  let writtenCount = withUnsafePointer(to: &toAddress) { ptr in
    ptr.withMemoryRebound(to: xsys_sockaddr.self, capacity: 1) {
      bptr in
      return xsys.sendto(fd.fd, &data, data.count, 0, bptr, addrlen)
    }
  }

  guard writtenCount >= 0 else {
    return POSIXErrorCode(rawValue: xsys.errno)!
  }

  return nil
}
