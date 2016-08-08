//
//  HTTPError.swift
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

// HTTP_ERRNO_MAP in original, enum has HPE_ prefix

#if swift(>=3.0) // #swift3-fd
#else
public typealias Error = ErrorType
#endif

public enum HTTPError : Error {
  case OK
  
  /* Callback-related errors */
  case CB_message_begin
  case CB_url
  case CB_header_field
  case CB_header_value
  case CB_headers_complete
  case CB_body
  case CB_message_complete
  case CB_status
  case CB_chunk_header
  case CB_chunk_complete
   
  /* Parsing-related errors */
  case INVALID_EOF_STATE
  case HEADER_OVERFLOW
  case CLOSED_CONNECTION
  case INVALID_VERSION
  case INVALID_STATUS
  case INVALID_METHOD
  case INVALID_URL
  case INVALID_HOST
  case INVALID_PORT
  case INVALID_PATH
  case INVALID_QUERY_STRING
  case INVALID_FRAGMENT
  case LF_EXPECTED
  case INVALID_HEADER_TOKEN
  case INVALID_CONTENT_LENGTH
  case INVALID_CHUNK_SIZE
  case INVALID_CONSTANT
  case INVALID_INTERNAL_STATE
  case STRICT
  case PAUSED
  case UNKNOWN
}

extension HTTPError : CustomStringConvertible {
  
  public var name: String {
    switch self {
      case .OK:                     return "OK"
    
      /* Callback-related errors */
      case .CB_message_begin:       return "CB_message_begin"
      case .CB_url:                 return "CB_url"
      case .CB_header_field:        return "CB_header_field"
      case .CB_header_value:        return "CB_header_value"
      case .CB_headers_complete:    return "CB_headers_complete"
      case .CB_body:                return "CB_body"
      case .CB_message_complete:    return "CB_message_complete"
      case .CB_status:              return "CB_status"
      case .CB_chunk_header:        return "CB_chunk_header"
      case .CB_chunk_complete:      return "CB_chunk_complete"
    
      /* Parsing-related errors */
      case .INVALID_EOF_STATE:      return "INVALID_EOF_STATE"
      case .HEADER_OVERFLOW:        return "HEADER_OVERFLOW"
      case .CLOSED_CONNECTION:      return "CLOSED_CONNECTION"
      case .INVALID_VERSION:        return "INVALID_VERSION"
      case .INVALID_STATUS:         return "INVALID_STATUS"
      case .INVALID_METHOD:         return "INVALID_METHOD"
      case .INVALID_URL:            return "INVALID_URL"
      case .INVALID_HOST:           return "INVALID_HOST"
      case .INVALID_PORT:           return "INVALID_PORT"
      case .INVALID_PATH:           return "INVALID_PATH"
      case .INVALID_QUERY_STRING:   return "INVALID_QUERY_STRING"
      case .INVALID_FRAGMENT:       return "INVALID_FRAGMENT"
      case .LF_EXPECTED:            return "LF_EXPECTED"
      case .INVALID_HEADER_TOKEN:   return "INVALID_HEADER_TOKEN"
      case .INVALID_CONTENT_LENGTH: return "INVALID_CONTENT_LENGTH"
      case .INVALID_CHUNK_SIZE:     return "INVALID_CHUNK_SIZE"
      case .INVALID_CONSTANT:       return "INVALID_CONSTANT"
      case .INVALID_INTERNAL_STATE: return "INVALID_INTERNAL_STATE"
      case .STRICT:                 return "STRICT"
      case .PAUSED:                 return "PAUSED"
      case .UNKNOWN:                return "UNKNOWN"
    }
  }
  
  public var description: String {
    switch self {
      case .OK: return "success"
      
      /* Callback-related errors */
      case .CB_message_begin:       return "the on_message_begin callback failed"
      case .CB_url:                 return "the on_url callback failed"
      case .CB_header_field:        return "the on_header_field callback failed"
      case .CB_header_value:        return "the on_header_value callback failed"
      case .CB_headers_complete:
        return "the on_headers_complete callback failed"
      case .CB_body:                return "the on_body callback failed"
      case .CB_message_complete:    return
        "the on_message_complete callback failed"
      case .CB_status:              return "the on_status callback failed"
      case .CB_chunk_header:        return "the on_chunk_header callback failed"
      case .CB_chunk_complete:      return
        "the on_chunk_complete callback failed"
   
      /* Parsing-related errors */
      case .INVALID_EOF_STATE:      return "stream ended at an unexpected time"
      case .HEADER_OVERFLOW:        return
        "too many header bytes seen; overflow detected"
      case .CLOSED_CONNECTION:      return
        "data received after completed connection: close message"
      case .INVALID_VERSION:        return "invalid HTTP version"
      case .INVALID_STATUS:         return "invalid HTTP status code"
      case .INVALID_METHOD:         return "invalid HTTP method"
      case .INVALID_URL:            return "invalid URL"
      case .INVALID_HOST:           return "invalid host"
      case .INVALID_PORT:           return "invalid port"
      case .INVALID_PATH:           return "invalid path"
      case .INVALID_QUERY_STRING:   return "invalid query string"
      case .INVALID_FRAGMENT:       return "invalid fragment"
      case .LF_EXPECTED:            return "LF character expected"
      case .INVALID_HEADER_TOKEN:   return "invalid character in header"
      case .INVALID_CONTENT_LENGTH: return
        "invalid character in content-length header"
      case .INVALID_CHUNK_SIZE:     return
        "invalid character in chunk size header"
      case .INVALID_CONSTANT:       return "invalid constant string"
      case .INVALID_INTERNAL_STATE: return
        "encountered unexpected internal state"
      case .STRICT:                 return "strict mode assertion failed"
      case .PAUSED:                 return "parser is paused"
      case .UNKNOWN:                return "an unknown error occurred"
    }
  }
}



// original compat

// TODO: http_errno_name() -> returns the name of the constant, useful!

public func http_errno_name(error: HTTPError) -> String {
  return error.name
}

public func http_errno_description(error: HTTPError) -> String {
  return error.description
}
