//
//  NozeIOSocketTests.swift
//  NozeIO
//
//  Created by Helge Heß on 4/10/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import XCTest

import core
@testable import net

class NozeIOSocketTests: NozeIOTestCase {
  
  func testSocketInit() {
    let sock = net.Socket()
    XCTAssertNotNil(sock)
  }
 
  func testSocketConnect() {
    enableRunLoop()
    
    var didLookup = false
    
    let sock = net.connect(80, "zeezide.de") { _ in
      print("did connect, all good ...")
      self.exitIfDone()
    }
    
    sock.onLookup { address, error in
      print("did lookup: \(address) \(error)")
      didLookup = true
    }
    
    sock.onError { error in
      print("error on connect: \(error)")
      XCTAssertTrue(false)
      self.exitIfDone()
    }
    
    waitForExit()
    XCTAssertTrue(didLookup)
  }

  func writeRequest(to sock: Socket) {
    // send some basic HTTP, ignore write rvals
    // Note: using the UTF-8 write() is actually wrong for HTTP [ISO-Latin-1 ..]
    sock.write("GET / HTTP/1.0\r\n")
    sock.write("Content-Length: 0\r\n")
    sock.write("Host: zeezide.com\r\n")
    sock.write("\r\n") // end() would immediately close socket
  }
  
  func testSocketBasicHTTPWriteRightAway() {
    enableRunLoop()
    
    let sock = net.connect(80, "zeezide.de") { _ in
      print("did connect, all good ...")
    }
    
    sock.onError { error in
      print("error on connect: \(error)")
      XCTAssertTrue(false)
      self.exitIfDone()
    }
    
    var allBuckets : Array<UInt8> = []
    sock.onReadable {
      while let bucket = sock.read() {
        print("bucket: \(bucket.count)")
        allBuckets += bucket
      }
    }
    
    sock.onEnd {
      print("read: #\(allBuckets.count) bytes.")

      let s = byteBucketToString(allBuckets)
      
      print("RESPONSE:\n---snip---\n\(s!)\n---snap---")
      self.exitIfDone()
    }
    
    writeRequest(to: sock)
    
    waitForExit()
  }

  func testSocketBasicHTTPWriteOnConnect() {
    enableRunLoop()
    
    let sock = net.connect(80, "zeezide.de") { sock in
      print("did connect, all good ...")
      
      // use nextTick, otherwise it is not much different as the write will
      // occur in the corked state
      nextTick {
        self.writeRequest(to: sock)
      }
    }
    
    sock.onError { error in
      print("error on connect: \(error)")
      XCTAssertTrue(false)
      self.exitIfDone()
    }
    
    var allBuckets : Array<UInt8> = []
    sock.onReadable {
      while let bucket = sock.read() {
        print("bucket: \(bucket.count)")
        allBuckets += bucket
      }
    }
    
    sock.onEnd {
      print("read: #\(allBuckets.count) bytes.")
      
      let s = byteBucketToString(allBuckets)
      
      print("RESPONSE:\n---snip---\n\(s!)\n---snap---")
      self.exitIfDone()
    }
    
    waitForExit()
  }
}

// This does not seem to work as an extension:
// - Array can't be constrained via where
// - _ArrayType does not have withUnsafeBufferPointer
func byteBucketToString(_ bucket: Array<UInt8>) -> String? {
  var padded = bucket
  padded.append(0) // zero terminate
  return String(cString: padded)
}
