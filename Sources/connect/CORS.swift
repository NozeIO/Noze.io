//
//  CORS.swift
//  Noze.io
//
//  Created by Helge Heß on 02/06/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import http

fileprivate let defaultMethods : [ HTTPMethod ] = [
  .GET, .HEAD, .POST, .DELETE, .OPTIONS, .PUT, .PATCH
]
fileprivate let defaultHeaders = [ "Accept", "Content-Type" ]

public func cors(allowOrigin  origin  : String,
                 allowHeaders headers : [ String     ]? = nil,
                 allowMethods methods : [ HTTPMethod ]? = nil)
            -> Middleware
{
  return { req, res, next in
    let sHeaders = (headers ?? defaultHeaders).joined(separator: ", ")
    let sMethods = (methods ?? defaultMethods).map { $0.method }
                                              .joined(separator: ",")
    
    res.setHeader("Access-Control-Allow-Origin",  origin)
    res.setHeader("Access-Control-Allow-Headers", sHeaders)
    res.setHeader("Access-Control-Allow-Methods", sMethods)
    
    if req.method == "OPTIONS" { // we handle the options
      // FIXME: not sure this is a good idea, should probably bubble up too      
      res.setHeader("Allow", sMethods)
      res.writeHead(200)
      res.end()
    }
    else {
      next()
    }
  }
}
