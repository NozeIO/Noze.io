//
//  Socket.swift
//  Noze.io
//
//  Created by Helge Heß on 4/10/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import Dispatch
#if os(Linux)
  import Glibc
#else
  import Darwin
#endif

import xsys
import core
import events
import streams
import fs
import dns

public typealias ConnectCB = ( Socket ) -> Void
public typealias TimeoutCB = ( Socket ) -> Void

public enum SocketError : Error {
  case Generic(POSIXErrorCode)
  case ConnectionRefused(sockaddr_any)
  
  public init(_ errno: Int32, _ address: sockaddr_any) {
    if errno == ECONNREFUSED {
      self = .ConnectionRefused(address)
    }
    else {
      self = .Generic(POSIXErrorCode(rawValue: errno)!)
    }
  }
  public init(_ errno: Int32) {
    self = .Generic(POSIXErrorCode(rawValue: errno)!)
  }
}

private let heavyDebug = false

enum SocketConnectionState {
  case Disconnected
  case Connecting
  case Connected
}

let connectQueue = DispatchQueue(label:     "io.noze.net.connect",
                                attributes: DispatchQueue.Attributes.concurrent)

/// TODO: doc
open class Socket : Duplex<SocketSourceTarget, SocketSourceTarget>,
                    DuplexByteStreamType, FileDescriptorStream
{
  // TBD: We could make Socket a generic type on the SocketAddress, like in
  //      SwiftSockets. But the Node Socket is more dynamic and does stuff like
  //      lookup etc.
  // TODO: this doesn't flush all event handler queues, e.g. timeout when the
  //       underlying socket is closed.
  
  let io : SocketSourceTarget
  
  public var fd : FileDescriptor {
    return io.fd
  }
  
  public init(_ fd         : FileDescriptor   = nil,
              queue        : DispatchQueue = core.Q,
              enableLogger : Bool             = false)
  {
    io = SocketSourceTarget(fd)
    
    if fd != nil {
      self.connectionState = .Connected // Right?
    }
    
    super.init(source: io, target: io,
               queue:        queue,
               enableLogger: enableLogger)
    
    if fd == nil {
      // Pause the streams until we are actually connected!
      self.pause()
      self.cork()
    }
    else {
      isSigPipeDisabled = true
    }
  }
  deinit {
    // print("dealloc socket \(self)")
  }
  
  
  // MARK: - Connect
  
  var connectionState = SocketConnectionState.Disconnected
  
  public func connect(options o: ConnectOptions, onConnect: ConnectCB? = nil)
              -> Self
  {
    return connect(port: o.port, host: o.hostname ?? "localhost",
                   family: o.family,
                   onConnect: onConnect)
  }
  
  public func connect(port lPort : Int,
                      host       : String      = "localhost",
                      family     : sa_family_t = sa_family_t(xsys.AF_INET),
                      onConnect  : ConnectCB?  = nil) -> Self
  {
    // TODO: Node has a few more options, but lets keep it simple for now ;-)
    guard connectionState == .Disconnected else {
      return self // TODO: error handling somehow
    }
    
    connectionState = .Connecting
    
    if !didRetainQ {
      core.module.retain()
      didRetainQ = true
    }
    
    dns.lookup(host, family: family) { error, address in
      self.lookupListeners.emit((error, address))
      
      if let error = error {
        self.connectionState = .Disconnected
        self.errorListeners.emit(error)
        return
      }
      
      guard var address = address else {
        self.connectionState = .Disconnected
        // TODO: emit some error
        return
      }
      
      // NOTE: The address does not have a correct port.
      //  TBD: Why does it even return a sockaddr in the
      //       first place?
      //       Well, for SRV etc it might make sense, but
      //       not for a plain lookup
      
      address.port = lPort

      if let cb = onConnect { _ = self.onConnect(handler: cb) }
      
      // looks like we can't modify Enums in Swift (i.e. patch in the port),
      // hence we need to pass it along for later patching
      self.connect(address)
    }
    
    return self
  }

  public func connect(_ address: sockaddr_any) {
    switch address {
      case .AF_INET (let addr): connect(addr)
      case .AF_INET6(let addr): connect(addr)
      case .AF_LOCAL(let addr): connect(addr)
    }
  }
  
  public var remoteAddress : sockaddr_any? = nil
  
  func _setupSocket(domain d: Int32, type: Int32 = xsys.SOCK_STREAM) -> Int32 {
    assert(io.fd == nil)
    
    let lfd   = socket(d, type, 0)
    let errno = xsys.errno
    log.debug("setup socket: \(lfd)")
    guard lfd != -1 else {
      log.debug("  failed: \(errno)")
      return errno
    }
    
    io.fd = FileDescriptor(lfd)
    log.debug("  FD: \(io.fd)")
    self.isSigPipeDisabled = true
    return 0
  }
  
  func _primaryConnect<AT: SocketAddress>(address a: AT) -> Int32 {
    let lfd = self.io.fd.fd
    
    var addr = a
    let len  = addr.len
    
    log.debug("connect socket to \(addr) " +
              "\(self.io.fd)  \(self.io.fd.isNonBlocking) ...")
    let rc = withUnsafePointer(to: &addr) { ptr -> Int32 in
      return ptr.withMemoryRebound(to: xsys_sockaddr.self, capacity: 1) {
        bptr in
        return xsys.connect(lfd, bptr, socklen_t(len)) //only returns block
      }
    }
    let perrno = xsys.errno
    
    guard rc == 0 else {
      let errstr : String = {
        guard let cstr = strerror(perrno) else { return "?" }
        return String(cString: cstr)
      }()
      self.log.debug("Could not connect \(self) to \(addr): " +
                     "\(perrno) \(errstr)")
      return perrno
    }
    
    // log.debug("  got: \(rc)")
    
    return 0
  }
  
  func _onDidConnect<AT: SocketAddress>(address a: AT) {
    // TODO: how to assign to remoteAddress
    log.debug("  connected: \(a)")
    
    connectionState = .Connected
    
    log.debug("did connect to \(a)")
    connectListeners.emit(self)
    
    // resume streams, start IO on socket
    resume()
    uncork()
  }
  
  public func connect<AT: SocketAddress>(_ address: AT) {
    let log = self.log
    log.enter(); defer { log.leave() }
    log.debug("   address: \(address)")
    
    guard connectionState != .Connected else {
      return // TODO: error handling somehow
    }
    
    connectionState = .Connecting
    
    // setup socket if necessary
    
    if io.fd == nil {
      let rc = _setupSocket(domain: AT.domain)
      guard rc == 0 else {
        self.connectionState = .Disconnected
        self.errorListeners.emit(SocketError(xsys.errno))
        return
      }
    }
    
    // connect, async in a connect Q (TODO: possible via GCD?)
    
    connectQueue.async {
      let perrno = self._primaryConnect(address: address)
      
      // check if connect failed
      
      guard perrno == 0 else {
        nextTick {
          log.debug("  failed, put back to disconnect.")
          self.connectionState = .Disconnected
          
          self.log.debug("Could not connect \(self) to \(address)") // TODO: log
          self.errorListeners.emit(SocketError(perrno, sockaddr_any(address)!))
        }
        return
      }
      
      // connect did not fail
      log.debug("  connected, tick ...")
      nextTick {
        self._onDidConnect(address: address)
      }
    }
  }
  

  // MARK: - Event Handlers
  
  var lookupListeners  = EventOnceListenerSet<(Error?, sockaddr_any?)>()
  var connectListeners = EventOnceListenerSet<Socket>()
  var timeoutListeners = EventListenerSet<Socket>(
                           queueLength: 1, coalesce: true)

  @discardableResult
  public func onLookup(handler cb: @escaping LookupCB) -> Self {
    lookupListeners.add(handler: cb)
    return self
  }
  @discardableResult
  public func onceLookup(handler cb: @escaping LookupCB) -> Self {
    lookupListeners.add(handler: cb, once: true)
    return self
  }
  
  @discardableResult
  public func onConnect(handler cb: @escaping ConnectCB) -> Self {
    connectListeners.add(handler: cb)
    return self
  }
  @discardableResult
  public func onceConnect(handler cb: @escaping ConnectCB) -> Self {
    connectListeners.add(handler: cb, once: true)
    return self
  }
  
  @discardableResult
  public func onTimeout(handler cb: @escaping TimeoutCB) -> Self {
    timeoutListeners.add(handler: cb)
    return self
  }
  @discardableResult
  public func onceTimeout(handler cb: @escaping TimeoutCB) -> Self {
    timeoutListeners.add(handler: cb, once: true)
    return self
  }
  
  
  // MARK: - Low Level Socket Stuff
  
  #if os(Linux)
  // No: SO_NOSIGPIPE on Linux, use MSG_NOSIGNAL in send()
  public var isSigPipeDisabled: Bool {
    get { return false }
    set { /* DANGER, DANGER, ALERT */ }
  }
  #else
  public var isSigPipeDisabled: Bool {
    get { return getSocket(option: SO_NOSIGPIPE) }
    set { _ = setSocket(option: SO_NOSIGPIPE, value: newValue) }
  }
  #endif
  
  public var keepAlive: Bool {
    get { return getSocket(option: SO_KEEPALIVE) }
    set { _ = setSocket(option: SO_KEEPALIVE, value: newValue) }
  }
  public var dontRoute: Bool {
    get { return getSocket(option: SO_DONTROUTE) }
    set { _ = setSocket(option: SO_DONTROUTE, value: newValue) }
  }
  public var socketDebug: Bool {
    get { return getSocket(option: SO_DEBUG) }
    set { _ = setSocket(option: SO_DEBUG, value: newValue) }
  }
  public var noDelay: Bool {
    get { return getTcp(option: TCP_NODELAY) }
    set { _ = setTcp(option: TCP_NODELAY, value: newValue) }
  }
  
  public var sendBufferSize: Int32 {
    get { return getSocket(option: SO_SNDBUF) ?? -42    }
    set { _ = setSocket(option: SO_SNDBUF, value: newValue) }
  }
  public var receiveBufferSize: Int32 {
    get { return getSocket(option: SO_RCVBUF) ?? -42    }
    set { _ = setSocket(option: SO_RCVBUF, value: newValue) }
  }
  public var socketError: Int32 {
    return getSocket(option: SO_ERROR) ?? -42
  }

  public func setSocket(option o: Int32, value: Int32) -> Bool {
    return set(protocol: xsys.SOL_SOCKET, option: o, value: value)
  }

  public func setTcp(option o: Int32, value: Int32) -> Bool {
    return set(protocol: Int32(xsys.IPPROTO_TCP), option: o, value: value)
  }

  public func set(protocol p: Int32, option o: Int32, value: Int32) -> Bool {
    guard io.fd.isValid else { return false }
    
    var buf = value
    let rc  = xsys.setsockopt(io.fd.fd, p, o,
                              &buf, socklen_t(MemoryLayout<Int32>.stride))
    
    if rc != 0 { // ps: Great Error Handling
      print("Could not set option \(o) on socket \(self)")
    }
    return rc == 0
  }

  // TBD: Can't overload optionals in a useful way?
  // func getSocket(option: option: Int32) -> Int32
  public func getSocket(option o: Int32) -> Int32? {
    return get(protocol: xsys.SOL_SOCKET, option: o)
  }

  public func getTcp(option o: Int32) -> Int32? {
    return get(protocol: Int32(xsys.IPPROTO_TCP), option: o)
  }

  public func get(protocol p: Int32, option o: Int32) -> Int32? {
    guard io.fd.isValid else { return nil }
    
    var buf    = Int32(0)
    var buflen = socklen_t(MemoryLayout<Int32>.stride)
    
    let rc = getsockopt(io.fd.fd, p, o, &buf, &buflen)
    guard rc == 0 else { // ps: Great Error Handling
      print("Could not get option \(o) from socket \(self)")
      return nil
    }
    return buf
  }
  
  public func setSocket(option o: Int32, value: Bool) -> Bool {
    return setSocket(option: o, value: value ? 1 : 0)
  }
  public func setTcp(option o: Int32, value: Bool) -> Bool {
    return setTcp(option: o, value: value ? 1 : 0)
  }
  public func getSocket(option o: Int32) -> Bool {
    let v: Int32? = getSocket(option: o)
    return v != nil ? (v! == 0 ? false : true) : false
  }
  public func getTcp(option o: Int32) -> Bool {
    let v: Int32? = getTcp(option: o)
    return v != nil ? (v! == 0 ? false : true) : false
  }
  
  
  // MARK: - Logging
  
  override open var logStateInfo : String {
    return "io=\(io) \(super.logStateInfo)"
  }
  
  
  // MARK: - Open State

  public var allowsHalfOpen : Bool {
    set { io.allowsHalfOpen = newValue }
    get { return io.allowsHalfOpen }
  }
}
