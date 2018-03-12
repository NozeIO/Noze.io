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
  
  var routes = ContiguousArray<Route>()
  
  func add(route e: Route) {
    routes.append(e)
  }
  
  
  // MARK: MiddlewareObject
  
  public func handle(request  req     : IncomingMessage,
                     response res     : ServerResponse,
                     next     endNext : @escaping Next)
  {
    guard !self.routes.isEmpty else { return endNext() }
    
    final class State {
      var stack    : ArraySlice<Route>
      let request  : IncomingMessage
      let response : ServerResponse
      var next     : Next?
      
      init(_ stack    : ArraySlice<Route>,
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
        if let route = stack.popFirst() {
          route.handle(request: request, response: response, next: self.step)
        }
        else {
          next?(); next = nil
        }
      }
    }
    
    let state = State(routes[routes.indices],
                      req, res, endNext)
    state.step()
  }
  
}
