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

#if swift(>=3.0) // #swift3-inout

#if os(Linux)
  import Glibc
#else
  import Darwin
#endif

public extension http_parser {
  
  // Note:  The C macros directly invoke `return`. The Swift functions return
  //        an optional - if it is nil, flow should continue, otherwise the
  //        caller should return the returned value.
  // FIXME: the error codes are wrong
  
  /// Run the notify callback FOR, returning ER if it fails
  @inline(__always)
  internal mutating func CALLBACK_NOTIFY_(_ cbe           : Callback,
                                 _ CURRENT_STATE : inout ParserState,
                                 _ settings : http_parser_settings,
                                 _ ER            : size_t)
       -> size_t?
  {
    let cb : http_cb!
    switch cbe {
      case .MessageBegin:    cb = settings.cbMessageBegin
      case .HeadersComplete: cb = settings.cbHeadersComplete
      case .MessageComplete: cb = settings.cbMessageComplete
      case .ChunkHeader:     cb = settings.cbChunkHeader
      case .ChunkComplete:   cb = settings.cbChunkComplete
      default: assert(false, "incorrect CB");  cb = nil
    }
    
    guard cb != nil else { return nil }
    
    self.state = CURRENT_STATE
    if cb(self) != 0 { error = cbe.callbackError }
    
    CURRENT_STATE = self.state
    // The original macro has a hard return!
    return error != .OK ? ER : nil
  }
  
  /// Run the notify callback FOR and consume the current byte
  @inline(__always)
  internal mutating func CALLBACK_NOTIFY(_ cb            : Callback,
                                _ CURRENT_STATE : inout ParserState,
                                _ settings : http_parser_settings,
                                _ p:    UnsafePointer<CChar>?,
                                _ data: UnsafePointer<CChar>?)
    -> size_t?
  {
    let len : Int
    if let p = p, data = data {
      len = p - data + 1
    }
    else {
      len = 0
    }
    return CALLBACK_NOTIFY_(cb, &CURRENT_STATE, settings, len)
  }
  
  /// Run the notify callback FOR and don't consume the current byte
  @inline(__always)
  internal mutating func CALLBACK_NOTIFY_NOADVANCE(_ cb            : Callback,
                                          _ CURRENT_STATE : inout ParserState,
                                          _ settings : http_parser_settings,
                                          _ p:    UnsafePointer<CChar>?,
                                          _ data: UnsafePointer<CChar>?)
    -> size_t?
  {
    let len : Int
    if let p = p, data = data {
      len = p - data
    }
    else {
      len = 0
    }
    return CALLBACK_NOTIFY_(cb, &CURRENT_STATE, settings, len)
  }
  
  // TBD: maybe the CALLBACK_DATA funcs should be nested, so that they can
  //      directly patch the `mark`
  
  /// Run data callback FOR with LEN bytes, returning ER if it fails
  @inline(__always)
  internal mutating func CALLBACK_DATA_(_ cbe           : Callback,
                               _ mark          : inout UnsafePointer<CChar>?,
                               _ CURRENT_STATE : inout ParserState,
                               _ settings : http_parser_settings,
                               _ len: size_t, _ ER: size_t)
       -> size_t?
  {
    assert(error == .OK)
    
    if mark != nil {
      let cb : http_data_cb!
      switch cbe {
        case .URL:         cb = settings.cbURL
        case .Status:      cb = settings.cbStatus
        case .HeaderField: cb = settings.cbHeaderField
        case .HeaderValue: cb = settings.cbHeaderValue
        case .Body:        cb = settings.cbBody
        default: assert(false, "incorrect CB"); cb = nil
      }
      
      if let cb = cb {
        self.state = CURRENT_STATE
        if 0 != cb(self, mark!, len) {
          error = cbe.callbackError
        }
        CURRENT_STATE = self.state // in case the CB patched it
        
        /* We either errored above or got paused; get out */
        if error != .OK {
          return ER
        }
      }
      
      mark = nil // inout, propagates to caller
    }
    
    return nil
  }
  
  /// Run the data callback FOR and consume the current byte
  @inline(__always)
  internal mutating func CALLBACK_DATA(_ cb            : Callback,
                              _ mark          : inout UnsafePointer<CChar>?,
                              _ CURRENT_STATE : inout ParserState,
                              _ settings : http_parser_settings,
                              _ p:    UnsafePointer<CChar>?,
                              _ data: UnsafePointer<CChar>?) -> size_t?
  {
    let len : size_t, er : size_t
    if let p = p, mark = mark { len = p - mark }
    else { len = 0 }
    if let p = p, data = data { er = p - data + 1 }
    else { er = 0 }
    return CALLBACK_DATA_(cb, &mark, &CURRENT_STATE, settings, len, er)
  }
  /// Run the data callback FOR and consume the current byte
  @inline(__always)
  internal mutating func CALLBACK_DATA_NOADVANCE(_ cb: Callback,
                                        _ mark : inout UnsafePointer<CChar>?,
                                        _ CURRENT_STATE : inout ParserState,
                                        _ settings : http_parser_settings,
                                        _ p:    UnsafePointer<CChar>?,
                                        _ data: UnsafePointer<CChar>?) -> size_t?
  {
    let len : size_t, er : size_t
    if let p = p, mark = mark { len = p - mark }
    else { len = 0 }
    if let p = p, data = data { er = p - data }
    else { er = 0 }
    return CALLBACK_DATA_(cb, &mark, &CURRENT_STATE, settings, len, er)
  }
  
  
  // MARK: - Execute
  
  /// Executes the parser. Returns number of parsed bytes. Sets
  /// `error` on error.
  public mutating func execute(_ settings : http_parser_settings,
                               _ data: UnsafePointer<CChar>?, _ len: size_t)
                       -> size_t
  {
    /* We're in an error state. Don't bother doing anything. */
    guard error == .OK else { return 0 }
    
    var p             = data
    var CURRENT_STATE = self.state
    
    // handle EOF
    
    if (len == 0 /* EOF */) {
      switch CURRENT_STATE {
        case .s_body_identity_eof:
          /* Use of CALLBACK_NOTIFY() here would erroneously return 1 byte read if
           * we got paused.
           */
          let len = CALLBACK_NOTIFY_NOADVANCE(.MessageComplete, &CURRENT_STATE,
                                              settings, p, data)
          if let len = len { return len } // error
          return 0
          
        case .s_dead:             return 0
        case .s_start_req_or_res: return 0
        case .s_start_res:        return 0
        case .s_start_req:        return 0
        
        default:
          error = .INVALID_EOF_STATE
          return 1 // hu?
      }
    }
    
    
    // collect data markers
    
    var header_field_mark : UnsafePointer<CChar>? = nil
    var header_value_mark : UnsafePointer<CChar>? = nil
    var url_mark          : UnsafePointer<CChar>? = nil
    var body_mark         : UnsafePointer<CChar>? = nil
    var status_mark       : UnsafePointer<CChar>? = nil
    
    switch CURRENT_STATE {
      case .s_header_field: header_field_mark = data
      case .s_header_value: header_value_mark = data
      case .s_res_status:   status_mark       = data
      
      case .s_req_path, .s_req_schema, .s_req_schema_slash,
           .s_req_schema_slash_slash, .s_req_server_start, .s_req_server,
           .s_req_server_with_at, .s_req_query_string_start,
           .s_req_query_string, .s_req_fragment_start, .s_req_fragment:
        url_mark = data
      
      default: break
    }
    
    @inline(__always)
    func MARK(_ cbe: Callback /*, p : UnsafePointer<CChar> = p */) {
      // Note: argument crashes swiftc 2.2
      // #define MARK(FOR) if (!FOR##_mark)  FOR##_mark = p;
      if debugOn { print("  MARK \(cbe)") }
      switch cbe {
        case .HeaderField:
          if header_field_mark == nil { header_field_mark = p }
        case .HeaderValue:
          if header_value_mark == nil { header_value_mark = p }
        case .URL:    if url_mark    == nil { url_mark    = p }
        case .Body:   if body_mark   == nil { body_mark   = p }
        case .Status: if status_mark == nil { status_mark = p }
        default: assert(false, "Callback has no marker")
      }
    }
    
    /// transfer `CURRENT_STATE` to `state` ivar and return the given value
    @inline(__always)
    func RETURN(_ V: size_t) -> size_t {
      if debugOn { print("RETURN old \(self.state) new \(CURRENT_STATE)") }
      self.state = CURRENT_STATE
      return V
    }
    
    @inline(__always)
    func UPDATE_STATE(_ state: ParserState) {
      if debugOn { print("  UPDATE_STATE \(CURRENT_STATE) => \(state)") }
      CURRENT_STATE = state
    }
    
    
    /* the BIG'n'DIRTY step function */
    
    enum StepResult {
      case Continue  // continue loop
      case Reexecute // step again, in an inner loop
      case Error(HTTPError)
      case CallbackDone(size_t)
      case Return(size_t)
      
      var isReexecute : Bool {
        switch self { // cannot use == due to associated values
          case .Reexecute: return true
          default: return false
        }
      }
    }
    
    // REEXECUTE macro:
    //   if let len = gotoReexecute() { return len } // error?
    // crashes Swift 3 05-31: @inline(__always)
    func step(_ ch: CChar) -> StepResult {
      /* reexecute: label */

      if debugOn {
        print("\n<---------------------------------------")
        print("STEP \(debugChar(ch)) len=\(p! - data!) " +
              "\(CURRENT_STATE)")

        if CURRENT_STATE == .s_header_field {
          print("xxx HEADER FIELD")
        }
      }
      defer {
        if debugOn {
          if CURRENT_STATE == .s_header_field {
            print("xxx HEADER FIELD")
          }
          
          print("DONE \(debugChar(ch)) len=\(p! - data!) " +
                "\(CURRENT_STATE) \(self.error)")
          print("\n>---------------------------------------")
        }
      }
      
      switch CURRENT_STATE {
        case .s_dead:
          /* this state is used after a 'Connection: close' message
           * the parser will error out if it reads another message
           */
          if ch == CR || ch == LF { break }
          return .Error(.CLOSED_CONNECTION)

        case .s_start_req_or_res:
          if ch == CR || ch == LF { break }
          
          self.flags          = HTTPParserOptions()
          self.content_length = Int.max // was: ULLONG_MAX
          
          if ch == 72 /* 'H' */ {
            UPDATE_STATE(.s_res_or_resp_H);
            
            let len = CALLBACK_NOTIFY(.MessageBegin, &CURRENT_STATE, settings,
                                      p, data)
            if let len = len { return .CallbackDone(len) }
          }
          else {
            self.type = .Request;
            UPDATE_STATE(.s_start_req)
            return .Reexecute
          }
        
        case .s_res_or_resp_H:
          if ch == cT {
            self.type = .Response
            UPDATE_STATE(.s_res_HT)
          }
          else {
            guard ch == cE else { return .Error(.INVALID_CONSTANT) }
            
            self.type   = .Request
            self.method = .HEAD
            index = 2
            UPDATE_STATE(.s_req_method)
          }

        case .s_start_res:
          self.flags          = HTTPParserOptions()
          self.content_length = Int.max // was: ULLONG_MAX

          switch (ch) {
            case 72 /* 'H' */: UPDATE_STATE(.s_res_H);
            case CR: break
            case LF: break
            default: return .Error(.INVALID_CONSTANT)
          }
          
          let len = CALLBACK_NOTIFY(.MessageBegin, &CURRENT_STATE, settings,
                                    p, data)
          if let len = len { return .CallbackDone(len) }
        
        case .s_res_H:
          guard STRICT_CHECK(ch != cT) else { return .Error(.STRICT) }
          UPDATE_STATE(.s_res_HT)

        case .s_res_HT:
          guard STRICT_CHECK(ch != cT) else { return .Error(.STRICT) }
          UPDATE_STATE(.s_res_HTT)

        case .s_res_HTT:
          guard STRICT_CHECK(ch != cP) else { return .Error(.STRICT) }
          UPDATE_STATE(.s_res_HTTP)

        case .s_res_HTTP:
          guard STRICT_CHECK(ch != cSLASH) else { return .Error(.STRICT) }
          UPDATE_STATE(.s_res_first_http_major)
          break;

        case .s_res_first_http_major:
          guard ch >= c0 && ch <= c9 else { return .Error(.INVALID_VERSION) }
          
          http_major = Int16(ch - c0)
          UPDATE_STATE(.s_res_http_major)

        /* major HTTP version or dot */
        case .s_res_http_major:
          if ch == cDOT {
            UPDATE_STATE(.s_res_first_http_minor);
            break
          }
          
          guard IS_NUM(ch) else { return .Error(.INVALID_VERSION) }
          
          self.http_major *= Int16(10)
          self.http_major += Int16(ch - c0)
          
          guard self.http_major < 1000 else { return .Error(.INVALID_VERSION) }

        /* first digit of minor HTTP version */
        case .s_res_first_http_minor:
          guard IS_NUM(ch) else { return .Error(.INVALID_VERSION) }
          
          self.http_minor = Int16(ch - c0)
          UPDATE_STATE(.s_res_http_minor);

        /* minor HTTP version or end of request line */
        case .s_res_http_minor:
          if ch == cSPACE {
            UPDATE_STATE(.s_res_first_status_code);
            break
          }
          
          guard IS_NUM(ch) else { return .Error(.INVALID_VERSION) }
          
          self.http_minor *= Int16(10)
          self.http_minor += Int16(ch - c0)
          
          guard self.http_minor < 1000 else { return .Error(.INVALID_VERSION) }

        case .s_res_first_status_code:
          if !IS_NUM(ch) {
            if ch == cSPACE { break }

            return .Error(.INVALID_STATUS)
          }
          self.status_code = Int16(ch - 48 /* '0' */)
          UPDATE_STATE(.s_res_status_code);

        case .s_res_status_code:
          if !IS_NUM(ch) {
            switch (ch) {
              case cSPACE: UPDATE_STATE(.s_res_status_start);
              case CR:     UPDATE_STATE(.s_res_line_almost_done);
              case LF:     UPDATE_STATE(.s_header_field_start)
              default:     return .Error(.INVALID_STATUS)
            }
            break
          }

          self.status_code *= Int16(10)
          self.status_code += Int16(ch - c0)
          
          guard status_code < 1000 else { return .Error(.INVALID_STATUS) }

        case .s_res_status_start:
          if ch == CR { UPDATE_STATE(.s_res_line_almost_done); break }
          if ch == LF { UPDATE_STATE(.s_header_field_start);   break }
          MARK(.Status)
          UPDATE_STATE(.s_res_status);
          self.index = 0;

        case .s_res_status:
          if ch == CR {
            UPDATE_STATE(.s_res_line_almost_done)
            //CALLBACK_DATA(status)
            let rc = CALLBACK_DATA(.Status, &status_mark, &CURRENT_STATE,
                                   settings, p, data)
            if let rc = rc { return .CallbackDone(rc) }
            break
          }
          
          if ch == LF {
            UPDATE_STATE(.s_header_field_start)
            let rc = CALLBACK_DATA(.Status, &status_mark, &CURRENT_STATE,
                                   settings, p, data)
            if let rc = rc { return .CallbackDone(rc) }
            break
          }

        case .s_res_line_almost_done:
          guard STRICT_CHECK(ch != LF) else { return .Error(.STRICT) }
          UPDATE_STATE(.s_header_field_start)

        case .s_start_req:
          if ch == CR || ch == LF { break }

          self.flags = HTTPParserOptions()
          self.content_length = Int.max // was: ULLONG_MAX;
          
          guard IS_ALPHA(ch) else { return .Error(.INVALID_METHOD) }
          
          self.method = .GET
          self.index  = 1;
          switch ch {
            case cA: self.method = .ACL
            case cB: self.method = .BIND
            case cC: self.method = .CONNECT /* or COPY, CHECKOUT */
            case cD: self.method = .DELETE
            case cG: self.method = .GET
            case cH: self.method = .HEAD
            case cL: self.method = .LOCK /* or LINK */
            case cM: self.method = .MKCOL
               /* or MOVE, MKACTIVITY, MERGE, M-SEARCH, MKCALENDAR */
            case cN: self.method = .NOTIFY
            case cO: self.method = .OPTIONS
            case cP: self.method = .POST
              /* or PROPFIND|PROPPATCH|PUT|PATCH|PURGE */

            case cR: self.method = .REPORT /* or REBIND */
            case cS: self.method = .SUBSCRIBE /* or SEARCH */
            case cT: self.method = .TRACE
            case cU: self.method = .UNLOCK
              /* or UNSUBSCRIBE, UNBIND, UNLINK */
            default:
              return .Error(.INVALID_METHOD)
          }
          UPDATE_STATE(.s_req_method);
          
          // CALLBACK_NOTIFY(message_begin);
          let rc = CALLBACK_NOTIFY(.MessageBegin, &CURRENT_STATE, settings,
                                   p, data)
          if let rc = rc { return .CallbackDone(rc) }
          
          if debugOn { print("  METHOD: \(self.method)") }
          
          break;

        case .s_req_method:
          guard ch != 0 else { return .Error(.INVALID_METHOD) }
          
          //const char *matcher = method_strings[self.method];
          let matcher = self.method.csMethod
          
          
          if (ch == cSPACE && matcher[self.index] == 0) {
            UPDATE_STATE(.s_req_spaces_before_url);
          } else if (ch == matcher[self.index]) {
            /* nada */
          } else if (self.method == .CONNECT) {
            if (self.index == 1 && ch == cH) {
              self.method = .CHECKOUT;
            } else if (self.index == 2  && ch == cP) {
              self.method = .COPY;
            } else {
              return .Error(.INVALID_METHOD)
            }
          } else if (self.method == .MKCOL) {
            if (self.index == 1 && ch == cO) {
              self.method = .MOVE;
            } else if (self.index == 1 && ch == cE) {
              self.method = .MERGE;
            } else if (self.index == 1 && ch == cDASH) {
              self.method = .MSEARCH;
            } else if (self.index == 2 && ch == cA) {
              self.method = .MKACTIVITY;
            } else if (self.index == 3 && ch == cA) {
              self.method = .MKCALENDAR;
            } else {
              return .Error(.INVALID_METHOD)
            }
          } else if (self.method == .SUBSCRIBE) {
            if (self.index == 1 && ch == cE) {
              self.method = .SEARCH;
            } else {
              return .Error(.INVALID_METHOD)
            }
          } else if (self.method == .REPORT) {
              if (self.index == 2 && ch == cB) {
                self.method = .REBIND;
              } else {
                return .Error(.INVALID_METHOD)
              }
          } else if (self.index == 1) {
            if (self.method == .POST) {
              if (ch == cR) {
                self.method = .PROPFIND; /* or HTTP_PROPPATCH */
              } else if (ch == cU) {
                self.method = .PUT; /* or HTTP_PURGE */
              } else if (ch == cA) {
                self.method = .PATCH;
              } else {
                return .Error(.INVALID_METHOD)
              }
            } else if (self.method == .LOCK) {
              if (ch == cI) {
                self.method = .LINK;
              } else {
                return .Error(.INVALID_METHOD)
              }
            }
          } else if (self.index == 2) {
            if (self.method == .PUT) {
              if (ch == cR) {
                self.method = .PURGE;
              } else {
                return .Error(.INVALID_METHOD)
              }
            } else if (self.method == .UNLOCK) {
              if (ch == cS) {
                self.method = .UNSUBSCRIBE;
              } else if(ch == cB) {
                self.method = .UNBIND;
              } else {
                return .Error(.INVALID_METHOD)
              }
            } else {
              return .Error(.INVALID_METHOD)
            }
          } else if (self.index == 4 && self.method == .PROPFIND && ch == cP) {
            self.method = .PROPPATCH;
          } else if (self.index == 3 && self.method == .UNLOCK && ch == cI) {
            self.method = .UNLINK;
          } else {
            return .Error(.INVALID_METHOD)
          }
          
          self.index += 1
          if debugOn { print("  METHOD: \(self.method) INDEX \(self.index)") }

        case .s_req_spaces_before_url:
          if ch == cSPACE { break }
          
          MARK(.URL)
          if (self.method == .CONNECT) {
            UPDATE_STATE(.s_req_server_start);
          }
          
          UPDATE_STATE(parse_url_char(CURRENT_STATE, ch))
          guard CURRENT_STATE != .s_dead else { return .Error(.INVALID_URL) }


        case .s_req_schema,
             .s_req_schema_slash,
             .s_req_schema_slash_slash,
             .s_req_server_start:
          switch ch {
            /* No whitespace allowed here */
            case cSPACE, CR, LF:
              return .Error(.INVALID_URL)
            default:
              UPDATE_STATE(parse_url_char(CURRENT_STATE, ch))
              guard CURRENT_STATE != .s_dead else { return .Error(.INVALID_URL) }
          }

      case .s_req_server,
           .s_req_server_with_at,
           .s_req_path,
           .s_req_query_string_start,
           .s_req_query_string,
           .s_req_fragment_start,
           .s_req_fragment:
        switch ch {
          case cSPACE:
            UPDATE_STATE(.s_req_http_start)
            //CALLBACK_DATA(url);
            let rc = CALLBACK_DATA(.URL, &url_mark, &CURRENT_STATE, settings,
                                   p, data)
            if let rc = rc { return .CallbackDone(rc) }
          
          case CR, LF:
            self.http_major = 0
            self.http_minor = 9
            UPDATE_STATE(ch == CR
                         ? .s_req_line_almost_done
                         : .s_header_field_start)
            // CALLBACK_DATA(url)
            let rc = CALLBACK_DATA(.URL, &url_mark, &CURRENT_STATE, settings,
                                   p, data)
            if let rc = rc { return .CallbackDone(rc) }

          default:
            UPDATE_STATE(parse_url_char(CURRENT_STATE, ch))
            guard CURRENT_STATE != .s_dead else { return .Error(.INVALID_URL) }
        }

        case .s_req_http_start:
          switch ch {
            case cH:     UPDATE_STATE(.s_req_http_H)
            case cSPACE: break
            default:     return .Error(.INVALID_CONSTANT)
          }
        
        case .s_req_http_H:
          guard STRICT_CHECK(ch != cT) else { return .Error(.STRICT) }
          UPDATE_STATE(.s_req_http_HT)

        case .s_req_http_HT:
          guard STRICT_CHECK(ch != cT) else { return .Error(.STRICT) }
          UPDATE_STATE(.s_req_http_HTT)

        case .s_req_http_HTT:
          guard STRICT_CHECK(ch != cP) else { return .Error(.STRICT) }
          UPDATE_STATE(.s_req_http_HTTP)

        case .s_req_http_HTTP:
          guard STRICT_CHECK(ch != cSLASH) else { return .Error(.STRICT) }
          UPDATE_STATE(.s_req_first_http_major)

        /* first digit of major HTTP version */
        case .s_req_first_http_major:
          guard ch >= c1 && ch <= c9 else { return .Error(.INVALID_VERSION) }

          self.http_major = Int16(ch - c0)
          UPDATE_STATE(.s_req_http_major)

        /* major HTTP version or dot */
        case .s_req_http_major:
          if ch == cDOT {
            UPDATE_STATE(.s_req_first_http_minor)
            break;
          }
          guard IS_NUM(ch) else { return .Error(.INVALID_VERSION) }
          
          self.http_major *= 10;
          self.http_major += Int16(ch - c0);
          
          guard self.http_major < 1000 else { return .Error(.INVALID_VERSION) }

        /* first digit of minor HTTP version */
        case .s_req_first_http_minor:
          guard IS_NUM(ch) else { return .Error(.INVALID_VERSION) }
          self.http_minor = Int16(ch - c0)
          UPDATE_STATE(.s_req_http_minor)

        /* minor HTTP version or end of request line */
        case .s_req_http_minor:
          if ch == CR { UPDATE_STATE(.s_req_line_almost_done); break }
          if ch == LF { UPDATE_STATE(.s_header_field_start);   break }

          /* XXX allow spaces after digit? */
          
          guard IS_NUM(ch) else { return .Error(.INVALID_VERSION) }

          self.http_minor *= 10
          self.http_minor += ch - c0

          guard self.http_minor < 1000 else { return .Error(.INVALID_VERSION) }

        /* end of request line */
        case .s_req_line_almost_done:
          guard ch == LF else { return .Error(.LF_EXPECTED) }
          UPDATE_STATE(.s_header_field_start);

        case .s_header_field_start:
          if ch == CR { UPDATE_STATE(.s_headers_almost_done); break }

          if ch == LF {
            /* they might be just sending \n instead of \r\n so this would be
             * the second \n to denote the end of headers*/
            UPDATE_STATE(.s_headers_almost_done)
            return .Reexecute
          }

          let c = TOKEN(ch)
          guard c != 0 else { return .Error(.INVALID_HEADER_TOKEN) }


          MARK(.HeaderField);

          self.index = 0;
          UPDATE_STATE(.s_header_field)

          switch c {
            case cc: self.header_state = .h_C
            case cp: self.header_state = .h_matching_proxy_connection
            case ct: self.header_state = .h_matching_transfer_encoding
            case cu: self.header_state = .h_matching_upgrade
            default: self.header_state = .h_general
          }

        case .s_header_field:
          let start = p
          
          var ch = p!.pointee // needs to be outside of the loop!
          while p != (data! + len) {
            ch = p!.pointee
            let c = TOKEN(ch)
            if  c == 0 { break }

            switch self.header_state {
              case .h_general: break

              case .h_C:
                self.index += 1
                self.header_state = (c == co ? .h_CO : .h_general)

              case .h_CO:
                self.index += 1
                self.header_state = (c == cn ? .h_CON : .h_general)

              case .h_CON:
                self.index += 1
                switch c {
                  case cn: self.header_state = .h_matching_connection
                  case ct: self.header_state = .h_matching_content_length
                  default: self.header_state = .h_general
                }

              /* connection */

              case .h_matching_connection:
                self.index += 1
                if self.index > lCONNECTION || c != CONNECTION[self.index] {
                  self.header_state = .h_general;
                } else if self.index == lCONNECTION - 1 {
                  self.header_state = .h_connection;
                }
                break;

              /* proxy-connection */

              case .h_matching_proxy_connection:
                self.index += 1
                if (self.index > lPROXY_CONNECTION
                    || c != PROXY_CONNECTION[self.index]) {
                  self.header_state = .h_general;
                } else if self.index == lPROXY_CONNECTION-1 {
                  self.header_state = .h_connection;
                }

              /* content-length */

              case .h_matching_content_length:
                self.index += 1
                if (self.index > lCONTENT_LENGTH
                    || c != CONTENT_LENGTH[self.index]) {
                  self.header_state = .h_general;
                } else if self.index == lCONTENT_LENGTH-1 {
                  self.header_state = .h_content_length;
                }

              /* transfer-encoding */

              case .h_matching_transfer_encoding:
                self.index += 1
                if (self.index > lTRANSFER_ENCODING
                    || c != TRANSFER_ENCODING[self.index]) {
                  self.header_state = .h_general;
                } else if self.index == lTRANSFER_ENCODING-1 {
                  self.header_state = .h_transfer_encoding;
                }

              /* upgrade */

              case .h_matching_upgrade:
                self.index += 1
                
                if self.index > lUPGRADE || c != UPGRADE[self.index] {
                  self.header_state = .h_general;
                } else if self.index == lUPGRADE-1 {
                  self.header_state = .h_upgrade;
                }

              case .h_connection, .h_content_length, .h_transfer_encoding,
                   .h_upgrade:
                if ch != cSPACE { self.header_state = .h_general }

              default:
                assert(false, "Unknown header_state")
            }
            
            p! += 1
          }

          guard COUNT_HEADER_SIZE(p! - start!) else {
            return .Error(.HEADER_OVERFLOW)
          }

          if p == data! + len {
            p! -= 1
            break
          }
          
          if debugOn {
            let s = String.fromCString(header_field_mark!,
                                       length: (p! - header_field_mark!))!
            print("  H: \(s) CH: \(debugChar(ch))")
          }

          if ch == cCOLON {
            UPDATE_STATE(.s_header_value_discard_ws);
            
            // CALLBACK_DATA(header_field);
            let rc = CALLBACK_DATA(.HeaderField, &header_field_mark,
                                   &CURRENT_STATE, settings, p, data)
            if let rc = rc { return .CallbackDone(rc) }
            break
          }

          return .Error(.INVALID_HEADER_TOKEN)

        case .s_header_value_discard_ws:
          if ch == cSPACE || ch == cTAB { break }
          
          if ch == CR {
            UPDATE_STATE(.s_header_value_discard_ws_almost_done)
            break
          }
          if ch == LF {
            UPDATE_STATE(.s_header_value_discard_lws)
            break
          }
          
          /* FALLTHROUGH */
          fallthrough

        case .s_header_value_start:
          MARK(.HeaderValue)
          
          UPDATE_STATE(.s_header_value)
          self.index = 0

          let c = LOWER(ch)

          switch self.header_state {
            case .h_upgrade:
              _ = self.flags.insert(.F_UPGRADE)
              self.header_state = .h_general;

            case .h_transfer_encoding:
              /* looking for 'Transfer-Encoding: chunked' */
              if (cc == c) {
                self.header_state = .h_matching_transfer_encoding_chunked
              } else {
                self.header_state = .h_general
              }

            case .h_content_length:
              guard IS_NUM(ch) else { return .Error(.INVALID_CONTENT_LENGTH) }
              self.content_length = ch - c0;

            case .h_connection:
              /* looking for 'Connection: keep-alive' */
              if (c == ck) {
                self.header_state = .h_matching_connection_keep_alive;
              /* looking for 'Connection: close' */
              } else if (c == cc) {
                self.header_state = .h_matching_connection_close;
              } else if (c == cu) {
                self.header_state = .h_matching_connection_upgrade;
              } else {
                self.header_state = .h_matching_connection_token;
              }

            /* Multi-value `Connection` header */
            case .h_matching_connection_token_start: break

            default: self.header_state = .h_general; break
          }

        case .s_header_value:
          let start   = p
          var h_state = self.header_state
          
          while p != data! + len {
            let ch = p!.pointee
            
            if ch == CR {
              UPDATE_STATE(.s_header_almost_done);
              self.header_state = h_state;
              // CALLBACK_DATA(header_value);
              let rc = CALLBACK_DATA(.HeaderValue, &header_value_mark,
                                     &CURRENT_STATE, settings, p, data)
              if let rc = rc { return .CallbackDone(rc) }
              break // breaks while-loop
            }

            if ch == LF {
              UPDATE_STATE(.s_header_almost_done);
              guard COUNT_HEADER_SIZE(p! - start!) else {
                return .Error(.HEADER_OVERFLOW)
              }
              self.header_state = h_state;
              // CALLBACK_DATA_NOADVANCE(header_value);
              let rc = CALLBACK_DATA_NOADVANCE(.HeaderValue,
                                               &header_value_mark,
                                               &CURRENT_STATE, settings,
                                               p, data)
              if let rc = rc { return .CallbackDone(rc) }
              
              return .Reexecute
            }

            let c = LOWER(ch)

            switch h_state {
              case .h_general:
                var limit : size_t = data! + len - p!;

                limit = min(limit, HTTP_MAX_HEADER_SIZE);

                // p_cr = (const char*) memchr(p, CR, limit);
                // p_lf = (const char*) memchr(p, LF, limit);
#if os(Linux)
                let p_cr = UnsafePointer<CChar>(memchr(p!, Int32(CR), limit))
                let p_lf = UnsafePointer<CChar>(memchr(p!, Int32(LF), limit))
#else
                let p_cr = UnsafePointer<CChar>(memchr(p, Int32(CR), limit))
                let p_lf = UnsafePointer<CChar>(memchr(p, Int32(LF), limit))
#endif
                if p_cr != nil {
                  if p_lf != nil && p_cr >= p_lf {
                    p = p_lf
                  } else {
                    p = p_cr
                  }
                } else if p_lf != nil {
                  p = p_lf
                } else {
                  p = data! + len;
                }
                p! -= 1

              case .h_connection,
                   .h_transfer_encoding:
                assert(false, "Shouldn't get here.")

              case .h_content_length:
                if ch == cSPACE { break }

                guard IS_NUM(ch) else {
                  self.header_state = h_state;
                  return .Error(.INVALID_CONTENT_LENGTH)
                }

                var t = Int(self.content_length)
                t *= 10
                t += Int(ch - c0)

                /* Overflow? Test against a conservative limit for simplicity. */
                // HH: was ULLONG_MAX
                if (Int.max - 10) / 10 < self.content_length {
                  self.header_state = h_state;
                  return .Error(.INVALID_CONTENT_LENGTH)
                }

                self.content_length = Int(t)

              /* Transfer-Encoding: chunked */
              case .h_matching_transfer_encoding_chunked:
                self.index += 1
                if self.index > lCHUNKED || c != CHUNKED[self.index] {
                  h_state = .h_general
                } else if self.index == lCHUNKED-1 {
                  h_state = .h_transfer_encoding_chunked
                }

              case .h_matching_connection_token_start:
                /* looking for 'Connection: keep-alive' */
                if c == ck {
                  h_state = .h_matching_connection_keep_alive
                /* looking for 'Connection: close' */
                } else if c == cc {
                  h_state = .h_matching_connection_close
                } else if c == cu {
                  h_state = .h_matching_connection_upgrade
                } else if STRICT_TOKEN(c) != 0 {
                  h_state = .h_matching_connection_token
                } else if c == cSPACE || c == cTAB {
                  /* Skip lws */
                } else {
                  h_state = .h_general
                }

              /* looking for 'Connection: keep-alive' */
              case .h_matching_connection_keep_alive:
                self.index += 1;
                if self.index > lKEEP_ALIVE || c != KEEP_ALIVE[self.index] {
                  h_state = .h_matching_connection_token
                } else if self.index == lKEEP_ALIVE-1 {
                  h_state = .h_connection_keep_alive
                }

              /* looking for 'Connection: close' */
              case .h_matching_connection_close:
                self.index += 1
                if self.index > lCLOSE || c != CLOSE[self.index] {
                  h_state = .h_matching_connection_token
                } else if self.index == lCLOSE-1 {
                  h_state = .h_connection_close
                }

              /* looking for 'Connection: upgrade' */
              case .h_matching_connection_upgrade:
                self.index += 1
                if self.index > lUPGRADE || c != UPGRADE[self.index] {
                  h_state = .h_matching_connection_token
                } else if self.index == lUPGRADE-1 {
                  h_state = .h_connection_upgrade
                }

              case .h_matching_connection_token:
                if ch == cCOMMA {
                  h_state = .h_matching_connection_token_start
                  self.index = 0
                }

              case .h_transfer_encoding_chunked:
                if ch != cSPACE { h_state = .h_general }

              case .h_connection_keep_alive,
                   .h_connection_close,
                   .h_connection_upgrade:
                if ch == cCOMMA {
                  if h_state == .h_connection_keep_alive {
                    _ = self.flags.insert(.F_CONNECTION_KEEP_ALIVE)
                  } else if h_state == .h_connection_close {
                    _ = self.flags.insert(.F_CONNECTION_CLOSE)
                  } else if h_state == .h_connection_upgrade {
                    _ = self.flags.insert(.F_CONNECTION_UPGRADE)
                  }
                  h_state = .h_matching_connection_token_start
                  self.index = 0;
                } else if ch != cSPACE {
                  h_state = .h_matching_connection_token
                }

              default:
                UPDATE_STATE(.s_header_value)
                h_state = .h_general
            }
            
            p! += 1
          }
          self.header_state = h_state;

          guard COUNT_HEADER_SIZE(p! - start!) else {
            return .Error(.HEADER_OVERFLOW)
          }

          if (p == data! + len) {
            p! -= 1
          }

        case .s_header_almost_done:
          guard STRICT_CHECK(ch != LF) else { return .Error(.STRICT) }
          UPDATE_STATE(.s_header_value_lws)
          
        case .s_header_value_lws:
          if ch == cSPACE || ch == cTAB {
            UPDATE_STATE(.s_header_value_start)
            return .Reexecute
          }

          /* finished the header */
          switch self.header_state {
            case .h_connection_keep_alive:
              _ = self.flags.insert(.F_CONNECTION_KEEP_ALIVE)
            case .h_connection_close:
              _ = self.flags.insert(.F_CONNECTION_CLOSE)
            case .h_transfer_encoding_chunked:
              _ = self.flags.insert(.F_CHUNKED)
            case .h_connection_upgrade:
              _ = self.flags.insert(.F_CONNECTION_UPGRADE)
            default: break;
          }

          UPDATE_STATE(.s_header_field_start)
          return .Reexecute

        case .s_header_value_discard_ws_almost_done:
          guard STRICT_CHECK(ch != LF) else { return .Error(.STRICT) }
          UPDATE_STATE(.s_header_value_discard_lws)

        case .s_header_value_discard_lws:
          if (ch == cSPACE || ch == cTAB) {
            UPDATE_STATE(.s_header_value_discard_ws)
            break
          } else {
            switch self.header_state {
              case .h_connection_keep_alive:
                _ = self.flags.insert(.F_CONNECTION_KEEP_ALIVE)
              case .h_connection_close:
                _ = self.flags.insert(.F_CONNECTION_CLOSE)
              case .h_connection_upgrade:
                _ = self.flags.insert(.F_CONNECTION_UPGRADE)
              case .h_transfer_encoding_chunked:
                _ = self.flags.insert(.F_CHUNKED)
              default: break
            }

            /* header value was empty */
            MARK(.HeaderValue)
            UPDATE_STATE(.s_header_field_start);
            
            let rc = CALLBACK_DATA_NOADVANCE(.HeaderValue,
                                             &header_value_mark,
                                             &CURRENT_STATE, settings, p, data)
            if let rc = rc { return .CallbackDone(rc) }
            
            return .Reexecute
          }

        case .s_headers_almost_done:
          guard STRICT_CHECK(ch != LF) else { return .Error(.STRICT) }

          if self.flags.contains(.F_TRAILING) {
            /* End of a chunked request */
            UPDATE_STATE(.s_message_done);
            let rc = CALLBACK_NOTIFY_NOADVANCE(.ChunkComplete, &CURRENT_STATE,
                                               settings, p, data)
            if let rc = rc { return .CallbackDone(rc) }
            
            return .Reexecute
          }

          UPDATE_STATE(.s_headers_done);

          /* Set this here so that on_headers_complete() callbacks can see it */
          self.upgrade =
            ((self.flags.contains(.F_UPGRADE)
              && self.flags.contains(.F_CONNECTION_UPGRADE))
              || (self.method == .CONNECT))
          
          /* Here we call the headers_complete callback. This is somewhat
           * different than other callbacks because if the user returns 1, we
           * will interpret that as saying that this message has no body. This
           * is needed for the annoying case of recieving a response to a HEAD
           * request.
           *
           * We'd like to use CALLBACK_NOTIFY_NOADVANCE() here but we cannot, so
           * we have to simulate it by handling a change in errno below.
           */
          if let cb = settings.cbHeadersComplete {
            switch cb(self) {
              case 0:
                break;

              case 1:
                _ = self.flags.insert(.F_SKIPBODY)
                break;

              default:
                error = .CB_headers_complete
                return .Return(p! - data!)
            }
          }
          
          guard error == .OK else { return .Return(p! - data!)}
          
          return .Reexecute

        case .s_headers_done:
          guard STRICT_CHECK(ch != LF) else { return .Error(.STRICT) }

          self.nread = 0

          let hasBody = self.flags.contains(.F_CHUNKED) ||
            (self.content_length > 0
              && self.content_length != Int.max /* ULLONG_MAX */)
          if (self.upgrade && (self.method == .CONNECT ||
                                  (self.flags.contains(.F_SKIPBODY))
                                   || !hasBody))
          {
            /* Exit, the rest of the message is in a different protocol. */
            UPDATE_STATE(NEW_MESSAGE);
            // CALLBACK_NOTIFY(message_complete);
            let rc = CALLBACK_NOTIFY(.MessageComplete, &CURRENT_STATE,
                                     settings, p, data)
            if let rc = rc { return .CallbackDone(rc) }
            return .Return((p! - data!) + 1)
          }

          if self.flags.contains(.F_SKIPBODY) {
            UPDATE_STATE(NEW_MESSAGE);
            // CALLBACK_NOTIFY(message_complete);
            let rc = CALLBACK_NOTIFY(.MessageComplete, &CURRENT_STATE,
                                     settings, p, data)
            if let rc = rc { return .CallbackDone(rc) }
          } else if self.flags.contains(.F_CHUNKED) {
            /* chunked encoding - ignore Content-Length header */
            UPDATE_STATE(.s_chunk_size_start);
          } else {
            if self.content_length == 0 {
              /* Content-Length header given but zero: Content-Length: 0\r\n */
              UPDATE_STATE(NEW_MESSAGE);
              // CALLBACK_NOTIFY(message_complete);
              let rc = CALLBACK_NOTIFY(.MessageComplete, &CURRENT_STATE,
                                       settings, p, data)
              if let rc = rc { return .CallbackDone(rc) }
            } else if self.content_length != Int.max /* ULLONG_MAX */ {
              /* Content-Length header given and non-zero */
              UPDATE_STATE(.s_body_identity)
            } else {
              if (!messageNeedsEOF) {
                /* Assume content-length 0 - read the next */
                UPDATE_STATE(NEW_MESSAGE);
                // CALLBACK_NOTIFY(message_complete);
                let rc = CALLBACK_NOTIFY(.MessageComplete, &CURRENT_STATE,
                                         settings, p, data)
                if let rc = rc { return .CallbackDone(rc) }
              } else {
                /* Read body until EOF */
                UPDATE_STATE(.s_body_identity_eof)
              }
            }
          }

        case .s_body_identity:
          let to_read : Int /* uint64_t */ = min(self.content_length,
                                       ((data! + len) - p!));

          assert(self.content_length != 0
              && self.content_length != Int.max /* ULLONG_MAX */);

          /* The difference between advancing content_length and p is because
           * the latter will automaticaly advance on the next loop iteration.
           * Further, if content_length ends up at 0, we want to see the last
           * byte again for our message complete callback.
           */
          MARK(.Body)

          self.content_length -= to_read;
          p! += to_read - 1;

          if (self.content_length == 0) {
            UPDATE_STATE(.s_message_done);

            /* Mimic CALLBACK_DATA_NOADVANCE() but with one extra byte.
             *
             * The alternative to doing this is to wait for the next byte to
             * trigger the data callback, just as in every other case. The
             * problem with this is that this makes it difficult for the test
             * harness to distinguish between complete-on-EOF and
             * complete-on-length. It's not clear that this distinction is
             * important for applications, but let's keep it for now.
             */
            let rc = CALLBACK_DATA_(.Body, &body_mark, &CURRENT_STATE,
                                    settings, p! - body_mark! + 1, p! - data!)
            if let rc = rc { return .CallbackDone(rc) }
            
            return .Reexecute
          }

        
        /* read until EOF */
        case .s_body_identity_eof:
          MARK(.Body)
          p = data! + len - 1;
        
        case .s_message_done:
          UPDATE_STATE(NEW_MESSAGE)
          
          // CALLBACK_NOTIFY(message_complete);
          let rc = CALLBACK_NOTIFY(.MessageComplete, &CURRENT_STATE,
                                   settings, p, data)
          if let rc = rc { return .CallbackDone(rc) }
          
          if self.upgrade {
            /* Exit, the rest of the message is in a different protocol. */
            return .Return((p! - data!) + 1)
          }

        case .s_chunk_size_start:
          assert(self.nread == 1);
          assert(self.flags.contains(.F_CHUNKED))

          let unhex_val = unhex[Int(ch)]; // (unsigned char)
          guard unhex_val != -1 else {
            return .Error(.INVALID_CHUNK_SIZE)
          }

          self.content_length = Int(unhex_val)
          UPDATE_STATE(.s_chunk_size);

        case .s_chunk_size:
          assert(self.flags.contains(.F_CHUNKED))

          if ch == CR { UPDATE_STATE(.s_chunk_size_almost_done); break; }

          let unhex_val = unhex[Int(ch)]

          if unhex_val == -1 {
            if ch == cSEMICOLON || ch == cSPACE {
              UPDATE_STATE(.s_chunk_parameters);
              break
            }

            return .Error(.INVALID_CHUNK_SIZE)
          }

          var t = self.content_length
          t *= 16
          t += Int(unhex_val)

          /* Overflow? Test against a conservative limit for simplicity. */
          if ((Int.max /*ULLONG_MAX*/ - 16) / 16 < self.content_length) {
            return .Error(.INVALID_CONTENT_LENGTH)
          }
          
          self.content_length = t;

        case .s_chunk_parameters:
          assert(self.flags.contains(.F_CHUNKED))
          /* just ignore this shit. TODO check for overflow */
          if ch == CR {
            UPDATE_STATE(.s_chunk_size_almost_done);
          }

        case .s_chunk_size_almost_done:
          assert(self.flags.contains(.F_CHUNKED))
          guard STRICT_CHECK(ch != LF) else { return .Error(.STRICT) }

          self.nread = 0;

          if (self.content_length == 0) {
            _ = self.flags.insert(.F_TRAILING)
            UPDATE_STATE(.s_header_field_start)
          } else {
            UPDATE_STATE(.s_chunk_data)
          }
          
          // CALLBACK_NOTIFY(chunk_header);
          let rc = CALLBACK_NOTIFY(.ChunkHeader, &CURRENT_STATE, settings,
                                   p, data)
          if let rc = rc { return .CallbackDone(rc) }

        case .s_chunk_data:
          let to_read = min(self.content_length, ((data! + len) - p!))

          assert(self.flags.contains(.F_CHUNKED))
          assert(self.content_length != 0
              && self.content_length != Int.max /* ULLONG_MAX */)

          /* See the explanation in s_body_identity for why the content
           * length and data pointers are managed this way.
           */
          MARK(.Body)
          self.content_length -= to_read;
          p! += to_read - 1;

          if self.content_length == 0 {
            UPDATE_STATE(.s_chunk_data_almost_done);
          }
        
        case .s_chunk_data_almost_done:
          assert(self.flags.contains(.F_CHUNKED))
          assert(self.content_length == 0)
          guard STRICT_CHECK(ch != CR) else { return .Error(.STRICT) }
          UPDATE_STATE(.s_chunk_data_done);
          
          // CALLBACK_DATA(body);
          let rc = CALLBACK_DATA_(.Body, &body_mark, &CURRENT_STATE, settings,
                                  p! - body_mark! + 1, p! - data!)
          if let rc = rc { return .CallbackDone(rc) }

        case .s_chunk_data_done:
          assert(self.flags.contains(.F_CHUNKED))
          guard STRICT_CHECK(ch != LF) else { return .Error(.STRICT) }
          self.nread = 0
          UPDATE_STATE(.s_chunk_size_start);
          
          // CALLBACK_NOTIFY(chunk_complete);
          let rc = CALLBACK_NOTIFY(.ChunkComplete, &CURRENT_STATE, settings,
                                   p, data)
          if let rc = rc { return .CallbackDone(rc) }

        /* guaranteed by compiler ;-)
        default:
          assert(false) //  && "unhandled state");
          return .Error(.INVALID_INTERNAL_STATE)
         */
      }
      
      return .Continue // no exception, goto next byte
    }
    
    
    /* the main loop */
    
    assert(p == data)
    if debugOn { print("START LOOP len=\(p! - data!) \(CURRENT_STATE)") }
    while p! != (data! + len) {
      let ch = p!.pointee
      
      if debugOn {
        let s = String.fromCString(data!, length: p! - data!)!
        let sq = String(s.characters.map {
          if $0 == "\r" { return "#" }
          if $0 == "\n" { return "#" }
          return $0
        })
        print("\n+  LOOP CHAR \(debugChar(ch)) '\(sq)'"
              + " len=\(p! - data!) \(CURRENT_STATE)")
      }
      
      if CURRENT_STATE.isParsingHeader {
        if !COUNT_HEADER_SIZE(1) {
          if self.error == .OK { self.error = .UNKNOWN }
          return RETURN(p! - data!) // size consumed
        }
      }
      
      // Original: reexecute: switch CURRENT_STATE {} ...
      
      var rc = StepResult.Continue
      repeat {
        rc = step(ch)
        switch rc {
          case .Continue:
            if debugOn {
              print("  CONTINUE \(debugChar(ch)) " +
                    "len=\(p! - data!) \(CURRENT_STATE)")
            }
          
          case .Reexecute:
            if debugOn {
              print("  REEXECUTE \(debugChar(ch)) " +
                    "len=\(p! - data!) \(CURRENT_STATE)")
            }
          
          case .CallbackDone(let ER): // the C CALLBACK macros directly return
            if debugOn {
              print("  CALLBACK DONE \(debugChar(ch)) " +
                    "ER=\(ER) len=\(p! - data!) \(CURRENT_STATE)")
            }
            return ER
          
          case .Return(let len):
            // this is different to CBDone in that it updates the state
            if debugOn {
              print("  RETURN \(debugChar(ch))" +
                    " LEN=\(len) len=\(p! - data!) \(CURRENT_STATE)")
            }
            return RETURN(len)
          
          case .Error(let error):
            if debugOn {
              print("  ERROR \(debugChar(ch)) \(error)" +
                    " LEN=\(len) len=\(p! - data!) \(CURRENT_STATE)")
            }
            self.error = error == .OK ? .UNKNOWN : error
            return RETURN(p! - data!) // size consumed
        }
      } while rc.isReexecute
      
      //if let len = gotoReexecute() { return len } // error?
      
      // FOR LOOP END
      p! += 1
    }
    if debugOn { print("LOOP DONE len=\(p! - data!) \(CURRENT_STATE)") }
    
    
    /* Run callbacks for any marks that we have leftover after we ran our of
     * bytes. There should be at most one of these set, so it's OK to invoke
     * them in series (unset marks will not result in callbacks).
     *
     * We use the NOADVANCE() variety of callbacks here because 'p' has already
     * overflowed 'data' and this allows us to correct for the off-by-one that
     * we'd otherwise have (since CALLBACK_DATA() is meant to be run with a 'p'
     * value that's in-bounds).
     */

    /* this seems to xhang swiftc 2.2
     assert(((header_field_mark != nil ? 1 : 0) +
             (header_value_mark != nil ? 1 : 0) +
             (url_mark          != nil ? 1 : 0) +
             (body_mark         != nil ? 1 : 0) +
             (status_mark       != nil ? 1 : 0)) <= 1);
    */
     var rc = CALLBACK_DATA_NOADVANCE(.HeaderField, &header_field_mark,
                                      &CURRENT_STATE, settings, p, data)
     if let rc1 = rc { return rc1 } // error
    
     rc = CALLBACK_DATA_NOADVANCE(.HeaderValue, &header_value_mark,
                                  &CURRENT_STATE, settings, p, data)
     if let rc2 = rc { return rc2 } // error
    
     rc = CALLBACK_DATA_NOADVANCE(.URL, &url_mark, &CURRENT_STATE, settings,
                                  p, data)
     if let rc3 = rc { return rc3 } // error
    
     rc = CALLBACK_DATA_NOADVANCE(.Body, &body_mark, &CURRENT_STATE, settings,
                                  p, data)
     if let rc4 = rc { return rc4 } // error
    
     rc = CALLBACK_DATA_NOADVANCE(.Status, &status_mark, &CURRENT_STATE,
                                  settings, p, data)
     if let rc5 = rc { return rc5 } // error
 
     // regular return
     return RETURN(len)
  }
 
  @inline(__always)
  internal mutating func STRICT_CHECK(_ condition: Bool) -> Bool {
    // the original has a 'goto error'
    if HTTP_PARSER_STRICT {
      if condition {
        error = .STRICT
        return false
      }
      return true
    }
    else {
      return true
    }
  }
  

  /* Don't allow the total size of the HTTP headers (including the status
   * line) to exceed HTTP_MAX_HEADER_SIZE.  This check is here to protect
   * embedders against denial-of-service attacks where the attacker feeds
   * us a never-ending header that the embedder keeps buffering.
   *
   * This check is arguably the responsibility of embedders but we're doing
   * it on the embedder's behalf because most won't bother and this way we
   * make the web a little safer.  HTTP_MAX_HEADER_SIZE is still far bigger
   * than any reasonable request or response so this should never affect
   * day-to-day operation.
   */
  @inline(__always)
  internal mutating func COUNT_HEADER_SIZE(_ V: Int) -> Bool {
    self.nread += V
    if self.nread > HTTP_MAX_HEADER_SIZE {
      error = .HEADER_OVERFLOW
      return false // original does 'goto error'
    }
    return true
  }
}

func debugChar(_ ch: CChar) -> String {
  let p : String
  switch ch {
    case LF:   p = "NL"
    case CR:   p = "CR"
    case cTAB: p = "TAB"
    default:   p = "'\(UnicodeScalar(Int(ch)))'"
  }
  return "\(ch) \(p)"
}

#endif // Swift 3
