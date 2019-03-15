//
//  ServerResponse.swift
//  Noze.io
//
//  Created by Helge Heß on 6/2/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import http
import Freddy

public extension ServerResponse {
  // TODO: Would be cool: send(stream: GReadableStream), then stream.pipe(self)
  
  
  // MARK: - Status Handling
  
  /// Set the HTTP status, returns self
  ///
  /// Example:
  ///
  ///     res.status(404).send("didn't find it")
  ///
  @discardableResult
  func status(_ code: Int) -> Self {
    statusCode = code
    return self
  }
  
  /// Set the HTTP status code and send the status description as the body.
  ///
  func sendStatus(_ code: Int) {
    let status = HTTPStatus(code)
    statusCode = code
    send(status.statusText)
  }
  
  
  // MARK: - Sending Content
 
  func send(_ string: String) {
    if canAssignContentType {
      var ctype = string.hasPrefix("<html") ? "text/html" : "text/plain"
      ctype += "; charset=utf-8"
      setHeader("Content-Type", ctype)
    }
    
    self.end(string)
  }
  
  func send(_ data: [UInt8]) {
    if canAssignContentType {
      setHeader("Content-Type", "application/octet-stream")
    }
    
    self.end(data)
  }
  
  func send(_ object: JSON)          { json(object) }
  func send(_ object: JSONEncodable) { json(object) }
  
  var canAssignContentType : Bool {
    return !headersSent && getHeader("Content-Type") == nil
  }
  
  func format(handlers: [ String : () -> () ]) {
    var defaultHandler : (() -> ())? = nil
    
    guard let rq = request else {
      handlers["default"]?()
      return
    }
    
    for ( key, handler ) in handlers {
      guard key != "default" else { defaultHandler = handler; continue }
      
      if let mimeType = rq.accepts(key) {
        if canAssignContentType {
          setHeader("Content-Type", mimeType)
        }
        handler()
        return
      }
    }
    if let cb = defaultHandler { cb() }
  }
  
  
  // MARK: - Header Accessor Renames
  
  func get(_ header: String) -> Any? {
    return getHeader(header)
  }
  func set(_ header: String, _ value: Any?) {
    if let v = value {
      setHeader(header, v)
    }
    else {
      removeHeader(header)
    }
  }
}
