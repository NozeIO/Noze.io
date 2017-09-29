//
//  fd.swift
//  Noze.io
//
//  Created by Helge Hess on 11/04/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

public typealias xsysOpenType = (UnsafePointer<CChar>, CInt) -> CInt

#if os(Linux)
  import Glibc
  
  public let open      : xsysOpenType = Glibc.open
  public let close     = Glibc.close
  public let read      = Glibc.read
  public let write     = Glibc.write
  public let recvfrom  = Glibc.recvfrom
  public let sendto    = Glibc.sendto
  
  public let access    = Glibc.access
  public let F_OK      = Glibc.F_OK
  public let R_OK      = Glibc.R_OK
  public let W_OK      = Glibc.W_OK
  public let X_OK      = Glibc.X_OK

  #if swift(>=3.2) // Swift 3.2/4 maps Glibc.stat to the struct
    public func stat(_ p: UnsafePointer<Int8>!,
                     _ r: UnsafeMutablePointer<stat>!) -> Int32
    {
      // FIXME: We cannot call `Darwin.stat` here since that resolves to the
      //        `struct stat` in Swift 3.2, not the `stat` function.
      //        A potential workaround is creating two separate files, one
      //        doing:
      //          import struct Darwin.stat
      //          typealias xsys_struct_stat = Darwin.stat
      //        and the other one doing
      //          import func Darwin.stat
      //          let xsys_func_stat = Darwin.stat
      //        ... but well.
      return Glibc.lstat(p, r)
    }
  #else
    public let stat    = Glibc.stat
  #endif
  public let lstat     = Glibc.lstat
  
  public let opendir   = Glibc.opendir
  public let closedir  = Glibc.closedir
  public let readdir   = Glibc.readdir

  public typealias dirent      = Glibc.dirent
  public typealias stat_struct = Glibc.stat

  // TODO: no O_EVTONLY on Linux?
  public let O_EVTONLY = Glibc.O_RDONLY

#else
  import Darwin
  
  public let open      : xsysOpenType = Darwin.open
  public let close     = Darwin.close
  public let read      = Darwin.read
  public let write     = Darwin.write
  public let recvfrom  = Darwin.recvfrom
  public let sendto    = Darwin.sendto
  
  public let access    = Darwin.access
  public let F_OK      = Darwin.F_OK
  public let R_OK      = Darwin.R_OK
  public let W_OK      = Darwin.W_OK
  public let X_OK      = Darwin.X_OK

  #if swift(>=3.2) // Swift 3.2 maps Darwin.stat to the struct
    public func stat(_ p: UnsafePointer<Int8>!,
                     _ r: UnsafeMutablePointer<stat>!) -> Int32
    {
      // FIXME: We cannot call `Darwin.stat` here since that resolves to the
      //        `struct stat` in Swift 3.2, not the `stat` function.
      //        A potential workaround is creating two separate files, one
      //        doing:
      //          import struct Darwin.stat
      //          typealias xsys_struct_stat = Darwin.stat
      //        and the other one doing
      //          import func Darwin.stat
      //          let xsys_func_stat = Darwin.stat
      //        ... but well.
      return Darwin.lstat(p, r)
    }
  #else
    public let stat = Darwin.stat
  #endif
  public let lstat     = Darwin.lstat
  
  public let opendir   = Darwin.opendir
  public let closedir  = Darwin.closedir
  public let readdir   = Darwin.readdir
  
  public typealias dirent      = Darwin.dirent
  public typealias stat_struct = Darwin.stat

  public let O_EVTONLY = Darwin.O_EVTONLY
  
#endif
