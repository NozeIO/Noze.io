//
//  NozeIOTests.swift
//  NozeIOTests
//
//  Created by Helge Hess on 08/07/15.
//  Copyright © 2015 ZeeZide GmbH. All rights reserved.
//

import XCTest

@testable import core
@testable import streams
@testable import console

class NozeIOBasicAsyncTests: NozeIOTestCase {
  
  // MARK: - Runloop Tests
  
  func testAsyncNumberGenerator() {
    //let stream = NumberGenerator(max: 12).readable()
    let stream = AsyncNumberGenerator(max: 4, delay: 50).readable()
    let log    = stream.log
    
    let readSize    = 0
    let greedyRead  = readSize < 1 && false
    let delayedRead : Int = true ? 500 : 0
    
    stream.onReadable {
      log.enter(function: "onReadable")
      defer { log.leave(function: "onReadable") }
      
      let block : () -> Void  = {
        let bucket = readSize > 0 ? stream.read(count: readSize) : stream.read()
        print("CCC BUCKET: \(bucket)")
        
        if (readSize < 1 && bucket == nil) || (bucket == nil && stream.hitEOF) {
          print("Exit, hit EOF")
          self.exitIfDone()
        }
        
        if greedyRead {
          while let bucket = stream.read() {
            print("CCC Another BUCKET: \(bucket)")
          }
          if stream.hitEOF {
            print("Exit, hit greedy EOF")
            self.exitIfDone()
          }
        }
      }
      
      if delayedRead < 1 {
        block()
      }
      else {
        setTimeout(delayedRead, block)
      }
    }
    
    enableRunLoop()
    waitForExit()
  }
  
  func testNumberPrinterStream() {
    impTestNumberPrinterStream(testCork: false, testWriteV: true)
  }
  func impTestNumberPrinterStream(testCork l : Bool, testWriteV : Bool) {
    let testCork = l // to make it work in S2&3
    enableRunLoop()
    
    // var stream = NumberPrinter().writable() // as a full target
    // var stream = SyncSinkTarget(NumberPrinter()).writable() // as a sink
    let stream = ASyncSinkTarget(NumberPrinter(),
                                 maxCountPerDispatch: 1).writable() // as a sink
    
    print("C: write([1,2,3]) .. [\(stream.logStateInfo)]")
    var more = stream.write([ 1, 2, 3 ])
    print("C: did write, can do more?: \(more) [\(stream.logStateInfo)]")
    
    if testCork {
      print("C: corking ...")
      stream.cork()
    }
    
    print("C: write([4,5,6]) .. [\(stream.logStateInfo)]")
    more = stream.write([ 4, 5, 6 ])
    print("C: did write, can do more?: \(more) [\(stream.logStateInfo)]")
    
    if testWriteV {
      print("C: writev .. [\(stream.logStateInfo)]")
      more = stream.writev(buckets: [ [ 10, 11, 12, 13 ], [ 20 ], [ 30, 31 ] ])
      print("C: did writev, can do more?: \(more) [\(stream.logStateInfo)]")
    }
    
    print("C: end with 42 .. [\(stream.logStateInfo)]")
    stream.end([ 42 ])
    print("C: ended stream: [\(stream.logStateInfo)]")
    
    if testCork {
      print("C: uncorking later ...")
      stream.nextTick {
        print("C: uncork ...")
        stream.uncork()
      }
    }
    
    
    stream.onError { error in
      print("C: ERROR: \(error)")
      self.exitIfDone()
    }
    stream.onFinish {
      print("C: stream finished.")
      self.exitIfDone()
    }
    print("------")
    waitForExit()
  }
  
  
  func testConcat() {
    enableRunLoop() // pipe requires async
    
    let fix = "Hello World"
    let src = fix.characters.readableSource().readable()
    
    src | concat { data in
      print("Got data: \(data)")
      XCTAssertEqual(data, Array(fix.characters))
      self.exitIfDone()
    }
    
    waitForExit()
  }
  
  
  func testBasicStream() {
    enableRunLoop() // pipe requires async
    
    let rs = Readable<UInt8>()
    rs.push("beep ")
    rs.push("boop\n")
    rs.push(nil)
    rs | utf8 | concat { res in
      let s = String(res)
      XCTAssertEqual(s, "beep boop\n")
      self.exitIfDone()
    }
    
    waitForExit()
  }
  
  func testBasicPullStream() {
    enableRunLoop() // pipe requires async
    
    let rs = Readable<UInt8>()
    
    var c : UInt8 = 97
    rs._read {
      let cZ : UInt8 = 122
      XCTAssert(c <= cZ) // doesn't stop because it runs in a different thread?
      assert(c <= cZ)
      
      rs.push([c])
      
      c += 1
      if c > cZ /* 'z' */ {
        rs.push(nil)
      }
    }
    rs.onError { err in
      XCTAssertNil(err)
    }
    
    let s = rs | utf8 | concat { res in
      let s = String(res)
      XCTAssertEqual(s, "abcdefghijklmnopqrstuvwxyz")
      self.exitIfDone()
    }

    s.onError { err in
      XCTAssertNil(err)
    }
    
    waitForExit()
  }
  
  func testBasicWriteStream() {
    enableRunLoop() // pipe requires async
    
    var chunks = [ UInt8 ]()

    let ws = Writable<UInt8>()
    ws._write { chunk, done in
      chunks.append(contentsOf: chunk)
      done(nil)
    }
    ws.onFinish {
      XCTAssertEqual(chunks,
                     [ 104, 101, 108, 108, 111, 32, 119, 111, 114, 108, 100 ])
      self.exitIfDone()
    }
    
    "hello world" | ws
    
    waitForExit()
  }
}
