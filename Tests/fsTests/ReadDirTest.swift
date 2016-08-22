//
//  FileSystemTests.swift
//  NozeIO
//
//  Created by Helge Heß on 5/6/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import XCTest

@testable import streams
@testable import fs

class NozeReaddirTests: XCTestCase {

  func testSyncReaddir() throws {
    let entries = fs.readdirSync("/bin")
    XCTAssertNotNil(entries)
    XCTAssertTrue(entries!.contains("ls"))
    XCTAssertTrue(entries!.contains("pwd"))
    XCTAssertTrue(!entries!.contains(".."))
    XCTAssertTrue(!entries!.contains("."))
  }
  

#if os(Linux)
  static var allTests = {
    return [
      ( "testSyncReaddir", testSyncReaddir )
    ]
  }()
#endif
}
