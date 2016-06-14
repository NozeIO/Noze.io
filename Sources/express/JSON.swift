//
//  JSON.swift
//  Noze.io
//
//  Created by Helge Heß on 6/3/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import streams
import http
import json
@_exported import Freddy

public extension ServerResponse {
  // TODO: add jsonp
  // TODO: be a proper stream
  // TODO: Maybe we don't want to convert to a `JSON`, but rather stream real
  //       object.
  
  public func json(object: JSON) {
    if canAssignContentType {
      setHeader("Content-Type", "application/json; charset=utf-8")
    }
    writeJSON(object: object)
    end()
  }
}


// MARK: - Helpers

#if swift(>=3.0) // #swift3-1st-kwarg

public extension ServerResponse {

  public func json(_ object: JSON) { json(object: object) }
  
  public func json(_ object: JSONEncodable) {
    json(object: object.toJSON())
  }
  
  public func json(_ object: Any?) {
    if let o = object {
      if let jsonEncodable = (o as? JSONEncodable) {
        json(jsonEncodable)
      }
      else {
        json(String(0))
      }
    }
    else {
      json(object: .Null)
    }
  }
}

#else // Swift 2.2
  
public extension ServerResponse {
  
  public func json(object: JSONEncodable) {
    json(object.toJSON())
  }

  public func json(object: Any?) {
    if let o = object {
      if let jsonEncodable = (o as? JSONEncodable) {
        json(jsonEncodable)
      }
      else {
        json("\(o)")
      }
    }
    else {
      json(.Null)
    }
  }
  
}
  
#endif // Swift 2.2
