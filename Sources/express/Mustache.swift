//
//  Mustache.swift
//  Noze.io
//
//  Created by Helge Hess on 02/06/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import fs
import console
import mustache

let mustacheExpress : ExpressEngine = { path, options, done in
  fs.readFile(path, "utf8") { str, err in
    guard err == nil else {
      done(err!)
      return
    }
    
    guard let template = str else {
      console.error("read file return no error but no string either: \(path)")
      done("Got no string?")
      return
    }
    
    let parser = MustacheParser()
    let tree   = parser.parse(string: template)
    let result = tree.render(object: options)
    
    done(nil, result)
  }
}
