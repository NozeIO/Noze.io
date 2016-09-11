//
//  misc.swift
//  Noze.io
//
//  Created by Helge Heß on 4/27/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

// TODO: This file triggers a weird warning on Swift 3 2016-05-09:
//    <unknown>:0: warning: will never be executed
//    <unknown>:0: note: a call to a noreturn function

#if os(Linux)
  import Glibc
  
  public typealias size_t  = Glibc.size_t
  public let memcpy        = Glibc.memcpy
  public let strlen        = Glibc.strlen
  public let strchr        = Glibc.strchr

  // Looks like todays Linux Swift doesn't have arc4random either.
  // Emulate it (badly).
  public func arc4random_uniform(_ v : UInt32) -> UInt32 { // sigh
    return UInt32(rand() % Int32(v))
  }
  
  public let kill          = Glibc.kill
  public let chdir         = Glibc.chdir
  public let getcwd        = Glibc.getcwd
  public let getegid       = Glibc.getegid
  public let geteuid       = Glibc.geteuid
  public let getgid        = Glibc.getgid
  public let getuid        = Glibc.getuid
  public typealias pid_t   = Glibc.pid_t
  public let posix_spawn   = Glibc.posix_spawn
  public let posix_spawnp  = Glibc.posix_spawnp
  public let waitpid       = Glibc.waitpid
  
  public let getenv        = Glibc.getenv

  // signals
  public let SIGTERM       = Glibc.SIGTERM
  public let SIGHUP        = Glibc.SIGHUP
  public let SIGINT        = Glibc.SIGINT
  public let SIGQUIT       = Glibc.SIGQUIT
  public let SIGKILL       = Glibc.SIGKILL
  public let SIGSTOP       = Glibc.SIGSTOP
  
  // stdio
  public let STDIN_FILENO  = Glibc.STDIN_FILENO
  public let STDOUT_FILENO = Glibc.STDOUT_FILENO
  public let STDERR_FILENO = Glibc.STDERR_FILENO
  // public let NOFILE        = Glibc.NOFILE // missing on Linux
  public typealias mode_t  = Glibc.mode_t
  public let O_RDONLY      = Glibc.O_RDONLY
  
  // rlimit
  public typealias rlimit  = Glibc.rlimit
  public let getrlimit     = Glibc.getrlimit
  public let RLIMIT_NOFILE = Glibc.RLIMIT_NOFILE
  public let _SC_OPEN_MAX  = Glibc._SC_OPEN_MAX
  public let sysconf       = Glibc.sysconf
#else
  import Darwin

  public typealias size_t  = Darwin.size_t
  public let memcpy        = Darwin.memcpy
  public let strlen        = Darwin.strlen
  public let strchr        = Darwin.strchr
  public let arc4random_uniform = Darwin.arc4random_uniform
  
  public let kill          = Darwin.kill
  public let chdir         = Darwin.chdir
  public let getcwd        = Darwin.getcwd
  public let getegid       = Darwin.getegid
  public let geteuid       = Darwin.geteuid
  public let getgid        = Darwin.getgid
  public let getuid        = Darwin.getuid
  public typealias pid_t   = Darwin.pid_t
  public let posix_spawn   = Darwin.posix_spawn
  public let posix_spawnp  = Darwin.posix_spawnp
  public let waitpid       = Darwin.waitpid

  public let getenv        = Darwin.getenv
  
  // signals
  public let SIGTERM       = Darwin.SIGTERM
  public let SIGHUP        = Darwin.SIGHUP
  public let SIGINT        = Darwin.SIGINT
  public let SIGQUIT       = Darwin.SIGQUIT
  public let SIGKILL       = Darwin.SIGKILL
  public let SIGSTOP       = Darwin.SIGSTOP
  
  // stdio
  public let STDIN_FILENO  = Darwin.STDIN_FILENO
  public let STDOUT_FILENO = Darwin.STDOUT_FILENO
  public let STDERR_FILENO = Darwin.STDERR_FILENO
  public let NOFILE        = Darwin.NOFILE
  public typealias mode_t  = Darwin.mode_t
  public let O_RDONLY      = Darwin.O_RDONLY

  // rlimit
  public typealias rlimit  = Darwin.rlimit
  public let getrlimit     = Darwin.getrlimit
  public let RLIMIT_NOFILE = Darwin.RLIMIT_NOFILE
  public let _SC_OPEN_MAX  = Darwin._SC_OPEN_MAX
  public let sysconf       = Darwin.sysconf
#endif


// MARK: - noreturn funcs

// Those trigger a `warning: will never be executed` even though
// nothing is executed ;-)
//   public let abort         = Darwin.abort
//   public let exit          = Darwin.exit
#if os(Linux)
  public func abort()             -> Never { Glibc.abort()    }
  public func exit(_ code: Int32) -> Never { Glibc.exit(code) }
#else // Darwin
  public func abort()             -> Never { Darwin.abort()    }
  public func exit(_ code: Int32) -> Never { Darwin.exit(code) }
#endif // Darwin


// MARK: - process status macros

private func _WSTATUS (_ x: CInt) -> CInt  { return x & 0x7F         }
public  func WSTOPSIG (_ x: CInt) -> CInt  { return x >> 8           }
public  func WIFEXITED(_ x: CInt) -> Bool  { return _WSTATUS(x) == 0 }

public func WIFSTOPPED (_ x: CInt) -> Bool {
  return _WSTATUS(x) == 0x7F && WSTOPSIG(x) != 0x13
}

public func WIFSIGNALED (_ x: CInt) -> Bool {
  return _WSTATUS(x) != 0x7F && _WSTATUS(x) != 0
}

public func WEXITSTATUS(_ x: CInt) -> CInt { return (x >> 8) & 0xFF }
public func WTERMSIG   (_ x: CInt) -> CInt { return _WSTATUS(x) }
