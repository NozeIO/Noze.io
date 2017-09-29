//
//  FileSystemTests.swift
//  NozeIO
//
//  Created by Helge Heß on 5/6/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import XCTest

import xsys
@testable import streams
@testable import fs

class NozeIOFileSystemTests: NozeIOTestCase {

  // MARK: - Directory
  
  func testSyncReaddir() throws {
    let entries = try? fs.readdirSync("/bin")
    XCTAssertNotNil(entries)
    XCTAssertTrue(entries!.contains("ls"))
    XCTAssertTrue(entries!.contains("pwd"))
    XCTAssertTrue(!entries!.contains(".."))
    XCTAssertTrue(!entries!.contains("."))
  }

  func testAsyncReaddir() {
    inRunloop { done in
      fs.readdir("/bin") { (error, entries) in
        XCTAssertNil(error)
        XCTAssertNotNil(entries)
        XCTAssertTrue(entries!.contains("ls"))
        XCTAssertTrue(entries!.contains("pwd"))
        done()
      }
    }
  }
  
  
  // MARK: - File Read Stream
  
  func testReadStreamConcat() {
    inRunloop { done in
      _ = fs.createReadStream("/etc/passwd") | concat { data in
        // print("read data: \(data)")
        XCTAssert(data.count > 1000) // on both, OSX&Ubuntu
        done()
      }
    }
  }
  
  func testReadStreamConcatUTF8() {
    inRunloop { done in
      _ = fs.createReadStream("/etc/passwd") | utf8 | concat { data in
        let s = String(data)
        //print("/etc/passwd: \(s)")
        
        XCTAssert(data.count > 1000) // on both, OSX&Ubuntu
        
        XCTAssert(s.contains("root:"))
        XCTAssert(s.contains("nobody:"))
        done()
      }
    }
  }
  
  func testReadStreamConcatWithErrorHandler() {
    inRunloop { done in
      let s = fs.createReadStream("/etc/passwd") | concat { data in
        // print("read data: \(data)")
        XCTAssert(data.count > 1000) // on both, OSX&Ubuntu
        done()
      }
      
      // TODO: directly attaching the error crashes swiftc (2016-05-06)
      _ = s.onError { err in
        XCTAssertTrue(false)
      }
    }
  }
  
  func testReadStreamMissingFile() {
    inRunloop { done in
      _ = fs.createReadStream("/Zzzz")
        .onReadable {
          XCTAssertTrue(false)
          done()
        }
        .onError { err in
          XCTAssertNotNil(err)
          XCTAssertTrue(err is POSIXErrorCode)
          let pe = err as! POSIXErrorCode
          XCTAssertEqual(pe, POSIXErrorCode.ENOENT)
          done()
        }
    }
  }
  
  func testReadStream404WithConcatPipe() {
    inRunloop { done in
      let s = fs.createReadStream("/Zzzz") | concat { data in
        // print("data is \(data)")
        XCTAssertEqual(data.count, 0)
        done()
      }
      // TODO: directly attaching the error crashes swiftc (2016-05-06)
      _ = s.onError { err in
        XCTAssertNotNil(err)
        XCTAssertTrue(err is PipeSourceError)
        let pipeErr = err as! PipeSourceError
        XCTAssertTrue(pipeErr.error is POSIXErrorCode)
        let pe = pipeErr.error as! POSIXErrorCode
        XCTAssertEqual(pe, POSIXErrorCode.ENOENT)
        done()
      }
    }
  }
  
  func testReadStream404WithErrHandlerConcatPipe() {
    inRunloop { done in
      let s = fs.createReadStream("/Zzzz")
        .onError { err in
          XCTAssertNotNil(err)
          XCTAssertTrue(err is POSIXErrorCode)
          let pe = err as! POSIXErrorCode
          XCTAssertEqual(pe, POSIXErrorCode.ENOENT)
        }
        | concat { data in
          // print("data is \(data)")
          XCTAssertEqual(data.count, 0)
          done()
        }
      // TODO: directly attaching the error crashes swiftc (2016-05-06)
      _ = s.onError { err in
        XCTAssertNotNil(err)
        XCTAssertTrue(err is PipeSourceError)
        let pipeErr = err as! PipeSourceError
        XCTAssertTrue(pipeErr.error is POSIXErrorCode)
        let pe = pipeErr.error as! POSIXErrorCode
        XCTAssertEqual(pe, POSIXErrorCode.ENOENT)
        done()
      }
    }
  }
  
  func testReadStream404WithNoFwdConcatPipe() {
    inRunloop { done in
      let s = fs.createReadStream("/Zzzz").pipe(concat { data in
        // print("data is \(data)")
        XCTAssertEqual(data.count, 0)
        done()
      }, passErrors: false)
      // TODO: directly attaching the error crashes swiftc (2016-05-06)
      _ = s.onError { err in
        XCTAssertNil(err) // the *concat* should not get an error
        done()
      }
    }
  }
  
  func testReadStream404WithErrHandlerNoFwdConcatPipe() {
    inRunloop { done in
      let s = fs.createReadStream("/Zzzz")
        .onError { err in
          XCTAssertNotNil(err)
          XCTAssertTrue(err is POSIXErrorCode)
          let pe = err as! POSIXErrorCode
          XCTAssertEqual(pe, POSIXErrorCode.ENOENT)
        }
        .pipe(concat { data in
          // print("data is \(data)")
          XCTAssertEqual(data.count, 0)
          done()
        }, passErrors: false)
      // TODO: directly attaching the error crashes swiftc (2016-05-06)
      _ = s.onError { err in
        XCTAssertNil(err) // the *concat* should not get an error
        done()
      }
    }
  }
  
  
  // MARK: - File Read Convenience
  
  func testReadFileBytes() {
    inRunloop { done in
      fs.readFile("/etc/passwd") { err, data in
        //print("bytes: \(data)")
        XCTAssertNotNil(data)
        XCTAssertNil(err)
        XCTAssert(data!.count > 1000) // on both, OSX&Ubuntu
        done()
      }
    }
  }
  
  func testReadFileString() {
    inRunloop { done in
      fs.readFile("/etc/passwd", "utf8") { err, s in
        //print("string: \(s)")
        XCTAssertNotNil(s)
        XCTAssertNil(err)
        XCTAssert(s!.contains("root:"))
        XCTAssert(s!.contains("nobody:"))
        done()
      }
    }
  }
  
  
  // MARK: - Temp Files
  
  func testTempFile() {
    inRunloop { done in
      _ = temp.track() // make sure the tmpfile gets deleted at process exit
      
      temp.open("nozetest-", suffix: ".tmp") { error, info in
        print("FD: \(info?.fd as Optional)")
        print("  FN: \(info?.path as Optional)")
        print("  ERROR: \(error as Optional)")
        
        XCTAssertNil(error)
        XCTAssertNotNil(info)
        
        if let info = info {
          XCTAssertTrue(info.fd.isValid)
          XCTAssertNotNil(info.path)
          
          XCTAssertTrue(info.path.hasPrefix("/tmp/nozetest-"))
          XCTAssertTrue(info.path.hasSuffix(".tmp"))
        }
        
        done()
      }
    }
  }

  func testTempStream() {
    inRunloop { done in
      _ = temp.track() // make sure the tmpfile gets deleted at process exit
      
      let stream = temp.createWriteStream("nozetest-", suffix: ".tmp")
      _ = stream.onError { error in XCTAssertTrue(false) } // unexpected error
      
      _ = stream.write("Hello World!\n")
      
      _ = stream.onceFinish {
        //print("done with writing: \(stream)")
        // we can't easily get a hold of the filename?
        done()
      }
      
      // FIXME: needs to be called after hooking up onceFinish
      //  BUG:  not sure why this would be
      stream.end()
    }
  }
  
  
  // MARK: - File Write Convenience

  func testWriteFile() {
    inRunloop { done in
      fs.writeFile("/tmp/nozetest-write-file.txt", "Hello World!\n") { error in
        XCTAssertNil(error)
        done()
      }
    }
  }
  
  
  // MARK: - Unix Funcs
  
  func testAccessOK() {
    inRunloop { done in
      fs.access("/bin") { error in
        XCTAssertNil(error)
        done()
      }
    }
  }
  
  func testAccessMissing() {
    inRunloop { done in
      fs.access("/Zeeeee") { error in
        XCTAssertNotNil(error)
        XCTAssert(error is POSIXErrorCode)
        XCTAssertEqual((error! as! POSIXErrorCode), POSIXErrorCode.ENOENT)
        done()
      }
    }
  }
  
  func testAccessWithMode() {
    inRunloop { done in
      fs.access("/bin", fs.R_OK | fs.W_OK) { error in
        XCTAssertNotNil(error)
        XCTAssert(error is POSIXErrorCode)
#if os(Linux)
        XCTAssertEqual((error! as! POSIXErrorCode), POSIXErrorCode.EACCES)
#else
        XCTAssertEqual((error! as! POSIXErrorCode), POSIXErrorCode.EPERM)
#endif
        done()
      }
    }
  }
  
  func testStat() {
    inRunloop { done in
      fs.stat("/bin") { error, stat in
        XCTAssertNil(error)
        XCTAssertNotNil(stat)
        XCTAssertTrue (stat!.isDirectory())
        XCTAssertFalse(stat!.isFile())
        XCTAssertTrue(stat!.size > 0)
        done()
      }
    }
  }


#if os(Linux)
  static var allTests = {
    return [
      ( "testSyncReaddir",           testSyncReaddir           ),
      ( "testAsyncReaddir",          testAsyncReaddir          ),
      ( "testReadStreamConcat",      testReadStreamConcat      ),
      ( "testReadStreamConcatUTF8",  testReadStreamConcatUTF8  ),
      ( "testReadStreamConcatWithErrorHandler",
         testReadStreamConcatWithErrorHandler ),
      ( "testReadStreamMissingFile",       testReadStreamMissingFile       ),
      ( "testReadStream404WithConcatPipe", testReadStream404WithConcatPipe ),
      ( "testReadStream404WithErrHandlerConcatPipe",
         testReadStream404WithErrHandlerConcatPipe ),
      ( "testReadStream404WithNoFwdConcatPipe",
         testReadStream404WithNoFwdConcatPipe ),
      ( "testReadStream404WithErrHandlerNoFwdConcatPipe",
         testReadStream404WithErrHandlerNoFwdConcatPipe ),
      ( "testReadFileBytes",  testReadFileBytes  ),
      ( "testReadFileString", testReadFileString ),
      ( "testTempFile",       testTempFile       ),
      ( "testTempStream",     testTempStream     ),
      ( "testWriteFile",      testWriteFile      ),
      ( "testAccessOK",       testAccessOK       ),
      ( "testAccessMissing",  testAccessMissing  ),
      ( "testAccessWithMode", testAccessWithMode ),
      ( "testStat",           testStat           ),
    ]
  }()
#endif
}
