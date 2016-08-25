//
//  NozeIOTests.swift
//  NozeIOTests
//
//  Created by Helge Hess on 08/07/15.
//  Copyright © 2015 ZeeZide GmbH. All rights reserved.
//

import XCTest

@testable import streams
@testable import fs
@testable import process

class NozeIOPipeTests: NozeIOTestCase {

  // TODO: this sometimes fails/hangs. Maybe Xcode stdout issue?
  func testPipeEtcPasswdToStdout() throws {
    // Note: types declared just for clarity
    let fn        = "/etc/passwd"
    let inStream  : SourceStream<FileSource>   = fs.createReadStream(fn)
    let outStream : TargetStream<StdOutTarget> = process.stdout
    
    impTestPipe(inStream, outStream)
  }
  
  func testPipeEtcPasswdToDevNull() {
    impTestPipe(fs.createReadStream("/etc/passwd"),
                fs.createWriteStream("/dev/null"))
  }
  
#if swift(>=3.0) // #swift3-1st-kwarg
  private func impTestPipe<TI: GReadableStreamType, TO: GWritableStreamType
                           where TI.ReadType == TO.WriteType>
                (_ src: TI, _ dest: TO)
  {
    impTestPipe(src: src, dest)
  }
#endif
  private func impTestPipe<TI: GReadableStreamType, TO: GWritableStreamType
                           where TI.ReadType == TO.WriteType>
                (src: TI, _ dest: TO)
  {
    enableRunLoop()
    
    _ = src.pipe(dest)
    
    _ = dest.onFinish {
      // Note: I don't think this is called for stdout. That is the issue
      self.exitIfDone()
    }
    _ = src.onEnd {
      // This is not quite right, but a workaround for onFinish not being
      // called ...
      self.exitIfDone()
    }
    
    waitForExit()
  }


#if os(Linux)
  static var allTests = {
    return [
      ( "testPipeEtcPasswdToStdout",  testPipeEtcPasswdToStdout  ),
      ( "testPipeEtcPasswdToDevNull", testPipeEtcPasswdToDevNull ),
    ]
  }()
#endif
}
