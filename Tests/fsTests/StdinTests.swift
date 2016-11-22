//
//  NozeIOTests.swift
//  NozeIOTests
//
//  Created by Helge Hess on 08/07/15.
//  Copyright © 2015 ZeeZide GmbH. All rights reserved.
//

import XCTest

import xsys
@testable import process

class StdinTests: NozeIOTestCase {
  
  func XtestStdin() throws { // this is interactive ...
    enableRunLoop()
    
    let stream = process.stdin
    let log    = stream.log
    
    _ = stream.onError { error in
      print("CCC GOT ERROR: \(error)")
      if let perr = error as? POSIXErrorCode {
        print("  Posix: \(perr.rawValue)")
      }
      // stream.close()?
    }
    
    _ = stream.onEnd {
      print("CCC: stream ENDed")
    }
    
    _ = stream.onReadable {
      log.enter(function: "onReadable")
      defer { log.leave(function: "onReadable") }
      
      let bucket = stream.read()
      
      if let bucket = bucket {
        print("CCC got bucket \(bucket)")
      }
      else {
        print("CCC hit EOF.")
        assert(stream.hitEOF)
        self.exitIfDone()
      }
    }
    
    waitForExit()
  }
}

#if os(Linux)
extension StdinTests {
  static var allTests = {
    return [
      /*( "XtestStdin", XtestStdin )*/
    ]
  }()
}
#endif
