//
//  NozeIOLeftPadTests.swift
//  NozeIO
//
//  Created by Helge Hess on 21/04/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import XCTest

@testable import leftpad

class LeftPadTests: XCTestCase {
  
  let str = "Hello"
  
  func testLeftPadLongerString() throws {
    let a = str.leftpad(2)
    XCTAssertEqual(a, str) // no change
  }
  
  func testLeftPadEqualString() {
    let a = str.leftpad(5)
    XCTAssertEqual(a, str) // no change
  }
  
  func testLeftPad() {
    let a = str.leftpad(10)
    XCTAssertEqual(a, "     Hello")
  }
  
  func testLeftPadCustom() {
    let a = str.leftpad(10, c: "#")
    XCTAssertEqual(a, "#####Hello")
  }
}

#if os(Linux)
extension LeftPadTests {
  static var allTests = {
    return [
      ( "testLeftPadLongerString", testLeftPadLongerString ),
      ( "testLeftPadEqualString",  testLeftPadEqualString  ),
      ( "testLeftPad",             testLeftPad             ),
      ( "testLeftPadCustom",       testLeftPadCustom       )
    ]
  }()
}
#endif
