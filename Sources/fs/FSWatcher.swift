//
//  FSWatcher.swift
//  Noze.io
//
//  Created by Helge Hess on 02/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import xsys
import core
import events

public enum FSWatcherChange {
  case Rename, Write, Delete
}

public typealias FSWatcherEvent = ( event: FSWatcherChange, filename: String? )
public typealias FSWatcherCB    = ( FSWatcherEvent ) -> Void

public class FSWatcher: ErrorEmitter {
  // TBD: should that be just a readable stream producing watcher events?
  //      we would get all the buffering and streaming and all that.
  //      disadvantage: user has to read() instead of getting stuff pushed.
  
  let path       : String
  let Q          : DispatchQueueType
  var fd         : CInt?
  var src        : DispatchSourceType? = nil
  var didRetainQ : Bool = false
  
  public init(_ filename : String,
              persistent : Bool = true,
              listener   : FSWatcherCB? = nil)
  {
    self.path = filename
    self.Q    = core.Q // right? (MultiCrap uses a secondary global Q)
    
    let lfd = xsys.open(filename, xsys.O_EVTONLY)
    fd = lfd >= 0 ? lfd : nil
    
    super.init()
    
    if let fd = fd {
      // TBD: is the `else if` right? Or could it contain multiple? Probably!
#if !swift(>=3.0) || !(os(OSX) || os(iOS) || os(watchOS) || os(tvOS)) // #swift3-new-gcd
      let flags =
        (DISPATCH_VNODE_WRITE | DISPATCH_VNODE_RENAME | DISPATCH_VNODE_DELETE)
      src = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE,
                                   UInt(fd),
                                   flags, Q)
      src!.setEventHandler {
        // TODO
        // MultiCrap dispatches `cb` on main queue
        let changes = self.src!.data
        if (changes & DISPATCH_VNODE_DELETE != 0) {
          self.changeListeners.emit( ( .Delete, nil ) )
        }
        else if (changes & DISPATCH_VNODE_RENAME != 0) {
          self.changeListeners.emit( ( .Rename, nil ) )
        }
        else if (changes & DISPATCH_VNODE_WRITE != 0) {
          self.changeListeners.emit( ( .Write, nil ) )
        }
        else {
          assert(false, "unexpected change event: \(changes)")
        }
      }      
#else
      let flags : DispatchSource.FileSystemEvent = [ .write, .rename, .delete ]
      src = DispatchSource.fileSystemObject(fileDescriptor: fd,
                                            eventMask: flags, queue: Q)
      src!.setEventHandler {
        // TODO
        // MultiCrap dispatches `cb` on main queue
        let changes = (self.src! as! DispatchSourceFileSystemObject).data
        if changes.contains(.delete) {
          self.changeListeners.emit( ( .Delete, nil ) )
        }
        else if changes.contains(.rename) {
          self.changeListeners.emit( ( .Rename, nil ) )
        }
        else if changes.contains(.write) {
          self.changeListeners.emit( ( .Write, nil ) )
        }
        else {
          assert(false, "unexpected change event: \(changes)")
        }
      }      
#endif

      src!.setCancelHandler { [unowned self] in
        if let fd = self.fd {
          _ = xsys.close(fd)
          self.fd = nil
        }
      }
      
      if persistent {
        didRetainQ = true
        core.module.retain()
      }

      if let cb = listener {
        self.changeListeners.add(handler: cb)
      }

      src!.resume()
    }
    else {
      let error = POSIXError(rawValue: xsys.errno)!
      errorListeners.emit(error)
    }
  }
  deinit {
    close()
  }
  
  public func close() {
    if let src = src {
      src.cancel()
      self.src = nil
    }
    
    if didRetainQ {
      didRetainQ = false
      core.module.release()
    }
  }
  

  // MARK: - Events

  public var closeListeners  = EventListenerSet<FSWatcher>()
  public var changeListeners = EventListenerSet<FSWatcherEvent>()
  
  public func onClose(cb: ( FSWatcher ) -> Void) -> Self {
    closeListeners.add(handler: cb)
    return self
  }
  public func onceClose(cb: ( FSWatcher ) -> Void) -> Self {
    closeListeners.add(handler: cb, once: true)
    return self
  }
  
  public func onChange(cb: ( FSWatcherEvent ) -> Void) -> Self {
    changeListeners.add(handler: cb)
    return self
  }
  public func onceChange(cb: ( FSWatcherEvent ) -> Void) -> Self {
    changeListeners.add(handler: cb, once: true)
    return self
  }
}
