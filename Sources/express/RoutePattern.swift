//
//  RoutePattern.swift
//  ExExpress
//
//  Created by Helge Hess on 31/03/17.
//  Copyright © 2017 ZeeZide GmbH. All rights reserved.
//

private let debugMatcher = false

enum RoutePattern : CustomStringConvertible {
  case Root             // /
  case Text    (String) // public (as in /public/abc)
  case Variable(String) // :id
  case Wildcard         // *
  case EOL              // $
  case Prefix  (String) // hello*
  case Suffix  (String) // *hello
  case Contains(String) // *hello*
  
  func match(string s: String) -> Bool {
    switch self {
      case .Root:            return s == ""
      case .Text(let v):     return s == v
      case .Wildcard:        return true
      case .Variable:        return true // allow anything, like .Wildcard
      case .Prefix(let v):   return s.hasPrefix(v)
      case .Suffix(let v):   return s.hasSuffix(v)
      case .Contains(let v): return s.contains(v)
      case .EOL:             return false // nothing should come anymore
    }
  }
  
  public var description : String {
    switch self {
      case .Root:             return "/"
      case .Text(let v):      return v
      case .Wildcard:         return "*"
      case .EOL:              return "$"
      case .Variable (let n): return ":\(n)"
      case .Prefix(let v):    return "\(v)*"
      case .Suffix(let v):    return "*\(v)"
      case .Contains(let v):  return "*\(v)*"
    }
  }

  /**
   * Creates a pattern for a given 'url' string.
   *
   * - the "*" string is considered a match-all.
   * - otherwise the string is split into path components (on '/')
   * - if it starts with a "/", the pattern will start with a Root symbol
   * - "*" (like in `/users/ * / view`) matches any component (spaces added)
   * - if the component starts with `:`, it is considered a variable.
   *   Example: `/users/:id/view`
   * - "text*", "*text*", "*text" creates hasPrefix/hasSuffix/contains patterns
   * - otherwise the text is matched AS IS
   */
  static func parse(_ s: String) -> [ RoutePattern ]? {
    if s == "*" { return nil } // match-all
    
    var url = URL()
    url.path = s
    let comps = url.escapedPathComponents!
    
    var isFirst = false
    
    var pattern : [ RoutePattern ] = []
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
        pattern.append(.Variable(c[vIdx..<c.endIndex]))
        continue
      }
      
      if c.hasPrefix("*") {
        let vIdx = c.index(after: c.startIndex)
        if c == "**" {
          pattern.append(.Wildcard)
        }
        else if c.hasSuffix("*") && c.characters.count > 1 {
          let eIdx = c.index(before: c.endIndex)
          pattern.append(.Contains(c[vIdx..<eIdx]))
        }
        else {
          pattern.append(.Prefix(c[vIdx..<c.endIndex]))
        }
        continue
      }
      if c.hasSuffix("*") {
        let eIdx = c.index(before: c.endIndex)
        pattern.append(.Suffix(c[c.startIndex..<eIdx]))
        continue
      }

      pattern.append(.Text(c))
    }
    
    return pattern
  }
  
  
  // MARK: - Pattern Matching
  
  static func match(pattern p: [ RoutePattern ],
                    against escapedPathComponents: [ String ],
                    variables: inout [ String : String ]) -> String?
  {
    // Note: Express does a prefix match, which is important for mounting.
    // TODO: Would be good to support a "$" pattern which guarantees an exact
    //       match.
    var pattern = p
    var matched = ""
    
    if debugMatcher {
      print("match: components: \(escapedPathComponents)\n" +
            "       against:    \(pattern)")
    }
    
    // this is to support matching "/" against the "/*" ("", "*") pattern
    // That is:
    //   /hello/abc  [pc = 2]
    // will match
    //   /hello*     [pc = 1]
    if escapedPathComponents.count + 1 == pattern.count {
      if case .Wildcard = pattern.last! {
        let endIdx = pattern.count - 1
        pattern = Array<RoutePattern>(pattern[0..<endIdx])
      }
    }
    
    // there have to be more or the same number of components in the path like
    // things to match in the pattern ...
    guard escapedPathComponents.count >= pattern.count else { return nil }
    
    // If the pattern ends in $
    if let lastComponent = pattern.last {
      if case .EOL = lastComponent {
        // is this correct?
        guard escapedPathComponents.count < pattern.count else { return nil }
      }
    }
    
    
    var lastWasWildcard = false
    var lastWasEOL      = false
    for i in pattern.indices {
      let patternComponent = pattern[i]
      let matchComponent   = escapedPathComponents[i] // TODO: unescape?
      
      guard patternComponent.match(string: matchComponent) else {
        if debugMatcher {
          print("  no match on: '\(matchComponent)' (\(patternComponent))")
        }
        return nil
      }
      
      if i == 0 && matchComponent.isEmpty {
        matched += "/"
      }
      else {
        if matched != "/" { matched += "/" }
        matched += matchComponent
      }
      
      if debugMatcher {
        print("  comp matched[\(i)]: \(patternComponent) " +
              "against '\(matchComponent)'")
      }

      if case .Variable(let s) = patternComponent {
        variables[s] = matchComponent // TODO: unescape
      }
      
      
      // Special case, last component is a wildcard. Like /* or /todos/*. In
      // this case we ignore extra URL path stuff.
      let isLast = i + 1 == pattern.count
      if isLast {
        if case .Wildcard = patternComponent {
          lastWasWildcard = true
        }
        if case .EOL = patternComponent {
          lastWasEOL = true
        }
      }
    }

    if debugMatcher {
      if lastWasWildcard || lastWasEOL {
        print("MATCH: last was WC \(lastWasWildcard) EOL \(lastWasEOL)")
      }
    }
    
    if escapedPathComponents.count > pattern.count {
      //if !lastWasWildcard { return nil }
      if lastWasEOL { return nil } // all should have been consumed
    }
    
    if debugMatcher { print("  match: '\(matched)'") }
    return matched
  }
}
