// Noze.io Cookie Setting Web Server
// - to compile in Swift 3 invoke: swift build
// - to run result: .build/debug/httpd-cookies

import xsys
import http

let links = [
  ( "/",        "Reload"    ),
  ( "/set",     "Set"       ),
  ( "/reset",   "Reset"     ),
  ( "/age10s",  "Age10s"    ),
  ( "/expires", "Expire10s" )
]

_ = http.createServer { req, res in
  let cookies = Cookies(req, res)
  
  switch req.url {
    
    case "/set":
      cookies.set("theAnswer", "42")
      res.writeHead(302, [ "Location": "/" ])
      return res.end("Now let's check.")
    
    case "/age10s":
      cookies.set("theAnswer", "42", maxAge: 10)
      res.writeHead(302, [ "Location": "/" ])
      return res.end("Now let's check.")
    
    case "/expires":
      let expires = time_t.now + 10
      cookies.set("theAnswer", "42", expires: expires)
      res.writeHead(302, [ "Location": "/" ])
      return res.end("Now let's check.")
    
    case "/reset":
      cookies.reset("theAnswer")
      res.writeHead(302, [ "Location": "/" ])
      return res.end("Now let's check.")

    default:
      res.writeHead(200, [ "Content-Type": "text/html" ])
      res.write("<h1>Cookies at: \(req.url)</h1>")

      let navLinks = links.map { "<a href=\"\($0)\">\($1)</a>" }
      res.write("<p>" + navLinks.joined(separator: " | ") + "</p>")
      
      res.write("<table><tbody>")
      for (name, value) in cookies.cookies {
        res.write("<tr><td>\(name)</td><td>\(value)</td></tr>")
      }
      res.write("</tbody></table>")
      
      // finish up
      res.end()
  }
}
.listen(1337) {
  print("Server listening: \($0)")
}
