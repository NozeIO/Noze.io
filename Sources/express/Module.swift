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

public func express(middleware: @escaping Middleware...) -> Express {
  let app = Express()
  
  for m in middleware {
    _ = app.use(m)
  }
  
  return app
}
