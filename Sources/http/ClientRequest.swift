//
//  ClientRequest.swift
//  NozeIO
//
//  Created by Helge Heß on 4/27/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import core
import streams
import events
import net
import base64

public typealias AbortEventCB    = ( Void            ) -> Void
public typealias ContinueEventCB = ( Void            ) -> Void
public typealias ResponseEventCB = ( IncomingMessage ) -> Void
public typealias ExpectEventCB   = (( IncomingMessage, ServerResponse )) -> Void
public typealias ConnectEventCB  = (( ServerResponse, Socket, [UInt8] )) -> Void
public typealias SocketEventCB   = ( Socket ) -> Void


public class ClientRequest : HTTPMessageWrapper {
  
  public let method : HTTPMethod
  public let path   : String
  public let agent  : Agent

  var connection : DuplexByteStreamType? = nil
  
  public init(options opts: RequestOptions) {
    self.method = opts.method
    self.path   = opts.path
    self.agent  = opts.getAgent()
    
    super.init()
    
    // push headers into `ClientRequest`
    
    for ( key, value ) in opts.headers {
      setHeader(key, value)
    }
    
    if let data = opts.auth {
      let encoded = Base64.encode(data: Array(data.utf8))
      setHeader("Authorization", "Basic " + encoded)
    }
    
    _completeHeaders(options: opts)
    
    // TBD: core.module.retain()
    
    self.setup(options: opts)
  }
  
  
  // MARK: - Complete Headers
  
  func _completeHeaders(options opts: RequestOptions) {
    let hasHost = headers[ci: "Host"]           != nil
    let hasCLen = headers[ci: "Content-Length"] != nil
    let hasUA   = headers[ci: "User-Agent"]     != nil
    
    if !hasHost {
      if let s = opts.hostname {
        let defPort = URL.port(forScheme: opts.scheme)
        let p       = opts.port
        if defPort == p {
          setHeader("Host", s)
        }
        else {
          setHeader("Host", "\(s):\(p)")
        }
      }
    }
    
    if !hasCLen {
      // TODO
      if method == .GET || method == .HEAD {
        setHeader("Content-Length", 0)
      }
    }
    
    if !hasUA {
      setHeader("User-Agent", "Noze.io/0.42.1337")
    }
  }
  
  
  // MARK: - Socket & Parsing
  
  var parser  : IncomingMessageParser! = nil
  var message : IncomingMessage?       = nil
  
  func setup(options opts : RequestOptions) {
    assert(connection == nil, "Connection already set?")
    
    /* create connection (or get it from a pool) */
    
    if let cb = opts.createConnection {
      connection = cb(opts)
    }
    else {
      connection = agent.createConnection(options: opts)
    }

    // assign to wrapper
    stream = connection
    
    // We can close the write end of the socket when we are done, the server
    // will get the EOF and know that the HTTP/0.9 request is complete ;-)
    
    if let sock = connection as? Socket {
      sock.allowsHalfOpen = true
      
      // TODO: probably need a more generic version (onConnectionSet?)
      
      // this is probably too early
      self.socketListeners.emit(sock)
    }
    
    // Note: the connection is paused after creation. It gets an auto-resume
    //       once the first listener is added
  }
  
  func setupParser() {
    assert(connection != nil, "No use in setting up a parser w/o a connection")
    guard let c = connection else { return }
    
    // Oh well, all those inline callbacks are an'bad stylz
    let p = IncomingMessageParser()
    
    _ = p.onRequest { m, p, v, h in
      assert(false)
    }
    
    _ = p.onResponse { [unowned self] s, v, h in
      assert(self.message == nil, "already has a message assigned!")
      
      let msg = IncomingMessage(self.connection!)
      msg.statusCode  = s
      msg.httpVersion = v
      msg.headers     = h
      
      self.message = msg
      self.responseListeners.emit(msg)
    }
    
    _ = p.onDone { // response body has finished
      self.doneParsing()
    }
    
    _ = p.onData { data in
      assert(self.message != nil)
      self.message?.push(bucket: data)
    }
    
    self.parser = p
    
    // hook up to connection
    
    _ = c.onEnd {
      p.end() // EOF, parser can still emit events!!!
    }
    
    _ = c.onReadable {
      if let chunks = c.read(count: nil) {
        p.write(bucket: chunks)
      }
    }
  }
  
  func doneParsing() {
    self.message?.push(bucket: nil) // EOF - notifies the client that the read is done
    
    // TBD: self.message = nil
    self.parser = nil
    
    if let c = self.connection {
      // FIXME: unhook readable listener!
      
      // FIXME: This breaks sometimes because pause() stops event handlers!
      //        That is, a paused stream won't emit onReadable even if the
      //        buffer is still full.
      //        I think the root cause is that we directly hook up with the
      //        socket. What we want here is that the socket is corked/paused,
      //        but the Message still functions!
      /*
      c.pause() // this prevents the onEnd handler!
      c.cork()
      */
      agent.pool(connection: c)
      
      self.connection = nil
      self.stream = nil
    }
  }
  
  
  // MARK: - Write Method Head
  
  override func _primaryWriteIntro() {
    if parser == nil { setupParser() }
    _ = self.write("\(method.method) \(path) HTTP/1.1\r\n")
  }
  
  
  // MARK: - Client Events
  
  public var responseListeners = EventListenerSet<IncomingMessage>() // #onetime
  public var abortListeners    = EventListenerSet<Void>()
  public var continueListeners = EventListenerSet<Void>()
  public var expectListeners   =
                EventListenerSet<( IncomingMessage, ServerResponse )>()
  public var socketListeners   = EventListenerSet<Socket>() // #onetime
  
  public func onResponse(handler cb: ResponseEventCB) -> Self {
    responseListeners.add(handler: cb)
    return self
  }
  public func onceResponse(handler cb: ResponseEventCB) -> Self {
    responseListeners.add(handler: cb, once: true)
    return self
  }
  
  public func onAbort(handler cb: AbortEventCB) -> Self {
    abortListeners.add(handler: cb)
    return self
  }
  public func onceAbort(handler cb: AbortEventCB) -> Self {
    abortListeners.add(handler: cb, once: true)
    return self
  }
  
  public func onContinue(handler cb: ContinueEventCB) -> Self {
    continueListeners.add(handler: cb)
    return self
  }
  public func onceContinue(handler cb: ContinueEventCB) -> Self {
    continueListeners.add(handler: cb, once: true)
    return self
  }
  
  public func onCheckExpectation(handler cb: ExpectEventCB) -> Self {
    expectListeners.add(handler: cb)
    return self
  }
  public func onceCheckExpectation(handler cb: ExpectEventCB) -> Self {
    expectListeners.add(handler: cb, once: true)
    return self
  }
  
  public func onSocket(handler cb: SocketEventCB) -> Self {
    socketListeners.add(handler: cb)
    return self
  }
  public func onceSocket(handler cb: SocketEventCB) -> Self {
    socketListeners.add(handler: cb, once: true)
    return self
  }
  
  // TODO: connect, upgrade
}
