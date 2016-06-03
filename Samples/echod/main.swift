// Noze.io Echo Daemon
// - to compile in Swift 3 invoke: swift build
// - to run result: .build/debug/echod

import net

net.createServer { sock in
    print("# accepted socket.")
    sock.write("Welcome to Noze.io!\r\n")
    sock | sock
  }
  .listen(1337) { address in print("echod: running \(address)") }
