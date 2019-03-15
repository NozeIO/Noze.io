//
//  MiddlewareObject.swift
//  Noze.io
//
//  Created by Helge Hess on 02/06/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import http
import connect
import console

public protocol MiddlewareObject {
  
  func handle(request  req: IncomingMessage,
              response res: ServerResponse,
              next     cb:  @escaping Next)
  
}

public extension MiddlewareObject {
  
  var middleware: Middleware {
    return { req, res, cb in
      self.handle(request: req, response: res, next: cb)
    }
  }

  var requestHandler: RequestEventCB {
    return { req, res in
      self.handle(request: req, response: res) { ( args: Any... ) in 
        // essentially the final handler
        console.warn("No middleware called end: " +
                     "\(self) \(req.method) \(req.url)")
        res.writeHead(404)
        res.end()
      }
    }
  }
}
