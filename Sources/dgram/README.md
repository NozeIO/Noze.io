# Noze.io UDP / Datagram module

An UDP/datagram socket module modelled after the builtin Node
[dgram module](https://nodejs.org/api/dgram.html).

### Example

Small UDP server which echos back packets it receives:

```Swift
import dgram

sock = dgram.createSocket()
sock
  .onMessage   { (msg, from) in
    sock.send(msg, to: from) // echo back
  }
  .bind(1337)
```

You can test that on Linux using

    nc.openbsd -u localhost 1337

and on macOS via

    nc -vu4 localhost 1337


### TODO

- [ ] make the Datagram socket a proper stream (e.g. a
      `Duplex<Datagram,Datagram>`)
- [ ] sends are blocking and not queued

### Who

Noze.io is brought to you by
[The Always Right Institute](http://www.alwaysrightinstitute.com)
and
[ZeeZide](http://zeezide.de).

The `dgram` module was contributed by 
[David Lichteblau](https://github.com/lichtblau).
