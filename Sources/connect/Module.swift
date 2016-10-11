//
//  Module.swift
//  Noze.io
//
//  Created by Helge Heß on 4/3/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

@_exported import core
@_exported import streams

public struct NozeConnect : NozeModule {
}

public var module = NozeConnect()

// See https://bugs.swift.org/browse/SR-2907, this is really an:
// #if swift(>=3.0.1) (which doesn't work :-).
// Once Xcode 8.0.1 is out, we can drop this.
#if os(Linux)
  public func connect(middleware: Middleware...) -> Connect {
    let app = Connect()
    
    for m in middleware {
      _ = app.use(m)
    }
    
    return app
  }
#else
  public func connect(middleware: @escaping Middleware...) -> Connect {
    let app = Connect()
    
    for m in middleware {
      _ = app.use(m)
    }
    
    return app
  }
#endif
