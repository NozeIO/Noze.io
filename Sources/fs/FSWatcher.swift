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
  var didRetainQ : Bool = false
  
  init(_ filename : String,
       persistent : Bool = true,
       listener   : FSWatcherCB? = nil)
  {
    self.path = filename
    self.Q    = core.Q // right? (MultiCrap uses a secondary global Q)
    
    super.init()
    
    if persistent {
      didRetainQ = true
      core.module.retain()
    }

    if let cb = listener {
      self.changeListeners.add(handler: cb)
    }
  }
  deinit {
    close()
  }
  
  public func close() {
    if didRetainQ {
      didRetainQ = false
      core.module.release()
    }
    
    closeListeners.emit(self)
  }
  

  // MARK: - Events

  public var closeListeners  = EventOnceListenerSet<FSWatcher>()
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

public class FSRawWatcher: FSWatcher {
  // TBD: should that be just a readable stream producing watcher events?
  //      we would get all the buffering and streaming and all that.
  //      disadvantage: user has to read() instead of getting stuff pushed.
  
  var fd  : CInt?
  var src : DispatchSourceProtocol? = nil
  
  override public init(_ filename : String,
                       persistent : Bool = true,
                       listener   : FSWatcherCB? = nil)
  {
    let lfd = xsys.open(filename, xsys.O_EVTONLY)
    fd = lfd >= 0 ? lfd : nil
    
    super.init(filename, persistent: persistent, listener: listener)
    
    if let fd = fd {
      // TBD: is the `else if` right? Or could it contain multiple? Probably!
      let flags : DispatchSource.FileSystemEvent = [ .write, .rename, .delete ]
  
      src = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fd,
                                                      eventMask: flags,queue: Q)
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

      src!.setCancelHandler { [weak self] in
        if let fd = self?.fd {
          _ = xsys.close(fd)
          self?.fd = nil
        }
      }
      
      src!.resume()
    }
    else {
      let error = POSIXErrorCode(rawValue: xsys.errno)!
      errorListeners.emit(error)
    }
  }
  
  override public func close() {
    if let src = src {
      src.cancel()
      self.src = nil
    }
    
    if let fd = self.fd {
      _ = xsys.close(fd)
      self.fd = nil
    }

    super.close()
  }
}

public class FSDirWatcher: FSWatcher {
  // TODO: error handling
  
  fileprivate var dirWatcher : DirectoryContentsWatcher?
  
  public init(_ fn       : String,
              persistent : Bool = true,
              recursive  : Bool = false,
              listener   : FSWatcherCB? = nil)
  {
    super.init(fn, persistent: persistent, listener: listener)
    
    dirWatcher = DirectoryContentsWatcher(path: fn, recursive: recursive) {
      event in // self is NOT weak, object stays awake until closed
      self.changeListeners.emit(event)
    }
  }
  
  override public func close() {
    dirWatcher?.close()
    dirWatcher = nil
    
    super.close()
  }
}

fileprivate class DirectoryContentsWatcher {
  
  let path       : String
  let recursive  : Bool
  var listener   : FSWatcherCB?
  
  var ownWatcher        : FSWatcher! = nil
  var childToFSWatcher  = [ String : FSWatcher ]()
  var childToDirWatcher = [ String : DirectoryContentsWatcher ]()
  
  init(path: String, recursive: Bool = true, listener: FSWatcherCB?) {
    self.path      = path
    self.listener  = listener
    self.recursive = recursive
    
    self.ownWatcher = FSRawWatcher(path) { [weak self] event in
      self?.onSelfChange(event)
    }
    
    syncDirectory()
  }
  deinit {
    self.close()
  }
  
  func close() {
    listener = nil
    
    ownWatcher?.close()
    ownWatcher = nil
    
    for ( _, watcher ) in childToFSWatcher {
      watcher.close()
    }
    childToFSWatcher = [:]
    
    for ( _, watcher ) in childToDirWatcher {
      watcher.close()
    }
    childToDirWatcher = [:]
  }
  
  func syncDirectory() {
    readdir(path) { [weak self] err, children in
      guard let `self` = self else { return }
      let newChildren = Set(children ?? [])
      
      for ( old, _ ) in self.childToFSWatcher {
        if !newChildren.contains(old) {
          self._dropChild(old)
        }
      }
      
      for new in newChildren {
        if self.childToFSWatcher[new] != nil { continue }
        
        let fullPath = self.path + "/" + new
        
        let dirWatch : Bool = {
          guard self.recursive else { return false }
          guard let finfo = try? fs.statSync(fullPath) else { return false }
          return finfo.isDirectory()
        }()
        
        // FIXME: duplicate events for dir itself?
        if dirWatch {
          self.childToDirWatcher[new] =
            DirectoryContentsWatcher(path: fullPath, recursive: true,
                                     listener: self.listener)
        }
        
        self.childToFSWatcher[new] = FSRawWatcher(fullPath) {
          [weak self] event in
         
          self?.onChildChange(event, new)
        }
      }
    }
  }
  
  func _dropChild(_ old : String) {
    if let watcher = self.childToFSWatcher.removeValue(forKey: old) {
      watcher.close()
    }
    if let watcher = self.childToDirWatcher.removeValue(forKey: old) {
      watcher.close()
    }
  }
  
  func onChildChange(_ event: FSWatcherEvent, _ path: String) {
    let fullPath = self.path + "/" + path
    listener?( ( event.event, fullPath) )
    
    // This is a little funny. for atomic writes the original file gets
    // deleted! If we don't resync, we hang on to the incorrect file
    // descriptor.
    if case .Delete = event.event {
      self._dropChild(path)
      
      nextTick {
        self.syncDirectory()
      }
    }
  }
  
  func onSelfChange(_ event: FSWatcherEvent) {
    listener?( ( event.event, self.path ) )
    nextTick {
      self.syncDirectory()
    }
  }
}

#endif /* !Linux */

