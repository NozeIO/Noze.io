//
//  IncomingMessageParser.swift
//  Noze.io
//
//  Created by Helge Hess on 20/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import xsys
import core
import console
import streams
import net
import enum     http_parser.HTTPError
import protocol http_parser.http_parser_settings
import struct   http_parser.http_parser

private let heavyDebug   = false
private let debugTraffic = false

/// Uses the low-level parser to construct an IncomingMessage
class IncomingMessageParser: http_parser_settings {
  // TBD: should this be a Transform stream? (too much overhead?)
  
  var parser    = http_parser() // this is per-socket
  
  enum LastCallback { case None, Field, Value, URL }
  var lastCB    = LastCallback.None
  var headers   = Dictionary<String, Any>()
  var url       = ""
  
  init() {
  }
  
  
  // MARK: - Comining Parser Callbacks
  
  typealias RequestCB  = ( String, String, String, [String : Any] ) -> Void
  typealias ResponseCB = ( Int,    String, [String : Any] ) -> Void
  typealias DoneCB     = () -> Void
  typealias DataCB     = ( [UInt8] ) -> Void
  
  var cbRequest  : RequestCB?  = nil
  var cbResponse : ResponseCB? = nil
  var cbDone     : DoneCB?     = nil
  var cbData     : DataCB?     = nil
  
  func onRequest(handler cb: RequestCB) -> Self {
    cbRequest = cb
    return self
  }
  func onResponse(handler cb: ResponseCB) -> Self {
    cbResponse = cb
    return self
  }
  /// HTTP message did complete (but Socket could be keep-alive!)
  func onDone(handler cb: DoneCB) -> Self {
    cbDone = cb
    return self
  }
  func onData(handler cb: DataCB) -> Self {
    cbData = cb
    return self
  }
  
  /// HTTP parser read a block of body data
  func push(data d: [ UInt8 ]) {
    // TODO: was message.push(d)
    cbData?(d)
  }
  
  
  // MARK: - Feed the parser
  
  func write(bucket b: [ UInt8 ]) {
    /* push to parser */
    
    if heavyDebug {
      if  debugTraffic { print("write: #\(b.count) \(b)") }
      else { print("write: #\(b.count)") }
    }
    
    let rc : xsys.size_t = b.withUnsafeBufferPointer { ptr in
      let cp = UnsafePointer<CChar>(ptr.baseAddress)
      return self.parser.execute(self, cp, b.count)
    }
    
    /* exit if parser failed */
    guard rc == b.count else {
      if heavyDebug { print("  FAIL rc: \(rc) vs \(b.count)") }
      parserFailed(error: self.parser.error)
      return
    }
  }
  func end() {
    /* push to parser */

    // print("END")
    _ = self.parser.execute(self, nil, 0)
          // Note: this can still generate events!!!
  }
  
  
  // MARK: - Low Level Parser
  
  func parserFailed(error e: HTTPError) {
    console.error("HTTP ERROR:", e)
    // TODO
    // emitDone()
  }
  
  
  let buffer   = RawByteBuffer(capacity: 100)
  var lastName : String? = nil

  func onMessageBegin(parser p: http_parser ) -> Int {
    self.lastCB = .None
    self.headers.removeAll()
    self.buffer.reset()
    return 0
  }
  func onMessageComplete(parser p: http_parser ) -> Int {
    if heavyDebug { print("on-msg complete") }
    self.cbDone?()
    return 0
  }
  func onStatus(parser p: http_parser, _ data: UnsafePointer<CChar>, _ len: size_t)
       -> Int
  {
    //assert(false) // should not be called, we are parsing a request ...
    return 0
  }
  
  func onURL(parser p: http_parser, _ data: UnsafePointer<CChar>, _ len: size_t)
       -> Int
  {
    return self.processDataCB(newState: .URL, p: data, len: len)
  }
  func onHeaderField(parser p: http_parser,
                     _ data: UnsafePointer<CChar>, _ l: size_t)
       -> Int
  {
    return self.processDataCB(newState: .Field, p: data, len: l)
  }
  func onHeaderValue(parser p: http_parser,
                     _ data: UnsafePointer<CChar>, _ l: size_t)
       -> Int
  {
    return self.processDataCB(newState: .Value, p: data, len: l)
  }
  
  func onBody(parser p: http_parser,
              _ data: UnsafePointer<CChar>, _ len: size_t)
       -> Int
  {
    // FIXME: do proper buckets. Should have a weak-bucket which copies only
    //        when it leaves the call stack.
    if heavyDebug { print("on-body: #\(len)") }
    let cp     = UnsafePointer<UInt8>(data) // hm. should onBody be UInt8?
    let buffer = UnsafeBufferPointer<UInt8>(start: cp, count:len)
    self.push(data: Array(buffer))
    return 0
  }
  
  
  final func addHeaderLine(name ln: String, value: String) {
    // FIXME: multi-value etc
    if heavyDebug { print("HEADER \(ln): \(value)") }
    headers[ci: ln] = value
  }
  
  
  // MARK: - Parsing Callbacks
  
  final func onHeadersComplete(parser p: http_parser) -> Int {
    let parser = p
    // process open ends
    var dummy : CChar = 0
    _ = processDataCB(newState: .None, p: &dummy, len: 0) // finish up
    
    // fill request
    
    let status = Int(parser.status_code ?? 0)
    let method = status == 0 ? parser.method.method : ""
    if heavyDebug { print("METHOD: \(method)") }
    let httpVersion : String
    if parser.hasVersion {
      httpVersion = "\(parser.http_major).\(parser.http_minor)"
    }
    else {
      httpVersion = "HTTP/1.0"
    }

    if heavyDebug { print("headers complete: \(status) \(method)") }
    
    // OK, we got the message (except the body). Let the consumer know.
    if status == 0 {
      cbRequest?(method, url, httpVersion, headers)
    }
    else {
      cbResponse?(status, httpVersion, headers)
    }
    headers.removeAll()
    url = ""
    
    return 0
  }
  
  final func processDataCB(newState s: LastCallback,
                           p: UnsafePointer<CChar>, len: size_t) -> Int
  {
    let newState = s
    if lastCB == newState { // continue value
      buffer.addBytes(p, length: len)
      return 0 // done already. state is the same
    }
    
    switch lastCB { // != newState!
      case .URL: // finished URL
        if buffer.count > 0 {
          if let s = buffer.asString() {
            url = s
            // print("URL: \(url)")
          }
          else {
            console.error("Cannot build URL string from buffer: \(buffer)")
          }
        }
      
      case .Field: // last field was a name
        lastName = buffer.asString()
      
      case .Value: // last field was a value, now something new
        let value = self.buffer.asString()
        assert(lastName != nil, "header value w/o a name?")
        assert(value    != nil, "header value missing?")
        addHeaderLine(name: lastName!, value: value!)
        lastName = nil
      
      default:
        break
    }
    
    // store new data & state
    buffer.reset()
    lastCB = newState
    if len > 0 {
      buffer.addBytes(p, length: len)
    }
    return 0
  }

  
}
