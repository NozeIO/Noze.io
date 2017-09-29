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

// Note: @escaping for 3.0.0 compat, not intended as per SR-2907
#if swift(>=4.0) // HH
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

