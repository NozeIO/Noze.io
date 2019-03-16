//
//  ChildProcess.swift
//  Noze.io
//
//  Created by Helge Heß on 27/04/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import xsys
import core
import events
import streams
#if os(Linux)
  import let Glibc.ECHILD
#else
  // importing this from xsys doesn't seem to work
  import Foundation // this is for POSIXErrorCode : Error
#endif

public typealias ExitCB = ( Int?, Int? ) -> Void
  // TODO: this is a nice enum

var activeChildProcesses = Array<ChildProcess>()

public class ChildProcess : ErrorEmitter {
  // TBD: this should be a Readable, so that we can directly pipe it to
  //      something else, like: spawn("ls") | response
  //      and a writable as well, for ls | sort | uniq
  //      Note: though we could also just implement pipe
  
  public let pid    : xsys.pid_t
  var controlPipe   : SourceStream<PipeSource>? = nil
  var didRetainCore = false
  
  // pipes
  public var stdio  = [ Int32 : StreamType ]()
  public var stdin  : TargetStream<PipeTarget>? = nil
  public var stdout : SourceStream<PipeSource>? = nil
  public var stderr : SourceStream<PipeSource>? = nil
  
  
  // MARK: - Init
  
  init(pid: pid_t, controlPipe: SourceStream<PipeSource>? = nil) {
    self.pid = pid
    
    super.init()
    
    activeChildProcesses.append(self)
    
    if let cp = controlPipe {
      core.module.retain()
      didRetainCore = true
      activeChildProcesses.append(self) // keep us alive
      
      self.controlPipe = cp
      configureControlPipe()
    }
  }
  
  
  // MARK: - Control Pipe
  
  private final func configureControlPipe() {
    if let cp = self.controlPipe {
      _ = cp.onceReadable {
        guard nil == cp.read() else {
          print("WARN: ChildProcess control pipe got readable?: \(self)")
          assert(false, "onReadable on control pipe, should only emit at end")
          return
        }
      }
      _ = cp.onceError { error in
        print("ERROR: ChildProcess control pipe has an error: \(error) \(self)")
        assert(false, "onError on control pipe")
      }
      _ = cp.onceEnd {
        cp.closeReadStream()
        self.controlPipe = nil
        self.controlPipeDidEnd()
      }
    }
  }
  
  private final func controlPipeDidEnd() {
    var status : Int32 = 0

    // schedule on a different queue, just in case?
    // there is also WNOHANG
    let rc = xsys.waitpid(pid, &status, 0)
    
    if rc == -1 {
      // TODO
      let error = POSIXErrorCode(rawValue: xsys.errno)
      print("ERROR: waitpid error: \(error as Optional)")
      
      if error?.rawValue == ECHILD {
        print("  child gone already?")
      }
    }
    else {
      assert(rc == pid, "got a different pid from waitpid?")
      if xsys.WIFEXITED(status) {
        processDidFinish(code: Int(WEXITSTATUS(status)))
      }
      else if xsys.WIFSIGNALED(status) {
        // Node.js emits a String
        processDidFinish(signal: Int(WTERMSIG(status)))
      }
      else {
        print("ChildProcess: Other termination reason!")
        processDidFinish(code: nil, signal: nil)
      }
    }
  }
  
  private final func processDidFinish(code c: Int? = nil, signal: Int? = nil) {
    if let code = c {
      exitListeners.emit( ( code, nil ) )
    }
    else if let signal = signal {
      exitListeners.emit( ( nil, signal ) )
    }
    
    if didRetainCore { core.module.release(); didRetainCore = false }
    
    #if swift(>=5)
      let myIdx = activeChildProcesses.firstIndex(where: { $0 === self })
    #else
      let myIdx = activeChildProcesses.index(where: { $0 === self })
    #endif
    if let idx = myIdx {
      activeChildProcesses.remove(at: idx)
    }
    else {
      assert(false, "child process missing")
      print("WARN: did not find child process in table? \(self)")
    }
  }
  
  @discardableResult
  public func kill(_ signal: Int32 = xsys.SIGTERM) -> Bool {
    let rc = xsys.kill(pid, signal)
    return rc == 0
  }

  
  // TODO: looks like Node maintains extra pipes for communication:
  //       - disconnect, message (child: process.send()), connected
  //       - child.send(msg, handle, opts, cb)
  //       - can even send descriptors fvia sendHandle argument

  
  // MARK: - Events
  
  // TODO: close (figure out what that is. streams got close but child
  //              is alive?)
  
  public var exitListeners = EventListenerSet<(Int?,Int?)>()
  
  @discardableResult
  public func onExit(cb: @escaping ExitCB) -> Self {
    exitListeners.add(handler: cb)
    return self
  }
  
  @discardableResult
  public func onceExit(cb: @escaping ExitCB) -> Self {
    exitListeners.add(handler: cb, once: true)
    return self
  }
}
