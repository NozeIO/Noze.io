# Noze.io UDP / Datagram module

An UDP/Datagram Sockets module modelled after the builtin Node
[dgram module](https://nodejs.org/api/dgram.html).

### Example

```Swift
import Foundation // for String/Data
import dgram
import console

let sock = dgram.createSocket()
sock
  .onListening { address in console.info ("dgram: bound to:", address) }
  .onError     { err     in console.error("error:", err) }
  .onMessage   { (msg, from) in
    sock.send(msg, to: from) // Echo back
  }
  .bind(10000)
```

### TODO

- [ ] make the Datagram socket a proper stream (e.g. Duplex<Datagram,Datagram>)
- [ ] sends are blocking and are not enqueued

### Who

Noze.io is brought to you by
[The Always Right Institute](http://www.alwaysrightinstitute.com)
and
[ZeeZide](http://zeezide.de).

The `dgram` module was contributed by 
[David Lichteblau](https://github.com/lichtblau).
