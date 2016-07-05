//
//  FileTarget.swift
//  Noze.IO
//
//  Created by Helge Hess on 23/06/15.
//  Copyright © 2015 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import xsys
import core
import streams
#if os(Linux)
  import Glibc
#else
  import Darwin
#endif

/// A target which can open a file and write to it.
///
/// Don't use this directly, rather do a:
///
///     let stream = fs.createWriteStream("/dev/null")
///
public class FileTarget: GCDChannelBase, GWritableTargetType {
  
  let path   : String
  var isOpen : Bool { return fd.isValid }
  let mode   : mode_t = (S_IWUSR | S_IRUSR | S_IRGRP | S_IROTH)
  let flags  = (O_WRONLY | O_CREAT)
  
  override public var fd : FileDescriptor {
    set {
      super.fd = newValue
    }
    get {
      if super.fd.isValid { return super.fd }
      guard channel != nil else { return nil }
      super.fd = FileDescriptor(channel.fileDescriptor)
      return super.fd
    }
  }
  
  // MARK: - init & teardown
  
  init(path: String) {
    self.path = path
    super.init(nil) // all stored class properties must be init'ed? why?
  }
  
  public override func createChannelIfMissing(Q q: DispatchQueueType) -> ErrorType? {
    guard channel == nil else { return nil } // ignore double-call
    
    if fd.isValid { // we already have a file-descriptor, but no channel
      channel = dispatch_io_create(xsys_DISPATCH_IO_STREAM, fd.fd, q, cleanupChannel)
    }
    else {
      channel = dispatch_io_create_with_path(xsys_DISPATCH_IO_STREAM, path,
                                             flags, mode, q, cleanupChannel)
    }
    
    // Essentially GCD channels already implement a buffer very similar to
    // Node.JS. But we do it on our own. Hence make GCD report input ASAP.
    channel.setLimit(lowWater: 1)
    return channel != nil ? nil : POSIXError(rawValue: xsys.errno)
  }
  
  // MARK: - Description
  
  public override func descriptionAttributes() -> String {
    var s = super.descriptionAttributes()
    s += " path='\(path)'"
    return s
  }
}
