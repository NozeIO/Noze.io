//
//  URLParser.swift
//  HTTPParser
//
//  Created by Helge Heß on 25/04/16.
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

// enum http_parser_url_fields
// This is not a bitset in http_parser.h
public struct HTTPParserURLFields : OptionSetType {
  
  public let rawValue : Int
  
  public init(rawValue: Int = 0) {
    self.rawValue = rawValue
  }
  
  static let SCHEMA   = HTTPParserURLFields(rawValue: 1 << 0)
  static let HOST     = HTTPParserURLFields(rawValue: 1 << 1)
  static let PORT     = HTTPParserURLFields(rawValue: 1 << 2)
  static let PATH     = HTTPParserURLFields(rawValue: 1 << 3)
  static let QUERY    = HTTPParserURLFields(rawValue: 1 << 4)
  static let FRAGMENT = HTTPParserURLFields(rawValue: 1 << 5)
  static let USERINFO = HTTPParserURLFields(rawValue: 1 << 6)
}

/* Result structure for http_parser_parse_url().
 *
 * Callers should index into field_data[] with UF_* values iff field_set
 * has the relevant (1 << UF_*) bit set. As a courtesy to clients (and
 * because we probably have padding left over), we convert any port to
 * a uint16_t.
 */
public struct HTTPParserURL {
  
  var field_set : HTTPParserURLFields
  var port      : UInt16 // Converted UF_PORT string
  
  /* Offset into buffer in which field starts */
  var pSchema   : UnsafePointer<CChar>? = nil
  var pHost     : UnsafePointer<CChar>? = nil
  var pPort     : UnsafePointer<CChar>? = nil
  var pPath     : UnsafePointer<CChar>? = nil
  var pQuery    : UnsafePointer<CChar>? = nil
  var pFragment : UnsafePointer<CChar>? = nil
  var pUserInfo : UnsafePointer<CChar>? = nil

  var lSchema   : Int16 = 0
  var lHost     : Int16 = 0
  var lPort     : Int16 = 0
  var lPath     : Int16 = 0
  var lQuery    : Int16 = 0
  var lFragment : Int16 = 0
  var lUserInfo : Int16 = 0
  
  mutating func setField(field: HTTPParserURLFields,
                         _ ptr:   UnsafePointer<CChar>,
                         _ len:   Int16)
  {
    switch field {
      case HTTPParserURLFields.SCHEMA:   pSchema   = ptr; lSchema   = len
      case HTTPParserURLFields.HOST:     pHost     = ptr; lHost     = len
      case HTTPParserURLFields.PORT:     pPort     = ptr; lPort     = len
      case HTTPParserURLFields.PATH:     pPath     = ptr; lPath     = len
      case HTTPParserURLFields.QUERY:    pQuery    = ptr; lQuery    = len
      case HTTPParserURLFields.FRAGMENT: pFragment = ptr; lFragment = len
      case HTTPParserURLFields.USERINFO: pUserInfo = ptr; lUserInfo = len
      default: fatalError("unexpected URL field")
    }
    _ = field_set.insert(field)
  }
}

/* Our URL parser.
 *
 * This is designed to be shared by http_parser_execute() for URL validation,
 * hence it has a state transition + byte-for-byte interface. In addition, it
 * is meant to be embedded in http_parser_parse_url(), which does the dirty
 * work of turning state transitions URL components for its API.
 *
 * This function should only be invoked with non-space characters. It is
 * assumed that the caller cares about (and can detect) the transition between
 * URL and non-URL states by looking for these.
 */

func parse_url_char(s : ParserState, _ ch : CChar) -> ParserState {
  if ch == cSPACE || ch == CR || ch == LF { return .s_dead }
  
  if HTTP_PARSER_STRICT {
    if ch == cTAB || ch == cFORMFEED { return .s_dead }
  }
  
  switch s {
    case .s_req_spaces_before_url:
      /* Proxied requests are followed by scheme of an absolute URI (alpha).
       * All methods except CONNECT are followed by cSLASH or cSTAR.
       */
      
      if ch == cSLASH || ch == cSTAR { return .s_req_path }
      
      if IS_ALPHA(ch) { return .s_req_schema }
      
    case .s_req_schema:
      if IS_ALPHA(ch) { return s }
      
      if ch == cCOLON { return .s_req_schema_slash }
      
    case .s_req_schema_slash:
      if ch == cSLASH { return .s_req_schema_slash_slash }
      
    case .s_req_schema_slash_slash:
      if ch == cSLASH { return .s_req_server_start }
      
    case .s_req_server_with_at:
      guard ch != cAT else { return .s_dead }
      fallthrough
    case .s_req_server_start: fallthrough
    case .s_req_server:
      if ch == cSLASH { return .s_req_path               }
      if ch == cQM    { return .s_req_query_string_start }
      if ch == cAT    { return .s_req_server_with_at     }
      
      if IS_USERINFO_CHAR(ch) || ch == cLSB || ch == cRSB {
        return .s_req_server
      }
    
    case .s_req_path:
      if IS_URL_CHAR(ch) { return s }
      
      switch ch {
        case cQM:   return .s_req_query_string_start
        case cHASH: return .s_req_fragment_start
        default: break
      }
    
    case .s_req_query_string_start: fallthrough
    case .s_req_query_string:
      if IS_URL_CHAR(ch) { return .s_req_query_string }
      
      switch ch {
        case cQM: /* allow extra ? in query string */
          return .s_req_query_string
          
        case cHASH:
          return .s_req_fragment_start
        default: break
      }
    
    case .s_req_fragment_start:
      if IS_URL_CHAR(ch) { return .s_req_fragment }
      switch ch {
        case cQM:   return .s_req_fragment
        case cHASH: return s
        default: break
      }
    
    case .s_req_fragment:
      if IS_URL_CHAR(ch) { return s }
      
      switch ch {
        case cQM:   return s
        case cHASH: return s
        default:    break
      }
    
    default:
      break
  }
  
  /* We should never fall out of the switch above unless there's an error */
  return .s_dead;
}
#if swift(>=3.0) // #swift3-fd
func parse_url_char(_ s : ParserState, _ ch : CChar) -> ParserState {
  return parse_url_char(s: s, ch)
}
#endif
