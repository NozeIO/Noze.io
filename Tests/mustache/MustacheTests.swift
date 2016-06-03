//
//  MustacheTests.swift
//  Noze.io
//
//  Created by Helge Heß on 6/1/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import XCTest

@testable import mustache

class MustacheTests: XCTestCase {
  
  let fixTaxTemplate =
    "Hello {{name}}\n" +
    "You have just won {{& value}} dollars!\n" +
    "{{#in_ca}}\n" +
    "Well, {{{taxed_value}}} dollars, after taxes." +
    "{{/in_ca}}\n" +
    "{{#addresses}}" +
    "  Has address in: {{city}}" +
    "{{/addresses}}" +
    "{{^addresses}}" +
    "Has NO addresses" +
    "{{/addresses}}" +
  ""
  
  let fixDictChris : [ String : Any ] = [
    "name":        "Chris",
    "value":       10000,
    "taxed_value": Int(10000 - (10000 * 0.4)),
    "in_ca":       true,
    "addresses": [
      [ "city": "Cupertino" ]
    ]
  ]
  
  let fixChrisResult =
    "Hello Chris\n" +
    "You have just won 10000 dollars!\n" +
    "\n" +
    "Well, 6000 dollars, after taxes." +
    "\n" +
    "" +
    "  Has address in: Cupertino" +
    "" +
  ""

  func testDictKVC() throws {
    let v = KeyValueCoding.value(forKey: "name", inObject: fixDictChris)
    XCTAssertNotNil(v)
    if v != nil {
      XCTAssertTrue(v! is String)
      XCTAssertEqual(v as? String, "Chris")
    }
  }
  
  func testDictNumberKVC() throws {
    let v = KeyValueCoding.value(forKey: "value", inObject: fixDictChris)
    XCTAssertNotNil(v)
    if v != nil {
      XCTAssertTrue(v! is Int)
      XCTAssertEqual(v as? Int, 10000)
    }
  }
  
  func testSimpleMustacheDict() throws {
    let parser = MustacheParser()
    let tree   = parser.parse(string: fixTaxTemplate)
    let result = tree.render(object: fixDictChris)
    
    XCTAssertFalse(result.isEmpty)
    XCTAssertEqual(result, fixChrisResult)
  }
  
#if os(Linux)
  static var allTests = {
    return [
      ( "testSimpleMustacheDict", testSimpleMustacheDict ),
    ]
  }()
#endif
}
