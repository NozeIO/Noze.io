//
//  http_parser_settings.swift
//  Noze.io
//
//  Created by Helge Hess on 08/08/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if os(Linux)
  import typealias Glibc.size_t
#else
  import typealias Darwin.size_t
#endif

public protocol http_parser_settings {
  
  func onMessageBegin   (parser p : http_parser ) -> Int
  func onURL            (parser p : http_parser,
                         _ data: UnsafePointer<CChar>, _ len: size_t) -> Int
  func onStatus         (parser p : http_parser,
                         _ data: UnsafePointer<CChar>, _ len: size_t) -> Int
  func onHeaderField    (parser p : http_parser,
                         _ data: UnsafePointer<CChar>, _ len: size_t) -> Int
  func onHeaderValue    (parser p : http_parser,
                           _ data: UnsafePointer<CChar>, _ len: size_t) -> Int
  func onHeadersComplete(parser p : http_parser ) -> Int
  func onBody           (parser p : http_parser,
                         _ data: UnsafePointer<CChar>, _ len: size_t) -> Int
  func onMessageComplete(parser p : http_parser ) -> Int
  
  /* When on_chunk_header is called, the current chunk length is stored
   * in parser->content_length.
   */
  func onChunkHeader    (parser p : http_parser ) -> Int
  func onChunkComplete  (parser p : http_parser ) -> Int

}

public extension http_parser_settings {
  func onMessageBegin   (parser p : http_parser ) -> Int { return 0 }
  func onURL            (parser p : http_parser,
                         _ data: UnsafePointer<CChar>, _ len: size_t) -> Int
       { return 0 }
  func onStatus         (parser p : http_parser,
                         _ data: UnsafePointer<CChar>, _ len: size_t) -> Int
       { return 0 }
  func onHeaderField    (parser p : http_parser,
                         _ data: UnsafePointer<CChar>, _ len: size_t) -> Int
       { return 0 }
  func onHeaderValue    (parser p : http_parser,
                         _ data: UnsafePointer<CChar>, _ len: size_t) -> Int
       { return 0 }
  func onHeadersComplete(parser p : http_parser ) -> Int
       { return 0 }
  func onBody           (parser p : http_parser,
                         _ data: UnsafePointer<CChar>, _ len: size_t) -> Int
       { return 0 }
  func onMessageComplete(parser p : http_parser ) -> Int { return 0 }
  
  /* When on_chunk_header is called, the current chunk length is stored
   * in parser->content_length.
   */
  func onChunkHeader    (parser p : http_parser ) -> Int { return 0 }
  func onChunkComplete  (parser p : http_parser ) -> Int { return 0 }
}

// MARK: - Closure Based Settings Imp. Note: Closures == Slow!

public struct http_parser_settings_cb : http_parser_settings {

  public init() {}

  var cbMessageBegin    : http_cb?      = nil
  var cbURL             : http_data_cb? = nil
  var cbStatus          : http_data_cb? = nil
  var cbHeaderField     : http_data_cb? = nil
  var cbHeaderValue     : http_data_cb? = nil
  var cbHeadersComplete : http_cb?      = nil
  var cbBody            : http_data_cb? = nil
  var cbMessageComplete : http_cb?      = nil

  /* When on_chunk_header is called, the current chunk length is stored
   * in parser->content_length.
   */
  var cbChunkHeader     : http_cb? = nil
  var cbChunkComplete   : http_cb? = nil

  public mutating func onMessageBegin   (cb: http_cb)      { cbMessageBegin    = cb }
  public mutating func onURL            (cb: http_data_cb) { cbURL             = cb }
  public mutating func onStatus         (cb: http_data_cb) { cbStatus          = cb }
  public mutating func onHeaderField    (cb: http_data_cb) { cbHeaderField     = cb }
  public mutating func onHeaderValue    (cb: http_data_cb) { cbHeaderValue     = cb }
  public mutating func onHeadersComplete(cb: http_cb)      { cbHeadersComplete = cb }
  public mutating func onBody           (cb: http_data_cb) { cbBody            = cb }
  public mutating func onMessageComplete(cb: http_cb)      { cbMessageComplete = cb }
  public mutating func onChunkHeader    (cb: http_cb)      { cbChunkHeader     = cb }
  public mutating func onChunkComplete  (cb: http_cb)      { cbChunkComplete   = cb }

  // MARK: - Protocol Implementation
  // don't confuse the names ;-)
  
  public func onMessageBegin(parser p: http_parser ) -> Int {
    guard let cb : http_cb = cbMessageBegin else { return 0 }
    return cb(p)
  }
  
  public func onURL(parser p: http_parser, _ data: UnsafePointer<CChar>, _ len: size_t)
              -> Int
  {
    guard let cb : http_data_cb = cbURL else { return 0 }
    return cb(p, data, len)
  }

  public func onStatus(parser p: http_parser,
                       _ data: UnsafePointer<CChar>, _ len: size_t) -> Int
  {
    guard let cb : http_data_cb = cbStatus else { return 0 }
    return cb(p, data, len)
  }

  public func onHeaderField(parser p: http_parser,
                            _ data: UnsafePointer<CChar>, _ len: size_t) -> Int
  {
    guard let cb : http_data_cb = cbHeaderField else { return 0 }
    return cb(p, data, len)
  }
  public func onHeaderValue(parser p: http_parser,
                            _ data: UnsafePointer<CChar>, _ len: size_t) -> Int
  {
    guard let cb : http_data_cb = cbHeaderValue else { return 0 }
    return cb(p, data, len)
  }
  
  public func onHeadersComplete(parser p: http_parser ) -> Int {
    guard let cb : http_cb = cbHeadersComplete else { return 0 }
    return cb(p)
  }

  public func onBody(parser p: http_parser,
                     _ data: UnsafePointer<CChar>, _ len: size_t) -> Int
  {
    guard let cb : http_data_cb = cbBody else { return 0 }
    return cb(p, data, len)
  }
  
  public func onMessageComplete(parser p: http_parser ) -> Int {
    guard let cb : http_cb = cbMessageComplete else { return 0 }
    return cb(p)
  }
  
  public func onChunkHeader(parser p: http_parser ) -> Int {
    guard let cb : http_cb = cbChunkHeader else { return 0 }
    return cb(p)
  }
  public func onChunkComplete(parser p: http_parser ) -> Int {
    guard let cb : http_cb = cbChunkComplete else { return 0 }
    return cb(p)
  }
}
