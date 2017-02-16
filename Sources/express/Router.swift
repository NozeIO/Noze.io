//
//  Router.swift
//  Noze.io
//
//  Created by Helge Heß on 6/2/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import http
import connect

open class Router: MiddlewareObject {
  
  var routes = [Route]()
  
  func add(route e: Route) {
    routes.append(e)
  }
  
  
  // MARK: MiddlewareObject
  
  public func handle(request  req     : IncomingMessage,
                     response res     : ServerResponse,
                     next     endNext : @escaping Next)
  {
    guard !self.routes.isEmpty else { return endNext() }
    
    let routes = self.routes // make a copy to protect against modifications
    var next : Next? = { _ in } // cannot be let as it's self-referencing
    
    var i = 0 // capture position in matching-middleware array (shared)
    
    next = { args in
      
      // grab next item from matching middleware array
      let route      = routes[i]
      i += 1 // this is shared between the blocks, move position in array
      
      // call the middleware - which gets the handle to go to the 'next'
      // middleware. the latter can be the 'endNext'
      let isLast = i == routes.count
      route.handle(request: req, response: res, next: isLast ? endNext : next!)
      if isLast { next = nil }
    }
    
    // inititate the traversal
    next!()
  }
  
}
