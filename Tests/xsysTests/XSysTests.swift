//
//  XSysTests.swift
//  XSysTests
//
//  Created by Helge Hess on 23/07/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import XCTest

@testable import xsys

let secsPerDay        = 24 * 60 * 60
let secsPerYear       = 365 * secsPerDay
let somePastTimestamp = 1469287435

class XSysTests: XCTestCase {
  
  func testNow() throws {
    let now1 = time_t.now
    XCTAssert(now1 != 0)
    
    XCTAssert(now1 > somePastTimestamp &&
              now1 < somePastTimestamp + (secsPerYear * 15))
    
    let now2 = timeval.now
    XCTAssert(now2.seconds > somePastTimestamp &&
              now2.seconds < somePastTimestamp + (secsPerYear * 15))
    
    let now3 = timespec.now
    XCTAssert(now3.seconds > somePastTimestamp &&
              now3.seconds < somePastTimestamp + (secsPerYear * 15))
  }

#if !os(Linux)
  func testUUIDEqual() {
    let uuid1 = xsys_uuid.generate()
    XCTAssertEqual(uuid1, uuid1)
  }
  
  func testUUIDGen() {
    let uuid1 = xsys_uuid.generate()
    let uuid2 = xsys_uuid.generate()
    print("UUID1: \(uuid1) \(uuid1.arrayValue)")
    print("UUID2: \(uuid2) \(uuid2.arrayValue)")
    XCTAssertNotEqual(uuid1, uuid2)
  }
  
  func testUUIDParse() {
    let sample = "B7E3531A-10C5-4C87-8B7B-1E908C08DFC2"
    let value  : [ UInt8 ] =
      [183, 227, 83, 26, 16, 197, 76, 135, 139, 123, 30, 144, 140, 8, 223, 194]
    let uuid = xsys_uuid(sample)
    XCTAssertNotNil(uuid)
    XCTAssertEqual(uuid!.arrayValue, value)
  }
#endif
  
#if os(Linux)
  static var allTests = {
    return [
      /* Not on Linux
      ( "testUUIDEqual", testUUIDEqual ),
      ( "testUUIDGen",   testUUIDGen   ),
      ( "testUUIDParse", testUUIDParse ),
       */
      ( "testNow",       testNow       )
    ]
  }()
#endif
}
