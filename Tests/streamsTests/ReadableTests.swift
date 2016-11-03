//
//  ReadableTests.swift
//  Noze.io
//
//  Created by Fabian Fett on 02/11/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import XCTest
import streams
import console

class ReadableTests: NozeIOTestCase {

  func testReadablePipeThenPush() {
    enableRunLoop()
    
    var done = false
    
    let readable = Readable<String>()
    let writeable = Writable<String>() { chunk, next in
      console.dir(chunk)
      next(nil)
    }
    
    readable | writeable 
      .onFinish {
        XCTAssert(done)
        self.exitIfDone()
      }
    
    readable.push(["Hi dude"])
    
    done = true
    readable.push(nil)
    
    waitForExit()
  }
  
  func testReadablePushFirstThenPipe() {
    enableRunLoop()
    
    let readable = Readable<String>()
    let writeable = Writable<String>() { chunk, done in
      console.dir(chunk)
      done(nil)
    }
    
    readable.push(["Hi dude"])
    readable.push(nil)
    
    readable | writeable 
      .onFinish {
        self.exitIfDone()
      }
    
    waitForExit()
  }
  
}
