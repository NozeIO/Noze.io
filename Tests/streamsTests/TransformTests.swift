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

fileprivate func strlen(_ s: String) -> Int {
  #if swift(>=3.2)
    return s.count
  #else
    return s.characters.count
  #endif
}

class NozeIOTransformTests: NozeIOTestCase {
  
  func testSimpleNoopTransformSpecializeByType() throws {
    enableRunLoop() // pipe requires async
    
    let fix = "Hello World"
    #if swift(>=3.2)
      let src = fix.readableSource().readable()
    #else
      let src = fix.characters.readableSource().readable()
    #endif
    
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
    #if swift(>=3.2)
      let src = fix.readableSource().readable()
    #else
      let src = fix.characters.readableSource().readable()
    #endif

    var collectResult = ""
    
    let ts = Transform<Character, Character> { chunk, _, done in
      if heavyLog { print("TTUU: transform got chunk \(chunk)") }
      let upperChunk = String(chunk).uppercased()
      collectResult += upperChunk
      #if swift(>=3.2)
        done(nil, Array<Character>(upperChunk))
      #else
        done(nil, Array<Character>(upperChunk.characters))
      #endif
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
    #if swift(>=3.2)
      let src = fix.readableSource().readable()
    #else
      let src = fix.characters.readableSource().readable()
    #endif
   
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
    #if swift(>=3.2)
      XCTAssertEqual(concatData!, Array(fix))
    #else
      XCTAssertEqual(concatData!, Array(fix.characters))
    #endif
  }
  
  func testSimpleTransformDoubleConcat() {
    enableRunLoop() // pipe requires async
    
    let fix = "Hello World"
    #if swift(>=3.2)
      let src = fix.readableSource().readable()
    #else
      let src = fix.characters.readableSource().readable()
    #endif
    
    var concatData : [ Character ]? = nil
    
    src | through2 { chunk, push, done in
            // double the chunks (NOT the string!)
            if heavyLog { print("TT22: transform got chunk \(chunk)") }
            push(chunk)
            done(nil, chunk)
          }
        | concat { concatData = $0; self.exitIfDone() }
    
    waitForExit()
    
    if heavyLog { print("TT22: got data", concatData as Any) }
    XCTAssertNotNil(concatData)
    #if swift(>=3.2)
      XCTAssertEqual(concatData!.count, fix.count * 2)
    #else
      XCTAssertEqual(concatData!.count, fix.characters.count * 2)
    #endif
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
