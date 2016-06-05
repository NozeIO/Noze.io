Noze.io Tests
=============

Notes 2016-05-23:

- SPM matches tests to the targets, which matters for linking. E.g. you can't
  put stuff testing `dns` into `net`, results in linking errors

- I couldn't figure out how to 'enhance' `XCTest`. Hence I had to copy
  `NozeIOTestCase.swift` to each and every test module.
  Let's use `streams/NozeIOTestCase.swift` as the master.
  - in XCode it's a single reference.

- SPM seems to allow you to test a specific class or test, but not a specific
  module?

NozeIOTestCase
==============

Noze tests often need to run with a runloop / queue. To easen that, there is
a NozeIOTestCase baseclass a test can inherit from.

A test using the runloop, needs to signal that by:

wantsRunloop += 1

and have the

waitForExit()

at the end.



Command Line Xcode
==================

Running the tests on the command line:

xcodebuild -scheme NozeIO test
