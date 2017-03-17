// Noze.io UDP server
// - to compile in Swift 3 invoke: swift build
// - to run result: .build/debug/udpd
// - to try it: nc.openbsd -u <interface> 10000

import Foundation
import dgram
import net
import xsys

let sock = dgram.createSocket()
sock
  .onListening { address in print("dgram: bound to \(address)") }
  .onError { err in print("error: \(err)") }
  .onMessage { (msg, from) in
    print("received: \(msg) from \(from)")
    if let decoded = String(data: Data(msg), encoding: .utf8) {
      print("decoded: \(decoded)")
      print("calling send on \(sock) with \([UInt8](decoded.uppercased().utf8))")
      sock.send([UInt8](decoded.uppercased().utf8), to: from)
    }
  }
  .bind(10000)
