//
//  Route.swift
//  Noze.io
//
//  Created by Helge Heß on 6/2/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import http
import connect

private let patternMarker : UInt8 = 58 // ':'

public struct Route: MiddlewareObject {
  
  public enum Pattern {
    case Root
    case Text    (String)
    case Variable(String)
    case Wilcard
  }
  
  let middlewares : [ Middleware ]
    // TBD: I think in Express.js, even the Route objects are middleware stack,
    //      and they allow you to hook up multiple objects to the same route
  
  let methods    : [ HTTPMethod ]?
  
  let urlPrefix  : String?
  let urlPattern : [ Pattern ]?
    // FIXME: all this works a little different in Express.js. Exact matches,
    //        non-path-component matches, regex support etc.
  
  init(urlPrefix: String?, method: HTTPMethod?, middleware: Middleware) {
    // FIXME: urlPrefix should be url or sth
    
    if let m = method { self.methods = [ m ] }
    else { self.methods = nil }
    
    self.middlewares = [ middleware ]
    
    if let prefixOrPattern = urlPrefix {
      if prefixOrPattern == "*" {
        self.urlPrefix  = nil
        self.urlPattern = nil
      }
      else if prefixOrPattern.utf8.index(of: patternMarker) == nil {
        self.urlPrefix  = urlPrefix
        self.urlPattern = nil
      }
      else {
        self.urlPrefix = nil
        self.urlPattern = parseURLPattern(url: prefixOrPattern)
      }
    }
    else {
      self.urlPrefix  = nil
      self.urlPattern = nil
    }
  }
  
  init(middleware: Middleware) {
    self.init(urlPrefix: nil, method: nil, middleware: middleware)
  }
  
  init(urlPrefix: String, middleware: Middleware) {
    self.init(urlPrefix: urlPrefix, method: nil, middleware: middleware)
  }
  
  
  // MARK: MiddlewareObject
  
  public func handle(request  req: IncomingMessage,
                     response res: ServerResponse,
                     next     cb:  Next)
  {
    guard matches(request: req) else { cb(); return }
    
    // push route state
    let oldParams = req.params
    let oldRoute  = req.route
    req.params = extractPatternVariables(request: req)
    req.route  = self
    let endNext : Next = { _ in
      req.params = oldParams
      req.route  = oldRoute
      cb()
    }
    
    // loop over route middleware
    let middlewares = self.middlewares
    var next : Next = { _ in } // cannot be let as it's self-referencing
    
    var i = 0 // capture position in matching-middleware array (shared)
    
    next = { args in
      
      // grab next item from middleware array
      let middleware = middlewares[i]
      i += 1 // this is shared between the blocks, move position in array
      
      // call the middleware - which gets the handle to go to the 'next'
      // middleware. the latter can be the 'endNext'
      middleware(req, res, (i == middlewares.count) ? endNext : next)
    }
    
    // inititate the traversal
    next()
  }
  
  
  // MARK: - Matching
  
  func matches(request req: IncomingMessage) -> Bool {
    if let methods = self.methods {
      let reqMethod = HTTPMethod(string: req.method)!
      guard methods.contains(reqMethod) else { return false }
    }
    
    // TODO: consider mounting!
    let matchPrefix = req.url
    
    if let p = urlPrefix {
      guard matchPrefix.hasPrefix(p) else { return false }
    }
    
    if let pat = urlPattern {
      var url = URL()
      url.path = matchPrefix
      let matchComponents = url.escapedPathComponents!
      
      guard matchComponents.count >= pat.count else { return false }

      for i in pat.indices {
        let patternComponent = pat[i]
        let matchComponent   = matchComponents[i]
        
        switch patternComponent {
          case .Root:        guard matchComponent == "" else { return false }
          case .Text(let s): guard matchComponent == s  else { return false }
          case .Wilcard:     continue
          case .Variable:    continue // take anything
        }
      }
    }
    
    return true
  }
  
  func extractPatternVariables(request rq: IncomingMessage)
       -> [ String : String ]
  {
    guard let pat = urlPattern else { return [:] }
    
    // TODO: consider mounting!
    let matchPrefix = rq.url
    
    var url = URL()
    url.path = matchPrefix
    let matchComponents = url.escapedPathComponents!
    
    var vars = [ String : String ]()
    
    for i in pat.indices {
      guard i < matchComponents.count else { break }
      
      let patternComponent = pat[i]
      let matchComponent   = matchComponents[i]
      
      switch patternComponent {
        case .Root, .Text, .Wilcard: continue
        case .Variable(let s):       vars[s] = matchComponent
      }
    }
    
    return vars
  }
  
}

func parseURLPattern(url s: String) -> [ Route.Pattern ] {
  var url = URL()
  url.path = s
  let comps = url.escapedPathComponents!
  
  var isFirst = false
  
  var pattern : [ Route.Pattern ] = []
  for c in comps {
    if isFirst {
      isFirst = false
      if c == "" { // root
        pattern.append(.Root)
        continue
      }
    }
    
    if c == "*" {
      pattern.append(.Wilcard)
      continue
    }
    
    if c.hasPrefix(":") {
#if swift(>=3.0)
      let vIdx = c.index(after: c.startIndex)
#else
      let vIdx = c.startIndex.successor()
#endif
      pattern.append(.Variable(c[vIdx..<c.endIndex]))
    }
    else {
      pattern.append(.Text(c))
    }
  }
  
  return pattern
}

private let routeKey = "io.noze.express.route"

public extension IncomingMessage {
  
  public var route : Route? {
    set { extra[routeKey] = newValue }
    get { return extra[routeKey] as? Route }
  }
  
}
