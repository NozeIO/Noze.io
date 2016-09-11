//
//  NozeCore.swift
//  Noze.io
//
//  Created by Helge Heß on 5/17/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import xsys

#if os(Linux)
import func Glibc.atexit
import func Glibc.signal
import var  Glibc.SIG_IGN
import var  Glibc.SIGPIPE
#else
import func Darwin.atexit
#endif

private let debugRetain = false

public class NozeCore : NozeModule {
  
  init() {
    // We never really want SIGPIPE's
    signal(SIGPIPE, SIG_IGN)
    //signal(SIGCHLD, SIG_IGN)
  }
  
  // MARK: - Track Work
  
  // Note: this is supposed to be used on the *main thread*! Hence it doesn't
  //       require a semaphore.
  var workCount         = 0
  let exitDelayInMS     : Int64 = 100
  var didRegisterAtExit = false
  
  public var retainDebugMap : [ String : Int ] = [:]
  
  /// make sure the process stays alive, balance with release
  // Note: # is for debugging, maybe only in debug mode?
  public final func retain(filename: String? = #file, line: Int? = #line,
                           function: String? = #function)
  {
    workCount += 1
    
    if debugRetain {
      let hash = "\(filename)"
      let old = retainDebugMap[hash] ?? 0
      retainDebugMap[hash] = old + 1
      
      print("RETAIN [\(workCount)/\(old + 1)]: \(hash)")
    }

    if !didRegisterAtExit {
      _registerAtExit()
    }
  }
  
  /// reduce process counter, might quit
  public final func release(filename: String? = #file, line: Int? = #line,
                            function: String? = #function)
  {
    if debugRetain {
      let hash = "\(filename)"
      let old = retainDebugMap[hash] ?? 0
      assert(old > 0)
      if old == 1 {
        retainDebugMap.removeValue(forKey: hash)
      }
      else {
        retainDebugMap[hash] = old - 1
      }
      
      print("RELEASE[\(workCount)/\(old)]: \(hash)")
    }
    
    workCount -= 1
    if workCount == 0 {
      if debugRetain {
        print("TERMINATE[\(workCount): \(filename):\(line) \(function)")
      }
      maybeTerminate()
    }
  }
  
  func maybeTerminate() {
    // invoke a little later, in case some new work comes in
    // TBD: does this actually make any sense?
    let nsecs = exitDelayInMS * Int64(NSEC_PER_MSEC)
    dispatch_after(xsys_dispatch_time(DISPATCH_TIME_NOW, nsecs), Q) {
      if self.workCount == 0 { // work still zero, terminate
        self.exit()
      }
    }
  }
  
  /// use `run` as your runloop sink
  public func run() {
    dispatch_main() // never returns
  }
  
  public var exitFunction : ( Int ) -> Void = { code in
    //print("core.exit(\(code))")
    xsys.exit(Int32(code))
  }
  
  public var  exitCode : Int = 0
  public func exit(_ code: Int? = nil) {
    exitFunction(code ?? exitCode)
  }

  
  // Use atexit to invoke dispatch_main. Bad hack, never do that at home!!
  //
  // Without this hack all Noze tools would have to call core.module.run()
  // or dispatch_main(). This way they don't.
  //
  // Essentially the process tries to exit normally (falls through
  // main.swift), and calls the atexit() handler. At this point we start
  // the actual dispatch loop.
  // Obviously this is a HACK and not exactly what atexit() was intended
  // for :->
  func _registerAtExit() {
    guard !didRegisterAtExit else { return }
    didRegisterAtExit = true
    atexit {
      if !nozeWasInAtExit {
        nozeWasInAtExit = true
        dispatch_main()
      }
    }
  }
}
var nozeWasInAtExit = false

public func disableAtExitHandler() {
  module.didRegisterAtExit = true
  nozeWasInAtExit          = true
}
