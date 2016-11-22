import XCTest


@testable import base64Tests
@testable import child_processTests
@testable import cryptoTests
@testable import dnsTests
@testable import fsTests
@testable import http_parserTests
@testable import httpTests
@testable import jsonTests
@testable import leftpadTests
@testable import mustacheTests
@testable import netTests
@testable import streamsTests
@testable import xsysTests


let tests = [
  // base64
  testCase(Base64Tests.allTests),

  // childProcess
  testCase(ChildProcessTests.allTests),

  // crypto
  testCase(MD5Tests.allTests),

  // dns
  testCase(DNSTests.allTests),

  // fs
  testCase(FileSourceTests.allTests),
  testCase(FileSystemTests.allTests),
  testCase(PipeTests.allTests),
  testCase(ReadDirTests.allTests),
  // testCase(StdinTests.allTests),
  testCase(StdoutTests.allTests),

  // httpParser
  testCase(HTTPParserTests.allTests),

  // http
  testCase(BasicAuthTests.allTests),
  testCase(HttpClientTests.allTests),
  testCase(URLTests.allTests),

  // json
  testCase(JSONModuleTests.allTests),

  // leftpad
  testCase(LeftPadTests.allTests),

  // mustache
  testCase(MustacheTests.allTests),

  // net
  testCase(ServerTests.allTests),
  testCase(SocketTests.allTests),

  // streams
  testCase(BasicAsyncTests.allTests),
  testCase(BasicTests.allTests),
  testCase(EventsTests.allTests),
  testCase(ReadableTests.allTests),
  testCase(StringDecoderTests.allTests),
  testCase(TransformTests.allTests),

  // xsys
  testCase(XSysTests.allTests),
]

XCTMain(tests)

