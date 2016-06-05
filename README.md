<h2>Noze.io
  <img src="https://pbs.twimg.com/profile_images/725354235056017409/poiNAOlB_400x400.jpg"
       align="right" />
</h2>

![Mac OS X](https://img.shields.io/badge/os-Mac%20OS%20X-green.svg?style=flat)
![iOS](https://img.shields.io/badge/os-iOS-green.svg?style=flat)
![Linux](https://img.shields.io/badge/os-linux-green.svg?style=flat)
![MIT](https://img.shields.io/badge/license-MIT-blue.svg?style=flat)
![Travis](https://api.travis-ci.org/NozeIO/Noze.io.svg?branch=develop&style=flat)

"Das Haus das Verrückte macht."

**Noze.io** is an attempt to carry over the [Node.js](http://nodejs.org/)
ideas into *pure* [Swift](http://swift.org).
It uses [libdispatch](https://github.com/apple/swift-corelibs-libdispatch)
for event-driven, non-blocking I/O.
**Noze.io** is built around type-safe back-pressure aware pull-streams
(using Swift generics)
operating on batches of items. Instead of just operating on bytes,
operate on batches of Unicode lines or database records or HTML
responses or - you get the idea.
Be efficient: Stream everything and ßatch.

A focus is to keep the API similar to Node. Not always possible -
Swift is not JavaScript - but pretty close.
It comes with rechargeables included, **Noze.io** is self-contained and
doesn't require any extra dependencies.

**Noze.io** works in Cocoa environments as well as on Linux,
and it works with Swift 2.2 as well as the latest Swift 3 drop.
In fact we suggest 2.2 until Swift 3 is actually released.

*Is it a good idea?* You [tell us](http://noze.io/about/).
Not sure, but we think it might be, because:
*a)* While Swift looks *very* much like JavaScript, it is actually a very
high performance statically typed and AOT-compiled language,
*b)* Code often looks better in Swift, mostly due to trailing-closure syntax,
*c)* No monkey patching while still providing extensions.
~~There are cons too.~~

#### Shows us some code!

There is a reasonably large collection of simple, focused:
[Noze.io examples](https://github.com/NozeIO/Noze.io/tree/master/Samples)
But here you go, the "standard" Node example, a HelloWorld httpd:

    import http

    http.createServer { req, res in 
        res.writeHead(200, [ "Content-Type": "text/html" ])
        res.end("&lt;h1&gt;Hello World&lt;/h1&gt;")
      }
      .listen(1337)

An echo daemon, just piping the in-end of a socket into its own-out end:

    import net

    net.createServer { sock in
        sock.write("Welcome to Noze.io!\r\n")
        sock | sock
      }
      .listen(1337)

More complex stuff including a Todo-MVC backend can be found in the
[Noze.io examples](https://github.com/NozeIO/Noze.io/tree/master/Samples).
Like what you see? Head over to our [Start page](http://noze.io/start/)
to get started.

### Contact

Hey, we love feedback. Join the mailing list, Slack channel or just drop us
an email to tell us why this is crap (or not?).

- [Mailing List](https://groups.google.com/forum/#!forum/nozeio)
- [Slack](https://nozeio.slack.com)
- [info@noze.io](mailto:info@noze.io)

### Status

- We chose the traditional Swift approach:
  Make something barely usable, though demoable,
  and release it with a 2.0 version tag.
  Then hope that the community kicks in and fills open spots.
  Well kinda. It's pretty good already! 😉

- It already has
  [leftpad](https://github.com/NozeIO/Noze.io/tree/develop/Sources/leftpad).

- Implements primarily the happy path. Errors will error. Presumably this
  will improve over time.

- A huge strength of Node is the npm package environment and the
  <a href="http://heathersfilm.tripod.com/script.txt" target="ext">myriad</a>s 
  of packages available for it.
  Or wait, is it? Well, at least we have
  [leftpad](https://github.com/NozeIO/Noze.io/tree/develop/Sources/leftpad)
  included.
  And we hope that the [Swift package](https://swift.org/package-manager/)
  environment is going to grow as well.

- There are tons of open ends in Noze.io. We welcome contributions of all kinds.

### Who

Noze.io is brought to you by
[The Always Right Institute](http://www.alwaysrightinstitute.com)
and
[ZeeZide](http://zeezide.de).
We wouldn't be sad if more people would like to join the effort :-)
