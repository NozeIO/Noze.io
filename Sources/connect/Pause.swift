//
//  Pause.swift
//  Noze.io
//
//  Created by Helge Hess on 21/07/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import core

/// Middleware to simulate latency.
///
/// Pause all requests:
///
///     app.use(pause(1337)) // wait for 1337secs, then continue
///     app.get("/") { req, res in
///       res.send("Waited 1337 secs")
///     }
///
public func pause(timeout: Int, _ error: ErrorProtocol? = nil) -> Middleware {
  return { req, res, next in
    setTimeout(timeout) {
      if let error = error {
        next(error)
      }
      else {
        next()
      }
    }
  }
}

#if swift(>=3.0) // #swift3-1st-arg
public func pause(_ timeout: Int, _ error: ErrorProtocol? = nil) -> Middleware {
  return pause(timeout: timeout, error: error)
}
#endif
