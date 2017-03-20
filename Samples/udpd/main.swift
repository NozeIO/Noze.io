// Noze.io UDP server
// - to compile in Swift 3 invoke: swift build
// - to run result: .build/debug/udpd
// - to try it:
//   - Linux: nc.openbsd -u <interface> 10000
//   - macOS: nc -vu4 localhost 10000

import Foundation // for String/Data
import dgram
import console

let sock = dgram.createSocket()
sock
  .onListening { address in console.info ("dgram: bound to:", address) }
  .onError     { err     in console.error("error:", err) }
  .onMessage   { (msg, from) in
    console.log("received: \(msg) from \(from)")
    
    guard let decoded = String(data: Data(msg), encoding: .utf8) else {
      console.info("could not decode packet: \(msg)")
      return
    }
    
    console.log("  decoded:",
                decoded.replacingOccurrences(of: "\n", with: "\\n"))
    
    let packet = [UInt8](decoded.uppercased().utf8)
    console.log("  calling send on \(sock) with:", packet)
    sock.send(packet, to: from)
  }
  .bind(10000)
