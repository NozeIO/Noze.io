//
//  Server.swift
//  Noze.io
//
//  Created by Helge Heß on 4/27/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import xsys
import core
import events
import class net.Server
import class net.Socket

public typealias ClientErrorEventCB = (( Error, Socket )) -> Void
public typealias RequestEventCB = (( IncomingMessage, ServerResponse )) -> Void

open class Server: net.Server {
  
  // TODO
  var httpConnections = [ HTTPConnection ]()
  
  public init(enableLogger: Bool = false) {
    super.init(allowHalfOpen  : true,
               pauseOnConnect : true,
               enableLogger   : enableLogger)
    
    _ = self.onConnection { [unowned self] sock in
      self._httpAccept(socket: sock)
    }
  }
  
  public func _httpAccept(socket s: Socket) {
    log.enter(); defer { log.leave() }
    
    let con = HTTPConnection(s, log)
    
    con.cbDone    = { [unowned self] c in
      self._connectionIsDone(c: c)
    }
    con.cbMessage = { [unowned self] c, msg in
      self._connection(c: c, parsedMessage: msg)
    }
    
    httpConnections.append(con)
    
    assert(self.pauseOnConnect)
    s.resume()
  }
  
  func _connectionIsDone(c con: HTTPConnection) {
    log.enter(); defer { log.leave() }
    
    let idx = httpConnections.index(where: { $0 === con }) // not Equatable
    assert(idx != nil)
    if let idx = idx {
      httpConnections.remove(at: idx)
    }
  }

  func _connection(c con: HTTPConnection, parsedMessage req: IncomingMessage) {
    let res = ServerResponse(con.stream!)
    requestListeners.emit( ( req, res ) )
  }


  // MARK: - Events
  // Inherited: close, connection, listening

  public var continueListeners    = EventListenerSet<Void>()
  public var clientErrorListeners = EventListenerSet<( Error, Socket )>()
  public var requestListeners     =
               EventListenerSet<( IncomingMessage, ServerResponse )>()
  
  @discardableResult
  public func onContinue(handler cb: @escaping ContinueEventCB) -> Self {
    continueListeners.add(handler: cb);             return self
  }
  @discardableResult
  public func onceContinue(handler cb: @escaping ContinueEventCB) -> Self {
    continueListeners.add(handler: cb, once: true); return self
  }
  
  @discardableResult
  public func onClientError(handler cb: @escaping ClientErrorEventCB) -> Self {
    clientErrorListeners.add(handler: cb);             return self
  }
  @discardableResult
  public func onceClientError(handler cb: @escaping ClientErrorEventCB) -> Self {
    clientErrorListeners.add(handler: cb, once: true); return self
  }
  
  @discardableResult
  public func onRequest(handler lcb: @escaping RequestEventCB) -> Self {
    requestListeners.add(handler: lcb);            return self
  }
  @discardableResult
  public func onceRequest(handler cb: @escaping RequestEventCB) -> Self {
    requestListeners.add(handler: cb, once: true); return self
  }
  
  // TODO: connect, upgrade

  // MARK: - Logging
  
  override open var logStateInfo : String {
    var s = ""
    s += " #http=\(httpConnections.count)"
    
    let su = super.logStateInfo
    if !su.isEmpty { s += " " + su }
    return s
  }
}
