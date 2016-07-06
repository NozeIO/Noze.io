//
//  TempFS.swift
//  NozeIO
//
//  Created by Helge Heß on 5/7/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if os(Linux)
  import Glibc
#else
  import Darwin
#endif
import Dispatch

import xsys
import core
import streams

public class TempModule : NozeModule {
  // TODO:
  // - directories
  
  public var module : TempModule { return self }
    // nested module, still has module

  
  // MARK: - Tracking
  
  public var isTracking : Bool = false
  
  public func track() -> Self {
    isTracking = true
    return self
  }
  
  
  
  /// Wrap mkstemp/mkstemps. Synchronous.
  func openSync(template: String, suffix: String)
       -> ( ErrorProtocol?, ( fd: FileDescriptor, path: String )? )
  {
    // mkstemp modifies the incoming buffer to contain the resulting name
#if swift(>=3.0) // #swift3-cstr
    let inPlaceTemplate = strdup(template + suffix)!
#else
    let inPlaceTemplate = strdup(template + suffix)
    assert(inPlaceTemplate != nil)
#endif
    defer { free(inPlaceTemplate) }
    
    let fd = suffix.isEmpty
      ? mkstemp(inPlaceTemplate)
      : mkstemps(inPlaceTemplate, Int32(suffix.utf8.count))
    
    guard fd != -1 else { return ( POSIXError(rawValue: xsys.errno), nil ) }
    
    // Note: This is not how Node does it. Node also allows 'cleanup' calls,
    //       which I guess implies that it actually trackes the pathes it
    //       created and then registers an atexit handler to clean them up.
    if isTracking { unlink(inPlaceTemplate) }
    
#if swift(>=3.0) // #swift3-cstr
    let resolvedTemplate = String(validatingUTF8: inPlaceTemplate)
#else
    let resolvedTemplate = String.fromCString(inPlaceTemplate)
#endif
    assert(resolvedTemplate != nil)
    
    return ( nil, ( FileDescriptor(fd), resolvedTemplate! ) )
  }

  public func open(prefix:  String = "nzf-",
                   suffix:  String = "",
                   dir:     String = "/tmp", // TODO: use os.tmpDir()
                   pattern: String = "XXXXXXXX",
                   cb: ( ErrorProtocol?, ( fd: FileDescriptor, path: String )? )
              -> Void)
  {
    // TODO: Node does dir = os.tmpDir(), "myapp"
    core.module.retain()
    dispatch_async(fs.module.Q) {
      let template = dir + "/" + prefix + pattern
      let ( err, info ) = self.openSync(template, suffix: suffix)
      dispatch_async(core.Q) {
        cb(err, info)
        core.module.release()
      }
    }
  }
  
  public func createWriteStream(prefix:  String = "nzf-",
                                suffix:  String = "",
                                dir:     String = "/tmp", // TODO: use os.tmpDir()
                                pattern: String = "XXXXXXXX")
              -> TargetStream<FileTarget>
  {
    // A lame, blocking implementation. It'll do for now. FIXME
    
    let template = dir + "/" + prefix + pattern
    let ( error, info ) = openSync(template, suffix: suffix)
    
    // result is non-optional, create anyways
    let target = FileTarget(path: info?.path ?? template + suffix)
    if let error = error {
      target.closeTarget()
      
      let stream = target.writable(hwm: 1)
      stream.errorListeners.emit(error)
      return stream
    }
    else {
      target.fd = info!.fd // assign fix fd
      
      let stream = target.writable()
      return stream
    }
  }

#if swift(>=3.0) // #swift3-1st-arg
  func openSync(_ template: String, suffix: String)
       -> ( ErrorProtocol?, ( fd: FileDescriptor, path: String )? )
  {
    return openSync(template: template, suffix: suffix)
  }
  public func open(_ prefix: String = "nzf-",
                   suffix:   String = "",
                   dir:      String = "/tmp", // TODO: use os.tmpDir()
                   pattern:  String = "XXXXXXXX",
                   cb: ( ErrorProtocol?, ( fd: FileDescriptor, path: String )? )
              -> Void)
  {
    open(prefix: prefix, suffix: suffix, dir: dir, pattern: pattern, cb: cb)
  }
  public func createWriteStream(_ prefix: String = "nzf-",
                                suffix:   String = "",
                                dir:      String = "/tmp",
                                            // TODO: use os.tmpDir()
                                pattern:  String = "XXXXXXXX")
              -> TargetStream<FileTarget>
  {
    return createWriteStream(prefix: prefix, suffix: suffix, dir: dir,
                             pattern: pattern)
  }
#endif
}

public let temp = TempModule()
