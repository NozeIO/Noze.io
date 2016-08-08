//
//  BodyParser.swift
//  Noze.io
//
//  Created by Helge Hess on 30/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import http
import json

public typealias BodyParserJSON = json.JSON

/// An enum which stores the result of the `bodyParser` middleware. The result
/// can be accessed as `request.body`, e.g.
///
///     if case .JSON(let json) = request.body {
///       // do JSON stuff
///     }
///
public enum BodyParserBody {
  
  case NotParsed
  case NoBody // IsPerfect
  case Error(SwiftError)
  
  case URLEncoded(Dictionary<String, Any>)
  
  case JSON(BodyParserJSON)
  
  case Raw([UInt8])
  case Text(String)
  
  public var json : BodyParserJSON? {
    switch self {
      case .JSON(let json): return json
      default: return nil
    }
  }
  
  public var text : String? {
    switch self {
      case .Text(let s): return s
      default: return nil
    }
  }
}

public extension BodyParserBody {
  
  public subscript(key : String) -> Any? {
    get {
      switch self {
        case .URLEncoded(let dict): return dict[key]
        // TODO: support JSON
        default: return nil
      }
    }
  }
  public subscript(string key : String) -> String {
    get {
      switch self {
        case .URLEncoded(let dict):
          guard let v = dict[key] else { return "" }
          if let s = v as? String                  { return s }
          if let s = v as? CustomStringConvertible { return s.description }
          return "\(v)"
        
        // TODO: support JSON
        default: return ""
      }
    }
  }
}

extension BodyParserBody : ExpressibleByStringLiteral {

  public init(stringLiteral value: String) {
    self = .Text(value)
  }
  
  public init(extendedGraphemeClusterLiteral value: StringLiteralType) {
    self = .Text(value)
  }
  
  public init(unicodeScalarLiteral value: StringLiteralType) {
    self = .Text(value)
  }
}


// Module holding the different variants of bodyParsers.
public struct bodyParser {
  
  public class Options {
    let inflate = false
    let limit   = 100 * 1024
  }
  
  private static let requestKey = "io.noze.connect.body-parser.body"
}


public enum BodyParserError : Error {
  
  case ExtraStoreInconsistency
  
}


// MARK: - IncomingMessage extension

public extension IncomingMessage {
  
  public var body : BodyParserBody {
    set {
      extra[bodyParser.requestKey] = newValue
    }
    
    get {
      guard let body = extra[bodyParser.requestKey] else {
        return BodyParserBody.NotParsed
      }
      
      if let body = body as? BodyParserBody { return body }
      
      return BodyParserBody.Error(BodyParserError.ExtraStoreInconsistency)
    }
  }
  
}


// MARK: - JSON

// curl -H "Content-type: application/json" -X POST \
//   -d '{ "login": "xyz", "password": "opq", "port": 80 }' \
//   http://localhost:1337/login

public extension bodyParser {
  
  /// This middleware parses the request body if the content-type is JSON,
  /// and pushes the the JSON parse result into the `body` property of the
  /// request.
  ///
  /// Example:
  ///
  ///     app.use(bodyParser.json())
  ///     app.use { req, res, next in
  ///       print("Log JSON Body: \(req.body.json)")
  ///       next()
  ///     }
  ///
  public static func json(options opts: Options = Options()) -> Middleware {
    
    return { req, res, next in
      guard typeIs(req, [ "json" ]) != nil else { next(); return }
      
      // lame, should be streaming
      _ = req | concat { bytes in
        let result = BodyParserJSON.parse(bytes)
        // TODO: error?
        req.body = result != nil ? .JSON(result!) : .NoBody
        next()
      }
    }
    
  }

}


// MARK: - Raw & Text

public extension bodyParser {

  public static func raw(options opts: Options = Options()) -> Middleware {
    return { req, res, next in
      // lame, should be streaming
      _ = req | concat { bytes in
        req.body = .Raw(bytes)
        next()
      }
    }
  }
  
  public static func text(options opts: Options = Options()) -> Middleware {
    return { req, res, next in
      // text/plain, text/html etc
      // TODO: properly process charset parameter, this assumes UTF-8
      guard typeIs(req, [ "text" ]) != nil else { next(); return }
      
      // lame, should be streaming
      _ = req | utf8 | concat { chars in
        req.body = .Text(String(chars))
        next()
      }
    }
  }
  
}


// MARK: - URL Encoded

public extension bodyParser {
  
  public static func urlencoded(options opts: Options = Options())
                     -> Middleware
  {
    return { req, res, next in
      guard typeIs(req, [ "application/x-www-form-urlencoded" ]) != nil else {
        next()
        return
      }
      
      // TODO: `extended` option. (maps to our zopeFormats?)
      _ = req | utf8 | concat { chars in
        let qp = querystring.parse(String(chars))
        req.body = .URLEncoded(qp)
        next()
      }
    }
  }
}
