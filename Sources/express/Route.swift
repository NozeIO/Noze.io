//
//  Route.swift
//  Noze.io
//
//  Created by Helge Heß on 6/2/16.
//  Copyright © 2016-2017 ZeeZide GmbH. All rights reserved.
//

import http
import connect

private let patternMarker : UInt8 = 58 // ':'
private let debugMatcher  = false

public struct Route: MiddlewareObject {
  
  public enum Pattern {
    case Root
    case Text    (String)
    case Variable(String)
    case Wildcard
    case Prefix  (String)
    case Suffix  (String)
    case Contains(String)
    
    func match(string s: String) -> Bool {
      switch self {
        case .Root:            return s == ""
        case .Text(let v):     return s == v
        case .Wildcard:        return true
        case .Variable:        return true // allow anything, like .Wildcard
        case .Prefix(let v):   return s.hasPrefix(v)
        case .Suffix(let v):   return s.hasSuffix(v)
        case .Contains(let v): return s.contains(v)
      }
    }
  }
  
  let middleware : ContiguousArray<Middleware>
    // TBD: I think in Express.js, even the Route objects are middleware stack,
    //      and they allow you to hook up multiple objects to the same route
  
  let methods    : ContiguousArray<HTTPMethod>?
  
  let urlPattern : [ Pattern ]?
    // FIXME: all this works a little different in Express.js. Exact matches,
    //        non-path-component matches, regex support etc.
  
  init(pattern    : String?,
       method     : HTTPMethod?,
       middleware : ContiguousArray<Middleware>)
  {
    // FIXME: urlPrefix should be url or sth
    
    if let m = method { self.methods = [ m ] }
    else { self.methods = nil }
    
    self.middleware = middleware
    
    self.urlPattern = pattern != nil ? parseURLPattern(url: pattern!) : nil
  }
  
  
  // MARK: MiddlewareObject
  
  public func handle(request  req: IncomingMessage,
                     response res: ServerResponse,
                     next     cb:  @escaping Next)
  {
    guard matches(request: req)    else { return cb() }
    guard !self.middleware.isEmpty else { return cb() }
    
    // push route state
    let oldParams = req.params
    let oldRoute  = req.route
    req.params = extractPatternVariables(request: req)
    req.route  = self
    let endNext : Next = { ( args: Any... ) in
      req.params = oldParams
      req.route  = oldRoute
      cb()
    }
    
    // loop over route middleware
    let stack = self.middleware
    var next  : Next? = { ( args: Any... ) in }
                  // cannot be let as it's self-referencing
    
    var i = 0 // capture position in matching-middleware array (shared)
    
    next = { ( args: Any... ) in
      
      // grab next item from middleware array
      let middleware = stack[i]
      i += 1 // this is shared between the blocks, move position in array
      
      // call the middleware - which gets the handle to go to the 'next'
      // middleware. the latter can be the 'endNext'
      let isLast = i == stack.count
      middleware(req, res, isLast ? endNext : next!)
      if isLast { next = nil }
    }
    
    // inititate the traversal
    next!()
  }
  
  
  // MARK: - Matching
  
  func matches(request req: IncomingMessage) -> Bool {
    
    // match methods
    
    if let methods = self.methods {
      let reqMethod = HTTPMethod(string: req.method)!
      guard methods.contains(reqMethod) else { return false }
    }
    
    // match URLs
    
    if var pattern = urlPattern {
      // TODO: consider mounting!
      
      let escapedPathComponents = split(urlPath: req.url)
      if debugMatcher {
        print("MATCH: \(req.url)\n  components: \(escapedPathComponents)\n" +
              "  against: \(pattern)")
      }
      
      // this is to support matching "/" against the "/*" ("", "*") pattern
      if escapedPathComponents.count + 1 == pattern.count {
        if case .Wildcard = pattern.last! {
          let endIdx = pattern.count - 1
          pattern = Array<Pattern>(pattern[0..<endIdx])
        }
      }
      
      guard escapedPathComponents.count >= pattern.count else { return false }
      
      var lastWasWildcard = false
      for i in pattern.indices {
        let patternComponent = pattern[i]
        let matchComponent   = escapedPathComponents[i]
        
        guard patternComponent.match(string: matchComponent) else {
          return false
        }
        
        if debugMatcher {
          print("  MATCHED[\(i)]: \(patternComponent) \(matchComponent)")
        }
        
        // Special case, last component is a wildcard. Like /* or /todos/*. In
        // this case we ignore extra URL path stuff.
        if case .Wildcard = patternComponent {
          let isLast = i + 1 == pattern.count
          if isLast { lastWasWildcard = true }
        }
      }
      
      if escapedPathComponents.count > pattern.count {
        if !lastWasWildcard { return false }
      }
    }
    
    return true
  }
  
  private func split(urlPath s: String) -> [ String ] {
    var url  = URL()
    url.path = s
    return url.escapedPathComponents!
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
        case .Variable(let s): vars[s] = matchComponent
        default:               continue
      }
    }
    
    return vars
  }
  
}

func parseURLPattern(url s: String) -> [ Route.Pattern ]? {
  if s == "*" { return nil } // match-all
  
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
      pattern.append(.Wildcard)
      continue
    }
    
    if c.hasPrefix(":") {
      let vIdx = c.index(after: c.startIndex)
      pattern.append(.Variable(String(c[vIdx..<c.endIndex])))
      continue
    }
    
    if c.hasPrefix("*") {
      let vIdx = c.index(after: c.startIndex)
      #if swift(>=3.2)
        let characters = c
      #else
        let characters = c.characters
      #endif
      if c == "**" {
        pattern.append(.Wildcard)
      }
      else if c.hasSuffix("*") && characters.count > 1 {
        let eIdx = c.index(before: c.endIndex)
        pattern.append(.Contains(String(c[vIdx..<eIdx])))
      }
      else {
        pattern.append(.Prefix(String(c[vIdx..<c.endIndex])))
      }
      continue
    }
    if c.hasSuffix("*") {
      let eIdx = c.index(before: c.endIndex)
      pattern.append(.Suffix(String(c[c.startIndex..<eIdx])))
      continue
    }

    pattern.append(.Text(c))
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
