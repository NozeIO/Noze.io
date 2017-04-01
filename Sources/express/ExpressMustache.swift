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
  fs.readFile(path, "utf8") { err, str in
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
    
    let ctx = ExpressMustacheContext(path: path, object: options)
    tree.render(inContext: ctx) { result in
      done(nil, result)
    }
  }
}

class ExpressMustacheContext : MustacheDefaultRenderingContext {
  
  let viewPath : String
  
  init(path p: String, object root: Any?) {
    self.viewPath = path.dirname(p)
    super.init(root)
  }
  
  override func retrievePartial(name n: String) -> MustacheNode? {
    let ext         = ".mustache"
    let partialPath = viewPath + "/" + (n.hasSuffix(ext) ? n : (n + ext))
    
    guard let template = fs.readFileSync(partialPath, "utf8") else {
      console.error("could not load partial: \(n): \(partialPath)")
      return nil
    }
    
    let parser = MustacheParser()
    let tree   = parser.parse(string: template)
    return tree
  }
  
}