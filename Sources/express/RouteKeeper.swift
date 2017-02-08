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
  public func use(_ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: nil, method: nil, middleware: [cb]))
    return self
  }
  
  @discardableResult
  public func use(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: nil, middleware: [cb]))
    return self
  }
  
  @discardableResult
  public func all(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: nil, middleware: [cb]))
    return self
  }
  
  @discardableResult
  public func get(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: .GET, middleware: [cb]))
    return self
  }
  @discardableResult
  public func post(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: .POST, middleware: [cb]))
    return self
  }
  @discardableResult
  public func head(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: .HEAD, middleware: [cb]))
    return self
  }
  @discardableResult
  public func put(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: .PUT, middleware: [cb]))
    return self
  }
  @discardableResult
  public func del(_ p: String, _ cb: @escaping Middleware) -> Self {
    add(route: Route(pattern: p, method: .DELETE, middleware: [cb]))
    return self
  }
  @discardableResult
  public func patch(_ p: String, _ cb: @escaping Middleware) -> Self {
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
  public func use(_ middleware: MiddlewareObject) -> Self {
    return use(middleware.middleware)
  }
  
  @discardableResult
  public func use(_ p: String, _ middleware: MiddlewareObject) -> Self {
    return use(p, middleware.middleware)
  }
  
  @discardableResult
  public func all(_ p: String, _ middleware: MiddlewareObject) -> Self {
    return all(p, middleware.middleware)
  }
  
  @discardableResult
  public func get(_ p: String, _ middleware: MiddlewareObject) -> Self {
    return get(p, middleware.middleware)
  }
  
  @discardableResult
  public func post(_ p: String, _ middleware: MiddlewareObject) -> Self {
    return post(p, middleware.middleware)
  }
  
  @discardableResult
  public func head(_ p: String, _ middleware: MiddlewareObject) -> Self {
    return head(p, middleware.middleware)
  }
  
  @discardableResult
  public func put(_ p: String, _ middleware: MiddlewareObject) -> Self {
    return put(p, middleware.middleware)
  }
  
  @discardableResult
  public func del(_ p: String, _ middleware: MiddlewareObject) -> Self {
    return del(p, middleware.middleware)
  }
  
  @discardableResult
  public func patch(_ p: String, _ middleware: MiddlewareObject) -> Self {
    return patch(p, middleware.middleware)
  }
}
