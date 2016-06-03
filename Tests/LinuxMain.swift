import XCTest

let testStreams = true
let testFS      = true
let testDNS     = true
let testHTTP    = true

@testable import streamsTestSuite
@testable import leftpadTestSuite
@testable import fsTestSuite
@testable import dnsTestSuite
@testable import httpTestSuite

var tests = [ // leftpad
  testCase(NozeIOLeftPadTests.allTests),
]

tests += testStreams ? [ // streams
  testCase(NozeIOBasicTests.allTests),
  testCase(NozeIOStringDecoderTests.allTests),
  testCase(NozeIOTransformTests.allTests),
] : []

tests += testFS ? [ // fs
  testCase(NozeIOFileSourceTests.allTests),
  testCase(NozeIOFileSystemTests.allTests),
  testCase(NozeIOPipeTests.allTests),
  testCase(NozeReaddirTests.allTests),
  testCase(NozeIOStdoutTests.allTests),
] : []

tests += testDNS ? [ // dns
  testCase(NozeIODNSTests.allTests),
] : []

tests += testHTTP ? [ // http
  testCase(NozeIOURLTests.allTests),
  testCase(NozeIOHttpClientTests.allTests),
] : []

XCTMain(tests)

