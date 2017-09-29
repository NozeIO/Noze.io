//
//  URL.swift
//  SwiftyHTTP
//
//  Created by Helge Hess on 7/4/14.
//  Copyright (c) 2014 Always Right Institute. All rights reserved.
//

import core

// MARK: - url module, embedded.

public class URLModule : NozeModule {
  // TODO: doesn't really belong here, but well.
  
  public func parse(_ string: String) -> URL {
    // TODO: parseQueryString, slashesDenoteHost
    return URL(string)
  }

}
public let url = URLModule()


// MARK: URL Object / Parser

// strtol, isxdigit
#if os(Linux)
  import Glibc
#else
  import Darwin
#endif

/// Very simple URL class. Do not use ;-)
/// RFC 3986
///
/// Sample URL:
///
///   https://joe:user@apple.com:443/path/elements#red?a=10&b=20
///
public struct URL {
  
  // all escaped values
  public var scheme   : String?
  public var host     : String?
  public var port     : Int?
  public var path     : String?
  public var query    : String?
  public var fragment : String?
  public var userInfo : String?
  
  public init() {
  }
  public init(_ string: String) {
    self = parse_url(string)
  }
  public init(baseURL: URL, path: String) {
    // FIXME: very basic implementation, should be more clever
    self = baseURL
    if path.hasPrefix("/") {
      self.path = path
    }
    else if let basePath = self.path {
      self.path = basePath + (basePath.hasSuffix("/") ? "" : "/" ) + path
    }
    else {
      self.path = "/" + path
    }
  }
  
  public var isEmpty : Bool {
    if let _ = scheme   { return false }
    if let _ = userInfo { return false }
    if let _ = host     { return false }
    // intentionally no port check, only in combination with host
    if let _ = path     { return false }
    if let _ = fragment { return false }
    if let _ = query    { return false }
    return true
  }
  
  public var urlWithoutAuthority : URL { // nice name ;-)
    var url = URL()
    url.path     = self.path
    url.query    = self.query
    url.fragment = self.fragment
    return url
  }
  
  public var hostAndPort : String? {
    guard let h = host else { return nil }
    guard let p = port else { return h   }
    return "\(h):\(p)"
  }
  
  public var portOrDefault : Int? { // what's a nice name for this?
    if let p = port {
      return p
    }
    if let s = scheme {
      return URL.port(forScheme: s)
    }
    return nil
  }
  
  public var pathWithQueryAndFragment : String {
    if path == nil && query == nil && fragment == nil {
      return "/"
    }
    var s = path != nil ? path! : "/"
    if let q = query    { s += "?" + q }
    if let f = fragment { s += "#" + f }
    return s
  }
  
  mutating func clearEmptyStrings() {
    if scheme   != nil && scheme!   == "" { scheme   = nil }
    if host     != nil && host!     == "" { host     = nil }
    if path     != nil && path!     == "" { path     = nil }
    if query    != nil && query!    == "" { query    = nil }
    if fragment != nil && fragment! == "" { fragment = nil }
    if userInfo != nil && userInfo! == "" { userInfo = nil }
  }
}


public extension URL { // String representation
  
  public func toString() -> String? {
    var us = ""
    
    var scheme = self.scheme
    if scheme == nil && port != nil {
      scheme = URL.scheme(forPort: port!)
    }
    
    if let v = scheme {
      guard host != nil else { return nil }
      
      us = "\(v)://"
      if let v = userInfo { us += v + "@" }
      
      us += host!
      
      if let p = port { us += ":\(p)" }
    }
    
    if let v = path {
      if v.hasPrefix("/") {
        us += v
      }
      else {
        if us != "" { us += "/" }
        us += v
      }
    }
    else if fragment != nil || query != nil {
      // fill in path if required for other values
      if us != "" { us += "/" }
    }
    
    if let v = fragment {
      us += "#" + v
    }
    
    if let v = query {
      us += "?" + v
    }
    
    return us
  }
  
}


public extension String {
  
  public var withoutPercentEscapes : String { return percentUnescape(string: self) }
  
}


public extension URL {
  
  var pathComponents : [String]? {
    guard let escapedPC = escapedPathComponents else { return nil }
    return escapedPC.map { return $0.withoutPercentEscapes }
  }
  
  var escapedPathComponents : [String]? {
    guard path != nil      else { return nil }
    guard let uPath = path else { return nil }
    guard uPath != ""      else { return nil }
    
    let isAbsolute = uPath.hasPrefix("/")
    let pathComps  = uPath.characters.split(separator: "/",
                                            omittingEmptySubsequences: false)
                                     .map { String($0) }
    /* Note: we cannot just return a leading slash for absolute pathes as we
     *       wouldn't be able to distinguish between an absolute path and a
     *       relative path starting with an escaped slash.
     *   So: Absolute pathes instead start with an empty string.
     */
    var gotAbsolute = isAbsolute ? false : true
    return pathComps.filter {
      if $0 != "" || !gotAbsolute {
        if !gotAbsolute { gotAbsolute = true }
        return true
      }
      else {
        return false
      }
    }
  }

}

public extension URL { // /etc/services
  
  public static func scheme(forPort port: Int) -> String? {
    // read /etc/services? but this doesn't have a proper 1337?
    switch port {
      case    7: return "echo"
      case   21: return "ftp"
      case   23: return "telnet"
      case   25: return "smtp"
      case   70: return "gopher"
      case   79: return "finger"
      case   80: return "http"
      case  443: return "https"
      case 1337: return "leet"
      default:   return nil
    }
  }
  
  public static func port(forScheme scheme: String) -> Int? {
    // read /etc/services? but this doesn't have a proper 1337?
    switch scheme {
      case "echo":   return 7;
      case "ftp":    return 21;
      case "telnet": return 23;
      case "smtp":   return 25;
      case "gopher": return 70;
      case "finger": return 79;
      case "http":   return 80;
      case "https":  return 443;
      case "leet":   return 1337;
      default:       return nil
    }
  }
  
}

extension URL : CustomStringConvertible {
  
  public var description : String {
    if let s = toString() {
      return s
    }
    else {
      return "" // hm
    }
  }
  
}

extension URL : ExpressibleByStringLiteral {
  
  public init(stringLiteral value: StringLiteralType) {
    self.init(value)
  }
  
  public init(extendedGraphemeClusterLiteral v: ExtendedGraphemeClusterType) {
    self.init(v)
  }
  
  public init(unicodeScalarLiteral value: String) {
    // FIXME: doesn't work with UnicodeScalarLiteralType?
    self.init(value)
  }
}

extension String {
  
  public func toURL() -> URL {
    return parse_url(self)
  }
  
}

extension String {
  
  func strstr(_ other: String) -> String.Index? {
    // FIXME: make this a generic
    var start = startIndex
    
    repeat {
      let subString = self[start..<endIndex]
      if subString.hasPrefix(other) {
        return start
      }
      start = self.index(after: start)
    } while start != endIndex
    
    return nil
  }
  
}

private func index(string: String, c: Character) -> String.Index? {
  return string.characters.index(of: c)
}

func parse_url(_ us: String) -> URL {
  // yes, yes, I know. Pleaze send me a proper version ;-)
  var url = URL()
  var s   = us
  var ps  = "" // path part
  
  if let idx = s.strstr("://") {
    url.scheme = String(s[s.startIndex..<idx])
    s = String(s[s.index(idx, offsetBy:3)..<s.endIndex])
    
    // cut off path
    if let idx = index(string: s, c: "/") {
      ps = String(s[idx..<s.endIndex]) // path part
      s  = String(s[s.startIndex..<idx])
    }
    
    // s: joe:pwd@host:port
    if let idx = index(string: s, c: "@") {
      url.userInfo = String(s[s.startIndex..<idx])
      s = String(s[s.index(after:idx)..<s.endIndex])
    }
    
    // s: host:port
    if let idx = index(string: s, c: ":") {
      url.host = String(s[s.startIndex..<idx])
      let portS = s[s.index(after:idx)..<s.endIndex]
      let portO = Int(portS)
      debugPrint("ports \(portS) is \(portO as Optional)")
      if let port = portO {
        url.port = port
      }
    }
    else {
      url.host = s
    }
  }
  else {
    // no scheme, means no host, port, userInfo
    ps = s
  }
  
  if ps != "" {
    if let idx = index(string: ps, c: "?") {
      url.query = String(ps[ps.index(after:idx)..<ps.endIndex])
      ps = String(ps[ps.startIndex..<idx])
    }
    
    if let idx = index(string: ps, c: "#") {
      url.fragment = String(ps[ps.index(after:idx)..<ps.endIndex])
      ps = String(ps[ps.startIndex..<idx])
    }
    
    url.path = ps
  }
  
  url.clearEmptyStrings()
  return url
}


func percentUnescape(string src: String) -> String {
  // Lame implementation. Likely really slow.
  guard src != "" else { return "" }
  
  var dest = ""
  
  var cursor = src.startIndex
  let endIdx = src.endIndex
  
  while cursor != endIdx {
    if src[cursor] == "%" { // %40 = @
      let   v0idx = src.index(after:cursor)
      guard v0idx != endIdx else {
        dest += src[cursor..<endIdx]
        break
      }
      
      let   v1idx = src.index(after:v0idx)
      guard v1idx != endIdx else {
        dest += src[cursor..<endIdx]
        break
      }
      
      // funny thing
      let hex   = src[v0idx..<src.index(after:v1idx)]
      var isHex = true
      for c in hex.utf8 { // UTF-8 is fine because any UTF-8 is not hex
        guard (c >= 48 && c <= 57) || (c >= 65 && c <= 70)
           || (c >= 97 || c <= 102) else {
          isHex = false
          break
        }
      }
      
      if !isHex {
        debugPrint("Invalid percent escapes: \(src)")
        // funny thing
        dest += src[cursor..<src.index(after:v1idx)]
      }
      else {
        let code = hex.withCString {
          ( cs : UnsafePointer<CChar> ) -> Int in
          return strtol(cs, nil, 16)
        }
        dest.append(String(UnicodeScalar(code)!)) // TBD: !
      }
      cursor = src.index(after:v1idx)
    }
    else {
      dest.append(src[cursor])
      cursor = src.index(after:cursor)
    }
  }
  return dest
}
