//
//  JSONTests.swift
//  NozeIO
//
//  Created by Helge Heß on 5/6/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import XCTest

@testable import streams
@testable import json

class NozeJSONTests: NozeIOTestCase {
  
  func testSimpleDictStringParse() {
    let fixture = "{ \"name\": \"John Doe\", \"age\": 42 }"
    
    let obj : JSON! = JSON.parse(fixture)
    XCTAssertNotNil(obj)
    
    XCTAssertNotNil(obj["name"])
    XCTAssertNotNil(obj["age"])
    
    let name = obj["name"]!
    let age  = obj["age"]!
    
    XCTAssertEqual(name, "John Doe")
    XCTAssertEqual(age,  42)
  }
  
}
