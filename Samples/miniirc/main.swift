// Noze.io Minimal IRC Daemon
// - to compile in Swift 3 invoke: swift build
// - to run result: .build/debug/miniirc

import net

net.createServer { sock in
    print("# accepted socket.")
    let _ = Session(socket: sock)
  }
  .listen(6667) { address in print("miniirc: running \(address)") }
