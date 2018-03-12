//
//  NozeIODNSTests.swift
//  NozeIO
//
//  Created by Helge Hess on 11/04/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import XCTest

@testable import xsys
@testable import dns

class NozeIODNSTests: NozeIOTestCase {
  
  func testLookup() throws {
    enableRunLoop()
    
    dns.lookup("zeezide.de") { error, address in
      guard let addr = address else {
        print("DNS ERROR:", error as Any)
        XCTAssertTrue(false)
        self.exitIfDone()
        return
      }
      
      print("DNS resolved address:", addr)
      self.exitIfDone()
    }
    
    waitForExit()
  }
  
#if os(Linux)
  static var allTests = {
    return [
      ( "testLookup", testLookup )
    ]
  }()
#endif
}
