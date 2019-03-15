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
  
  func json(_ object: JSON) {
    if canAssignContentType {
      setHeader("Content-Type", "application/json; charset=utf-8")
    }
    writeJSON(object: object)
    end()
  }
}


// MARK: - Helpers

public extension ServerResponse {

  func json(_ object: JSONEncodable) {
    json(object.toJSON())
  }
  
  func json(_ object: Any?) {
    if let o = object {
      if let jsonEncodable = (o as? JSONEncodable) {
        json(jsonEncodable)
      }
      else {
        json(String(0))
      }
    }
    else {
      json(.Null)
    }
  }
}

