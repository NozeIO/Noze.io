//
//  FSWatcher.swift
//  NozeIO
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
  let Q          : dispatch_queue_t
  var fd         : CInt?
  var src        : dispatch_source_t? = nil
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
      let flags =
        (DISPATCH_VNODE_WRITE | DISPATCH_VNODE_RENAME | DISPATCH_VNODE_DELETE)
      
      src = dispatch_source_create(DISPATCH_SOURCE_TYPE_VNODE,
                                   UInt(fd),
                                   flags, Q)
      dispatch_source_set_event_handler(src!) {
        // TODO
        // MultiCrap dispatches `cb` on main queue
        let changes = dispatch_source_get_data(self.src!);
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
      
      dispatch_source_set_cancel_handler(src!) { [unowned self] in
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
      
#if os(Linux)
#if swift(>=3.0) // #swift3-fd
      dispatch_resume(unsafeBitCast(src, to: dispatch_object_t.self))
#else
      dispatch_resume(unsafeBitCast(src, dispatch_object_t.self))
#endif
#else
      dispatch_resume(src!)
#endif
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
      dispatch_source_cancel(src)
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
