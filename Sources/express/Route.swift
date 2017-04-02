//
//  Route.swift
//  Noze.io
//
//  Created by Helge Heß on 6/2/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

private let patternMarker : UInt8 = 58 // ':'

/**
 * A Route is a middleware which wraps another middleware and guards it by a
 * condition. For example:
 *
 *     app.get("/index") { req, res, next in ... }
 *
 * This creates a Route wrapping the closure given. It only runs the
 * embedded closure if:
 * - the method of the request is 'GET'
 * - the request path is equal to "/index"
 * In all other cases it immediately calls the `next` handler.
 *
 * ## Path Patterns
 *
 * The Route accepts a pattern for the path:
 * - the "*" string is considered a match-all.
 * - otherwise the string is split into path components (on '/')
 * - if it starts with a "/", the pattern will start with a Root symbol
 * - "*" (like in `/users/ * / view`) matches any component (spaces added)
 * - if the component starts with `:`, it is considered a variable.
 *   Example: `/users/:id/view`
 * - "text*", "*text*", "*text" creates hasPrefix/hasSuffix/contains patterns
 * - otherwise the text is matched AS IS
 *
 * Variables can be extracted using:
 *
 *     req.params[int: "id"]
 *
 * and companions.
 */
open class Route: MiddlewareObject, RouteKeeper, CustomStringConvertible {
  
  public enum MiddlewareHolder : MiddlewareObject {
    case object(MiddlewareObject)
    case middleware(Middleware)
    case errorMiddleware(ErrorMiddleware)
    
    public func handle(error    : Error?,
                       request  : IncomingMessage,
                       response : ServerResponse,
                       next     : @escaping Next) throws
    {
      switch self {
        case .object(let mw):
          try mw.handle(error: error, request: request, response: response,
                        next: next)
        
        case .middleware(let mw):
          guard error == nil else { return next() }
          try mw(request, response, next)
        
        case .errorMiddleware(let mw):
          guard let error = error else { return next() }
          try mw(error, request, response, next)
      }
    }
  }
  
  let debug      = false
  var id         : String?
  
  var middleware : [ MiddlewareHolder ]
  public var isEmpty : Bool { return middleware.isEmpty }
  public var count   : Int  { return middleware.count }
  
  let methods    : [ String ]? // FIXME: use an enum, strings are slow to match
  
  let urlPattern : [ RoutePattern ]?
    // FIXME: all this works a little different in Express.js. Exact matches,
    //        non-path-component matches, regex support etc.
  
 
  public init(id: String? = nil, pattern: String?, method: String?,
              middleware: [ MiddlewareHolder ])
  {
    self.id = id
    
    if let m = method { self.methods = [ m ] }
    else { self.methods = nil }
    
    self.middleware = middleware
    
    self.urlPattern = pattern != nil ? RoutePattern.parse(pattern!) : nil
      
    if debug {
      if self.middleware.isEmpty {
        console.log("\(logPrefix) setup route w/o middleware: \(self)")
      }
      else {
        console.log("\(logPrefix) setup route: \(self)")
      }
    }
  }
  
  public convenience init(id: String? = nil, pattern: String?, method: String?,
                          middleware: [ Middleware ])
  {
    self.init(id: id, pattern: pattern, method: method,
              middleware: middleware.map { .middleware($0) })
  }
  public convenience init(id: String? = nil, pattern: String?, method: String?,
                          middleware: [ ErrorMiddleware ])
  {
    self.init(id: id, pattern: pattern, method: method,
              middleware: middleware.map { .errorMiddleware($0) })
  }
  public convenience init(id: String? = nil, pattern: String?, method: String?,
                          middleware: [ MiddlewareObject ])
  {
    self.init(id: id, pattern: pattern, method: method,
              middleware: middleware.map { .object($0) })
  }

  public convenience init(id: String? = nil, pattern: String?) {
    self.init(id: id, pattern: pattern, method: nil,
              middleware: [] as [ MiddlewareHolder ])
  }
  
  
  // MARK: MiddlewareObject
  
  public func handle(error    errorIn    : Error?,
                     request  req        : IncomingMessage,
                     response res        : ServerResponse,
                     next     parentNext :  @escaping Next) throws
  {
    let debug = self.debug
    let ids   = logPrefix
    if debug { console.log("\(ids) > enter route:", self) }
    
    if let methods = self.methods {
      guard methods.contains(req.method) else {
        if debug {
          console.log("\(ids) route method does not match, next:", self)
        }
        return parentNext()
      }
    }
    
    let params    : [ String : String ]
    let matchPath : String?
    if let pattern = urlPattern {
      var newParams = req.params // TBD
      
      if let base = req.baseURL {
        let mountPath = req.url.substring(from: base.endIndex)
        let comps     = split(urlPath: mountPath)

        let mountMatchPath = RoutePattern.match(pattern   : pattern,
                                                against   : comps,
                                                variables : &newParams)
        guard let match = mountMatchPath else {
          if debug {
            console.log("\(ids) mount route path does not match, next:", self)
          }
          return parentNext()
        }
        
        matchPath = base + match
      }
      else {
        let comps = split(urlPath: req.url)
        
        guard let mp = RoutePattern.match(pattern   : pattern,
                                          against   : comps,
                                          variables : &newParams)
         else {
          if debug {
            console.log("\(ids) route path does not match, next:",
              self)
          }
          return parentNext()
         }
        matchPath = mp
      }
      
      if debug { console.log("\(ids)     path match:", matchPath) }
      
      params = newParams
    }
    else {
      matchPath = nil
      params    = req.params
    }
    
    guard !self.middleware.isEmpty else {
      if debug {
        console.log("\(ids) route has no middleware, next:", self)
      }
      return parentNext()
    }
    
    if debug { console.log("\(ids) * route matches") }
    
    
    // push route state
    let oldParams = req.params
    let oldRoute  = req.route
    let oldBase   = req.baseURL
    req.params  = params
    req.route   = self
    if let mp = matchPath {
      req.baseURL = mp
      if debug { console.log("\(ids)   push baseURL:", req.baseURL) }
    }

    var errorToThrow : Error? = nil
    var error        : Error? = errorIn
    
    let endNext : Next = { _ in
      req.params  = oldParams
      req.route   = oldRoute
      req.baseURL = oldBase
      errorToThrow = error
      
      // invoke the next middleware above us, if there was no error
      if let error = errorToThrow {
        // different way to pass back control
        if debug { console.log("\(ids)   end-next-error:", self, error) }
      }
      else {
        if debug { console.log("\(ids)   end-next:", self) }
        parentNext()
      }
    }
    
    
    // loop over route middleware
    let stack = self.middleware
    let count = stack.count // optimization ;->
    
    var i = 0 // capture position in matching-middleware array (shared)
    
    if debug { console.log("\(ids)   walk stack #\(count) of", self) }
    
    var next  : Next = { _ in } // cannot be let, it is self-referencing.
    next = { args in
      
      // grab next item from middleware array
      let middleware = stack[i]
      i += 1 // this is shared between the blocks, move position in array

      if debug {
        let errorInfo = error != nil ? " error=\(error!)" : " no-error"
        if count == 1 {
          console.log("\(ids)     run", middleware, "in", self, errorInfo)
        }
        else {
          console.log("\(ids)     run[\(i)/\(count)]", middleware,
                      "in", self, errorInfo)
        }
      }
      
      // call the middleware - which gets the handle to go to the 'next'
      // middleware. the latter can be the 'endNext'
      let isLast = i == count
      do {
        try middleware.handle(error: error,
                              request: req, response: res,
                              next: isLast ? endNext : next)
      }
      catch (let e) {
        if debug { console.log("\(ids)     catched:", e, "in", self) }
        
        error = e
          // The important part, from now own we have the error and will execute
          // error middleware. And if we leave this middleware (endNext), we
          // will throw, which is going to be catched by the outer scope.
          // BUT: Only if endNext was actually called. If an error middleware
          // did handle the error (and not call its next), the `errorToThrow`
          // is not set.
        
        // In this case we assume the middleware has NOT called next yet!
        // Note: next itself does NOT throw. It would track a handled error
        //       in its outer stack.
        // So we call next (or endNext) to continue ...
        if debug { console.log("\(ids)     call next after error") }
        if isLast { endNext() } else { next() }
      }
      if isLast {
        if debug { console.log("\(ids)     last mw of:", self) }
        //next = nil
      }
    }
    
    // Inititate the traversal. This walks the middleware array by recursively
    // calling the same (if the middleware choses to 'continue' by calling 
    // next).
    next()

    // In this case we didn't call `parentNext` in the endNext handler. Instead
    // we throw to bubble up the error. The outer Route will capture it, call
    // the next we got passed in and all will be good :-)
    // TBD: instead call parentNext(error)?
    if let e = errorToThrow {
      if debug { console.log("\(ids) rethrow:", e) }
      throw e
    }
  }
  
  
  // MARK: - Matching
  
  private func split(urlPath s: String) -> [ String ] {
    var url  = URL()
    url.path = s
    return url.escapedPathComponents!
  }
  
  
  // MARK: - RouteKeeper
  
  public func add(route e: Route) {
    middleware.append(.object(e))
  }
  
  
  // MARK: - Description
  
  lazy var logPrefix : String = {
    let logPrefixPad = 20
    let id = self.id ?? ObjectIdentifier(self).debugDescription
    let p  = id
    let ids = p.characters.count < logPrefixPad
      ? p + String(repeating: " ", count: logPrefixPad - p.characters.count)
      : p
    return "[\(ids)]:"
  }()
  
  public var description : String {
    var ms = "<Route:"
    
    if let id = id {
      ms += " [\(id)]"
    }
    
    var hadLimit = false
    if let methods = methods, !methods.isEmpty {
      ms += " "
      ms += methods.joined(separator: ",")
      hadLimit = true
    }
    if let pattern = urlPattern {
      ms += " "
      ms += pattern.map({$0.description}).joined(separator: "/")
      hadLimit = true
    }
    if !hadLimit { ms += " *" }
    
    if middleware.isEmpty {
      ms += " NO-middleware"
    }
    else if middleware.count > 1 {
      ms += " #middleware=\(middleware.count)"
    }
    else {
      switch middleware[0] {
        case .object    (let mw): ms += " \(mw)"
        case .middleware:         ms += " mw"
        case .errorMiddleware:    ms += " errmw"
      }
    }
    
    ms += ">"
    return ms
  }
  
}


// MARK: - Request Extension

private let routeKey   = "io.noze.express.route"
private let baseURLKey = "io.noze.express.baseurl"

public extension IncomingMessage {
  
  public var baseURL : String? {
    set { extra[baseURLKey] = newValue }
    get { return extra[baseURLKey] as? String }
  }
  
  public var route : Route? {
    set { extra[routeKey] = newValue }
    get { return extra[routeKey] as? Route }
  }
  
}
