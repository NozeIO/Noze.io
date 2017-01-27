//
//  Express.swift
//  Noze.io
//
//  Created by Helge Heß on 6/2/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import net
import http
import connect

open class Express: SettingsHolder, MiddlewareObject, RouteKeeper {
  
  let router   = Router()
  var settings = [ String : Any ]()
  
  public init() {
    // defaults
    set("view engine", "mustache")
    engine("mustache", mustacheExpress)
    engine("html",     mustacheExpress)
  }
  
  // MARK: - MiddlewareObject
  
  public func handle(request  req : IncomingMessage,
                     response res : ServerResponse,
                     next     cb  : @escaping Next)
  {
    let oldApp = req.app
    let oldReq = res.request
    req.extra[appKey] = self
    res.extra[appKey] = self
    res.extra[reqKey] = req
    
    router.handle(request: req, response: res) { _ in
      req.extra[appKey] = oldApp
      res.extra[appKey] = oldApp
      res.extra[reqKey] = oldReq
      
      cb() // continue
    }
  }
  
  // MARK: - Route Keeper
  
  public func add(route e: Route) {
    router.add(route: e)
  }
  
  // MARK: - SettingsHolder
  
  public func set(_ key: String, _ value: Any?) {
    if let v = value {
      settings[key] = v
    }
    else {
      settings.removeValue(forKey: key)
    }
  }
  
  public func get(_ key: String) -> Any? {
    return settings[key]
  }
  
  // MARK: - Engines
  
  var engines = [ String : ExpressEngine]()
  
  public func engine(_ key: String, _ engine: @escaping ExpressEngine) {
    engines[key] = engine
  }
}

private let appKey    = "io.noze.express.app"
private let reqKey    = "io.noze.express.request"
private let paramsKey = "io.noze.express.params"

public typealias ExpressEngine = (
    _ path:    String,
    _ options: Any?,
    _ done:    @escaping ( Any?... ) -> Void
  ) -> Void


// MARK: - App access helper

public extension IncomingMessage {
  
  public var app : Express? { return extra[appKey] as? Express }
  
  public var params : [ String : String ] {
    set {
      extra[paramsKey] = newValue
    }
    get {
      // TODO: should be :Any
      return (extra[paramsKey] as? [ String : String ]) ?? [:]
    }
  }
  
}
public extension ServerResponse {
  
  public var app : Express? { return extra[appKey] as? Express }
  
  public var request : IncomingMessage? {
    return extra[reqKey] as? IncomingMessage
  }
  
}

public extension Dictionary where Key : ExpressibleByStringLiteral {
  public subscript(int key : Key) -> Int? {
    guard let v = self[key] else { return nil }
    if let i = (v as? Int) { return i }
    return Int("\(v)")
  }
}


// MARK: - Wrap Server

public extension Express {
  
  @discardableResult
  public func listen(_ port: Int? = nil, backlog: Int = 512,
                     onListening cb : (( net.Server ) -> Void)? = nil) -> Self
  {
    let mo     = self as! MiddlewareObject // not sure why this is necessary
    let server = http.createServer(onRequest: mo.requestHandler)
    _ = server.listen(port, backlog: backlog, onListening: cb)
    return self
  }

}
