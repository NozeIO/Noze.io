//
//  HTTPParserTests.swift
//  HTTPParserTests
//
//  Created by Helge Hess on 30/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import XCTest
@testable import http_parser

class HTTPParserTests: XCTestCase {
  
  func testSimpleGETParsing() throws {
    
    let parser = HTTPParser()
    
    parser.onHeaderField { parser, buffer, size in
      print("Header: \(debugBucketAsString(buffer, size))")
      return 0
    }
    parser.onHeaderValue { parser, buffer, size in
      print(" Value: \(debugBucketAsString(buffer, size))")
      return 0
    }
    parser.onURL { parser, buffer, size in
      print("URL:    \(debugBucketAsString(buffer, size))")
      return 0
    }
    parser.onHeadersComplete { parser in
      print("headers complete!")
      XCTAssertEqual(parser.nread, 68)
      //XCTAssertEqual(parser.content_length, 0)
      XCTAssertEqual(parser.http_major,     1)
      XCTAssertEqual(parser.http_minor,     1)
      XCTAssertNil  (parser.statusCode)
      XCTAssertEqual(parser.method, HTTPMethod.GET)
      XCTAssertEqual(parser.error,  HTTPError.OK)
      return 0
    }
    
    var didCallComplete = false
    parser.onMessageComplete { parser in
      print("message complete!")
      didCallComplete = true
      return 0
    }
    
    parser.onBody { _, _, _ in
      XCTAssertFalse(true) // Called body, not expected
      return 42
    }
    
    let ( cslen, plen ) = parser.parse(string: fixGetRequest)
    XCTAssertEqual(cslen, plen)
    
    XCTAssertTrue(didCallComplete)
  }
  
  func testSimplePOSTParsing() {
    
    let parser = HTTPParser()
    
    parser.onHeaderField { parser, buffer, size in
      print("Header: \(debugBucketAsString(buffer, size))")
      return 0
    }
    parser.onHeaderValue { parser, buffer, size in
      print(" Value: \(debugBucketAsString(buffer, size))")
      return 0
    }
    parser.onURL { parser, buffer, size in
      print("URL:    \(debugBucketAsString(buffer, size))")
      return 0
    }
    parser.onHeadersComplete { parser in
      print("headers complete!")
      XCTAssertEqual(parser.nread, 76)
      XCTAssertEqual(parser.content_length, 49)
      XCTAssertEqual(parser.http_major,     1)
      XCTAssertEqual(parser.http_minor,     1)
      XCTAssertNil  (parser.statusCode)
      XCTAssertEqual(parser.method, HTTPMethod.POST)
      XCTAssertEqual(parser.error,  HTTPError.OK)
      return 0
    }
    
    var didCallComplete = false
    parser.onMessageComplete { parser in
      print("message complete!")
      didCallComplete = true
      return 0
    }
    
    parser.onBody { parser, buffer, size in
      print("BODY:   \(debugBucketAsString(buffer, size))")
      return 0
    }
    
    // clen is 49 + hlen = 76 = 125
    let ( cslen, plen ) = parser.parse(string: fixPostRequest)
    XCTAssertEqual(cslen, plen)
    
    XCTAssertTrue(didCallComplete)
    
  }
  
  
  let fixGetRequest = makeRequest(method: "GET", "/hello", [
    "Content-Length" : "0",
    "Content-Type"   : "text/plain"
  ])
  
  let fixPostRequest = makeRequest(method: "POST", "/login",
    [
      "Content-Type"   : "application/json"
    ],
    "{ \"login\": \"xyz\", \"password\": \"opq\", \"port\": 80 }"
  )
}


// MARK: - Helpers

func makeRequest(method m: String, _ url: String,
                 _ headers: Dictionary<String, String>,
                 _ body: String? = nil)
     -> String
{
  var s = "\(m) \(url) HTTP/1.1\r\n"
  for (k, v) in headers {
    s += "\(k): \(v)\r\n"
  }
  
  if let b = body {
    s += "Content-length: \(b.utf8.count)\r\n"
  }
  
  s += "\r\n"
  
  if let b = body { s += b }

  return s
}

extension HTTPParser {
  
  func parse(string s: String) -> ( len: Int, parsed: Int ) {
    var cslen = 0, plen = 0

    s.withCString { cs in
      cslen = Int(strlen(cs))
      plen = self.execute(cs, size_t(cslen))
    }
    
    // EOF
    let plen2 = self.execute(nil, 0)
    XCTAssertEqual(plen2, 0)
    
    return ( cslen, plen )
  }
  
}

func debugBucketAsString(buf: UnsafePointer<CChar>, _ len: size_t) -> String {
  var s = ""
  for i in 0..<len {
    let c = buf[i]
    if isprint(Int32(c)) != 0 {
      s += " \(UnicodeScalar(Int(c)))"
    }
    else {
      s += " \\\(c)"
    }
  }
  return s
}

#if swift(>=3.0) // #swift3-1st-kwarg
func debugBucketAsString(_ buf: UnsafePointer<CChar>, _ len: size_t) -> String {
  return debugBucketAsString(buf: buf, len)
}
#endif
