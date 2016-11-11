//
//  BasicAuthTests.swift
//  Noze.io
//
//  Created by Fabian Fett on 19/10/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import XCTest

@testable import http
import base64

class BasicAuthTests: NozeIOTestCase {
  
  let testPort = 17235
  
  func testBasicAuth() {
    let myServer = http.createServer { req, res in
        print("S: GOT REQUEST: \(req)")
        
        do {
          let crd = try basicAuth.auth(req)
          
          guard crd.name == "test", crd.pass == "abc123" else {
            res.statusCode = 401
            res.setHeader("WWW-Authenticate", "Basic realm=\"Cows Heaven\"")
            res.end()
            return
          }
          
          res.statusCode = 200
          res.end()
        }
        catch let err as BasicAuth.Error {
          switch err {
            case .MissingAuthorizationHeader:
              res.statusCode = 401
              res.setHeader("WWW-Authenticate", "Basic realm=\"Cows Heaven\"")
            case .InvalidBasicAuthorizationHeader:
              res.statusCode = 400
          }
          res.end()
        }
        catch _ {
          res.statusCode = 500
          res.end()
        }
      }
      .listen(testPort)
    
    let tests: [(String, Int)] = [
      ("Basic "        + b64("test:abc123") , 200),
      ("   Basic    "  + b64("test:abc123") , 200),
      ("Basic "        + b64("test:abc12")  , 401),
      ("Basic abc1*"                        , 400),
      ("Bearer "       + b64("test:abc")    , 400),
      (""                                   , 400)
    ]
    
    for (auth, status) in tests {
      enableRunLoop()
      
      let opt = RequestOptions()
      opt.scheme   = "http"
      opt.hostname = "127.0.0.1"
      opt.port     = testPort
      opt.method   = .GET
      opt.headers["Authorization"] = auth
      
      let req = request(opt) { res in
        print("C: GOT RESPONSE: \(res)")
        XCTAssert(res.statusCode == status)
      
        self.exitIfDone()
      }
      
      print("T: request: \(req)")
      
      req.end()
    }
  
    waitForExit()
    
    myServer.close()
  }
  
  private func b64(_ string: String) -> String {
    return Base64.encode(data: Array(string.utf8))
  }
}
