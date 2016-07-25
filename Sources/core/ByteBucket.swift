//
//  ByteBucket.swift
//  Noze.io
//
//  Created by Helge Heß on 4/10/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

// TODO: Allow other stuff as ByteBuckets, e.g. file handles and such.
//       What we want is to be able to use sendfile() if a ByteBucket
//       reader/writer support that.
// Example: An HTTP server which can add a header and a footer to a file, which
//          is otherwise kept identical. In this case we would want a bucket
//          brigade like this:
//            [ "header", FileByteBucket("test.html"), "footer" ]
//          which would result int:
//            send(fd, "header")
//            sendfile(fd, inBucket.fd)
//            send(fd, "footer")
//          you get the idea :-)
// Example: directly use dispatch_data w/o copying ...

public typealias ByteBucket = [ UInt8 ]
