//
//  URLTests.swift
//  NozeIO
//
//  Created by Helge Hess on 04/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import XCTest

@testable import http

class NozeIOURLTests: NozeIOTestCase {
  
  func testComplexURLParse() throws {
    let fix = "https://joe:user@apple.com:443/path/elements#red?a=10&b=20"
    
    let url = http.url.parse(fix)
    
    XCTAssertFalse(url.isEmpty)
    XCTAssertEqual(url.scheme,   "https")
    XCTAssertEqual(url.userInfo, "joe:user")
    XCTAssertEqual(url.port,     443)
    XCTAssertEqual(url.path,     "/path/elements")
    XCTAssertEqual(url.fragment, "red")
    XCTAssertEqual(url.query,    "a=10&b=20")
  }

  func testComplexURLBuild() {
    let fix = "https://joe:user@apple.com:443/path/elements#red?a=10&b=20"
    
    let url = http.url.parse(fix)
    
    let regen = url.toString()
    XCTAssertNotNil(regen)
    XCTAssertEqual(fix, regen!)
  }
  
  func testQueryStringParse() {
    let fix = "a=5&b=3&c=Hello World&a=8"
    
    let parsed = querystring.parse(fix)
    XCTAssertFalse(parsed.isEmpty)
    XCTAssertNotNil(parsed["a"])
    XCTAssertNotNil(parsed["b"])
    XCTAssertNotNil(parsed["c"])
    XCTAssertTrue(parsed["b"] is String)
    XCTAssertTrue(parsed["c"] is String)
    XCTAssertTrue(parsed["a"] is Array<Any>)
    
    let b = parsed["b"] as! String
    let c = parsed["c"] as! String
    XCTAssertEqual(b, "3")
    XCTAssertEqual(c, "Hello World")
    XCTAssertEqual((parsed["a"] as! Array<Any>).map({ $0 as! String}), [ "5", "8" ])
  }
  
  func testQueryStringParseDecode() {
    let fix = "a=5&c=Hello%20World"
    
    let parsed = querystring.parse(fix)
    XCTAssertFalse(parsed.isEmpty)
    
    XCTAssertTrue(parsed["c"] is String)
    let c = parsed["c"] as! String
    XCTAssertEqual(c, "Hello World")
  }

  func testQueryStringZFormat() {
    let fix = "a:int=5&c:lines=Hello%0AWorld"
    
    let parsed = querystring.parse(fix)
    XCTAssertFalse(parsed.isEmpty)
    
    print("PARSED: \(parsed)")

    XCTAssertNotNil(parsed["a"])
    XCTAssertNotNil(parsed["c"])
    XCTAssertNil(parsed["a:int"])
    XCTAssertNil(parsed["c:lines"])
    
    XCTAssertTrue(parsed["a"] is Int)
    let a = parsed["a"] as! Int
    XCTAssertEqual(a, 5)
    
    XCTAssertTrue(parsed["c"] is [String])
    let c = parsed["c"] as! [String]
    XCTAssertEqual(c, ["Hello", "World"])
  }

#if os(Linux)
  static var allTests = {
    return [
      ( "testComplexURLParse",        testComplexURLParse ),
      ( "testComplexURLBuild",        testComplexURLBuild ),
      ( "testQueryStringParse",       testQueryStringParse ),
      ( "testQueryStringParseDecode", testQueryStringParseDecode ),
      ( "testQueryStringZFormat",     testQueryStringZFormat ),
    ]
  }()
#endif
}
