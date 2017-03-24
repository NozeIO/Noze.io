//
//  DgramTests.swift
//  NozeIO
//
//  Created by Helge Hess on 19/04/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import XCTest

import Foundation
import core
import xsys
@testable import net
@testable import dgram

class NozeIODgramTests: NozeIOTestCase {

  func testRequestResponse() {
    enableRunLoop()

    let server = dgram.createSocket()
    let client = dgram.createSocket()

    server
      .onListening { sock in
        XCTAssertTrue(server === sock)
        switch server.address! {
        case let .AF_INET(address):
          client
            .onError { err in XCTAssertNil(err) }
            .onListening { sock in
              XCTAssertTrue(client === sock)
              client.send([UInt8]("hello noze".utf8), to: address)
            }
            .onMessage { (resp, from) in
              if let decoded = String(
                   data: Data(resp), encoding: .utf8) {
                XCTAssertEqual(decoded, "HELLO NOZE")
                self.exitIfDone()
              }
            }
            .bind(0)
        case _:
          XCTAssertTrue(false)
        }
      }
      .onError { err in XCTAssertNil(err) }
      .onMessage { (req, from) in
        if let decoded = String(data: Data(req), encoding: .utf8) {
          server.send([UInt8](decoded.uppercased().utf8), to: from)
        }
      }
      .bind()

    waitForExit()
  }

  func testWellKnownPort() {
    enableRunLoop()

    dgram.createSocket()
      .onListening { server in
        switch server.address! {
        case let .AF_INET(address):
          XCTAssertEqual(address.port, 10000)
          self.exitIfDone()
        case _:
          XCTAssertTrue(false)
        }
      }
      .bind(10000)

    waitForExit()
  }

  func testReuse() {
    enableRunLoop()

    var counter = 0
    let count = { (server: dgram.Socket) in
      counter += 1
      XCTAssertTrue(counter <= 2)
      if counter == 2 {
        self.exitIfDone()
      }
    }

    dgram.createSocket().onListening(handler: count).bind(10000)
    dgram.createSocket().onListening(handler: count).bind(10000)

    waitForExit()
  }

  func testNoReuse() {
    enableRunLoop()

    var counter = 0
    let count = { (server: dgram.Socket) in
      counter += 1
      XCTAssertTrue(counter <= 1)
    }

    dgram.createSocket().onListening(handler: count).bind(10000)
    dgram.createSocket()
      .onListening(handler: count)
      .onError { err in
        XCTAssertEqual(err as? POSIXErrorCode,
                       POSIXErrorCode.EADDRINUSE)
        self.exitIfDone()
      }
      .bind(10000, exclusive: true)

    waitForExit()
  }

  #if os(Linux)
  static var allTests = {
    return [
      ( "testRequestResponse",             testRequestResponse             ),
      ( "testWellKnownPort",               testWellKnownPort               ),
      ( "testReuse",                       testReuse                       ),
      ( "testNoReuse",                     testNoReuse                     ),
    ]
  }()
  #endif
}
