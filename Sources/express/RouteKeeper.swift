//
//  RouteKeeper.swift
//  Noze.io
//
//  Created by Helge Heß on 6/2/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import http
import connect

public protocol RouteKeeper {
  
  func add(route e: Route)
  
}

// MARK: - Add Middleware
  
public extension RouteKeeper {
  
  @discardableResult
  func use(_ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: nil, method: nil, middleware: [cb]))
    return self
  }
  
  @discardableResult
  func use(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: nil, middleware: [cb]))
    return self
  }
  
  @discardableResult
  func all(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: nil, middleware: [cb]))
    return self
  }
  
  @discardableResult
  func get(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: .GET, middleware: [cb]))
    return self
  }
  @discardableResult
  func post(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: .POST, middleware: [cb]))
    return self
  }
  @discardableResult
  func head(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: .HEAD, middleware: [cb]))
    return self
  }
  @discardableResult
  func put(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: .PUT, middleware: [cb]))
    return self
  }
  @discardableResult
  func del(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: .DELETE, middleware: [cb]))
    return self
  }
  @discardableResult
  func patch(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: .PATCH, middleware: [cb]))
    return self
  }
}

public extension RouteKeeper {
  // Directly attach MiddlewareObject's as Middleware. That is:
  //   let app   = express()
  //   let admin = express()
  //   app.use("/admin", admin)
  
  @discardableResult
  func use(_ middleware: MiddlewareObject) -> Self {
    return use(middleware.middleware)
  }
  
  @discardableResult
  func use(_ p: String, _ middleware: MiddlewareObject) -> Self {
    return use(p, middleware.middleware)
  }
  
  @discardableResult
  func all(_ p: String, _ middleware: MiddlewareObject) -> Self {
    return all(p, middleware.middleware)
  }
  
  @discardableResult
  func get(_ p: String, _ middleware: MiddlewareObject) -> Self {
    return get(p, middleware.middleware)
  }
  
  @discardableResult
  func post(_ p: String, _ middleware: MiddlewareObject) -> Self {
    return post(p, middleware.middleware)
  }
  
  @discardableResult
  func head(_ p: String, _ middleware: MiddlewareObject) -> Self {
    return head(p, middleware.middleware)
  }
  
  @discardableResult
  func put(_ p: String, _ middleware: MiddlewareObject) -> Self {
    return put(p, middleware.middleware)
  }
  
  @discardableResult
  func del(_ p: String, _ middleware: MiddlewareObject) -> Self {
    return del(p, middleware.middleware)
  }
  
  @discardableResult
  func patch(_ p: String, _ middleware: MiddlewareObject) -> Self {
    return patch(p, middleware.middleware)
  }
}
