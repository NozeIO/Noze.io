//
//  NozeIOServerTests.swift
//  NozeIO
//
//  Created by Helge Hess on 19/04/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import XCTest

import core
import xsys
@testable import net

class NozeIOServerTests: NozeIOTestCase {
  
  func testServerSetup() {
    let server = net.createServer { sock in
      print("Wait, someone is attempting to talk to me! \(sock)")
      sock.end("bye bye!")
      print("All good, go ahead!")
    }
    .onError { error in
      print("Catched error: \(error)")
      XCTAssertNil(error)
    }
    
    XCTAssertNotNil(server)
  }
  
  func _createSampleServer() -> net.Server {
    let server = net.createServer { sock in
      print("Wait, someone is attempting to talk to me! \(sock)")
      sock.end("bye bye!")
      print("All good, go ahead!")
      self.exitIfDone()
    }
    .onError { error in
      print("Catched error: \(error)")
      XCTAssertNil(error)
      self.exitIfDone()
    }
    .onClose { server in
      print("Server stopped: \(server)")
      self.exitIfDone()
    }
    return server
  }

  func testServerListenOnWildcard() {
    let server = _createSampleServer()

    enableRunLoop()
    
    server.listen { srv in
      let address = srv.address
      XCTAssertNotNil(address)
      print("listening on \(address!)")

      XCTAssertTrue(srv.isListening)
      
      self.exitIfDone()
    }
    
    waitForExit()
  }
  
  func testServerListenOnPort() {
    let server = _createSampleServer()
    
    enableRunLoop()
    
    server.listen(17042) { srv in
      guard let address = srv.address else {
        XCTAssertNotNil(srv.address)
        return
      }
      
      print("listening on \(address)")
      
      switch address {
        case .AF_INET(let addr):
          XCTAssertEqual(addr.port, 17042)
        default:
          XCTAssertTrue(false, "Unexpected socket address")
      }

      XCTAssertTrue(srv.isListening)
      
      self.exitIfDone()
    }
    
    waitForExit()
  }
  
  func testServerConnect() {
    let server = _createSampleServer()
    
    enableRunLoop()
    
    server.listen { srv in
      let addr = srv.address! // the kernel assigned address (port) we bound to
      print("srv: \(addr)")
      
      net.connect(addr.port!, "127.0.0.1") { sock in
        print("did connect: \(sock)")
        sock.onEnd {
          print("  client did end: \(sock)")
          self.exitIfDone()
        }
      }
      .onError { err in
        print("client sock error: \(err)")
        XCTAssertNil(err, "Error \(err)")
        self.exitIfDone()
      }
    }
    
    waitForExit()
  }
}
