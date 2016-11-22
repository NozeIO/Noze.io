//
//  EventTests.swift
//  Noze.io
//
//  Created by Fabian Fett on 26/10/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import XCTest

import streams
@testable import fs
import net

class EventsTests: NozeIOTestCase {
  
  func testCollection() {
    enableRunLoop()
    
    let collection = [1...100]
    
    let src = collection.readableSource().readable()
    var onReadableForNil = 0
    var onEndCalled = 0
    src.onReadable { [unowned src] in
      if src.read() == nil {
        onReadableForNil += 1
      }
    }
    src.onEnd { [unowned self] in
      onEndCalled += 1
      setTimeout(500) { [unowned self] in
        self.exitIfDone()
      }
    }
    src.onError { [unowned self] (_) in
      XCTFail()
      self.exitIfDone()
    }

    waitForExit()
    
    XCTAssert(onReadableForNil == 1)
    XCTAssert(onEndCalled == 1)
  }
  
  func testFileStream() {
    enableRunLoop()
    
    let fn = "/etc/passwd"
    //let fn = "/Volumes/zDuo/WWDC 2015/225_hd_whats_new_in_nscollectionview.mp4"
    
    let stream = FileSource(path: fn).readable()
    var onReadableForNil = 0
    var onEndCalled = 0
    
    stream.onReadable { [unowned stream] in
      if stream.read() == nil {
        onReadableForNil += 1
      }
    }
    stream.onEnd { [unowned self] in
      onEndCalled += 1
      setTimeout(500) { [unowned self] in
        self.exitIfDone()
      }
    }
    stream.onError { [unowned self] (_) in
      XCTFail()
      self.exitIfDone()
    }
    
    waitForExit()
    
    XCTAssert(onReadableForNil == 1)
    XCTAssert(onEndCalled == 1)
  }
  
  func testSocket() {
    enableRunLoop()
    
    let sock = net.connect(80, "zeezide.de") { _ in
    }
    
    var onReadableForNil = 0
    var onEndCalled = 0
    
    sock.onReadable {
      if sock.read() == nil {
        onReadableForNil += 1
      }
    }
    sock.onEnd { 
      onEndCalled += 1
      setTimeout(500) { [unowned self] in
        self.exitIfDone()
      }
    }
    sock.onError { [unowned self] (_) in
      XCTFail()
      self.exitIfDone()
    }
    
    writeRequest(to: sock)
    
    waitForExit()   
    
    XCTAssert(onReadableForNil == 1)
    XCTAssert(onEndCalled == 1)
  }
  
  private func writeRequest(to sock: Socket) {
    // send some basic HTTP, ignore write rvals
    // Note: using the UTF-8 write() is actually wrong for HTTP [ISO-Latin-1 ..]
    sock.write("GET / HTTP/1.0\r\n")
    sock.write("Content-Length: 0\r\n")
    sock.write("Host: zeezide.com\r\n")
    sock.write("\r\n") // end() would immediately close socket
  }
}

#if os(Linux)
extension EventsTests {
  static var allTests = {
    return [
      ( "testCollection", testCollection ),
      ( "testFileStream", testFileStream ),
      ( "testSocket",     testSocket     ),
    ]
  }()
}
#endif
