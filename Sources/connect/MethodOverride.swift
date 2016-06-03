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
    
    guard methods.contains(req.method)     else { next(); return }
    guard let hv = req.headers[ci: header] else { next(); return }
    
    guard let hvs = (hv as? String) else {
      console.error("Override \(header) is not a string?: \(hv)")
      next()
      return
    }
    
    // patch method and continue
    req.method = hvs
    next()
  }
}
