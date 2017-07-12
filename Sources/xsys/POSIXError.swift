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
    case EDEADLK = 35 // == EDEADLOCK
    case ENAMETOOLONG = 36
    case ENOLCK  = 37
    case ENOSYS  = 38
    case ENOTEMPTY = 39
    case ELOOP   = 40
    case ENOMSG  = 42
    case EIDRM   = 43
    case ECHRNG  = 44
    case EL2NSYNC = 45
    case EL3HLT  = 46
    case EL3RST  = 47
    case ELNRNG  = 48
    case EUNATCH = 49
    case ENOCSI  = 50
    case EL2HLT  = 51
    case EBADE   = 52
    case EBADR   = 53
    case EXFULL  = 54
    case ENOANO  = 55
    case EBADRQC = 56
    case EBADSLT = 57
    case EBFONT  = 59
    case ENOSTR  = 60
    case ENODATA = 61
    case ETIME   = 62
    case ENOSR   = 63
    case ENONET  = 64
    case ENOPKG  = 65
    case EREMOTE = 66
    case ENOLINK = 67
    case EADV    = 68
    case ESRMNT  = 69
    case ECOMM   = 70
    case EPROTO  = 71
    case EMULTIHOP = 72
    case EDOTDOT = 73
    case EBADMSG = 74
    case EOVERFLOW = 75
    case ENOTUNIQ = 76
    case EBADFD  = 77
    case EREMCHG = 78
    case ELIBACC = 79
    case ELIBBAD = 80
    case ELIBSCN = 81
    case ELIBMAX = 82
    case ELIBEXEC = 83
    case EILSEQ  = 84
    case ERESTART = 85
    case ESTRPIPE = 86
    case EUSERS  = 87
    case ENOTSOCK = 88
    case EDESTADDRREQ = 89
    case EMSGSIZE = 90
    case EPROTOTYPE = 91
    case ENOPROTOOPT = 92
    case EPROTONOSUPPORT = 93
    case ESOCKTNOSUPPORT = 94
    case ENOTSUP = 95 // == EOPNOTSUPP
    case EPFNOSUPPORT = 96
    case EAFNOSUPPORT = 97
    case EADDRINUSE = 98
    case EADDRNOTAVAIL = 99
    case ENETDOWN = 100
    case ENETUNREACH = 101
    case ENETRESET = 102
    case ECONNABORTED = 103
    case ECONNRESET = 104
    case ENOBUFS = 105
    case EISCONN = 106
    case ENOTCONN = 107
    case ESHUTDOWN = 108
    case ETOOMANYREFS = 109
    case ETIMEDOUT = 110
    case ECONNREFUSED = 111
    case EHOSTDOWN = 112
    case EHOSTUNREACH = 113
    case EALREADY = 114
    case EINPROGRESS = 115
    case ESTALE  = 116
    case EUCLEAN = 117
    case ENOTNAM = 118
    case ENAVAIL = 119
    case EISNAM  = 120
    case EREMOTEIO = 121
    case EDQUOT  = 122
    case ENOMEDIUM = 123
    case EMEDIUMTYPE = 124
    case ECANCELED = 125
    case ENOKEY  = 126
    case EKEYEXPIRED = 127
    case EKEYREVOKED = 128
    case EKEYREJECTED = 129
    case EOWNERDEAD = 130
    case ENOTRECOVERABLE = 131
    case ERFKILL = 132
    case EHWPOISON = 133
  }

  extension POSIXErrorCode : Error {}

  public var errno : Int32 {
      get { return Glibc.errno }
      set { Glibc.errno = newValue }
  }
  
#else // MacOS
  import Darwin

  public let EWOULDBLOCK = Darwin.EWOULDBLOCK

  public var errno : Int32 {
      get { return Darwin.errno }
      set { Darwin.errno = newValue }
  }

  // this doesn't seem to work though
  import Foundation // this is for POSIXError : Error

  extension POSIXErrorCode : Error {}
#endif // MacOS
