//
//  Spawn.swift
//  Noze.io
//
//  Created by Helge Heß on 5/1/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import xsys
import core
import streams
import fs
import process

#if os(Linux)
  import Glibc
#else
  // importing this from xsys doesn't seem to work
  import Foundation // this is for POSIXError : Error
#endif

/// Same like the other spawn, but uses varargs `args`
public func spawn(_ command: String,
                  stdio: [ StdioAction ] = [ .Pipe, .Pipe, .Pipe ],
                  env:   [ String : String/*CustomStringConvertible*/ ] = [:],
                  _ args : String...)
            -> ChildProcess
{
  return spawn(command, args, stdio: stdio, env: env)
}

private typealias MutableCCharPtrArray = [ UnsafeMutablePointer<CChar>? ]

/// Execute a shell command.
///
/// TODO: document
///
/// ### Example
///
///     let child = spawn("tail", [ "-f", "/var/log/system.log ])
///     child.stdout.onReadable {
///        console.log("tail output: " + child.stdout.read())
///     }
///
///
/// ### Stdio Options
///
/// Stdio options is a N-object array which can take a set of objects:
/// - string: .Pipe, .Ignore (/dev/null), .Inherit
/// - a Stream which has a descriptor                    TODO
/// - a FileDescriptor or Int (dup2)
///
/// Sample: [ .Pipe, .Pipe, process.stderr ] (setting 0, 1, 2)
///
public func spawn(_ command: String, _ args: [ String ],
                  stdio: [ StdioAction ] = [ .Pipe, .Pipe, .Pipe ],
                  env:   [ String : String/*CustomStringConvertible*/ ]? = nil)
            -> ChildProcess
{
  // lets keep it simple for now ;-)
  // TODO: more options
  // TODO: Is all thise expensive? Should we do it in a secondary thread?
  //       Maybe. Likely. Though it collides with the expectation that the
  //       returned object has a pid already.
  
  // File descriptors are kept open on fork() in Unix. Ensure they are closed
  // in the child process.
  setAllCloseOnExec()
  
  
  /* setup environment */
  // TBD: apparently it is not to easy to grab our own environment ...
  let environ = prepare(environment: env ?? process.env)
  defer { for case let arg in environ { free(arg) } }
  
  /* setup arguments */
  var argsWithCmd = [ command ] + args
  var argv : MutableCCharPtrArray = argsWithCmd.map { argument in
    argument.withCString(strdup)
  }
  argv.append(nil)
  defer { for case let arg in argv { free(arg) } }
  
  
  /* file actions */
  
  var parentFdsToClose = [ Int32 ]()
  var parentPipeEnds   = [ Int32 : Int32]()
#if os(Linux)
  var fileActions = posix_spawn_file_actions_t()
#else
  var fileActions : posix_spawn_file_actions_t? = nil
#endif
  posix_spawn_file_actions_init(&fileActions)
  
  for ifd in 0..<stdio.count {
    let fd   = Int32(ifd)
    let fdop = stdio[ifd]
    
    switch fdop {
      case .Ignore:
        // TBD: do we need to close the old fd?
        let openMode : Int32
        switch fd {
          case xsys.STDIN_FILENO:  openMode = xsys.O_RDONLY
          case xsys.STDOUT_FILENO: openMode = O_WRONLY
          case xsys.STDERR_FILENO: openMode = O_WRONLY
          default: openMode = O_RDWR // we don't know, right?
        }
        posix_spawn_file_actions_addopen(&fileActions, Int32(fd),
                                         "/dev/null", openMode, 0)
      
      case .Pipe:
        var pipeFds : [ Int32 ] = [ -1, -1 ] // read-fd, write-fd
        let rc = pipe(&pipeFds)
        assert(rc == 0, "pipe failed \(strerror(xsys.errno))")
          // TBD: how to deal with this
        
        // this is a little weird, should there be pipein&pipeout?
        if fd == xsys.STDIN_FILENO {
          posix_spawn_file_actions_adddup2(&fileActions, pipeFds[0], fd)
          parentFdsToClose.append(pipeFds[0]) // parent can only write
          parentPipeEnds[fd] = pipeFds[1]
        }
        else { // out pipe
          posix_spawn_file_actions_adddup2(&fileActions, pipeFds[1], fd)
          parentFdsToClose.append(pipeFds[1]) // parent can only read
          parentPipeEnds[fd] = pipeFds[0]
        }
        
        // pipe is duped to desired location, close both of the original fds
        posix_spawn_file_actions_addclose(&fileActions, pipeFds[0])
        posix_spawn_file_actions_addclose(&fileActions, pipeFds[1])
      
      case .Inherit:
#if os(Linux) // FIXME
        // Linux Swift 2.2.1 doesn't have that. Maybe it is not actually
        // necessary anyways? Not sure.
        break
#else
        posix_spawn_file_actions_addinherit_np(&fileActions, Int32(fd))
#endif
      
      case .Fd(let gfd):
        posix_spawn_file_actions_adddup2(&fileActions, gfd.fd, fd)
        posix_spawn_file_actions_addclose(&fileActions, gfd.fd)
      
      // case: .Stream:FileDescriptorStream ...
    }
  }
  
  
  /* control pipe */
  // The whole purpose of this is to detect whether the process exited (in this
  // case the child pipe end will close and our read will fail). We can then
  // call waitpid() and release the child from being a Zombie. Though we like
  // the word Zombie. Maybe we should keep a set of children as Zombies? TBD
  
  var controlPipeFds : [ Int32 ] = [ -1, -1 ] // read/write
  let prc = pipe(&controlPipeFds)
  assert(prc == 0, "pipe failed \(strerror(xsys.errno))")
    // TBD: how to deal with this
#if os(Linux) // FIXME
  // Linux Swift 2.2.1 doesn't have that. Maybe it is not actually
  // necessary anyways? Not sure.
#else
  posix_spawn_file_actions_addinherit_np(&fileActions, controlPipeFds[1])
#endif
  posix_spawn_file_actions_addclose(&fileActions, controlPipeFds[0])
  parentFdsToClose.append(controlPipeFds[1]) // parent can only read
  
  
  // Spawn: http://tinyurl.com/zr3ycfh
  var pid : pid_t = 0
  let rc  = xsys.posix_spawnp(&pid, command, &fileActions, nil, argv, environ)
  
  
  // teardown fork state
  posix_spawn_file_actions_destroy(&fileActions)
  for fd in parentFdsToClose { _ = close(fd) }
  
  
  // TODO: SETUP control pipe?
  
  
  // handle Spawn result
  
  let child : ChildProcess
  if rc == 0 {
    // Setup control pipe in parent
    let cp = PipeSource(fd: controlPipeFds[0]).readable(hwm: 1)
    
    child = ChildProcess(pid: pid, controlPipe:cp)
    
    // Setup parent pipe ends
    for ( cfd, fd ) in parentPipeEnds {
      if cfd == xsys.STDIN_FILENO {
        let t = PipeTarget(fd: fd).writable()
        child.stdin = t
        child.stdio[cfd] = t
      }
      else {
        let t = PipeSource(fd: fd).readable()
        if cfd == xsys.STDOUT_FILENO {
          child.stdout = t
        }
        else if cfd == xsys.STDERR_FILENO {
          child.stderr = t
        }
        child.stdio[cfd] = t
      }
    }
  }
  else {
    // close parent pipe ends
    _ = close(controlPipeFds[0])
    for ( _, fd ) in parentPipeEnds { _ = close(fd) }
    
    let error = POSIXErrorCode(rawValue: rc)!
    
    child = ChildProcess(pid: 0)
    child.errorListeners.emit(error)
    
    nextTick { // does not work, because it is a once?
      if child.errorListeners.isEmpty {
        print("CATCHED error: \(error)") // TODO
      }
    }
  }
  
  
  return child
}

private func prepare(environment env: [ String : String],
                     preserveKeys : [ String ] = [ "PATH", "HOME" ] )
     -> MutableCCharPtrArray
{
  var environment = env // mutable copy
  // Ensure some:
  for key in preserveKeys {
    guard environment[key] == nil else { continue }
    
    guard let p = xsys.getenv(key) else { continue }
    
    if let s = String(validatingUTF8: p) {
      environment[key] = s
    }
  }
  
  var env : MutableCCharPtrArray = environment.map { pair in
    "\(pair.0)=\(pair.1)".withCString(strdup)
  }
  env.append(nil)
  
  return env
}

func setAllCloseOnExec() {
#if os(Linux)
  let openMax = Int32(xsys.sysconf(Int32(xsys._SC_OPEN_MAX)))
  var rlim = xsys.rlimit()
  let limMax : Int32
  let xRLIMIT_NOFILE =
        unsafeBitCast(xsys.RLIMIT_NOFILE, to: __rlimit_resource_t.self)
  if xsys.getrlimit(xRLIMIT_NOFILE, &rlim) != 0 {
    limMax = 0
  }
  else {
    limMax = Int32(rlim.rlim_max)
   }
#else
  let openMax = Int32(xsys.sysconf(xsys._SC_OPEN_MAX))
  let limMax = xsys.NOFILE
#endif
  let fd  = max(limMax, openMax)

  for cfd in 0...fd {
    switch cfd {
      case xsys.STDIN_FILENO, xsys.STDOUT_FILENO, xsys.STDERR_FILENO:
        break
      default:
        _ = xsys.fcntlVi(Int32(cfd), xsys.F_SETFD, xsys.FD_CLOEXEC)
    }
  }
}
