//
//  Module.swift
//  Noze.io
//
//  Created by Helge Heß on 4/3/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import core
@_exported import connect

public class NozeExpress : NozeModule {
}

public var module = NozeExpress()

// See https://bugs.swift.org/browse/SR-2907, this is really an:
// #if swift(>=3.0.1) (which doesn't work :-).
// Once Xcode 8.0.1 is out, we can drop this.
#if os(Linux)
  public func express(middleware: Middleware...) -> Express {
    let app = Express()
    
    for m in middleware {
      _ = app.use(m)
    }
    
    return app
  }
#else
  public func express(middleware: @escaping Middleware...) -> Express {
    let app = Express()
    
    for m in middleware {
      _ = app.use(m)
    }
    
    return app
  }
#endif
