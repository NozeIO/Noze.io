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


// MARK: - Client

let globalAgent = Agent()

/**
 * Example:
 *
 *     let req = request(options) { res in
 *       print("Response status: \(res.statusCode)")"
 *       res | utf8 | concat { data in
 *         result = String(data) // convert characters into String
 *         print("Response body: \(result)")
 *       }
 *     }
 */
@discardableResult
public func request(_ options     : RequestOptions,
                    onResponse cb : (( IncomingMessage ) -> Void)?)
            -> ClientRequest
{
  let req = ClientRequest(options: options)
  if let c = cb { _ = req.onResponse(handler: c) }
  return req
}

/**
 * Example:
 *
 *     let req = request("http://www.zeezide.de/") { res in
 *       print("Response status: \(res.statusCode)")"
 *       res | utf8 | concat { data in
 *         result = String(data) // convert characters into String
 *         print("Response body: \(result)")
 *       }
 *     }
 */
@discardableResult
public func request(_ url         : String,
                    onResponse cb : (( IncomingMessage ) -> Void)?)
            -> ClientRequest
{
  let lurl = http.url.parse(url)
  
  let options = RequestOptions()
  options.scheme   = lurl.scheme ?? options.scheme
  options.hostname = lurl.host   ?? options.hostname
  options.port     = lurl.port   ?? options.port
  options.path     = lurl.path   ?? options.path
  
  return request(options, onResponse: cb)
}

@discardableResult
public func get(_ s : String, onResponse cb : (( IncomingMessage ) -> Void)?)
            -> ClientRequest
{
  let req = request(s, onResponse: cb)
  req.end()
  return req
}

@discardableResult
public func get(_          o  : RequestOptions,
                onResponse cb : (( IncomingMessage ) -> Void)?)
            -> ClientRequest
{
  let req = request(o, onResponse: cb)
  req.end()
  return req
}


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
