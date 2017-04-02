//
//  Express.swift
//  Noze.io
//
//  Created by Helge Heß on 6/2/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import class http.IncomingMessage
import class http.ServerResponse
import process

open class Express: SettingsHolder, MountableMiddlewareObject, RouteKeeper,
                    CustomStringConvertible
{
  
  public let router   : Router
  public var settings = [ String : Any ]()
  
  public init(id: String? = nil, mount: String? = nil) {
    router = Router(id: id, pattern: mount)
    
    // defaults
    set("view engine", "mustache")
    engine("mustache", mustacheExpress)
    engine("html",     mustacheExpress)
  }
  
  // MARK: - MiddlewareObject
  
  open func handle(error        : Error?,
                   request  req : IncomingMessage,
                   response res : ServerResponse,
                   next         : @escaping Next) throws
  {
    let oldApp = req.app
    let oldReq = res.request
    req.extra[appKey] = self
    res.extra[appKey] = self
    res.extra[reqKey] = req
    
    try router.handle(error: error, request: req, response: res) { _ in
      // this is only called if no object in the sub-application called 'next'!
      req.extra[appKey] = oldApp
      res.extra[appKey] = oldApp
      res.extra[reqKey] = oldReq
      
      next() // continue
    }
  }
  
  open func clearAttachedState(request  req : IncomingMessage,
                               response res : ServerResponse)
  { // break cycles
    req.extra[appKey] = nil
    res.extra[appKey] = nil
    res.extra[reqKey] = nil
  }
  
  // MARK: - Route Keeper
  
  open func add(route e: Route) {
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
  
  
  // MARK: - Extension Point for Subclasses
  
  open func viewDirectory(for engine: String, response: ServerResponse)
            -> String
  {
    // Maybe that should be an array
    // This should allow 'views' as a relative path.
    // Also, in Apache it should be a configuration directive.
    let viewsPath = (get("views") as? String)
                 ?? process.env["EXPRESS_VIEWS"]
             //  ?? apacheRequest.pathRelativeToServerRoot(filename: "views")
                 ?? process.cwd()
    return viewsPath
  }

  
  // MARK: - Mounting
  
  final var mountListeners = [ ( Express ) -> Void ]()
  
  @discardableResult
  public func onMount(handler lcb: @escaping ( Express ) -> Void) -> Self {
    mountListeners.append(lcb)
    return self
  }
  
  public func emitOnMount(parent: Express) {
    for listener in mountListeners {
      listener(parent)
    }
  }
  
  /// One or more path patterns on which this instance was mounted as a sub
  /// application.
  open var mountPath : [ String ]?
  
  public func mount(at: String, parent: Express) {
    if mountPath == nil {
      mountPath = [ at ]
    }
    else {
      mountPath!.append(at)
    }
    emitOnMount(parent: parent)
  }
  
  
  // MARK: - Description
  
  open var description : String {
    var ms = "<\(type(of: self)):"
    
    if router.isEmpty {
      ms += " no-routes"
    }
    else if router.count == 1 {
      ms += " route"
    }
    else {
      ms += " #routes=\(router.count)"
    }
    
    if let mountPath = mountPath, !mountPath.isEmpty {
      if mountPath.count == 1 {
        ms += " mounted=\(mountPath[0])"
      }
      else {
        ms += " mounted=[\(mountPath.joined(separator: ","))]"
      }
    }
    
    if !engines.isEmpty {
      ms += " engines="
      ms += engines.keys.joined(separator: ",")
    }
    
    if !settings.isEmpty {
      for ( key, value ) in settings {
        ms += " '\(key)'='\(value)'"
      }
    }
    
    ms += ">"
    return ms
  }
}


private let appKey    = "io.noze.express.app"
private let reqKey    = "io.noze.express.request"
private let paramsKey = "io.noze.express.params"

public typealias ExpressEngine = (
    _ path:    String,
    _ options: Any?,
    _ done:    @escaping ( Any?... ) throws -> Void
  ) throws -> Void


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
#if swift(>=3.1)
    let mo     = self
#else
    let mo     = self as! MiddlewareObject // not sure why this is necessary
#endif
    let server = http.createServer(onRequest: mo.requestHandler)
    _ = server.listen(port, backlog: backlog, onListening: cb)
    return self
  }

}
