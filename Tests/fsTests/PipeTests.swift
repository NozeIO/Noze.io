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
    // TODO: revert when done
    print("PIPE TEST pwd-to-null")
    let pwd     = fs.createReadStream("/etc/passwd")
    let devNull = fs.createWriteStream("/dev/null")
    print("  target: \(devNull)")
    impTestPipe(pwd,
                devNull)
  }
  
  private func impTestPipe<TI: GReadableStreamType, TO: GWritableStreamType>
               (_ src: TI, _ dest: TO)
                           where TI.ReadType == TO.WriteType
  {
    enableRunLoop()
    
    print("PIPE: \(src) to \(dest)")
    _ = src.pipe(dest)
    
    _ = dest.onFinish {
      // Note: I don't think this is called for stdout. That is the issue
      print("  on dest finish")
      self.exitIfDone()
    }
    _ = src.onEnd {
      // This is not quite right, but a workaround for onFinish not being
      // called ...
      print("  on src end")
      self.exitIfDone()
    }
    
    print("WAIT")
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
