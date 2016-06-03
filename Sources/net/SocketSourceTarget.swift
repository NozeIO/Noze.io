//
//  SocketSourceTarget.swift
//  Noze.io
//
//  Created by Helge Hess on 31/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import xsys
import fs

private let heavyDebug = false

public class SocketSourceTarget : GCDChannelBase,
                                  GReadableSourceType, GWritableTargetType
{
  var allowsHalfOpen = false // TODO: complete me
  var isReadOpen     = true
  var isWriteOpen    = true

  override public func closeSource() {
    if allowsHalfOpen && isWriteOpen { // only shutdown read
      if heavyDebug { print("DEBUG: closing source ...") }
      _ = xsys.shutdown(fd.fd, xsys.SHUT_RD)
      isReadOpen = false
    }
    else {
      closeBoth()
    }
  }
  
  override public func closeTarget() {
    if allowsHalfOpen && isReadOpen { // only shutdown read
      if heavyDebug { print("DEBUG: closing target ...") }
      _ = xsys.shutdown(fd.fd, xsys.SHUT_WR)
      isWriteOpen = false
    }
    else {
      closeBoth()
    }
  }

  override public func closeBoth() {
    if heavyDebug { print("DEBUG: closing both ...") }
    super.closeBoth()
    isReadOpen  = false
    isWriteOpen = false
  }
}
