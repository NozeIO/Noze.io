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

#if swift(>=3.0) // #swift3-1st-arg #swift3-discardable-result
  
public extension RouteKeeper {
  
  @discardableResult public func use(_ cb: Middleware) -> Self {
    add(route: Route(pattern: nil, method: nil, middleware: [cb]))
    return self
  }
  
  @discardableResult public func use(_ p: String, _ cb: Middleware) -> Self {
    add(route: Route(pattern: p, method: nil, middleware: [cb]))
    return self
  }
  
  @discardableResult public func all(_ p: String, _ cb: Middleware) -> Self {
    add(route: Route(pattern: p, method: nil, middleware: [cb]))
    return self
  }
  
  @discardableResult public func get(_ p: String, _ cb: Middleware) -> Self {
    add(route: Route(pattern: p, method: .GET, middleware: [cb]))
    return self
  }
  @discardableResult public func post(_ p: String, _ cb: Middleware) -> Self {
    add(route: Route(pattern: p, method: .POST, middleware: [cb]))
    return self
  }
  @discardableResult public func head(_ p: String, _ cb: Middleware) -> Self {
    add(route: Route(pattern: p, method: .HEAD, middleware: [cb]))
    return self
  }
  @discardableResult public func put(_ p: String, _ cb: Middleware) -> Self {
    add(route: Route(pattern: p, method: .PUT, middleware: [cb]))
    return self
  }
  @discardableResult public func del(_ p: String, _ cb: Middleware) -> Self {
    add(route: Route(pattern: p, method: .DELETE, middleware: [cb]))
    return self
  }
  @discardableResult public func patch(_ p: String, _ cb: Middleware) -> Self {
    add(route: Route(pattern: p, method: .PATCH, middleware: [cb]))
    return self
  }
}
  
#else // Swift 2.2

public extension RouteKeeper {
  
  public func use(cb: Middleware) -> Self {
    add(route: Route(pattern: nil, method: nil, middleware: [cb]))
    return self
  }
  public func use(prefix: String, _ cb: Middleware) -> Self {
    add(route: Route(pattern: prefix, method: nil, middleware: [cb]))
    return self
  }
  
  public func all(prefix: String, _ cb: Middleware) -> Self {
    add(route: Route(pattern: prefix, method: nil, middleware: [cb]))
    return self
  }
  
  public func get(prefix: String, _ cb: Middleware) -> Self {
    add(route: Route(pattern: prefix, method: .GET, middleware: [cb]))
    return self
  }
  public func post(prefix: String, _ cb: Middleware) -> Self {
    add(route: Route(pattern: prefix, method: .POST, middleware: [cb]))
    return self
  }
  public func head(prefix: String, _ cb: Middleware) -> Self {
    add(route: Route(pattern: prefix, method: .HEAD, middleware: [cb]))
    return self
  }
  public func put(prefix: String, _ cb: Middleware) -> Self {
    add(route: Route(pattern: prefix, method: .PUT, middleware: [cb]))
    return self
  }
  public func del(prefix: String, _ cb: Middleware) -> Self {
    add(route: Route(pattern: prefix, method: .DELETE, middleware: [cb]))
    return self
  }
  public func patch(prefix: String, _ cb: Middleware) -> Self {
    add(route: Route(pattern: prefix, method: .PATCH, middleware: [cb]))
    return self
  }
}

#endif // Swift 2.2
