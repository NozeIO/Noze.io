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

class NozeIOBasicTests: XCTestCase {
  
  // MARK: - Simple Tests which need no run loop
  
  func testNumberPrinter() throws {
    // Use XCTAssert and related functions to verify your tests produce the
    // correct results.
    let Q      = core.Q
    let writer = NumberPrinter()
    
    writer.writev(queue: Q, chunks: [ [ 10 ] ] ) { _, _ in
      writer.writev(queue: Q, chunks: [ [ 41, 42 ] ] ) { _, _ in }
    }
    print("------")
  }
  
  func testSinkTarget() {
    let Q      = core.Q
    var target = SyncSinkTarget<NumberPrinter>(NumberPrinter())
    
    target.writev(queue: Q, chunks: [ [ 10 ] ] ) { _, writeCount in
      print("   * wrote: \(writeCount)")
      target.writev(queue: Q, chunks: [ [ 41, 42 ] ] ) { _, writeCount in
        print("   * wrote: \(writeCount)")
      }
    }
    print("------")
  }
  
  func testStringUTF8Generator() {
    let fix      = "Hello World"
    let src      = fix.utf8.readableSource().readable()
    var readData = Array<UInt8>()
    
    // FIXME: this is reordering (NOT loosing!) stuff at the HWM(5!) boundary.
    
    // Note: Not quite sure whether this is supposed to work. It only really
    //       can with sync streams as the read buffer might be empty (and need
    //       an async read). Hence read() can return nil w/o EOF being hit.
    while let bucket = src.read() {
      print("Got bucket: \(bucket)")
      readData += bucket
    }
    
    print("lbucket: \(readData)")
    XCTAssertEqual(readData.count, 11)
    XCTAssertEqual(readData, Array(fix.utf8))
  }
  
  func testStringCharacterGenerator() {
    let fix      = "Hello World"
    #if swift(>=3.2)
      let src    = fix.readableSource().readable()
    #else
      let src    = fix.characters.readableSource().readable()
    #endif
    var readData = Array<Character>()
    
    // Note: Not quite sure whether this is supposed to work. It only really
    //       can with sync streams as the read buffer might be empty (and need
    //       an async read). Hence read() can return nil w/o EOF being hit.
    while let bucket = src.read() {
      print("Got bucket: \(bucket)")
      readData += bucket
    }
    
    print("lbucket: \(readData)")
    XCTAssertEqual(readData.count, 11)
    
    // This has been seen to fail with the ' ' added to the end.
    // Some buffer fill push issue?
    #if swift(>=3.2)
      XCTAssertEqual(readData, Array(fix))
    #else
      XCTAssertEqual(readData, Array(fix.characters))
    #endif
  }
  /* This was for debugging only.
  func testStringCharacterGeneratorRepeat1000() {
    for _ in 1...1000 {
      testStringCharacterGenerator()
    }
  }
  */

#if os(Linux)
  static var allTests = {
    return [
      ( "testNumberPrinter",            testNumberPrinter            ),
      ( "testSinkTarget",               testSinkTarget               ),
      ( "testStringUTF8Generator",      testStringUTF8Generator      ),
      ( "testStringCharacterGenerator", testStringCharacterGenerator ),
    ]
  }()
#endif
}
