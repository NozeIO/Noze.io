//
//  HTTPParserTests.swift
//  HTTPParserTests
//
//  Created by Helge Hess on 30/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if os(Linux) || os(Android) || os(FreeBSD)
  import Glibc
#endif

import XCTest
@testable import http_parser

class HTTPParserTests: XCTestCase {
  
  func testSimpleGETParsing() throws {
    
    var parser   = http_parser()
    var settings = http_parser_settings_cb()

    settings.onHeaderField { parser, buffer, size in
      print("Header: \(debugBucketAsString(buffer, size))")
      return 0
    }
    settings.onHeaderValue { parser, buffer, size in
      print(" Value: \(debugBucketAsString(buffer, size))")
      return 0
    }
    settings.onURL { parser, buffer, size in
      print("URL:    \(debugBucketAsString(buffer, size))")
      return 0
    }
    settings.onHeadersComplete { parser in
      print("headers complete!")
      XCTAssertEqual(parser.nread, 68)
      //XCTAssertEqual(parser.content_length, 0)
      XCTAssertEqual(parser.http_major,     1)
      XCTAssertEqual(parser.http_minor,     1)
      XCTAssertEqual(parser.status_code,    0)
      XCTAssertEqual(parser.method, HTTPMethod.GET)
      XCTAssertEqual(parser.error,  HTTPError.OK)
      return 0
    }
    
    var didCallComplete = false
    settings.onMessageComplete { parser in
      print("message complete!")
      didCallComplete = true
      return 0
    }
    
    settings.onBody { _, _, _ in
      XCTAssertFalse(true) // Called body, not expected
      return 42
    }
    
    let ( cslen, plen ) = parser.parse(settings: settings,
                                       string: fixGetRequest)
    XCTAssertEqual(cslen, plen)
    
    XCTAssertTrue(didCallComplete)
  }
  
  func testSimplePOSTParsing() {
    
    var parser   = http_parser()
    var settings = http_parser_settings_cb()
    
    settings.onHeaderField { parser, buffer, size in
      print("Header: \(debugBucketAsString(buffer, size))")
      return 0
    }
    settings.onHeaderValue { parser, buffer, size in
      print(" Value: \(debugBucketAsString(buffer, size))")
      return 0
    }
    settings.onURL { parser, buffer, size in
      print("URL:    \(debugBucketAsString(buffer, size))")
      return 0
    }
    settings.onHeadersComplete { parser in
      print("headers complete!")
      XCTAssertEqual(parser.nread, 76)
      XCTAssertEqual(parser.content_length, 49)
      XCTAssertEqual(parser.http_major,     1)
      XCTAssertEqual(parser.http_minor,     1)
      XCTAssertEqual(parser.status_code,    0)
      XCTAssertEqual(parser.method, HTTPMethod.POST)
      XCTAssertEqual(parser.error,  HTTPError.OK)
      return 0
    }
    
    var didCallComplete = false
    settings.onMessageComplete { parser in
      print("message complete!")
      didCallComplete = true
      return 0
    }
    
    settings.onBody { parser, buffer, size in
      print("BODY:   \(debugBucketAsString(buffer, size))")
      return 0
    }
    
    // clen is 49 + hlen = 76 = 125
    let ( cslen, plen ) = parser.parse(settings: settings,
                                       string: fixPostRequest)
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

extension http_parser {
  
  mutating func parse(settings set: http_parser_settings, string s: String)
                -> ( len: Int, parsed: Int )
  {
    var cslen = 0, plen = 0

    s.withCString { cs in
      cslen = Int(strlen(cs))
      plen = self.execute(set, cs, size_t(cslen))
    }
    
    // EOF
    let plen2 = self.execute(set, nil, 0)
    XCTAssertEqual(plen2, 0)
    
    return ( cslen, plen )
  }
  
}

func debugBucketAsString(_ buf: UnsafePointer<CChar>, _ len: size_t) -> String {
  var s = ""
  for i in 0..<len {
    let c = buf[i]
    if isprint(Int32(c)) != 0 {
      s += " \(UnicodeScalar(Int(c))!)"
    }
    else {
      s += " \\\(c)"
    }
  }
  return s
}
