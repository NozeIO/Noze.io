//
//  NozeIOTests.swift
//  NozeIOTests
//
//  Created by Helge Hess on 08/07/15.
//  Copyright © 2015 ZeeZide GmbH. All rights reserved.
//

import XCTest

import streams
@testable import fs

class NozeIOFileSourceTests: NozeIOTestCase {

  func testFileSource() throws {
    let fn = "/etc/passwd"
    //let fn = "/Volumes/zDuo/WWDC 2015/225_hd_whats_new_in_nscollectionview.mp4"
    
    let stream = FileSource(path: fn).readable()
    var byteCounter = 0
    
    _ = stream.onEnd {
      print("counted \(byteCounter) bytes!")
      self.exitIfDone()
    }
    _ = stream.onError {
      print("ERROR: \($0)")
      self.exitIfDone()
    }
    
    _ = stream.onReadable {
      if let bucket = stream.read() {
        byteCounter += bucket.count
        //print("  counter now at \(byteCounter)")
      }
      else {
        print("  hit EOF ..")
      }
    }
    
    enableRunLoop()
    waitForExit()
  }


#if os(Linux)
  static var allTests = {
    return [
      ( "testFileSource", testFileSource ),
    ]
  }()
#endif
}
