//
//  FileSource.swift
//  Noze.IO
//
//  Created by Helge Hess on 23/06/15.
//  Copyright © 2015 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import core
import xsys
import streams

/// A source which can open a file and read from it.
/// 
/// Don't use this directly, rather do a:
///
///     let stream = fs.createReadStream("/etc/passwd")
///
public class FileSource: GCDChannelBase, GReadableSourceType {

  public static var defaultHighWaterMark : Int { return 1024 } // TODO
  
  let path   : String
  var isOpen : Bool { return fd.isValid }
  
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
  
  let mode      : mode_t = 0
  let openFlags = xsys.O_RDONLY
  
  public override func createChannelIfMissing(Q q: DispatchQueueType)
                       -> ErrorType?
  {
    guard channel == nil else { return nil }
    assert(!fd.isValid, "descriptor is valid, but channel is closed?")
    
    channel = dispatch_io_create_with_path(xsys_DISPATCH_IO_STREAM, path,
                                           openFlags, mode, q, cleanupChannel)
    return channel != nil ? nil : POSIXError(rawValue: xsys.errno)
  }
  
  
  // MARK: - Description
  
  public override func descriptionAttributes() -> String {
    var s = super.descriptionAttributes()
    s += " path='\(path)'"
    return s
  }
}
