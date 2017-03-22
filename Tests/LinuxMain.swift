import XCTest

let testStreams = true
let testFS      = true
let testDNS     = true
let testHTTP    = true
let testDGRAM   = true

@testable import streamsTests
@testable import leftpadTests
@testable import fsTests
@testable import dnsTests
@testable import httpTests
@testable import dgramTests

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

tests += testDGRAM ? [ // dgram
  testCase(NozeIODgramTests.allTests),
] : []

XCTMain(tests)

