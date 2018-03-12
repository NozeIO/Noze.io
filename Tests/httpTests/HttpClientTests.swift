//
//  HttpClientTests.swift
//  Noze.io
//
//  Created by Helge Heß on 5/20/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import XCTest

@testable import http

class NozeIOHttpClientTests: NozeIOTestCase {
  
  func testSimpleGetZZ() throws {
    enableRunLoop()
    
    var sizeReceived = 0
    _ = http.get("http://zeezide.com/") { res in
      print("C: \(res)")
      XCTAssert(res.statusCode == 200)
      
      _ = res.onReadable {
        guard let data = res.read() else { // EOF
          assert(res.hitEOF)
          // print("C: HIT EOF")
          return
        }
        
        //print("C: got data #\(data.count)")
        sizeReceived += data.count
      }
      _ = res.onEnd {
        // print("C: got end.")
        self.exitIfDone()
      }
    }
    
    waitForExit(timeoutInMS: 500 * 1000)
    
    print("Received: \(sizeReceived) bytes.")
    XCTAssert(sizeReceived > 1024)
  }
  
  func testSimplePipedGetZZ() {
    enableRunLoop()
    
    var result : String? = nil
    
    _ = http.get("http://zeezide.com/") { res in
      XCTAssert(res.statusCode == 200)
      _ = res | utf8 | concat { data in
        result = String(data)
        #if swift(>=3.2)
          print("got data: #\(data.count) " +
                "chars=#\(result?.count as Optional)")
        #else
          print("got data: #\(data.count) " +
                "chars=#\(result?.characters.count as Optional)")
        #endif
        self.exitIfDone()
      }
    }
    
    waitForExit()
    
    XCTAssertNotNil(result)
    XCTAssert(!(result?.isEmpty ?? true))
  }
  
  func testRawGetZZ() {
    enableRunLoop()
    
    let options = RequestOptions()
    options.scheme   = "http"
    options.hostname = "zeezide.com"
    options.port     = 80
    options.path     = "/"
    
    let req = request(options) { res in
      print("C: \(res)")
      XCTAssert(res.statusCode == 200)
      
      var result : String? = nil
      _ = res | utf8 | concat { data in
        result = String(data)
        
        #if swift(>=3.2)
          print("got data: #\(data.count) " +
                "chars=#\(result?.count as Optional)")
        #else
          print("got data: #\(data.count) " +
                "chars=#\(result?.characters.count as Optional)")
        #endif
        self.exitIfDone()
      }
    }
    
    var didGetOnSocket = false
    _ = req.onSocket { sock in
      //print("C: GOT SOCKET: \(sock)")
      didGetOnSocket = true
    }
    
    req.end()
    
    waitForExit()
    
    XCTAssert(didGetOnSocket)
  }
  
  func testSimpleSelfHostedGET() {
    enableRunLoop()
    
    let myServer = http.createServer { req, res in
        print("S: GOT REQUEST: \(req)")
        res.end("Hello")
      }
      .listen(17234)
    
    let req = get("http://127.0.0.1:17234/hello") {
      print("C: GOT RESPONSE: \($0)")
      self.exitIfDone()
    }
    
    print("T: request: \(req)")

    waitForExit()
    
    myServer.close()
  }
  

#if os(Linux)
  static var allTests = {
    return [
      ( "testSimpleGetZZ",      testSimpleGetZZ ),
      ( "testSimplePipedGetZZ", testSimplePipedGetZZ ),
      ( "testRawGetZZ",         testRawGetZZ ),
    ]
  }()
#endif
}
