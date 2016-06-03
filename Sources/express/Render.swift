//
//  Render.swift
//  Noze.io
//
//  Created by Helge Heß on 6/2/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import fs
import process
import http
import console

public extension ServerResponse {
  
  // TODO: How do we get access to the application?? Need to attach to the
  //       request? We need to retrieve values.
  
  public func render(template: String, _ options : Any? = nil) {
    let res = self
    
    guard let app = self.app else {
      console.error("No app object assigned to response: \(self)")
      res.writeHead(500)
      res.end()
      return
    }
    
    let viewEngine = (app.get("view engine") as? String) ?? "mustache"
    guard let engine = app.engines[viewEngine] else {
      console.error("Did not find view engine: \(viewEngine)")
      res.writeHead(500)
      res.end()
      return
    }

    let viewsPath      = (app.get("views") as? String) ?? process.cwd()

    let emptyOpts      : [ String : Any ] = [:]
    let appViewOptions = app.get("view options") ?? emptyOpts
    let viewOptions    = options ?? appViewOptions // TODO: merge if possible
    
    lookupTemplate(views: viewsPath, template: template, engine: viewEngine) {
      pathOrNot in
      guard let path = pathOrNot else {
        res.writeHead(404)
        res.end()
        return
      }
      
      engine(path: path, options: viewOptions) { results in
        let rc = results.count
        let v0 = rc > 0 ? results[0] : nil
        let v1 = rc > 1 ? results[1] : nil
        
        if let error = v0 {
          console.error("template error: \(error)")
          res.writeHead(500)
          res.end()
          return
        }
        
        guard let result = v1 else {
          console.warn("template returned no content: \(template) \(results)")
          res.writeHead(204)
          res.end()
          return
        }

        // TBD: maybe support a stream as a result? (result.pipe(res))
        let s = (result as? String) ?? "\(result)"
        
        if res.getHeader("Content-Type") == nil {
          res.setHeader("Content-Type", "text/html; charset=utf-8")
        }
        
        res.writeHead(200)
        res.write(s)
        res.end()
      }
    }
  }
  
}

private func lookupTemplate(views p: String, template t: String,
                            engine e: String, _ cb: ( String? ) -> Void)
{
  // TODO: try other combos
  let fsPath = "\(p)/\(t).\(e)"
  fs.stat(fsPath) { err, stat in
    guard err == nil && stat != nil else {
      console.error("did not find template \(t) at \(fsPath)")
      cb(nil)
      return
    }
    guard stat!.isFile() else {
      console.error("template path is not a file: \(fsPath)")
      cb(nil)
      return
    }
    cb(fsPath)
  }
}


#if swift(>=3.0) // #swift3-1st-arg
public extension ServerResponse {
  public func render(_ t: String, _ options : Any? = nil) {
    render(template: t, options)
  }
}
#endif


// Some protocol is implemented in Foundation, requiring this.
#if os(Linux)
#if swift(>=3.0)
  import Foundation
#endif
#else // Darwin
  import Foundation
#endif // Darwin
