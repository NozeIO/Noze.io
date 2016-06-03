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
  public func status(code: Int) -> Self {
    statusCode = code
    return self
  }
  
  /// Set the HTTP status code and send the status description as the body.
  ///
  public func sendStatus(code: Int) {
    let status = HTTPStatus(code)
    statusCode = code
    send(status.statusText)
  }
  
  
  // MARK: - Sending Content
 
  public func send(string: String) {
    if canAssignContentType {
      var ctype = string.hasPrefix("<html") ? "text/html" : "text/plain"
      ctype += "; charset=utf-8"
      setHeader("Content-Type", ctype)
    }
    
    self.end(string)
  }
  
  public func send(data: [UInt8]) {
    if canAssignContentType {
      setHeader("Content-Type", "application/octet-stream")
    }
    
    self.end(data)
  }
  
  public func send(object: JSON)          { json(object) }
  public func send(object: JSONEncodable) { json(object) }
  
  var canAssignContentType : Bool {
    return !headersSent && getHeader("Content-Type") == nil
  }
  
  public func format(handlers: [ String : () -> () ]) {
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
  
  public func get(header: String) -> Any? {
    return getHeader(header)
  }
  public func set(header: String, _ value: Any?) {
    return setHeader(header, value)
  }
}


#if swift(>=3.0) // #swift3-1st-kwarg
public extension ServerResponse {
  
  /// Set the HTTP status, returns self
  ///
  /// Example:
  ///
  ///     res.status(404).send("didn't find it")
  ///
  @discardableResult
  public func status(_ code: Int) -> Self {
    return status(code: code)
  }
  
  /// Set the HTTP status code and send the status description as the body.
  ///
  public func sendStatus(_ code: Int) { sendStatus(code: code) }
  
  public func send(_ string: String)        { send(string: string) }
  public func send(_ data:  [UInt8])        { send(data:   data)   }
  public func send(_ object: JSON)          { send(object: object) }
  public func send(_ object: JSONEncodable) { send(object: object) }

  public func get(_ header: String)   -> Any?  { return get(header: header) }
  public func set(_ header: String, _ v: Any?) { set(header: header, v) }
}
#endif // Swift 3
