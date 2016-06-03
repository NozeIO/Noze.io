// Noze.io Simple Connect based WebServer
// - to compile in Swift 3 invoke: swift build
// - to run result: .build/debug/connect-git

import http
import connect
import console
import child_process

let app = connect()

// Middleware: logs the request
app.use(logger("dev"))


let navigation = [
  ( "/",         "home"       ),
  ( "/status",   "git status" ),
  ( "/log",      "git log"    )
]

// Middleware: add a common header
app.use { req, res, next in
  res.setHeader("Content-Type", "text/html; charset=utf-8")
  res.write(
    "<h4>URL: \(req.url)</h4>" +
    "<div>"
  )
  let navLinks = navigation.map { "<a href=\"\($0)\">\($1)</a>" }
  res.write(navLinks.joined(separator: " | "))
  res.write("</div><hr />")
  
  next()
}

// Middleware: git status - output in pre
app.use("/status") { req, res, next in
  res.write("<h3>git status</h3>")
  res.write("<pre>")

  spawn("git", "status").stdout!
    .pipe(res, endOnFinish: false)
    .unpipePromise
    .then {
      res.write("</pre>")
      res.end()
    }
}


// Middleware: git log - parse response and output in table

app.use("/log", gitLog)


// Middleware: Homepage - final all-match
app.use { req, res, next in
  res.end("<h3>Welcome to Noze.io!</h3>")
}

// and run the server
app.listen(1337) {
  print("Server listening: \($0)")
}
