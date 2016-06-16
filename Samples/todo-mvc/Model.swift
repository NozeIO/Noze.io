//
//  Model.swift
//  Noze.io
//
//  Created by Helge Heß on 6/3/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import Freddy

struct Todo {
  
  var id        : Int
  var title     : String
  var completed : Bool
  var order     : Int
  
  var url : String { // this is a little weird API wise, but well ...
    return "\(ourAPI)todos/\(id)"
  }
  
}

extension Todo : JSONEncodable {
  
  func toJSON() -> JSON { // TODO: default imp via Mirror
    return JSON.Dictionary([
      "url"       : JSON(url),
      "id"        : JSON(id),
      "title"     : JSON(title),
      "completed" : JSON(completed),
      "order"     : JSON(order)
    ])
  }
}

extension Todo : JSONDecodable {
  
  init(json: JSON) throws {
    // Note: this does NOT work for partial objects!
    id        = try json.int   ("id")
    title     = try json.string("title")
    completed = try json.bool  ("completed")
    order     = try json.int   ("order")
  }
  
}
