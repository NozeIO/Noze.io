//
//  Server.swift
//  Noze.io
//
//  Created by Helge Heß on 4/17/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import xsys
import core
import events
import fs

public typealias ServerEventCB = ( Server ) -> Void

/// TODO: doc
open class Server : ErrorEmitter, LameLogObjectType {
  // Kinda like the SwiftSockets `PassiveSocket<T>`.
  // TBD: We could make Server a generic type on the SocketAddress, like in
  //      SwiftSockets. But the Node Server class doesn't work like that, so
  //      maybe we keep it that way.
  //      Another option would be to separate out that part as a generic.
  
  public let log          : Logger
  public var backlog      : Int?                = nil
  public var isListening  : Bool { return backlog != nil }
  public var fd           : FileDescriptor?     = nil // fd can be invalid too
  public var address      : sockaddr_any?       = nil
  public var listenSource : DispatchSourceProtocol? = nil
  public let Q            : DispatchQueue
  public var didRetainQ   : Bool = false // #linux-public
  
  public let allowHalfOpen  : Bool
  public let pauseOnConnect : Bool
  
  public init(allowHalfOpen  : Bool = false,
              pauseOnConnect : Bool = false,
              queue          : DispatchQueue = core.Q,
              enableLogger   : Bool = false)
  {
    self.Q   = queue
    self.log = Logger(enabled: enableLogger)
    
    self.allowHalfOpen  = allowHalfOpen
    self.pauseOnConnect = pauseOnConnect
    
    super.init()

    log.onAfterEnter  = { [unowned self] log in self.logState() }
    log.onBeforeLeave = { [unowned self] log in self.logState() }
  }
  deinit {
    self._primaryClose()
    
    if self.didRetainQ {
      core.module.release()
      self.didRetainQ = false
    }
  }
  
  
  // MARK: - Listening
  
  @discardableResult
  open func listen(_ port      : Int? = nil,
                   backlog     : Int  = 512,
                   onListening : ServerEventCB? = nil) -> Self
  {
    if let cb = onListening { _ = self.onListening(handler: cb) }
    
    // TODO: How to decide between IPv4 and IPv6? Node says it's using v6 when
    //       available.
    let address = xsys_sockaddr_in(port: port)
    
    return self.listen(address, backlog: backlog)
  }
  
  @discardableResult
  public func listen(_ address: sockaddr_any, backlog: Int = 512) -> Self {
    switch address {
      case .AF_INET (let addr): return listen(addr, backlog: backlog)
      case .AF_INET6(let addr): return listen(addr, backlog: backlog)
      case .AF_LOCAL(let addr): return listen(addr, backlog: backlog)
    }
  }
  
  @discardableResult
  public func listen<AT: SocketAddress>(_ address: AT, backlog: Int = 512,
                                        exclusive: Bool = false) -> Self
  {
    // Note: Everything here runs synchronously, which I guess is fine in this
    //       specific case? 
    // TBD:  We could dispatch it, but is it worth? Maybe. More stuff could be
    //       going on (connections to watchdogs etc).
    let log = self.log
    log.enter(); defer { log.leave() }
    log.debug("   address: \(address)")
    
    
    // setup socket if necessary
    
    if fd == nil {
      let rc = _setupSocket(domain: AT.domain)
      guard rc == 0 else { return catched(error: xsys.errno) } // TODO: better err
    }
    assert(fd?.isValid ?? false)
    
    
    // set SO_REUSEADDR - I suppose this is what `exclusive` is about?
    if !exclusive {
      let rc = _makeNonExclusive(fd: fd!)
      guard rc == 0 else { return catched(error: xsys.errno) } // TODO: better err
    }
    
    
    // bind socket
    
    let brc = _bind(address: address)
    guard brc == 0 else { return catched(error: xsys.errno) } // TODO: better err
    
    
    // determine the address we bound to
    
    let boundAddress : AT? = getasockname(fd: fd!.fd, xsys.getsockname)
    self.address = sockaddr_any(boundAddress)
    assert(self.address != nil)
    
    
    // setup GCD source
    
    let listenSource = DispatchSource.makeReadSource(fileDescriptor: fd!.fd,
                                                     queue: self.Q)
    self.listenSource = listenSource
    if !self.didRetainQ { core.module.retain() }
    
    
    // setup GCD callback
    // Note: This creates a retain-cycle, which is kinda the right thing to do
    //       (Server object should not go away until the dispatch source is
    //        active? Or should it go away an drop the source properly)
    //       In other words: the server only goes away if it is closed.
    listenSource.setEventHandler {
      self._onListenEvent(address: boundAddress)
    }
    listenSource.resume()
    
    
    // make non-blocking
    fd!.isNonBlocking = true
    
    
    // start listening ...
    
    let rc = xsys.listen(fd!.fd, Int32(backlog))
    guard rc == 0 else { return catched(error: xsys.errno) } // TODO: better err
    
    
    // finish up
    
    self.backlog = backlog
    
    nextTick {
      self.listeningListeners.emit(self)
    }
    return self
  }
  
  
  // MARK: - Accepting
  
  public func _onListenEvent<AT: SocketAddress>(address localAddress: AT?) {
    // #linux-public
    // This is cheating a little, we pass in the localAddress to capture the
    // generic socket type (which matches the one returned by accept().
    log.enter(); defer { log.leave() }
    
    repeat { // TBD: Presumably we might get multiple accepts per event?
      let lfd      = self.fd!.fd
      var baddr    = AT()
      var baddrlen = socklen_t(baddr.len) // this can change! (AF_LOCAL)
      
      let newFD = withUnsafeMutablePointer(to: &baddr) {
        ptr -> Int32 in
        return ptr.withMemoryRebound(to: xsys_sockaddr.self, capacity: 1) {
          bptr -> Int32 in
          return xsys.accept(lfd, bptr, &baddrlen);// buflenptr)
        }
      }
      
      if newFD != -1 {
        // a successful accept
        let socket = Socket(FileDescriptor(newFD), queue: self.Q)
        // TODO: it would be better to collect all the sockets in an array and
        //       just do a single tick at the end
        
        socket.isSigPipeDisabled = true
        
        socket.allowsHalfOpen = allowHalfOpen
        if pauseOnConnect {
          socket.pause()
        }
        
        if baddrlen > 0 {
          socket.remoteAddress = sockaddr_any(baddr)
        }
        
        accept(socket: socket)
      }
      else if xsys.errno == xsys.EWOULDBLOCK {
        // leave loop, we would block.
        break
      }
      else {
        let error = POSIXErrorCode(rawValue: xsys.errno)!
        handleAccept(error: error)
      }
    }
    while true
  }
  
  open func accept(socket s: Socket) {
    log.enter(); defer { log.leave() }
    log.log("socket: \(socket)")
    
    nextTick {
      // TODO: track connections in server
      self.connectionListeners.emit(s)
    }
  }
  
  open func handleAccept(error e: Error) { // #linux-public
    // TBD: is this a close condition? Probably, or not? :-) Let's say no
    //      for now and assume the socket is still good and can potentially
    //      accept() successfully in the future (once that RoR process
    //      running on the same machine crashed and released resources)
    print("Failed to accept() socket: \(self) \(e)")
    nextTick {
      self.errorListeners.emit(e)
    }
  }
  
  
  // MARK: - Binding
  
  public func _bind<AT: SocketAddress>(address a: AT) -> Int32 { // #linux-public
    var address = a
    return withUnsafePointer(to: &address) { ptr -> Int32 in
      return ptr.withMemoryRebound(to: xsys_sockaddr.self, capacity: 1) {
        bptr in
        return xsys.bind(fd!.fd, bptr, socklen_t(address.len))
      }
    }
  }
  
  
  // MARK: - Reuse server socket
  
  public func _makeNonExclusive(fd lfd: FileDescriptor) -> Int32 { // #linux-public
    var buf    = Int32(1)
    let buflen = socklen_t(MemoryLayout<Int32>.stride)
    let rc     = xsys.setsockopt(lfd.fd, xsys.SOL_SOCKET, xsys.SO_REUSEADDR,
                                 &buf, buflen)
    return rc
  }
  
  
  // MARK: - Closing the server
  
  open func close() {
    // TODO: Stop accepting connections.
    // TODO: In Node the server keeps a list of the connections and only closes
    //       once all connections have ended. Which probably makes some sense.
    _close()
  }
  
  public func _primaryClose() { // #linux-public
    if listenSource != nil {
      listenSource!.cancel()
      listenSource = nil
    }
    
    if let fd = self.fd {
      fd.close()
      self.fd = nil
    }
    self.address = nil
    self.backlog = nil
  }
  
  public func _close() { // #linux-public
    log.enter(); defer { log.leave() }
    
    _primaryClose()
    
    // notify close listeners
    nextTick {
      self.closeListeners.emit(self)
      
      nextTick { // TBD: is this desirable? delayed or not?
        self.connectionListeners.removeAllListeners()
        self.listeningListeners.removeAllListeners()
        
        if self.didRetainQ {
          core.module.release()
          self.didRetainQ = false
        }
      }
    }
  }
  
  
  // MARK: - Create server socket
  
  public func _setupSocket(domain d: Int32, type: Int32 = xsys.SOCK_STREAM)
               -> Int32 // #linux-public
  {
    assert(fd == nil)
    
    let lfd = xsys.socket(d, type, 0)
    let err = xsys.errno
    log.debug("setup socket: \(lfd)")
    guard lfd != -1 else {
      log.debug("  failed: \(xsys.errno)")
      return err
    }
    
    fd = FileDescriptor(lfd)
    log.debug("  FD: \(fd as Optional)")
    return 0
  }
  
  
  // MARK: - Events

  public var closeListeners      = EventOnceListenerSet<Server>()
  public var connectionListeners = EventListenerSet<Socket>()
  public var listeningListeners  = EventListenerSet<Server>()
  
  @discardableResult
  public func onClose  (handler cb: @escaping ServerEventCB) -> Self {
    closeListeners.add(handler: cb);                  return self
  }
  @discardableResult
  public func onceClose(handler cb: @escaping ServerEventCB) -> Self {
    closeListeners.add(handler: cb, once: true);      return self
  }
  
  @discardableResult
  public func onConnection  (handler cb: @escaping ConnectCB) -> Self {
    connectionListeners.add(handler: cb);             return self
  }
  @discardableResult
  public func onceConnection(handler cb: @escaping ConnectCB) -> Self {
    connectionListeners.add(handler: cb, once: true); return self
  }
  
  @discardableResult
  public func onListening(handler cb: @escaping ServerEventCB) -> Self
  {
    listeningListeners.add(handler: cb);              return self
  }
  @discardableResult
  public func onceListening(handler cb: @escaping ServerEventCB) -> Self
  {
    listeningListeners.add(handler: cb, once: true);  return self
  }
  
  
  // MARK: - ErrorEmitter
  
  public func catched(error e: Error) { // #linux-public
    log.enter(); defer { log.leave() }
    self.errorListeners.emit(e)
  }
  
  public func catched(error e: Int32, close: Bool = true) -> Self {
    // #linux-public
    catched(error: POSIXErrorCode(rawValue: e)!)
    if close { _close() }
    return self
  }
  
  
  // MARK: - Logging
  
  open var logStateInfo : String {
    var s = ""
    if let address = address { s += " \(address)" }
    if let fd      = fd      { s += " fd=\(fd.fd)" }
    if let backlog = backlog { s += " backlog=\(backlog)" }
    return s
  }
  
  open func logState() {
    guard log.enabled else { return }
    log.debug("[\(logStateInfo)]")
  }
  
}
