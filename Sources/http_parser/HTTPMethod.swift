//
//  HTTPMethod.swift
//  HTTPParser
//
//  Created by Helge Heß on 6/19/14.
//  Copyright © 2014 Always Right Institute. All rights reserved.
//
/* Copyright Joyent, Inc. and other Node contributors. All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 */

#if os(Linux)
  import Glibc
#else
  import Darwin
#endif

public enum HTTPMethod : Int8 {
  case DELETE = 0
  
  case GET
  case HEAD
  case POST
  case PUT
  /* pathological */
  case CONNECT
  case OPTIONS
  case TRACE
  /* WebDAV */
  case COPY
  case LOCK
  case MKCOL
  case MOVE
  case PROPFIND
  case PROPPATCH
  case SEARCH
  case UNLOCK
  case BIND
  case REBIND
  case UNBIND
  case ACL
  /* subversion */
  case REPORT
  case MKACTIVITY
  case CHECKOUT
  case MERGE
  /* upnp */
  case MSEARCH
  case NOTIFY
  case SUBSCRIBE
  case UNSUBSCRIBE
  /* RFC-5789 */
  case PATCH
  case PURGE
  /* CalDAV */
  case MKCALENDAR
  /* RFC-2068, section 19.6.1.2 */ 
  case LINK
  case UNLINK
  

  public init?(string: String) {
    switch string {
      case "GET":         self = .GET
      case "HEAD":        self = .HEAD
      case "PUT":         self = .PUT
      case "DELETE":      self = .DELETE
      case "POST":        self = .POST
      case "OPTIONS":     self = .OPTIONS
      
      case "PROPFIND":    self = .PROPFIND
      case "PROPPATCH":   self = .PROPPATCH
      case "MKCOL":       self = .MKCOL
      
      case "REPORT":      self = .REPORT
      
      case "MKCALENDAR":  self = .MKCALENDAR
      
      case "CONNECT":     self = .CONNECT
      case "TRACE":       self = .TRACE
      
      case "COPY":        self = .COPY
      case "MOVE":        self = .MOVE
      case "LOCK":        self = .LOCK
      case "UNLOCK":      self = .UNLOCK
      
      case "SEARCH":      self = .SEARCH
      
      case "MKACTIVITY":  self = .MKACTIVITY
      case "CHECKOUT":    self = .CHECKOUT
      case "MERGE":       self = .MERGE
      
      case "M-SEARCH":    self = .MSEARCH
      case "NOTIFY":      self = .NOTIFY
      case "SUBSCRIBE":   self = .SUBSCRIBE
      case "UNSUBSCRIBE": self = .UNSUBSCRIBE
      
      case "PATCH":       self = .PATCH
      case "PURGE":       self = .PURGE
      
      case "ACL":         self = .ACL
      case "BIND":        self = .BIND
      case "UNBIND":      self = .UNBIND
      case "REBIND":      self = .REBIND
      
      case "LINK":        self = .LINK
      case "UNLINK":      self = .UNLINK
      
      default: return nil
    }
  }
  
}

public extension HTTPMethod {

  public var method: String {
    switch self {
      case .GET:        return "GET"
      case .HEAD:       return "HEAD"
      case .PUT:        return "PUT"
      case .DELETE:     return "DELETE"
      case .POST:       return "POST"
      case .OPTIONS:    return "OPTIONS"
        
      case .PROPFIND:   return "PROPFIND"
      case .PROPPATCH:  return "PROPPATCH"
      case .MKCOL:      return "MKCOL"
        
      case .REPORT:     return "REPORT"
        
      case .MKCALENDAR: return "MKCALENDAR"

      case .CONNECT:    return "CONNECT"
      case .TRACE:      return "TRACE"
      
      case .COPY:       return "COPY"
      case .MOVE:       return "MOVE"
      case .LOCK:       return "LOCK"
      case .UNLOCK:     return "UNLOCK"
      
      case .SEARCH:     return "SEARCH"
      
      case .MKACTIVITY: return "MKACTIVITY"
      case .CHECKOUT:   return "CHECKOUT"
      case .MERGE:      return "MERGE"
      
      case .MSEARCH:    return "M-SEARCH"
      case .NOTIFY:     return "NOTIFY"
      case .SUBSCRIBE:  return "SUBSCRIBE"
      case .UNSUBSCRIBE:return "UNSUBSCRIBE"

      case .PATCH:      return "PATCH"
      case .PURGE:      return "PURGE"
      
      case .ACL:        return "ACL"
      case .BIND:       return "BIND"
      case .UNBIND:     return "UNBIND"
      case .REBIND:     return "REBIND"
      
      case .LINK:       return "LINK"
      case .UNLINK:     return "UNLINK"
    }
  }
  
  public var isSafe: Bool? { // can't say for extension methods
    switch self {
      case .GET, .HEAD, .OPTIONS:
        return true
      case .PROPFIND, .REPORT:
        return true
      default:
        return false
    }
  }
  
  public var isIdempotent: Bool? { // can't say for extension methods
    switch self {
      case .GET, .HEAD, .PUT, .DELETE, .OPTIONS:
        return true
      case .PROPFIND, .REPORT, .PROPPATCH:
        return true
      case .MKCOL, .MKCALENDAR:
        return true
      default:
        return false
    }
  }
}

extension HTTPMethod : CustomStringConvertible {
  
  public var description: String {
    return method
  }
}

public extension HTTPMethod {
  
  // TBD: I don't know. Yes, this allocs, but I have no idea how to do this
  //      better in Swift. Sure, we could use a CChar array instead of a
  //      string, but that doesn't really help much.
  static let csGET         = "GET".makeCString()
  static let csHEAD        = "HEAD".makeCString()
  static let csPUT         = "PUT".makeCString()
  static let csDELETE      = "DELETE".makeCString()
  static let csPOST        = "POST".makeCString()
  static let csOPTIONS     = "OPTIONS".makeCString()
  
  static let csPROPFIND    = "PROPFIND".makeCString()
  static let csPROPPATCH   = "PROPPATCH".makeCString()
  static let csMKCOL       = "MKCOL".makeCString()
  
  static let csREPORT      = "REPORT".makeCString()
  
  static let csMKCALENDAR  = "MKCALENDAR".makeCString()
  
  static let csCONNECT     = "CONNECT".makeCString()
  static let csTRACE       = "TRACE".makeCString()
  
  static let csCOPY        = "COPY".makeCString()
  static let csMOVE        = "MOVE".makeCString()
  static let csLOCK        = "LOCK".makeCString()
  static let csUNLOCK      = "UNLOCK".makeCString()
  
  static let csSEARCH      = "SEARCH".makeCString()
  
  static let csMKACTIVITY  = "MKACTIVITY".makeCString()
  static let csCHECKOUT    = "CHECKOUT".makeCString()
  static let csMERGE       = "MERGE".makeCString()
  
  static let csMSEARCH     = "M-SEARCH".makeCString()
  static let csNOTIFY      = "NOTIFY".makeCString()
  static let csSUBSCRIBE   = "SUBSCRIBE".makeCString()
  static let csUNSUBSCRIBE = "UNSUBSCRIBE".makeCString()
  
  static let csPATCH       = "PATCH".makeCString()
  static let csPURGE       = "PURGE".makeCString()
  
  static let csACL         = "ACL".makeCString()
  static let csBIND        = "BIND".makeCString()
  static let csUNBIND      = "UNBIND".makeCString()
  static let csREBIND      = "REBIND".makeCString()
  
  static let csLINK        = "LINK".makeCString()
  static let csUNLINK      = "UNLINK".makeCString()
  
  public var csMethod: UnsafePointer<CChar> {
    switch self {
      case .GET:         return HTTPMethod.csGET
      case .HEAD:        return HTTPMethod.csHEAD
      case .PUT:         return HTTPMethod.csPUT
      case .DELETE:      return HTTPMethod.csDELETE
      case .POST:        return HTTPMethod.csPOST
      case .OPTIONS:     return HTTPMethod.csOPTIONS
        
      case .PROPFIND:    return HTTPMethod.csPROPFIND
      case .PROPPATCH:   return HTTPMethod.csPROPPATCH
      case .MKCOL:       return HTTPMethod.csMKCOL
        
      case .REPORT:      return HTTPMethod.csREPORT
        
      case .MKCALENDAR:  return HTTPMethod.csMKCALENDAR

      case .CONNECT:     return HTTPMethod.csCONNECT
      case .TRACE:       return HTTPMethod.csTRACE
      
      case .COPY:        return HTTPMethod.csCOPY
      case .MOVE:        return HTTPMethod.csMOVE
      case .LOCK:        return HTTPMethod.csLOCK
      case .UNLOCK:      return HTTPMethod.csUNLOCK
      
      case .SEARCH:      return HTTPMethod.csSEARCH
      
      case .MKACTIVITY:  return HTTPMethod.csMKACTIVITY
      case .CHECKOUT:    return HTTPMethod.csCHECKOUT
      case .MERGE:       return HTTPMethod.csMERGE
      
      case .MSEARCH:     return HTTPMethod.csMSEARCH
      case .NOTIFY:      return HTTPMethod.csNOTIFY
      case .SUBSCRIBE:   return HTTPMethod.csSUBSCRIBE
      case .UNSUBSCRIBE: return HTTPMethod.csUNSUBSCRIBE

      case .PATCH:       return HTTPMethod.csPATCH
      case .PURGE:       return HTTPMethod.csPURGE
      
      case .ACL:         return HTTPMethod.csACL
      case .BIND:        return HTTPMethod.csBIND
      case .UNBIND:      return HTTPMethod.csUNBIND
      case .REBIND:      return HTTPMethod.csREBIND
      
      case .LINK:        return HTTPMethod.csLINK
      case .UNLINK:      return HTTPMethod.csUNLINK
    }
  }
}

// original compat

public func http_method_str(method: HTTPMethod) -> String {
  return method.description
}
