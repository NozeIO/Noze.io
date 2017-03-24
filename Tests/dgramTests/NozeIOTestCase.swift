//
//  NozeIOTestCase.swift
//  NozeIO
//
//  Created by Helge Hess on 30/03/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import XCTest
import core

struct StdErrStream : TextOutputStream {
  mutating func write(_ string: String) {
    fputs(string, stderr)
  }
}

var nzStdErr = StdErrStream()

public class NozeIOTestCase : XCTestCase {
  
  private var wantsRunloop = 0
  
  public override func setUp() {
    super.setUp()
    
    // the test is running on the main-queue, so we need to run Noze on a
    // secondary queue.
    core.Q = DispatchQueue(label: "de.zeezide.noze.testqueue")
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
  
  var done = DispatchSemaphore(value: 0)
  
  public func enableRunLoop() {
    self.wantsRunloop += 1
  }
  
  static let defaultWaitTimeoutInSecs = 10
  
  public func waitForExit(timeoutInMS to: Int =
                                 defaultWaitTimeoutInSecs * 1000)
  {
    let timeout = DispatchTime.now() + DispatchTimeInterval.milliseconds(to)

    let rc = done.wait(timeout: timeout)
    let didTimeout = rc == .timedOut
    if didTimeout {
      // not done in time
      XCTAssert(false, "hit async queue timeout!")
    }
  }
  
  public func exitIfDone(code: Int32 = 42) {
    wantsRunloop -= 1
    if wantsRunloop < 1 {
      //exit(code)
      done.signal()
      // this lets the waitForExit finish
    }
  }
  
  public func inRunloop(cb: (@escaping () -> Void) -> Void) {
    enableRunLoop()
    cb( { self.exitIfDone() } )
    waitForExit()
  }
}

// MARK: - Global Helper Funcs
// Note: those are not part of the class to avoid 'self' capture warnings.

#if os(Linux) || os(Android) || os(FreeBSD)
  import Glibc
#endif

// 'flush' print
public func fprint<T>(_ value: T) {
  fflush(stdout)
  print(value)
  fflush(stdout)
}
public func efprint<T>(_ value: T) {
  fflush(stderr)
  print(value, to:&nzStdErr)
  fflush(stderr)
}
