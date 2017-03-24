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

  public let stat      = Glibc.stat
  public let lstat     = Glibc.lstat
  
  public let opendir   = Glibc.opendir
  public let closedir  = Glibc.closedir
  public let readdir   = Glibc.readdir
  public let readdir_r = Glibc.readdir_r

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

  public let stat      = Darwin.stat
  public let lstat     = Darwin.lstat
  
  public let opendir   = Darwin.opendir
  public let closedir  = Darwin.closedir
  public let readdir   = Darwin.readdir
  public let readdir_r = Darwin.readdir_r
  
  public typealias dirent      = Darwin.dirent
  public typealias stat_struct = Darwin.stat

  public let O_EVTONLY = Darwin.O_EVTONLY
  
#endif
