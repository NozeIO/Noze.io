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
public class HTTPMessageWrapper : WritableByteStreamWrapper {
  // TODO: trailers
  // TODO: setTimeout(msecs, cb)
  
  public var extra = [ String : Any ]()
  
  override public init(_ stream: WritableByteStreamType) {
    super.init(stream)
  }
  override public init() {
    super.init()
  }
  
  public var headersSent   = false
  public var sendDate      = true
  
  func _primaryWriteIntro() {
    fatalError("subclasses need to override _primaryWriteIntro ...")
  }
  
  func _primaryWriteHTTPMessageHead() {
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
  
  public func writeContinue() {
    // could/should be converted to a static brigade
    _ = self.write("HTTP/1.1 100 Continue\r\n\r\n")
  }
  
  
  // MARK: - Headers

  var headers = Dictionary<String, Any>()
  
  public func setHeader(name: String, _ value: Any) {
    headers[ci: name] = value
  }
  public func removeHeader(name: String) {
    _ = headers.removeValueForKey(ci: name)
  }
  public func getHeader(name: String) -> Any? {
    return headers[ci: name]
  }
  
  // TODO: events: finish, close(terminated before end() was called)
  
  // MARK: - GWritableStreamType

  override public func writev(buckets c: [ [ UInt8 ] ], done: DoneCB?) -> Bool {
    if !headersSent { _primaryWriteHTTPMessageHead() }
    return super.writev(buckets: c, done: done)
  }
  
  override public func end() {
    if !headersSent { _primaryWriteHTTPMessageHead() }
    
    // TODO: emit trailers? (only on chunked/HTTP 1.1)
    // TODO: if we do keep-alive, we don't necessarily need to close the socket!
    super.end()
  }
}


// MARK: - Swift 3 Helpers

#if swift(>=3.0) // #swift3-1st-arg
public extension HTTPMessageWrapper {
  // In this case we really want those non-kwarg methods.
  
  public func setHeader(_ name: String, _ value: Any) {
    setHeader(name: name, value)
  }
  
  public func removeHeader(_ name: String) {
    removeHeader(name: name)
  }
  
  public func getHeader(_ name: String) -> Any? {
    return getHeader(name: name)
  }
}
#endif
