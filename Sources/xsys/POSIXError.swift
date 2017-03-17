//
//  POSIXError.swift
//  Noze.io
//
//  Created by Helge Hess on 11/04/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

// TBD: This is a bit weird. Now even more due to POSIXErrorCode vs POSIXError.
//      But well :-)

#if os(Linux)
  import Glibc

  public let EWOULDBLOCK = Glibc.EWOULDBLOCK
  
  // This is lame, but how else? This does not work:
  //   case EAGAIN = Glibc.EAGAIN
  //
  // code from, hopefully they are kinda stable :-):
  //   /usr/include/asm-generic/errno-base.h
  
  public enum POSIXErrorCode : CInt {
    case EPERM   = 1
    case ENOENT  = 2
    case ESRCH   = 3
    case EINTR   = 4
    case EIO     = 5
    case ENXIO   = 6
    case E2BIG   = 7
    case ENOEXEC = 8
    case EBADF   = 9
    case ECHILD  = 10
    case EAGAIN  = 11 // == EWOULDBLOCK
    case ENOMEM  = 12
    case EACCES  = 13
    case EFAULT  = 14
    case ENOTBLK = 15
    case EBUSY   = 16
    case EEXIST  = 17
    case EXDEV   = 18
    case ENODEV  = 19
    case ENOTDIR = 20
    case EISDIR  = 21
    case EINVAL  = 22
    case ENFILE  = 23
    case EMFILE  = 24
    case ENOTTY  = 25
    case ETXTBSY = 26
    case EFBIG   = 27
    case ENOSPC  = 28
    case ESPIPE  = 29
    case EROFS   = 30
    case EMLINK  = 31
    case EPIPE   = 32
    case EDOM    = 33
    case ERANGE  = 34
    case EADDRINUSE  = 98

    // extra
    case ECANCELED = 125
  }

  extension POSIXErrorCode : Error {}

  public var errno : Int32 { return Glibc.errno }
  
#else // MacOS
  import Darwin

  public let EWOULDBLOCK = Darwin.EWOULDBLOCK

  public var errno : Int32 { return Darwin.errno }

  // this doesn't seem to work though
  import Foundation // this is for POSIXError : Error

  extension POSIXErrorCode : Error {}
#endif // MacOS
