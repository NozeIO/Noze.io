//
//  socket.swift
//  Noze.io
//
//  Created by Helge Hess on 11/04/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if os(Linux)
  import Glibc
  
  public let socket       = Glibc.socket
  public let poll         = Glibc.poll
  public let bind         = Glibc.bind
  public let connect      = Glibc.connect
  public let listen       = Glibc.listen
  public let accept       = Glibc.accept
  public let shutdown     = Glibc.shutdown
  
  public let getsockname  = Glibc.getsockname
  public let getpeername  = Glibc.getpeername

  public let setsockopt   = Glibc.setsockopt

  public let getaddrinfo  = Glibc.getaddrinfo
  public let freeaddrinfo = Glibc.freeaddrinfo
  
  public let SOCK_STREAM  : Int32 = Int32(Glibc.SOCK_STREAM.rawValue)
  public let SOCK_DGRAM   : Int32 = Int32(Glibc.SOCK_DGRAM.rawValue)
  public let SHUT_RD      : Int32 = Int32(Glibc.SHUT_RD)
  public let SHUT_WR      : Int32 = Int32(Glibc.SHUT_WR)
  
  public typealias sa_family_t = Glibc.sa_family_t
  public let AF_UNSPEC    = Glibc.AF_UNSPEC
  public let AF_INET      = Glibc.AF_INET
  public let AF_INET6     = Glibc.AF_INET6
  public let AF_LOCAL     = Glibc.AF_LOCAL
  public let IPPROTO_TCP  = Glibc.IPPROTO_TCP
  public let PF_UNSPEC    = Glibc.PF_UNSPEC
  public let SOL_SOCKET   = Glibc.SOL_SOCKET
  public let SO_REUSEADDR = Glibc.SO_REUSEADDR
  public let SO_REUSEPORT = Glibc.SO_REUSEPORT

  // using an exact alias gives issues with sizeof()
  public typealias xsys_sockaddr     = Glibc.sockaddr
  public typealias xsys_sockaddr_in  = Glibc.sockaddr_in
  public typealias xsys_sockaddr_in6 = Glibc.sockaddr_in6
  public typealias xsys_sockaddr_un  = Glibc.sockaddr_un
  
  public typealias addrinfo          = Glibc.addrinfo
  public typealias socklen_t         = Glibc.socklen_t
#else
  import Darwin
  
  public let socket       = Darwin.socket
  public let poll         = Darwin.poll
  public let bind         = Darwin.bind
  public let connect      = Darwin.connect
  public let listen       = Darwin.listen
  public let accept       = Darwin.accept
  public let shutdown     = Darwin.shutdown
 
  public let getsockname  = Darwin.getsockname
  public let getpeername  = Darwin.getpeername
  
  public let setsockopt   = Darwin.setsockopt

  public let getaddrinfo  = Darwin.getaddrinfo
  public let freeaddrinfo = Darwin.freeaddrinfo

  public let SOCK_STREAM  = Darwin.SOCK_STREAM
  public let SOCK_DGRAM   = Darwin.SOCK_DGRAM
  public let SHUT_RD      = Darwin.SHUT_RD
  public let SHUT_WR      = Darwin.SHUT_WR
  
  public typealias sa_family_t = Darwin.sa_family_t
  public let AF_UNSPEC    = Darwin.AF_UNSPEC
  public let AF_INET      = Darwin.AF_INET
  public let AF_INET6     = Darwin.AF_INET6
  public let AF_LOCAL     = Darwin.AF_LOCAL
  public let IPPROTO_TCP  = Darwin.IPPROTO_TCP
  public let PF_UNSPEC    = Darwin.PF_UNSPEC
  public let SOL_SOCKET   = Darwin.SOL_SOCKET
  public let SO_REUSEADDR = Darwin.SO_REUSEADDR
  public let SO_REUSEPORT = Darwin.SO_REUSEPORT

  // using an exact alias gives issues with sizeof()
  public typealias xsys_sockaddr     = Darwin.sockaddr
  public typealias xsys_sockaddr_in  = Darwin.sockaddr_in
  public typealias xsys_sockaddr_in6 = Darwin.sockaddr_in6
  public typealias xsys_sockaddr_un  = Darwin.sockaddr_un
  
  public typealias addrinfo          = Darwin.addrinfo
  public typealias socklen_t         = Darwin.socklen_t
#endif
