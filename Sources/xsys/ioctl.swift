//
//  ioctl.swift
//  Noze.io
//
//  Created by Helge Hess on 11/04/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if os(Linux)
  import Glibc
#else
  import Darwin
#endif
// MARK: - ioctl / ioccom stuff

#if os(Linux)

  public let FIONREAD : CUnsignedLong = CUnsignedLong(Glibc.FIONREAD)
  
  public let F_SETFD    = Glibc.F_SETFD
  public let FD_CLOEXEC = Glibc.FD_CLOEXEC

#else /* os(Darwin) */
  // TODO: still required?
  public let IOC_OUT  : CUnsignedLong = 0x40000000
  
  // hh: not sure this is producing the right value
  public let FIONREAD : CUnsignedLong =
    ( IOC_OUT
    | ((CUnsignedLong(4 /* Int32 */) & CUnsignedLong(IOCPARM_MASK)) << 16)
    | (102 /* 'f' */ << 8) | 127)

  public let F_SETFD    = Darwin.F_SETFD
  public let FD_CLOEXEC = Darwin.FD_CLOEXEC

#endif /* os(Darwin) */


// MARK: - Replicate C shims - BAD HACK
// TODO: not required anymore? varargs work on Linux?
//       but not in Xcode yet?

private let dlHandle = dlopen(nil, RTLD_NOW)
private let fnFcntl  = dlsym(dlHandle, "fcntl")
private let fnIoctl  = dlsym(dlHandle, "ioctl")

typealias fcntlViType  =
    @convention(c) (Int32, Int32, Int32) -> Int32
typealias ioctlVipType =
    @convention(c) (Int32, CUnsignedLong, UnsafeMutablePointer<Int32>) -> Int32

public func fcntlVi(_ fildes: Int32, _ cmd: Int32, _ val: Int32) -> Int32 {
  // this works on Linux x64 and OSX 10.11/Intel, but obviously this depends on
  // the ABI and is pure luck aka Wrong
  let fp = unsafeBitCast(fnFcntl, to: fcntlViType.self)
  return fp(fildes, cmd, val)
}
public func ioctlVip(_ fildes: Int32, _ cmd: CUnsignedLong,
                     _ val: UnsafeMutablePointer<Int32>) -> Int32
{
  // this works on Linux x64 and OSX 10.11/Intel, but obviously this depends on
  // the ABI and is pure luck aka Wrong
  let fp = unsafeBitCast(fnIoctl, to: ioctlVipType.self)
  return fp(fildes, cmd, val)
}
