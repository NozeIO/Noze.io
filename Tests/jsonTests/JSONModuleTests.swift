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

class JSONModuleTests: NozeIOTestCase {
  
  let fixJson1 = "{ \"name\": \"John Doe\", \"age\": 42 }"
  let fixObj1  : [ String : Any ] = [ "name": "John Doe", "age": 42 ]
  
  func testSimpleDictStringParse() throws {
    let obj : JSON! = JSON.parse(fixJson1)
    XCTAssertNotNil(obj)
    
    XCTAssertNotNil(obj["name"])
    XCTAssertNotNil(obj["age"])
    
    let name = obj["name"]!
    let age  = obj["age"]!
    
    XCTAssertEqual(name, "John Doe")
    XCTAssertEqual(age,  42)
  }

  func testStringifyNull() {
    let s = JSON.stringify(nil)
    XCTAssertEqual(s, "null")
  }
 
  func testStringifyDict() {
    let s = JSON.stringify(fixObj1)
    
    let obj : JSON! = JSON.parse(s) // reparse
    XCTAssertNotNil(obj)
    XCTAssertEqual(obj, fixObj1.toJSON())
  }
}

#if os(Linux)
extension JSONModuleTests {
  static var allTests = {
    return [
      ( "testSimpleDictStringParse", testSimpleDictStringParse ),
      ( "testStringifyNull",         testStringifyNull         ),
      ( "testStringifyDict",         testStringifyDict         )  
    ]
  }()
}  
#endif
