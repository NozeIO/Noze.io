//
//  MethodOverride.swift
//  Noze.io
//
//  Created by Helge Heß on 5/31/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import console

public func methodOverride(header  : String = "X-HTTP-Method-Override",
                           methods : [ String ] = [ "POST" ])
            -> Middleware
{
  return { req, res, next in
    // TODO: support query values
    
    guard methods.contains(req.method)     else { return try next() }
    guard let hv = req.headers[ci: header] else { return try next() }
    
    guard let hvs = (hv as? String) else {
      console.error("Override \(header) is not a string?: \(hv)")
      return try next()
    }
    
    // patch method and continue
    req.method = hvs
    return try next()
  }
}
