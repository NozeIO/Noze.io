# Crypto Module

At this time the module just provides an MD5 hash which can be either used
directly or as a transform stream.

The current implementation is build on top of the excellent
[CryptoSwift](https://github.com/krzyzanowskim/CryptoSwift)
framework by [Marcin Krzyżanowski](mailto:marcin@krzyzanowskim.com).


## Examples

Direct call example:
    
    let hash = crypto.createHash("md5")!
    hash.update(string.utf8)
    let result = hash.digest("hex")

Stream example:

    let md5 = crypto.createHash("md5")!
    
    "Hello World".utf8 | md5 | concat { hash in
      let result = hash.joined().toString("hex")!
    }

Note that Noze.io always returns batches of objects - in this case it is a batch
of just one hash :-) To flatten that, the `.joined()` method is used.
