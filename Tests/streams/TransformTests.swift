//
//  NozeIOTransformTests.swift
//  NozeIO
//
//  Created by Helge Hess on 22/04/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import XCTest

import xsys
@testable import streams

private let heavyLog = false

class NozeIOTransformTests: NozeIOTestCase {
  
  private static func strlen(s: String) -> Int {
    return s.characters.count
  }
  
  func testSimpleNoopTransformSpecializeByType() throws {
    enableRunLoop() // pipe requires async
    
    let fix = "Hello World"
    let src = fix.characters.readableSource().readable()
    
    var collectResult = ""
    
    // When we don't provide an explicit type:
    //   Error: TReadItem cannot be inferred
    //   but it should work? Done is specializing `ReadBucketType`?
    let ts = Transform<Character, Character> { chunk, _, done in
      if heavyLog {
        print("TNOP: transform got chunk \(chunk) #\(chunk.count): " +
              "fix=#\(strlen(fix)) / had=#\(strlen(collectResult))")
      }
      
      collectResult += String(chunk)
      
      if heavyLog {
        print("      got=#\(strlen(collectResult))")
      }
      
      done(nil, chunk) // just done with that one chunk!
        // this should declare the generic output type to be Character ...
    }
    
    ts.onFinish {
      if heavyLog {
        print("Finished: \(ts)")
      }
      self.exitIfDone()
    }
    
    src.pipe(ts)
    
    waitForExit()
    
    if heavyLog { print("TNOP: DONE: \(collectResult)") }
    XCTAssertEqual(fix, collectResult)
  }
  
  func testSimpleUpperTransformSpecializeByType() {
    enableRunLoop() // pipe requires async
    
    let fix = "Hello World"
    let src = fix.characters.readableSource().readable()

    var collectResult = ""
    
    let ts = Transform<Character, Character> { chunk, _, done in
      if heavyLog { print("TTUU: transform got chunk \(chunk)") }
      let upperChunk = String(chunk).uppercased()
      collectResult += upperChunk
      done(nil, Array<Character>(upperChunk.characters))
    }
    ts.onFinish { self.exitIfDone() }
    
    src.pipe(ts)
    
    waitForExit()
    
    if heavyLog { print("TTUU: DONE: \(collectResult)") }
    XCTAssertEqual(fix.uppercased(), collectResult)
  }
  
  func testSimpleTransformConcat() {
    enableRunLoop() // pipe requires async
    
    let fix = "Hello World"
    let src = fix.characters.readableSource().readable()
   
    // When we don't provide an explicit type:
    //   Error: TReadItem cannot be inferred
    //   but it should work? Done is specializing `ReadBucketType`?
    let ts : Transform<Character, Character> = Transform { chunk, _, done in
      if heavyLog { print("TTTT: transform got chunk \(chunk)") }
      
      //done(nil, String(chunk).uppercaseString())
      
      done(nil, chunk)
        // this declares the generic output type to be the same like chunk
    }
    
    var concatData : [ Character ]? = nil
    
    src | ts | concat { data in
      if heavyLog { print("TTTT: got data: \(data)") }
      concatData = data
      self.exitIfDone()
    }
    
    waitForExit()
    XCTAssertNotNil(concatData)
    XCTAssertEqual(concatData!, Array(fix.characters))
  }
  
  func testSimpleTransformDoubleConcat() {
    enableRunLoop() // pipe requires async
    
    let fix = "Hello World"
    let src = fix.characters.readableSource().readable()
    
    var concatData : [ Character ]? = nil
    
    src | through2 { chunk, push, done in
            // double the chunks (NOT the string!)
            if heavyLog { print("TT22: transform got chunk \(chunk)") }
            push(chunk)
            done(nil, chunk)
          }
        | concat { concatData = $0; self.exitIfDone() }
    
    waitForExit()
    
    if heavyLog { print("TT22: got data \(concatData)") }
    XCTAssertNotNil(concatData)
    XCTAssertEqual(concatData!.count, fix.characters.count * 2)
  }

#if os(Linux)
  static var allTests = {
    return [
      ( "testSimpleNoopTransformSpecializeByType",
         testSimpleNoopTransformSpecializeByType  ),
      ( "testSimpleUpperTransformSpecializeByType",
         testSimpleUpperTransformSpecializeByType ),
      ( "testSimpleTransformConcat",
         testSimpleTransformConcat ),
      ( "testSimpleTransformDoubleConcat",
         testSimpleTransformDoubleConcat ),
    ]
  }()
#endif
}
