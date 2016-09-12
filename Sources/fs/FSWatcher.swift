//
//  FSWatcher.swift
//  Noze.io
//
//  Created by Helge Hess on 02/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if !os(Linux) // 2016-09-12: Not yet available on Linux
// TBD: can we do an own implementation? using inotify?
// http://www.ibm.com/developerworks/linux/library/l-ubuntu-inotify/

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
  let Q          : DispatchQueue
  var fd         : CInt?
  var src        : DispatchSourceProtocol? = nil
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
      let flags : DispatchSource.FileSystemEvent = [ .write, .rename, .delete ]
  
      src = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd, eventMask: flags,queue: Q)
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
      let error = POSIXErrorCode(rawValue: xsys.errno)!
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
  
  public func onClose(cb: @escaping ( FSWatcher ) -> Void) -> Self {
    closeListeners.add(handler: cb)
    return self
  }
  public func onceClose(cb: @escaping ( FSWatcher ) -> Void) -> Self {
    closeListeners.add(handler: cb, once: true)
    return self
  }
  
  public func onChange(cb: @escaping ( FSWatcherEvent ) -> Void) -> Self {
    changeListeners.add(handler: cb)
    return self
  }
  public func onceChange(cb: @escaping ( FSWatcherEvent ) -> Void) -> Self {
    changeListeners.add(handler: cb, once: true)
    return self
  }
}

#endif /* !Linux */

