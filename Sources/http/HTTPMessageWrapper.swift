//
//  HTTPMessageWrapper.swift
//  Noze.io
//
//  Created by Helge Heß on 5/20/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import core
import streams
import events
import net

/// Base class for `ServerResponse` and `ClientRequest`, which are very similar.
///
open class HTTPMessageWrapper : WritableByteStreamWrapper {
  // TODO: trailers
  // TODO: setTimeout(msecs, cb)
  // TODO: support for chunked
  
  public var extra = [ String : Any ]()
  
  override public init(_ stream: WritableByteStreamType) {
    super.init(stream)
  }
  override public init() {
    super.init()
  }
  
  public var headersSent   = false
  public var sendDate      = true
  
  open func _primaryWriteIntro() {
    fatalError("subclasses need to override _primaryWriteIntro ...")
  }
  
  open func _primaryWriteHTTPMessageHead() {
    assert(!headersSent)
    headersSent = true
    
    if sendDate && getHeader("Date") == nil {
      let s = generateDateHeader()
      if !s.isEmpty { setHeader("Date", s) }
    }
    
    _primaryWriteIntro()
    writeHeaders(toStream: self, headers)
    
    // mark as done.
    _ = self.writev(buckets: eolBrigade, done: nil)
  }
  
  open func writeContinue() {
    // could/should be converted to a static brigade
    _ = self.write("HTTP/1.1 100 Continue\r\n\r\n")
  }
  
  
  // MARK: - Headers

  var headers = Dictionary<String, Any>()
  
  public func setHeader(_ name: String, _ value: Any) {
    headers[ci: name] = value
  }
  public func removeHeader(_ name: String) {
    _ = headers.removeValue(forCIKey: name)
  }
  public func getHeader(_ name: String) -> Any? {
    return headers[ci: name]
  }
  
  // TODO: events: finish, close(terminated before end() was called)
  
  // MARK: - GWritableStreamType

  override open func writev(buckets c: [ [ UInt8 ] ], done: DoneCB?) -> Bool {
    if !headersSent { _primaryWriteHTTPMessageHead() }
    return super.writev(buckets: c, done: done)
  }
  
  override open func end() {
    if !headersSent { _primaryWriteHTTPMessageHead() }
    
    // TODO: emit trailers? (only on chunked/HTTP 1.1)
    // TODO: if we do keep-alive, we don't necessarily need to close the socket!
    super.end()
  }
}
