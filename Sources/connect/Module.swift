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

public func connect(middleware: Middleware...) -> Connect {
  let app = Connect()
  
  for m in middleware {
    _ = app.use(m)
  }
  
  return app
}
