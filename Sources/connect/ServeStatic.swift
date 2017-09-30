//
//  ServeStatic.swift
//  Noze.io
//
//  Created by Helge Heß on 08/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import fs
import process
import http

public enum ServeFilePermission {
  case Allow, Deny, Ignore
}

public enum IndexBehaviour {
  case None
  case IndexFile (String)
  case IndexFiles([String])
  
  public init() {
    self = .IndexFile("index.html")
  }
}

public struct ServeStaticOptions {
  
  public let dotfiles     = ServeFilePermission.Allow
  public let etag         = false
  public let extensions   : [ String ]? = nil
  public let index        = IndexBehaviour()
  public let lastModified = true
  public let redirect     = true
 
  public init() {} // otherwise init is private
}

public func serveStatic(path    p : String = process.cwd(),
                        options o : ServeStaticOptions = ServeStaticOptions())
            -> Middleware
{
  // Note: 'static' is a reserved work ...
  // TODO: wrapped request with originalUrl, baseUrl etc
  
  let lPath = !p.isEmpty ? p : process.cwd()
  
  // options
  let options = ServeStaticOptions()
  
  // middleware
  return { req, res, next in
    // we only want HEAD + GET
    guard req.method == "HEAD" || req.method == "GET" else { next(); return }
    
    // parse URL
    let url  = URL(req.url)
    guard let rqPath = url.path else { next(); return }
    
    // FIXME: sanitize URL, remove '..' etc!!!
    
    // naive implementation
    let fsPath = lPath + rqPath
    
    
    // dotfiles
    
    // TODO: extract last path component, check whether it is a dotfile
    let isDotFile = fsPath.hasPrefix(".") // TODO
    if isDotFile {
      switch options.dotfiles {
        case .Allow:  break
        case .Ignore: next(); return
        case .Deny:
          res.writeHead(404)
          res.end()
          return
      }
    }
    
    
    // stat
    fs.stat(fsPath) { err, stat in
      guard err == nil && stat != nil else { next(); return }
      let lStat = stat!
      
      
      // directory
      
      if lStat.isDirectory() {
        if options.redirect && !rqPath.hasSuffix("/") {
          res.writeHead(308, [ "Location": rqPath + "/" ])
          res.end()
          return
        }
        
        switch options.index {
          case .IndexFile(let filename):
            let indexPath =
              (fsPath.hasSuffix("/") ? fsPath : fsPath + "/")
              + filename
            
            fs.stat(indexPath) { err, stat in // TODO: reuse closure
              guard err == nil && stat != nil else { next(); return }
              guard stat?.isFile() ?? false   else { next(); return }
              
              // TODO: content-type?
              res.writeHead(200)
              _ = fs.createReadStream(indexPath) | res
            }
            return
          
          default: // TODO: implement multi-option
            res.writeHead(404)
            res.end()
            return
        }
      }
      
      
      // regular file
      
      guard lStat.isFile() else { next(); return }
      
      // TODO: content-type?
      res.writeHead(200)
      _ = fs.createReadStream(fsPath) | res
    }
  }
}


// MARK: - Convenience methods

public func serveStatic(_       p : String = process.cwd(),
                        options o : ServeStaticOptions = ServeStaticOptions())
            -> Middleware
{
  return serveStatic(path: p, options: o)
}
