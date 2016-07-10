//
//  Connect.swift
//  Noze.io
//
//  Created by Helge Heß on 5/3/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import net
import http

/// TODO: document, what are the varargs in Next?
public typealias Next       = (String...) -> Void

/// Supposed to call Next() when it is done.
public typealias Middleware = (IncomingMessage, ServerResponse, Next) -> Void


public class Connect {
  
  struct MiddlewareEntry {
    
    let urlPrefix  : String?
    let middleware : Middleware
    
    init(middleware: Middleware) {
      self.middleware = middleware
      self.urlPrefix  = nil
    }
    
    init(urlPrefix: String, middleware: Middleware) {
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
  
  var middlewarez = [MiddlewareEntry]()
  
  
  // MARK: - use()
  
#if swift(>=3.0) // #swift3-1st-arg #swift3-discardable-result
  @discardableResult public func use(_ cb: Middleware) -> Self {
    middlewarez.append(MiddlewareEntry(middleware: cb))
    return self
  }
  @discardableResult public func use(_ p: String, _ cb: Middleware) -> Self {
    middlewarez.append(MiddlewareEntry(urlPrefix: p, middleware: cb))
    return self
  }
#else // Swift 2.2
  public func use(cb: Middleware) -> Self {
    middlewarez.append(MiddlewareEntry(middleware: cb))
    return self
  }
  public func use(prefix: String, _ cb: Middleware) -> Self {
    middlewarez.append(MiddlewareEntry(urlPrefix: prefix, middleware: cb))
    return self
  }
#endif // Swift 2.2
  
  
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
  
  func doRequest(request: IncomingMessage, _ response: ServerResponse) {
    // first lookup all middleware matching the request (i.e. the URL prefix
    // matches)
    // TODO: would be nice to have this as a lazy filter.
    let matchingMiddleware = middlewarez.filter { $0.matches(request: request) }
    
    let endNext : Next = { _ in
      // essentially the final handler
      response.writeHead(404)
      response.end()
    }
    var next    : Next = { _ in } // cannot be let as it's self-referencing
    
    var i = 0 // capture position in matching-middleware array (shared)
    next = {
      args in
      
      // grab next item from matching middleware array
      let middleware = matchingMiddleware[i].middleware
      i += 1 // this is shared between the blocks, move position in array
      
      // call the middleware - which gets the handle to go to the 'next'
      // middleware. the latter can be the 'endNext' which won't do anything.
      middleware(request, response,
                 (i == matchingMiddleware.count) ? endNext : next)
    }
    
    next()
  }
  
}


// MARK: - Wrap Server

public extension Connect {
  
  public func listen(port: Int? = nil, backlog: Int = 5,
                     onListening cb : (( net.Server ) -> Void)? = nil) -> Self
  {
    let server = http.createServer(onRequest: self.handle)
    _ = server.listen(port, backlog: backlog, onListening: cb)
    return self
  }
  

#if swift(>=3.0) // #swift3-1st-arg #swift3-discardable-result
  @discardableResult
  public func listen(_ port: Int?, backlog: Int = 5,
                     onListening cb : (( net.Server ) -> Void)? = nil) -> Self
  {
    return listen(port: port, backlog: backlog, onListening: cb)
  }

  func doRequest(_ request: IncomingMessage, _ response: ServerResponse) {
    doRequest(request: request, response)
  }
#endif
  
}
