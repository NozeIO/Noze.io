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

public class Server: net.Server {
  
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
    
#if swift(>=3.0) // #swift3-fd
    let idx = httpConnections.index(where: { $0 === con }) // not Equatable
#else
    let idx = httpConnections.indexOf { $0 === con } // not Equatable
#endif
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
  
#if swift(>=3.0) // #swift3-discardable-result This-is-so-depressing
  @discardableResult
  public func onContinue(handler cb: ContinueEventCB) -> Self {
    continueListeners.add(handler: cb);             return self
  }
  @discardableResult
  public func onceContinue(handler cb: ContinueEventCB) -> Self {
    continueListeners.add(handler: cb, once: true); return self
  }
  
  @discardableResult
  public func onClientError(handler cb: ClientErrorEventCB) -> Self {
    clientErrorListeners.add(handler: cb);             return self
  }
  @discardableResult
  public func onceClientError(handler cb: ClientErrorEventCB) -> Self {
    clientErrorListeners.add(handler: cb, once: true); return self
  }
  
  @discardableResult
  public func onRequest(handler lcb: RequestEventCB) -> Self {
    requestListeners.add(handler: lcb);            return self
  }
  @discardableResult
  public func onceRequest(handler cb: RequestEventCB) -> Self {
    requestListeners.add(handler: cb, once: true); return self
  }
#else // Swift 2.2
  public func onContinue(handler cb: ContinueEventCB) -> Self {
    continueListeners.add(handler: cb);             return self
  }
  public func onceContinue(handler cb: ContinueEventCB) -> Self {
    continueListeners.add(handler: cb, once: true); return self
  }
  
  public func onClientError(handler cb: ClientErrorEventCB) -> Self {
    clientErrorListeners.add(handler: cb);             return self
  }
  public func onceClientError(handler cb: ClientErrorEventCB) -> Self {
    clientErrorListeners.add(handler: cb, once: true); return self
  }
  
  public func onRequest(handler lcb: RequestEventCB) -> Self {
    requestListeners.add(handler: lcb);            return self
  }
  public func onceRequest(handler cb: RequestEventCB) -> Self {
    requestListeners.add(handler: cb, once: true); return self
  }
#endif // Swift 2.2
  
  
  // TODO: connect, upgrade


  // MARK: - Logging
  
  public override var logStateInfo : String {
    var s = ""
    s += " #http=\(httpConnections.count)"
    
    let su = super.logStateInfo
    if !su.isEmpty { s += " " + su }
    return s
  }
}
