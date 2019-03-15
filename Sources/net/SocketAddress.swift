//
//  SocketAddress.swift
//  SwiftSockets
//
//  Created by Helge Heß on 6/12/14.
//  Copyright (c) 2014-2017 Always Right Institute. All rights reserved.
//

#if os(Linux)
import Glibc
#else
import Darwin
#endif

import xsys
import fs

// import Darwin.POSIX.netinet.`in` - this doesn't seem to work
// import struct Darwin.POSIX.netinet.`in`.sockaddr_in - neither

public let INADDR_ANY = in_addr(s_addr: 0)

/**
 * in_addr represents an IPv4 address in Unix. We extend that a little bit
 * to increase it's usability :-)
 */
public extension in_addr {

  static func make() -> in_addr {
    /* Disable the `init` API to please the 4.2 compiler in 4.0 mode. Was
     * ambiguous anyways. The default `in_addr.init` setting everything to 0
     * should match INADDR_ANY.s_addr (AFAIK all zeros).
     */
    var addr = in_addr()
    addr.s_addr = INADDR_ANY.s_addr
    return addr
  }
  
  init(string: String?) {
    #if swift(>=4.1)
      self.init()
    #endif
    
    if let s = string {
      if s.isEmpty {
        s_addr = INADDR_ANY.s_addr
      }
      else {
        var buf = INADDR_ANY // Swift wants some initialization
        
        s.withCString { cs in _ = inet_pton(xsys.AF_INET, cs, &buf) }
        s_addr = buf.s_addr
      }
    }
    else {
      s_addr = INADDR_ANY.s_addr
    }
  }
  
  var asString: String {
    if self == INADDR_ANY {
      return "*.*.*.*"
    }
    
    let len   = Int(INET_ADDRSTRLEN) + 2
    var buf   = [CChar](repeating:0, count: len)
    
    var selfCopy = self // &self doesn't work, because it can be const?
    let cs = inet_ntop(xsys.AF_INET, &selfCopy, &buf, socklen_t(len))
    
    return cs != nil ? String(validatingUTF8: cs!)! : ""
  }
  
}

public func ==(lhs: in_addr, rhs: in_addr) -> Bool {
  return __uint32_t(lhs.s_addr) == __uint32_t(rhs.s_addr)
}

extension in_addr : Equatable, Hashable {
  
  #if swift(>=5)
    public func hash(into hasher: inout Hasher) {
      // Knuth?
      Int(UInt32(s_addr) * 2654435761 % (2^32)).hash(into: &hasher)
    }
  #else
    public var hashValue: Int {
      // Knuth?
      return Int(UInt32(s_addr) * 2654435761 % (2^32))
    }
  #endif
  
}

extension in_addr: ExpressibleByStringLiteral {
  // this allows you to do: let addr : in_addr = "192.168.0.1"

  public init(stringLiteral value: StringLiteralType) {
    self.init(string: value)
  }
  
  public init(extendedGraphemeClusterLiteral v: ExtendedGraphemeClusterType) {
    self.init(string: v)
  }
  
  public init(unicodeScalarLiteral value: String) {
    // FIXME: doesn't work with UnicodeScalarLiteralType?
    self.init(string: value)
  }
}

extension in_addr: CustomStringConvertible {
  
  public var description: String {
    return asString
  }
    
}

extension sockaddr_in: SocketAddress {
  
  public static var domain = xsys.AF_INET // if you make this a let, swiftc segfaults
  public static var size   = __uint8_t(MemoryLayout<sockaddr_in>.stride)
    // how to refer to self?
  
  public static func make() -> sockaddr_in {
    /* Disable this API to please the 4.2 compiler in 4.0 mode. Was ambiguous
     anyways. The default `sockaddr_ini.init` setting everything to 0 is not
     what we want here though!
     Copied the imp to the other ctors.
     */
    var addr = sockaddr_in()
    #if os(Linux) // no sin_len on Linux
    #else
      addr.sin_len    = sockaddr_in.size
    #endif
    addr.sin_family = sa_family_t(sockaddr_in.domain)
    addr.sin_port   = 0
    addr.sin_addr   = INADDR_ANY
    addr.sin_zero   = (0,0,0,0,0,0,0,0)
    return addr
  }
  
  public init(address: in_addr = INADDR_ANY, port: Int?) {
    self.init()
    
    #if os(Linux) // no sin_len on Linux
    #else
      sin_len    = sockaddr_in.size
    #endif
    sin_family = sa_family_t(sockaddr_in.domain)
    sin_zero   = (0,0,0,0,0,0,0,0)

    sin_port = port != nil ? in_port_t(htons(CUnsignedShort(port!))) : 0
    sin_addr = address
  }
  
  public init(address: String?, port: Int?) {
    let isWildcard = address != nil
      ? (address! == "*" || address! == "*.*.*.*")
      : true;
    let ipv4       = isWildcard ? INADDR_ANY : in_addr(string: address)
    self.init(address: ipv4, port: port)
  }
  
  public init(string: String?) {
    if let s = string {
      if s.isEmpty {
        self.init(address: INADDR_ANY, port: nil)
      }
      else {
        // split string at colon
        #if swift(>=3.2)
          let components =
                s.split(separator: ":", maxSplits: 1).map { String($0) }
        #else
          let components =
            s.characters.split(separator: ":", maxSplits: 1).map { String($0) }
        #endif
        if components.count == 2 {
          self.init(address: components[0], port: Int(components[1]))
        }
        else {
          assert(components.count == 1)
          let c1         = components[0]
          let isWildcard = (c1 == "*" || c1 == "*.*.*.*")
          if isWildcard {
            self.init(address: nil, port: nil)
          }
          else if let port = Int(c1) { // it's a number
            self.init(address: nil, port: port)
          }
          else { // it's a host
            self.init(address: c1, port: nil)
          }
        }
      }
    }
    else {
      self.init(address: INADDR_ANY, port: nil)
    }
  }
  
  public var port: Int { // should we make that optional and use wildcard as nil
    get {
      return Int(xsys.ntohs(sin_port))
    }
    set {
      sin_port = in_port_t(htons(CUnsignedShort(newValue)))
    }
  }
  
  public var address: in_addr {
    return sin_addr
  }
  
  public var isWildcardPort:    Bool { return sin_port == 0 }
  public var isWildcardAddress: Bool { return sin_addr == INADDR_ANY }
  
  public var len: __uint8_t { return sockaddr_in.size }

  public var asString: String {
    let addr = address.asString
    return isWildcardPort ? "\(addr):*" : "\(addr):\(port)"
  }
}

public func == (lhs: sockaddr_in, rhs: sockaddr_in) -> Bool {
  return (lhs.sin_addr.s_addr == rhs.sin_addr.s_addr)
      && (lhs.sin_port        == rhs.sin_port)
}

extension sockaddr_in: Equatable, Hashable {
  
  #if swift(>=5)
    public func hash(into hasher: inout Hasher) {
      (sin_addr.hashValue + sin_port.hashValue).hash(into: &hasher)
    }
  #else
    public var hashValue: Int {
      return sin_addr.hashValue + sin_port.hashValue
    }
  #endif
  
}

/**
 * This allows you to do: let addr : sockaddr_in = "192.168.0.1:80"
 *
 * Adding an IntLiteralConvertible seems a bit too weird and ambigiuous to me.
 *
 * Note: this does NOT work:
 *   let s : sockaddr_in = "*:\(port)"
 * it requires:
 *   StringInterpolationConvertible
 */
extension sockaddr_in: ExpressibleByStringLiteral {
  
  public init(stringLiteral value: String) {
    self.init(string: value)
  }
  
  public init(extendedGraphemeClusterLiteral v: ExtendedGraphemeClusterType) {
    self.init(string: v)
  }

  public init(unicodeScalarLiteral v: String) {
    // FIXME: doesn't work with UnicodeScalarLiteralType?
    self.init(string: v)
  }
}

extension sockaddr_in: CustomStringConvertible {
  
  public var description: String {
    return asString
  }
  
}

extension sockaddr_in6: SocketAddress {
  
  public static var domain = xsys.AF_INET6
  public static var size   = __uint8_t(MemoryLayout<sockaddr_in6>.stride)
  
  public static func make() -> sockaddr_in6 {
    // CAREFUL: was `init` before, but that can't be overridden anymore (4.2)
    var addr = sockaddr_in6()
#if os(Linux) // no sin_len on Linux
#else
    addr.sin6_len      = sockaddr_in6.size
#endif
    addr.sin6_family   = sa_family_t(sockaddr_in6.domain)
    addr.sin6_port     = 0
    addr.sin6_flowinfo = 0
    addr.sin6_addr     = in6addr_any
    addr.sin6_scope_id = 0
    return addr
  }
  
  public var port: Int {
    get {
      return Int(xsys.ntohs(sin6_port))
    }
    set {
      sin6_port = in_port_t(htons(CUnsignedShort(newValue)))
    }
  }

  public var address: in6_addr {
    return sin6_addr
  }
  
  public var isWildcardPort: Bool { return sin6_port == 0 }
  
  public var len: __uint8_t { return sockaddr_in6.size }
}

extension sockaddr_un: SocketAddress {
  // TBD: sockaddr_un would be interesting as the size of the structure is
  //      technically dynamic (embedded string)
  
  public static var domain = AF_UNIX
  public static var size = __uint8_t(MemoryLayout<sockaddr_un>.stride) //CAREFUL
  
  // DO NOT USE, this is actually non-sense
  public static func make() -> sockaddr_un {
    // CAREFUL: was `init` before, but that can't be overridden anymore (4.2)
    var addr = sockaddr_un()
#if os(Linux) // no sin_len on Linux
#else // os(Darwin)
    addr.sun_len    = sockaddr_un.size // CAREFUL - kinda wrong
#endif // os(Darwin)
    addr.sun_family = sa_family_t(sockaddr_un.domain)
    
    // Autsch!
#if os(Linux)
    addr.sun_path   = ( // 16 per block, 108 total
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0
    );
#else // os(Darwin)
    addr.sun_path   = ( // 16 per block, 104 total
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0,
      0, 0, 0, 0, 0, 0, 0, 0
    );
#endif
    return addr
  }
  
  public var len: __uint8_t {
    // FIXME?: this is wrong. It needs to be the base size + string length in
    //         the buffer
    return sockaddr_un.size
  }
}


/* DNS */

public extension addrinfo {
  
  static func make() -> addrinfo {
    var info = addrinfo()
    // This was plain `init` before. Careful w/ the default ctor!
    info.ai_flags     = 0 // AI_CANONNAME, AI_PASSIVE, AI_NUMERICHOST
    info.ai_family    = xsys.AF_UNSPEC // AF_INET or AF_INET6 or AF_UNSPEC
    info.ai_socktype  = xsys.SOCK_STREAM
    info.ai_protocol  = 0   // or IPPROTO_xxx for IPv4
    info.ai_addrlen   = 0   // length of ai_addr below
    info.ai_canonname = nil // UnsafePointer<Int8>
    info.ai_addr      = nil // UnsafePointer<sockaddr>
    info.ai_next      = nil // UnsafePointer<addrinfo>
    return info
  }
  
  init(flags: Int32, family: Int32 = xsys.AF_UNSPEC) {
    #if swift(>=4.1) // else: "Must use self.init because imported from C"
      self.init()
    #endif
    ai_socktype  = xsys.SOCK_STREAM
    ai_protocol  = 0   // or IPPROTO_xxx for IPv4
    ai_addrlen   = 0   // length of ai_addr below
    ai_canonname = nil // UnsafePointer<Int8>
    ai_addr      = nil // UnsafePointer<sockaddr>
    ai_next      = nil // UnsafePointer<addrinfo>
    ai_flags     = flags
    ai_family    = family // AF_INET or AF_INET6 or AF_UNSPEC
  }
  
  var hasNext : Bool {
    return ai_next != nil
  }
  var next : addrinfo? {
    return hasNext ? ai_next.pointee : nil
  }
  
  var canonicalName : String? {
    guard ai_canonname != nil && ai_canonname[0] != 0 else { return nil }
    
    return String(validatingUTF8: ai_canonname)
  }
  
  var hasAddress : Bool {
    return ai_addr != nil
  }
  
  var isIPv4 : Bool {
    return hasAddress &&
           (ai_addr.pointee.sa_family == sa_family_t(sockaddr_in.domain))
  }
  
  var addressIPv4 : sockaddr_in?  { return address() }
  /* Not working anymore in b4
  public var addressIPv6 : sockaddr_in6? { return address() }
   */
  
  func address<T: SocketAddress>() -> T? {
    guard ai_addr != nil else { return nil }
    guard ai_addr.pointee.sa_family == sa_family_t(T.domain) else { return nil }
    
    let airptr = UnsafeRawPointer(ai_addr)
    let aiptr  = airptr?.assumingMemoryBound(to: T.self) // cast
    return aiptr?.pointee // copies the address to the return value
  }
  
  var dynamicAddress : SocketAddress? {
    guard hasAddress else { return nil }

    let airptr = UnsafeRawPointer(ai_addr)
    
    if ai_addr.pointee.sa_family == sa_family_t(sockaddr_in.domain) {
      let aiptr  = airptr?.assumingMemoryBound(to: sockaddr_in.self) // cast
      return aiptr?.pointee // copies the address to the return value
    }
    
    if ai_addr.pointee.sa_family == sa_family_t(sockaddr_in6.domain) {
      let aiptr  = airptr?.assumingMemoryBound(to: sockaddr_in6.self) // cast
      return aiptr?.pointee // copies the address to the return value
    }
    
    return nil
  }
}

extension addrinfo : CustomStringConvertible {
  
  public var description : String {
    var s = "<addrinfo"
    
    if ai_flags != 0 {
      var fs = [String]()
      var f  = ai_flags
      if f & AI_CANONNAME != 0 {
        fs.append("canonname")
        f = f & ~AI_CANONNAME
      }
      if f & AI_PASSIVE != 0 {
        fs.append("passive")
        f = f & ~AI_PASSIVE
      }
      if f & AI_NUMERICHOST != 0 {
        fs.append("numerichost")
        f = f & ~AI_NUMERICHOST
      }
      if f != 0 {
        fs.append("flags[\(f)]")
      }
      let fss = fs.joined(separator: ",")
      s += " flags=" + fss
    }
    
    if ai_family != xsys.AF_UNSPEC { s += sa_family_t(ai_family).description }
    switch ai_socktype {
      case 0:           break
      case xsys.SOCK_STREAM: s += " stream"
      case xsys.SOCK_DGRAM:  s += " datagram"
      default:               s += " type[\(ai_socktype)]"
    }
    
    if let cn = canonicalName {
      s += " " + cn
    }
    
    if hasAddress {
      if let a = addressIPv4 {
        s += " \(a)"
      }
      /* Not working anymore in b4
      else if let a = addressIPv6 {
        s += " \(a)"
      }
      */
      else {
        s += " address[len=\(ai_addrlen)]"
      }
    }
    
    s += (ai_next != nil ? " +" : "")
    
    s += ">"
    return s
  }
}

extension addrinfo : Sequence {
  
  public func makeIterator() -> AnyIterator<addrinfo> {
    var cursor : addrinfo? = self
    
    return AnyIterator {
      guard let info = cursor else { return nil }
      cursor = info.next
      return info
    }
  }
}

public extension sa_family_t {
  // Swift 2 : CustomStringConvertible, already imp?!
  
  // TBD: does Swift 2 still pick this up?
  var description : String {
    switch Int32(self) {
      case xsys.AF_UNSPEC: return ""
      case xsys.AF_INET:   return "IPv4"
      case xsys.AF_INET6:  return "IPv6"
      case xsys.AF_LOCAL:  return "local"
      default:        return "family[\(self)]"
    }
  }
  
}
