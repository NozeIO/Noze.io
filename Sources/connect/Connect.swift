//
//  Connect.swift
//  Noze.io
//
//  Created by Helge Heß on 5/3/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import net
import http

/// TODO: document, what are the varargs in Next? See SR-6030 wrt varargs
public typealias Next = ( Any... ) -> Void

/// Supposed to call Next() when it is done.
public typealias Middleware =
                   ( IncomingMessage, ServerResponse, @escaping Next ) -> Void


public class Connect {
  
  struct MiddlewareEntry {
    
    let urlPrefix  : String?
    let middleware : Middleware
    
    init(middleware: @escaping Middleware) {
      self.middleware = middleware
      self.urlPrefix  = nil
    }
    
    init(urlPrefix: String, middleware: @escaping Middleware) {
      self.urlPrefix  = urlPrefix
      self.middleware = middleware
    }
    
    func matches(request rq: IncomingMessage) -> Bool {
      if urlPrefix != nil && !rq.url.isEmpty {
        guard rq.url.hasPrefix(urlPrefix!) else { return false }
      }
      
      return true
    }
    
  }
  
  var middlewarez = ContiguousArray<MiddlewareEntry>()
  
  
  // MARK: - use()
  
  @discardableResult
  public func use(_ cb: @escaping Middleware) -> Self {
    middlewarez.append(MiddlewareEntry(middleware: cb))
    return self
  }
  @discardableResult
  public func use(_ p: String, _ cb: @escaping Middleware) -> Self {
    middlewarez.append(MiddlewareEntry(urlPrefix: p, middleware: cb))
    return self
  }
  
  
  // MARK: - Closures to pass on
  
  public var handle : RequestEventCB {
    return { req, res in
      self.doRequest(req, res)
    }
  }
  public var middleware : Middleware {
    return { req, res, cb in
      self.doRequest(req, res) // THIS IS WRONG, need to call cb() only on last
      cb()
    }
  }
  
  
  // MARK: - run middleware
  
  func doRequest(_ request: IncomingMessage, _ response: ServerResponse) {
    final class State {
      var stack    : ArraySlice<Middleware>
      let request  : IncomingMessage
      let response : ServerResponse
      var next     : Next?
      
      init(_ stack    : ArraySlice<Middleware>,
           _ request  : IncomingMessage,
           _ response : ServerResponse,
           _ next     : @escaping Next)
      {
        self.stack    = stack
        self.request  = request
        self.response = response
        self.next     = next
      }
      
      func step(_ args : Any...) {
        if let middleware = stack.popFirst() {
          middleware(request, response, self.step)
        }
        else {
          next?(); next = nil
        }
      }
    }
    
    func finalHandler(_ args: Any...) {
      response.writeHead(404)
      response.end()
    }
    
    // first lookup all middleware matching the request (i.e. the URL prefix
    // matches)
    // TODO: would be nice to have this as a lazy filter.
    
    let middleware = middlewarez.filter { $0.matches(request: request) }
                                .map    { $0.middleware }
    let state = State(middleware[middleware.indices],
                      request, response, finalHandler)
    state.step()
  }
  
}


// MARK: - Wrap Server

public extension Connect {
  
  @discardableResult
  func listen(_ port: Int?, backlog: Int = 512,
              onListening cb : (( net.Server ) -> Void)? = nil) -> Self
  {
    let server = http.createServer(onRequest: self.handle)
    _ = server.listen(port, backlog: backlog, onListening: cb)
    return self
  }
  
}
