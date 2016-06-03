// Noze.io Hello World Web Server
// - to compile in Swift 3 invoke: swift build
// - to run result: .build/debug/httpd-static

import xsys // for String.hasPrefix
import func process.cwd
import console
import fs
import http

// Naive static HTTP server, for demo purposes only. This one doesn't use any
// Connect etc, just the plain `http` module.

let __dirname = process.cwd() // our modules have no __dirname
print("DIR: \(__dirname)")

_ = http.createServer
  { req, res in
    func serve(path p: String, type: String) {
      fs.stat(p) { err, stat in
        if err != nil || stat == nil || !stat!.isFile() {
          res.writeHead(404)
          res.end()
          console.error("404: \(p)")
        }
        else { // got it
          console.info("200: \(p) \(type)")
          res.writeHead(200, [ "Content-Type": type ])
          fs.createReadStream(p) | res
        }
      }
    }
    
    // 'route'

    if req.method == "GET" && req.url.hasPrefix("/images") {
      serve(path: __dirname + req.url, type: "image/png")
    }
    else if req.method == "GET" && req.url == "/" {
      serve(path: __dirname + "/index.html", type: "text/html")
    }
    else {
      res.writeHead(404)
      res.end()
      console.error("404: \(req.method) \(req.url)")
    }
  }
  .listen(1337) {
    print("Server listening: \($0)")
  }
