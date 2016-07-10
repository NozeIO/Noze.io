//
//  Module.swift
//  Noze.io
//
//  Created by Helge Heß on 4/10/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

@_exported import core
@_exported import streams
import net

public class NozeHTTP : NozeModule {
}
public let module = NozeHTTP()



// MARK: - Server

#if swift(>=3.0) // #swift3-discardable-result
/// Creates an `http.Server` object and attaches a provided `onRequest` handler.
///
/// To activate the server, the `listen` method needs to be called.
///
/// Example:
///
///     http.createServer { req, res in
///       res.end("Hello World!")
///     }
///     .listen(1337)
///
@discardableResult
public func createServer(enableLogger el: Bool = false,
                         onRequest: RequestEventCB? = nil) -> Server {
  let srv = Server(enableLogger: el)
  if let cb = onRequest { _ = srv.onRequest(handler: cb) }
  return srv
}
#else // Swift 2.2
/// Creates an `http.Server` object and attaches a provided `onRequest` handler.
///
/// To activate the server, the `listen` method needs to be called.
///
/// Example:
///
///     http.createServer { req, res in
///       res.end("Hello World!")
///     }
///     .listen(1337)
///
public func createServer(enableLogger el: Bool = false,
                         onRequest: RequestEventCB? = nil) -> Server {
  let srv = Server(enableLogger: el)
  if let cb = onRequest { _ = srv.onRequest(handler: cb) }
  return srv
}
#endif


// MARK: - Client

let globalAgent = Agent()

public func request(options    opts : RequestOptions,
                    onResponse cb   : (( IncomingMessage ) -> Void)?)
            -> ClientRequest
{
  let req = ClientRequest(options: opts)
  if let c = cb { _ = req.onResponse(handler: c) }
  return req
}


public func request(url        s : String,
                    onResponse cb : (( IncomingMessage ) -> Void)?)
            -> ClientRequest
{
  let lurl = url.parse(s)
  
  let options = RequestOptions()
  options.scheme   = lurl.scheme ?? options.scheme
  options.hostname = lurl.host   ?? options.hostname
  options.port     = lurl.port   ?? options.port
  options.path     = lurl.path   ?? options.path
  
  return request(options: options, onResponse: cb)
}

public func get(url s : String, onResponse cb : (( IncomingMessage ) -> Void)?)
            -> ClientRequest
{
  let req = request(url: s, onResponse: cb)
  req.end()
  return req
}

public func get(options    o  : RequestOptions,
                onResponse cb : (( IncomingMessage ) -> Void)?)
            -> ClientRequest
{
  let req = request(options: o, onResponse: cb)
  req.end()
  return req
}


#if swift(>=3.0) // #swift3-1st-arg #swift3-discardable-result
@discardableResult
public func request(_ s : String,
                    onResponse cb : (( IncomingMessage ) -> Void)?)
            -> ClientRequest
{
  return request(url: s, onResponse: cb)
}
@discardableResult
public func get(_ s : String, onResponse cb : (( IncomingMessage ) -> Void)?)
            -> ClientRequest
{
  return get(url: s, onResponse: cb)
}
#else // Swift 2.2
public func request(s : String,
                    onResponse cb : (( IncomingMessage ) -> Void)?)
            -> ClientRequest
{
  return request(url: s, onResponse: cb)
}
public func get(s : String, onResponse cb : (( IncomingMessage ) -> Void)?)
            -> ClientRequest
{
  return get(url: s, onResponse: cb)
}
#endif // Swift 2.2


// MARK: - Reexport some Parser things

import enum http_parser.HTTPError
import enum http_parser.HTTPMethod
public typealias HTTPError  = http_parser.HTTPError
public typealias HTTPMethod = http_parser.HTTPMethod


// MARK: - Constants

/// Supported HTTP methods by parser
public let METHODS : [ String ] = [
  "DELETE",
  "GET",
  "HEAD",
  "POST",
  "PUT",
  "CONNECT",
  "OPTIONS",
  "TRACE",
  "COPY",
  "LOCK",
  "MKCOL",
  "MOVE",
  "PROPFIND",
  "PROPPATCH",
  "SEARCH",
  "UNLOCK",
  "BIND",
  "REBIND",
  "UNBIND",
  "ACL",
  "REPORT",
  "MKACTIVITY",
  "CHECKOUT",
  "MERGE",
  "MSEARCH",
  "NOTIFY",
  "SUBSCRIBE",
  "UNSUBSCRIBE",
  "PATCH",
  "PURGE",
  "MKCALENDAR",
  "LINK",
  "UNLINK"
]

public let STATUS_CODES : [ Int : String ] = [
  // TODO: complete me (in http_parser as well)
  200: "OK",
  201: "Created",
  204: "No Content",
  207: "MultiStatus",

  400: "Bad Request",
  401: "Unauthorized",
  402: "Payment Required",
  403: "FORBIDDEN",
  404: "NOT FOUND",
  405: "Method not allowed"
]
