//
//  HTTPParser.swift
//  HTTPParser
//
//  Created by Helge Heß on 4/25/16.
//  Copyright © 2016 Always Right Institute. All rights reserved.
//
/* Copyright Joyent, Inc. and other Node contributors. All rights reserved.
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to
 * deal in the Software without restriction, including without limitation the
 * rights to use, copy, modify, merge, publish, distribute, sublicense, and/or
 * sell copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 * FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
 * IN THE SOFTWARE.
 */

#if os(Linux)
  import typealias Glibc.size_t
#else
  import typealias Darwin.size_t
#endif

let HTTP_PARSER_STRICT   = false
let HTTP_MAX_HEADER_SIZE = (80 * 1024)

let debugOn = false

// HTTP_METHOD_MAP - is HTTPMethod enum
// HTTP_ERRNO_MAP  - is HTTPError  enum

public enum HTTPParserType {
  case Request
  case Response
  case Both
}

public typealias http_data_cb = ( http_parser,
                                  UnsafePointer<CChar>, size_t) -> Int
public typealias http_cb      = ( http_parser ) -> Int


public struct http_parser {
  // TBD: this could be a struct, except maybe for the callbacks - those would
  //      need to take an inout parameter?

  // MARK: - http_parser
  
  var type                  : HTTPParserType
  var flags                 = HTTPParserOptions()
  var state                 : ParserState       = .s_dead
  var header_state          : ParserHeaderState = .h_general
  var index                 : Int   = 0
    // this is UInt8, but Int can be used as an idx
  
  public var nread          : Int   = 0
  public var content_length : Int   = 0
  
  // READ-ONLY
  public var http_major     : Int16      = 0
  public var http_minor     : Int16      = 0
  public var status_code    : Int16      = 0       // responses only
  public var method         : HTTPMethod = .DELETE // requests only
  public var error          : HTTPError  = .OK
  
  public var upgrade        = false
  
  #if swift(>=3.0) // #swift3-ptr
    public var data : UnsafePointer<Void>? = nil // user data
  #else
    public var data : UnsafePointer<Void> = nil // user data
  #endif
  
  
  // MARK: - Init
  
  public init(type: HTTPParserType = .Both) { // http_parser_init
    self.type = type
    
    // start_state
    self.state = startState
  }

  public mutating func reset(type t: HTTPParserType = .Both) {
    self.type              = t
    self.flags             = HTTPParserOptions()
    self.state             = startState
    self.header_state      = .h_general
    self.index             = 0
    self.nread             = 0
    self.content_length    = 0
  
    self.http_major        = 0
    self.http_minor        = 0
    self.status_code       = 0
    self.method            = .DELETE
    self.error             = .OK
  
    self.upgrade           = false
    
    // Note: Data is preserved!
  }
  
  // MARK: - Callbacks
  
  enum Callback {
    case MessageBegin, MessageComplete
    case URL, Status
    case HeaderField, HeaderValue, HeadersComplete
    case Body
    case ChunkHeader, ChunkComplete
    
    var callbackError : HTTPError {
      switch self {
        case .MessageBegin:    return .CB_message_begin
        case .MessageComplete: return .CB_message_complete
        case .URL:             return .CB_url
        case .Status:          return .CB_status
        case .HeaderField:     return .CB_header_field
        case .HeaderValue:     return .CB_header_value
        case .HeadersComplete: return .CB_headers_complete
        case .Body:            return .CB_body
        case .ChunkHeader:     return .CB_chunk_header
        case .ChunkComplete:   return .CB_chunk_complete
      }
    }
  }
  
  // MARK: - Implementation

  public mutating func pause() {
    /* Users should only be pausing/unpausing a parser that is not in an error
     * state. In non-debug builds, there's not much that we can do about this
     * other than ignore it.
     */
    if error == .OK || error == .PAUSED {
      error = .PAUSED
    } else {
      assert(false, "Attempting to pause parser in error state")
    }
  }
  public mutating func resume() {
    if error == .OK || error == .PAUSED {
      error = .OK
    } else {
      assert(false, "Attempting to pause parser in error state")
    }
  }
  
  
  var isBodyFinal : Bool {
    // TODO
    return false
  }
  
  
  // MARK: - Implementation
  
  var startState : ParserState {
    switch type {
      case .Request:  return .s_start_req
      case .Response: return .s_start_res
      case .Both:     return .s_start_req_or_res
    }
  }
  
  var shouldKeepAlive : Bool = false // TODO: http_should_keep_alive
  
  var NEW_MESSAGE : ParserState {
    if HTTP_PARSER_STRICT {
      return shouldKeepAlive ? startState : .s_dead
    }
    else {
      return startState
    }
  }
  
  var messageNeedsEOF : Bool { // http_message_needs_eof()
    /* Does the parser need to see an EOF to find the end of the message? */
    if type == .Request {
      return false
    }
    
    /* See RFC 2616 section 4.4 */
    if status_code / 100 == 1 || /* 1xx e.g. Continue */
       status_code == 204 ||     /* No Content */
       status_code == 304 ||     /* Not Modified */
       flags.contains(.F_SKIPBODY) {     /* response to a HEAD request */
      return false
    }
    
    if (flags.contains(.F_CHUNKED)
        || content_length != Int.max /* ULLONG_MAX */)
    {
      return false
    }
    
    return true
  }
}

extension http_parser {
  public var hasVersion : Bool { return http_major != 0 || http_minor != 0 }
}

// HH: this is crap
// TBD: does this involve a dispatch once?
let PROXY_CONNECTION   = "proxy-connection".makeCString()
let CONNECTION         = "connection".makeCString()
let CONTENT_LENGTH     = "content-length".makeCString()
let TRANSFER_ENCODING  = "transfer-encoding".makeCString()
let UPGRADE            = "upgrade".makeCString()
let CHUNKED            = "chunked".makeCString()
let KEEP_ALIVE         = "keep-alive".makeCString()
let CLOSE              = "close".makeCString()

let lPROXY_CONNECTION  = 16
let lCONNECTION        = 10
let lCONTENT_LENGTH    = 14
let lTRANSFER_ENCODING = 17 // strlen(TRANSFER_ENCODING)
let lUPGRADE           =  7 // strlen(UPGRADE)
let lCHUNKED           =  7 // strlen(CHUNKED)
let lKEEP_ALIVE        = 10 // strlen(KEEP_ALIVE)
let lCLOSE             =  5 // strlen(CLOSE)
