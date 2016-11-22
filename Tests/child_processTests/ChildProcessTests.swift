//
//  ChildProcessTests.swift
//  NozeIO
//
//  Created by Helge Heß on 5/1/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import XCTest

#if os(Linux) || os(Android) || os(FreeBSD)
  import Glibc
#endif

import xsys
import streams
@testable import child_process

class ChildProcessTests: NozeIOTestCase {
  
  func testLsPipeToConcat() {
    enableRunLoop()
    
    let child = spawn("/bin/ls", "/bin")
      .onError { error in
        XCTAssert(false)
        self.exitIfDone()
      }
      .onExit { code, signal in
        XCTAssertNotNil(code)
        XCTAssertNil(signal)
        XCTAssertEqual(code!, 0)
      }
    
    _ = child | utf8 | concat { data in
      let s = String(data)
      XCTAssert(s.contains("bash\n"))
      XCTAssert(s.contains("ls\n"))
      
      self.exitIfDone()
    }
    
    waitForExit()
  }

  func testMissingBinary() {
    enableRunLoop()
    
    let child = spawn("/bin/ZZZ", "/bin")
      .onError { error in
        XCTAssert(error is POSIXErrorCode)
        let pe = error as! POSIXErrorCode
      
        XCTAssert(pe.rawValue == ENOENT)
      
        self.exitIfDone()
      }
    
    XCTAssertNil(child.stdout)
    
    waitForExit()
  }

  func testNonZeroExit() {
    enableRunLoop()
    
    _ = spawn("/bin/ls", "/XXXX")
      .onError { error in
        XCTAssert(false)
        self.exitIfDone()
      }
      .onExit { code, signal in
        XCTAssertNil(signal)
        XCTAssertNotNil(code)
        XCTAssertNotEqual(code!, 0)
        self.exitIfDone()
      }
    
    waitForExit()
  }
  
  func testMany() {
    for _ in 1...5 {
      testNonZeroExit()
    }
    for _ in 1...5 {
      testMissingBinary()
    }
    for _ in 1...5 {
      testLsPipeToConcat()
    }
  }
  
  func testBase64() {
    enableRunLoop()
    
    var result : String? = nil
    
    _ = "Hello World" | spawn("base64") | utf8 | concat { data in
      result = String(data)
      self.exitIfDone()
    }
    
    waitForExit()
    
    XCTAssertNotNil(result)
    XCTAssertEqual(result, "SGVsbG8gV29ybGQ=\n")
  }

  func testArrayToWC() {
    enableRunLoop()
    
    "Hello\n  World\n" | spawn("wc", "-l") | utf8 | concat { result in
      self.exitIfDone()
    }
    
    waitForExit()
  }
}

extension ChildProcessTests {
  static var allTests = {
    return [
      ( "testLsPipeToConcat", testLsPipeToConcat ),
      ( "testMissingBinary",  testMissingBinary  ),
      ( "testNonZeroExit",    testNonZeroExit    ),
      ( "testMany",           testMany           ),
      ( "testBase64",         testBase64         ),
      ( "testArrayToWC",      testArrayToWC      )
    ]
  }()
}
