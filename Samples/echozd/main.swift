// Noze.io Echo Daemon
// - to compile in Swift 3 invoke: swift build
// - to run result: .build/debug/echozd

import net

net.createServer { sock in
    print("# accepted socket.")
    sock.write("Welcome to Noze.io!\r\n")
    sock
      | utf8
      | through2 { chunk, push, end in
          end(nil, chunk.map {
            if      $0 == "s" { return "z" }
            else if $0 == "S" { return "Z" }
            else { return $0 }
          })
        }
      | toUTF8
      | sock
  }
  .listen(1337) { address in print("echod: running \(address)") }
