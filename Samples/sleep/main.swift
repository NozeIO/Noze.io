// Noze.io setTimeout example
// - to compile in Swift 3 invoke: swift build
// - to run result: .build/debug/sleep 2

#if os(Linux)
  import Glibc  // for exit()
#else
  import Darwin // for exit()
#endif

import core

#if swift(>=3.0) // #swift3-fd
#else
typealias CommandLine = Process
#endif

if CommandLine.argc < 2 {
  print("usage: \(CommandLine.arguments[0]) seconds")
  exit(42)
}

// scientifically tested runtime of this program
let ownRuntime = 113

if let seconds = Int(CommandLine.arguments[1]) {
  setTimeout(seconds * 1000 - ownRuntime) {}
}
