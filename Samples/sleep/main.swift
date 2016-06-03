// Noze.io setTimeout example
// - to compile in Swift 3 invoke: swift build
// - to run result: .build/debug/sleep 2

#if os(Linux)
  import Glibc  // for exit()
#else
  import Darwin // for exit()
#endif

import core

if Process.argc < 2 {
  print("usage: \(Process.arguments[0]) seconds")
  exit(42)
}

// scientifically tested runtime of this program
let ownRuntime = 113

if let seconds = Int(Process.arguments[1]) {
  setTimeout(seconds * 1000 - ownRuntime) {}
}
