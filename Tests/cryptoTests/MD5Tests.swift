//
//  NozeMD5Tests.swift
//  Noze.io
//
//  Created by Helge Hess on 26/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import XCTest

import streams
@testable import crypto

class MD5Tests: NozeIOTestCase {
  
  let hello_text = "Hello World"
  let hello_md5  = "b10a8db164e0754105b7a99be72e3fe5"
  
  func testDirectAccess() throws {
    let bytes = Array(hello_text.utf8)
    
    let hash = crypto.createHash("md5")!
    
    hash.update(bytes)
    let result = hash.digest("hex")
    
    XCTAssertNotNil(result)
    XCTAssertEqual(result!, hello_md5)
  }
  
  func testStream() {
    enableRunLoop()
    
    let md5 = crypto.createHash("md5")!
    
    hello_text.utf8 | md5 | concat {
      results in
      
      XCTAssertEqual(results.count, 1)
      
      let hash   = results.joined()
      let result = hash.toString("hex")
      
      XCTAssertNotNil(result)
      XCTAssertEqual(result!, self.hello_md5)
      
      self.exitIfDone()
    }
    
    waitForExit()
  }
}

#if os(Linux)
extension MD5Tests {
  static var allTests = {
    return [
      ( "testDirectAccess", testDirectAccess ),
      ( "testStream",       testStream       )
    ]
  }()
}
#endif
