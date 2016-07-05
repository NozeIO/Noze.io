//
//  HTTPParserState.swift
//  HTTPParser
//
//  Created by Helge Hess on 26/04/16.
//  Copyright © 2016 Always Right Institute. All rights reserved.
//

#if swift(>=3.0) // #swift3-fd
#else
public typealias OptionSet = OptionSetType
#endif

// enum in original
public struct HTTPParserOptions : OptionSet {
  // Use: let justChunked = HTTPParserOptions.F_CHUNKED
  //      let two : HTTPParserOptions = [ F_CHUNKED, F_CONNECTION_CLOSE]
  //      two.contains(.F_CONNECTION_CLOSE)
  
  public let rawValue : Int
  
  public init(rawValue: Int = 0) {
    self.rawValue = rawValue
  }
  
  static let F_CHUNKED               = HTTPParserOptions(rawValue: 1 << 0)
  static let F_CONNECTION_KEEP_ALIVE = HTTPParserOptions(rawValue: 1 << 1)
  static let F_CONNECTION_CLOSE      = HTTPParserOptions(rawValue: 1 << 2)
  static let F_CONNECTION_UPGRADE    = HTTPParserOptions(rawValue: 1 << 3)
  static let F_TRAILING              = HTTPParserOptions(rawValue: 1 << 4)
  static let F_UPGRADE               = HTTPParserOptions(rawValue: 1 << 5)
  static let F_SKIPBODY              = HTTPParserOptions(rawValue: 1 << 6)
}

enum ParserState : Int8 {
  case s_dead = 1 /* important that this is > 0 */
  
  case s_start_req_or_res
  case s_res_or_resp_H
  case s_start_res
  case s_res_H
  case s_res_HT
  case s_res_HTT
  case s_res_HTTP
  case s_res_first_http_major
  case s_res_http_major
  case s_res_first_http_minor
  case s_res_http_minor
  case s_res_first_status_code
  case s_res_status_code
  case s_res_status_start
  case s_res_status
  case s_res_line_almost_done
  
  case s_start_req
  
  case s_req_method
  case s_req_spaces_before_url
  case s_req_schema
  case s_req_schema_slash
  case s_req_schema_slash_slash
  case s_req_server_start
  case s_req_server
  case s_req_server_with_at
  case s_req_path
  case s_req_query_string_start
  case s_req_query_string
  case s_req_fragment_start
  case s_req_fragment
  case s_req_http_start
  case s_req_http_H
  case s_req_http_HT
  case s_req_http_HTT
  case s_req_http_HTTP
  case s_req_first_http_major
  case s_req_http_major
  case s_req_first_http_minor
  case s_req_http_minor
  case s_req_line_almost_done
  
  case s_header_field_start
  case s_header_field
  case s_header_value_discard_ws
  case s_header_value_discard_ws_almost_done
  case s_header_value_discard_lws
  case s_header_value_start
  case s_header_value
  case s_header_value_lws
  
  case s_header_almost_done
  
  case s_chunk_size_start
  case s_chunk_size
  case s_chunk_parameters
  case s_chunk_size_almost_done
  
  case s_headers_almost_done
  case s_headers_done
  
  /* Important: 's_headers_done' must be the last 'header' state. All
   * states beyond this must be 'body' states. It is used for overflow
   * checking. See the isParsingHeader property.
   */
  
  case s_chunk_data
  case s_chunk_data_almost_done
  case s_chunk_data_done
  
  case s_body_identity
  case s_body_identity_eof
  
  case s_message_done
  
  
  // PARSING_HEADER macro in orig
  var isParsingHeader : Bool {
    return self.rawValue <= ParserState.s_headers_done.rawValue
  }
  
  var isURLMarkerState : Bool {
    switch self {
      case .s_req_path,
           .s_req_schema,.s_req_schema_slash, .s_req_schema_slash_slash,
           .s_req_server_start, .s_req_server, .s_req_server_with_at,
           .s_req_query_string_start, .s_req_query_string,
           .s_req_fragment_start, .s_req_fragment:
        return true
      default:
        return false
    }
  }
}

enum ParserHeaderState : Int {
  case h_general = 0
  case h_C
  case h_CO
  case h_CON
  
  case h_matching_connection
  case h_matching_proxy_connection
  case h_matching_content_length
  case h_matching_transfer_encoding
  case h_matching_upgrade
  
  case h_connection
  case h_content_length
  case h_transfer_encoding
  case h_upgrade
  
  case h_matching_transfer_encoding_chunked
  case h_matching_connection_token_start
  case h_matching_connection_keep_alive
  case h_matching_connection_close
  case h_matching_connection_upgrade
  case h_matching_connection_token
  
  case h_transfer_encoding_chunked
  case h_connection_keep_alive
  case h_connection_close
  case h_connection_upgrade
}

enum ParserHTTPHostState : Int {
  case s_http_host_dead = 1
  case s_http_userinfo_start
  case s_http_userinfo
  case s_http_host_start
  case s_http_host_v6_start
  case s_http_host
  case s_http_host_v6
  case s_http_host_v6_end
  case s_http_host_v6_zone_start
  case s_http_host_v6_zone
  case s_http_host_port_start
  case s_http_host_port
}

