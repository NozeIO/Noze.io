//
//  sockaddr_any.swift
//  Noze.io
//
//  Created by Helge Hess on 12/04/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if os(Linux)
  import Glibc
#else
  import Darwin
#endif

// Note: This cannot conform to SocketAddress because it doesn't have a static
//       domain.
public enum sockaddr_any {
  
  case AF_INET (sockaddr_in)
  case AF_INET6(sockaddr_in6)
  case AF_LOCAL(sockaddr_un)
  
  public var domain: Int32 {
    switch self {
      case .AF_INET:  return xsys.AF_INET
      case .AF_INET6: return xsys.AF_INET6
      case .AF_LOCAL: return xsys.AF_LOCAL
    }
  }
  
  public var len: __uint8_t {
#if os(Linux)
    switch self {
      case .AF_INET:  return __uint8_t(MemoryLayout<sockaddr_in>.stride)
      case .AF_INET6: return __uint8_t(MemoryLayout<sockaddr_in6>.stride)
      case .AF_LOCAL:
        // TODO: just abort for now?
        return __uint8_t(MemoryLayout<sockaddr_un>.stride) // TODO:wrong
    }
#else
    switch self {
      case .AF_INET (let addr): return addr.sin_len
      case .AF_INET6(let addr): return addr.sin6_len
      case .AF_LOCAL(let addr): return addr.sun_len
    }
#endif
  }
  
  public var port : Int? {
    get {
      switch self {
        case .AF_INET (let addr): return Int(ntohs(addr.sin_port))
        case .AF_INET6(let addr): return Int(ntohs(addr.sin6_port))
        case .AF_LOCAL:           return nil
      }
    }
    set {
      let lPort = port != nil ? htons(CUnsignedShort(newValue!)) : 0
      switch self {
        case .AF_INET (var addr): addr.sin_port  = lPort; self = .AF_INET(addr)
        case .AF_INET6(var addr): addr.sin6_port = lPort; self = .AF_INET6(addr)
        case .AF_LOCAL: break
      }
    }
  }
  
  
  // initializers (can this be done in a better way?)
  
  public init(_ address: sockaddr_in) {
    self = .AF_INET(address)
  }
  public init(_ address: sockaddr_in6) {
    self = .AF_INET6(address)
  }
  public init(_ address: sockaddr_un) {
    self = .AF_LOCAL(address)
  }
  
  public init?<T: SocketAddress>(_ address: T?) {
    guard let address = address else { return nil }
    
    // a little hacky ...
    switch T.domain {
      case xsys.AF_INET:
        let lAddress = unsafeBitCast(address, to: xsys_sockaddr_in.self)
        self = .AF_INET(lAddress)
      
      case xsys.AF_INET6:
        let lAddress = unsafeBitCast(address, to: xsys_sockaddr_in6.self)
        self = .AF_INET6(lAddress)
      
      case xsys.AF_LOCAL: // TODO: this is likely wrong too (variable length!)
        let lAddress = unsafeBitCast(address, to: xsys_sockaddr_un.self)
        self = .AF_LOCAL(lAddress)
      
      default:
        print("Unexpected socket address: \(address)")
        return nil
    }
  }
  
  
  // TODO: how to implement this? Is it even possible? (is the associated value
  //       memory-stable, or do we get a local copy?)
  // public var genericPointer : UnsafePointer<sockaddr> { .. }
}

extension sockaddr_any: CustomStringConvertible {
  
  public var description: String {
    // description is added to the addresses in SocketAddress.swift
    switch self {
      case .AF_INET (let addr): return "\(addr)"
      case .AF_INET6(let addr): return "\(addr)"
      case .AF_LOCAL(let addr): return "\(addr)"
    }
  }
  
}
