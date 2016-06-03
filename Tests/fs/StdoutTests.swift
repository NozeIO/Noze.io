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
@testable import process

class NozeIOStdoutTests: NozeIOTestCase {

  func testStdoutTest() throws {
    enableRunLoop()
    
    let stream = process.stdout
    assert(!stream._primaryCanEnd)
    
    efprint("C1: write(Hello) .. [\(stream.logStateInfo)]")
    var more = stream.write([ 72, 101, 108, 108, 111 ])
    efprint("C1: did write, can do more?: \(more) [\(stream.logStateInfo)]")
    
    efprint("C2: write([4,5,6]) .. [\(stream.logStateInfo)]")
    more = stream.write([ 32, 119, 111, 114, 108, 100 ])
    efprint("C2: did write, can do more?: \(more) [\(stream.logStateInfo)]")
    
    efprint("C3: end with \\n .. [\(stream.logStateInfo)]")
    stream.end([ 10 ]) {
      // a stdout stream never finishes, hence this test just needs to wait when
      // everything has been written.
      // TODO: IS THIS RIGHT, DOESN'T FEEL RIGHT :-) Only on interactive stdout?
      efprint("C6: stream-end finished writing.")
      self.exitIfDone()
    }
    efprint("C3: ended stream: [\(stream.logStateInfo)]")
    
    
    _ = stream.onError { error in
      efprint("C4: ERROR: \(error)")
      self.exitIfDone()
    }
    _ = stream.onFinish {
      efprint("C5: stream finished.")
      XCTAssert(false, "stdout should never finish?")
      // a stdout stream never finishes with the current implementation?
      self.exitIfDone()
    }
    efprint("------")
    
    waitForExit()
  }


#if os(Linux)
  static var allTests = {
    return [
      ( "testStdoutTest", testStdoutTest )
    ]
  }()
#endif
}
