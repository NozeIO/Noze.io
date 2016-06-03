//
//  Base64Tests.swift
//  Noze.io
//
//  Created by Helge Hess on 26/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import XCTest

@testable import base64

class NozeBase64Tests: XCTestCase {
  
  let hello_text = "Hello World"
  let hello_b64  = "SGVsbG8gV29ybGQ="
  
  func testEncoding() {
    let result = Base64.encode(data: Array(hello_text.utf8))
    XCTAssertEqual(result, hello_b64)
  }
  func testDecoding() {
    let result = Base64.decode(string: hello_b64)
    XCTAssertEqual(result, Array(hello_text.utf8))
  }
  
}
