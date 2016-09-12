//
//  StringDecoderTests.swift
//  NozeIO
//
//  Created by Helge Heß on 5/1/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import XCTest

@testable import streams

class NozeIOStringDecoderTests: NozeIOTestCase {
  
  func testSimpleDecode() throws {
    enableRunLoop() // pipes need runloops, that's why.

    var s : String? = nil
    
    [ 90, 101, 101 ] | utf8 | concat { data in
      //print("Data: \(data)")
      XCTAssert(data.count == 3)
      s = String(data)
      self.exitIfDone()
    }
    
    waitForExit()
    
    XCTAssertNotNil(s)
    XCTAssertEqual(s, "Zee")
  }
  
  func testSzDecode() {
    enableRunLoop() // pipes need runloops, that's why.
    
    var s : String? = nil
    
    [ 0x48, 0x65, 0xC3, 0x9F ] | utf8 | concat { data in
      //print("Data: \(data)")
      XCTAssert(data.count == 3)
      s = String(data)
      self.exitIfDone()
    }
    
    waitForExit()
    
    XCTAssertNotNil(s)
    XCTAssertEqual(s, "Heß")
  }
  
  private final func _testReadLines(_ input: String, _ expectedLines: [String])
  {
    enableRunLoop() // pipes need runloops, that's why.
    
    input.utf8
      | readlines.onError { error in
          print("catched error: \(error)")
          XCTAssertNil(error)
        }
      | concat { lines in
          //print("Lines: \(lines)")
          XCTAssertEqual(lines.count, expectedLines.count)
          XCTAssertEqual(lines, expectedLines)
          self.exitIfDone()
        }
    
    waitForExit()
  }
  
  func testReadlines() {
    _testReadLines("Hello\nWorld", [ "Hello", "World" ])
  }
  func testManyReadlines() {
    for i in 0..<50 {
      _testReadLines("Hello\nWorld\(i)", [ "Hello", "World\(i)" ])
    }
  }
  func testEmptyReadLines()      { _testReadLines("", [ ])      }
  func testSingleEmptyReadLine() { _testReadLines("\n", [ "" ]) }
  func testManyEmptyReadLines()  { _testReadLines("\n\n\n\n", [ "","","","" ]) }
  
  func testLeadingReadLines() {
    _testReadLines("\nHello\nWorld", [ "", "Hello", "World" ])
  }
  func testTrailingReadLines() {
    _testReadLines("Hello\nWorld\n", [ "Hello", "World" ])
  }
  func testTrailingReadLines2() {
    _testReadLines("Hello\nWorld\n\n", [ "Hello", "World", "" ])
  }

  func testTrailingReadLinesCR() {
    _testReadLines("Hello\r\nWorld\r\n\r\n", [ "Hello", "World", "" ])
  }
  func testTrailingReadLinesExtraCR() {
    _testReadLines("Hello\nWorld\r\r\r\n",   [ "Hello", "World\r\r" ])
  }
  func testTrailingReadLinesTrailingCR() {
    // This one breaks the rule that the \r needs to be followed by a \n to be
    // removed. But well.
    _testReadLines("Hello\nWorld\r\n\r",     [ "Hello", "World", "" ])
  }
  
  func testUnique() {
    enableRunLoop() // pipes need runloops, that's why.
    
    let input = "Hello\nWorld\nNice\nHello\nHello\nWorld\n"
    
    input.utf8
      | readlines
      | uniq
      | concat { lines in
          //print("Lines: \(lines)")
          XCTAssertEqual(lines.count, 3)
          XCTAssertEqual(lines, [ "Hello", "World", "Nice" ])
          self.exitIfDone()
        }
    
    waitForExit()
  }

#if os(Linux)
  static var allTests = {
    return [
      ( "testSimpleDecode",                testSimpleDecode                ),
      ( "testSzDecode",                    testSzDecode                    ),
      ( "testReadlines",                   testReadlines                   ),
      ( "testManyReadlines",               testManyReadlines               ),
      ( "testEmptyReadLines",              testEmptyReadLines              ),
      ( "testSingleEmptyReadLine",         testSingleEmptyReadLine         ),
      ( "testManyEmptyReadLines",          testManyEmptyReadLines          ),
      ( "testLeadingReadLines",            testLeadingReadLines            ),
      ( "testTrailingReadLines",           testTrailingReadLines           ),
      ( "testTrailingReadLines2",          testTrailingReadLines2          ),
      ( "testTrailingReadLinesCR",         testTrailingReadLinesCR         ),
      ( "testTrailingReadLinesExtraCR",    testTrailingReadLinesExtraCR    ),
      ( "testTrailingReadLinesTrailingCR", testTrailingReadLinesTrailingCR ),
      ( "testUnique",                      testUnique ),
    ]
  }()
#endif

}
