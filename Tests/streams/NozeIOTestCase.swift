//
//  NozeIOTestCase.swift
//  NozeIO
//
//  Created by Helge Hess on 30/03/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import XCTest
import core

#if swift(>=3.0)
struct StdErrStream : OutputStream {
  mutating func write(_ string: String) {
    fputs(string, stderr)
  }
}
#else
struct StdErrStream : OutputStreamType {
  mutating func write(string: String) {
    fputs(string, stderr)
  }
}
#endif

var nzStdErr = StdErrStream()

public class NozeIOTestCase : XCTestCase {
  
  private var wantsRunloop = 0
  
  public override func setUp() {
    super.setUp()
    
    // the test is running on the main-queue, so we need to run Noze on a
    // secondary queue.
    core.Q = dispatch_queue_create("de.zeezide.noze.testqueue", nil)
    core.disableAtExitHandler() // we do not want atexit here
    core.module.exitFunction = { code in
      XCTAssert(code == 0)
      if self.wantsRunloop > 0 {
        print("WARN: test queue is not done yet?: #\(self.wantsRunloop)")
        // FIXME
        // XCTAssert(self.wantsRunloop == 0)
      }
    }
  }
  
  public override func tearDown() {
    super.tearDown()
  }
  
  
  // MARK: - Global Helper Funcs
  
#if swift(>=3.0)
  var done = dispatch_semaphore_create(0)!
#else
  var done = dispatch_semaphore_create(0)
#endif
  
  public func enableRunLoop() {
    self.wantsRunloop += 1
  }
  
  static let defaultWaitTimeoutInSecs = 10
  
  public func waitForExit(timeoutInMS to: Int =
                                 defaultWaitTimeoutInSecs * 1000)
  {
    let timeout = dispatch_time(DISPATCH_TIME_NOW,
                                Int64(to) * Int64(NSEC_PER_MSEC))
    
    if dispatch_semaphore_wait(done, timeout) > 0 {
      // not done in time
      XCTAssert(false, "hit async queue timeout!")
    }
  }
  
  public func exitIfDone(code: Int32 = 42) {
    wantsRunloop -= 1
    if wantsRunloop < 1 {
      //exit(code)
      dispatch_semaphore_signal(done)
      // this lets the waitForExit finish
    }
  }
  
#if swift(>=3.0)
  public func inRunloop(cb: @noescape (() -> Void) -> Void) {
    enableRunLoop()
    cb( { self.exitIfDone() } )
    waitForExit()
  }
#else
  public func inRunloop(@noescape cb: (() -> Void) -> Void) {
    enableRunLoop()
    cb( { self.exitIfDone() } )
    waitForExit()
  }
#endif
}

// MARK: - Global Helper Funcs
// Note: those are not part of the class to avoid 'self' capture warnings.

// 'flush' print
public func fprint<T>(value: T) {
  fflush(stdout)
  print(value)
  fflush(stdout)
}
public func efprint<T>(value: T) {
  fflush(stderr)
#if swift(>=3.0) // #swift3-fd
  print(value, to:&nzStdErr)
#else
  print(value, toStream:&nzStdErr)
#endif
  fflush(stderr)
}

#if swift(>=3.0) // #swift3-1st-arg
public func fprint<T>(_ value: T) {
  fprint(value: value)
}
public func efprint<T>(_ value: T) {
  efprint(value: value)
}
#endif


