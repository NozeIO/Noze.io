//
//  process.swift
//  Noze.IO
//
//  Created by Helge Hess on 02/07/15.
//  Copyright © 2015 ZeeZide GmbH. All rights reserved.
//

#if os(Linux)
  import Glibc
#else
  import Darwin
  // importing this from xsys doesn't seem to work
  import Foundation // this is for POSIXError : ErrorProtocol
#endif

import xsys
import core
@_exported import events

public class NozeProcess : NozeModule {
  lazy var warningListeners =
    EventListenerSet<Warning>(queueLength: 0)
}
public let module = NozeProcess()


// TODO: process.mainModule


// TODO: Events
// - beforeExit, disconnect, exit, message, rejectionHandled,
//   uncaughtException, unhandledException

// MARK: - Process Info

public var pid : Int { return Int(getpid()) }

public let getegid = xsys.getegid
public let geteuid = xsys.geteuid
public let getgid  = xsys.getgid
public let getuid  = xsys.getuid
// TODO: getgroups, initgroups, setegid, seteuid, setgid, setgroups, setuid


// MARK: - Run Control

public let abort = xsys.abort


public var exitCode : Int {
  set { core.module.exitCode = newValue }
  get { return core.module.exitCode }
}
public func exit(code: Int? = nil) { core.module.exit(code) }


public func kill(pid: Int, _ signal: Int32 = xsys.SIGTERM) throws {
  let rc = xsys.kill(pid_t(pid), signal)
  guard rc == 0 else { throw POSIXError(rawValue: xsys.errno)! }
}
public func kill(pid: Int, _ signal: String) throws {
  var sc : Int32 = xsys.SIGTERM
  switch signal {
    case "SIGTERM": sc = xsys.SIGTERM
    case "SIGTERM": sc = xsys.SIGTERM
    case "SIGHUP":  sc = xsys.SIGHUP
    case "SIGINT":  sc = xsys.SIGINT
    case "SIGQUIT": sc = xsys.SIGQUIT
    case "SIGKILL": sc = xsys.SIGKILL
    case "SIGSTOP": sc = xsys.SIGSTOP
    default: emitWarning("unsupported signal: \(signal)")
  }
  try kill(pid, sc)
}
#if swift(>=3.0) // #swift3-1st-arg
public func kill(_ pid: Int, _ signal: Int32 = xsys.SIGTERM) throws {
  try kill(pid: pid, signal)
}
public func kill(_ pid: Int, _ signal: String) throws {
  try kill(pid: pid, signal)
}
#endif

public let nextTick = core.nextTick


// TODO: hrtime()
// TODO: memoryUsage()
// TODO: title { set get }
// TODO: uptime

#if os(Linux)
let platform = "linux"
#else
let platform = "darwin"
#endif

// TODO: arch
// TODO: release

#if os(Linux)
public let isRunningInXCode = false
#else
public var isRunningInXCode : Bool = {
  // TBD: is there a better way?
  let s = getenv("XPC_SERVICE_NAME")
  if s == nil { return false }
  return strstr(s, "Xcode") != nil
}()
#endif
