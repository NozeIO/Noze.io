//
//  IncomingMessage.swift
//  Noze.io
//
//  Created by Helge Heß on 4/27/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import core
import streams
import events
import net
import fs

// TBD: Should we use higher-level Swift API for status/method?

public protocol IncomingMessageType : ReadableByteStreamType {

  var httpVersion   : String          { get }
  var statusCode    : Int             { get }
  var statusMessage : String?         { get }
  var method        : String          { get }
  var url           : String          { get }
  
  var headers      : [ String : Any ] { get }
  var rawHeaders   : [ String ]       { get }

  var extra        : [ String : Any ] { get set }
  
}

/// This can be both, a Request or a Response - it is a Response when it got
/// create by a client and it is a Request if it is coming from the Server.
///
open class IncomingMessage: ReadableStream<UInt8>, IncomingMessageType {
  // Note: This has an own buffer. Beware of the difference between the HTTP
  //       protocol stream (consumed by the HTTP parser) with chunked encoding
  //       an all that - and the 'body' stream. In HTTP/1.0 this could have
  //       been just the socket, but not anymore.
  
  // Node.js duplicate header handling:
  // - discard: age, authorization, content-length, content-type, etag, expires
  //            from, host, location, max-forwards, proxy-authentication,
  //            if-modified-since, if-unmodified-since, last-modified, referer,
  //            retry-after, user-agent
  // - array:   set-cookie
  // - ',':     *
  
  public var stream : ReadableByteStreamType?
  
  public var httpVersion   : String  = "1.1"
  public var statusCode    : Int     = 0   // response only
  public var statusMessage : String? = nil // response only
  public var method        : String  = ""  // Hm hm, should be `HTTPMethod?`
  public var url           : String  = ""
  
  public var headers    = Dictionary<String, Any>()
  public var rawHeaders = Array<String>()
  // TODO: trailers/rawTrailers
  
  
  /// Store extra information alongside the request. Try to use unique keys,
  /// e.g. via reverse-DNS to avoid middleware conflicts.
  public var extra = Dictionary<String, Any>()
  

  public init(_ stream: ReadableByteStreamType) {
    self.stream = stream
    super.init(highWaterMark: 10 /* TBD */)
  }
  
  // TODO
  
  // TODO: close event?
  
  // TODO: setTimeout(msecs,onTimeout)
  
  override open var logStateInfo : String {
    var s = ""
    
    if let ls = stream  {
      if let fdls = ls as? FileDescriptorStream {
        s += " sock=\(fdls.fd.fd)"
      }
      else {
        s += " stream=\(ls)"
      }
    }
    else                { s += " no-sock"          }
    
    if !method.isEmpty  { s += " " + method }
    if !url.isEmpty     { s += " " + url    }
    
    if statusCode != 0  { s += " status=\(statusCode)" }
    if let ls = statusMessage { s += " msg=\(ls)" }
    
    if !headers.isEmpty { s += " headers=#\(headers.keys.count)" }
    else                { s += " no-headers" }
    
    // append super info
    let ss = super.logStateInfo
    if !ss.isEmpty { s += " " + ss }
    return s
  }
}

public extension IncomingMessage {
  public func setHeader(_ name: String, _ value: Any) {
    headers[ci: name] = value
  }
  public func removeHeader(_ name: String) {
    _ = headers.removeValue(forCIKey: name)
  }
  public func getHeader(_ name: String) -> Any? {
    return headers[ci: name]
  }
}
