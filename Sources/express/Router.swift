//
//  Router.swift
//  Noze.io
//
//  Created by Helge Heß on 6/2/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

// A Route itself now can do everything a Router could do before (most
// importantly it can hold an array of middleware)
public typealias Router = Route

public extension Router {
  
  public convenience init(id: String? = nil, _ pattern: String? = nil,
                          _ middleware: Middleware...)
  {
    self.init(id: id, pattern: pattern, method: nil,
              middleware: middleware.map({ .middleware($0) }))
  }
  
}
