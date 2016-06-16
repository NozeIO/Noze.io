// Noze.io Simple Express based demo
// - to compile in Swift 3 invoke: swift build
// - to run result: .build/debug/express-simple

import xsys
import process
import http
import connect
import express
import console

let __dirname = process.cwd() // our modules have no __dirname
print("DIR: \(__dirname)")


let app = express()

app.use(logger("dev"))
app.use(bodyParser.urlencoded())
app.use(cookieParser())
app.use(session())
app.use(serveStatic(__dirname + "/public"))


// MARK: - Express Settings

app.set("view engine", "html") // really mustache, but we want to use .html
app.set("views", __dirname + "/views")


// MARK: - Session View Counter

app.use { req, _, next in
  req.session["viewCount"] = req.session[int: "viewCount"] + 1
  next()
}


// MARK: - Routes

let taglines = [
  "Ours is longer!",
  "Less than Perfect.",
  "Das Haus das Verrückte macht.",
  "Rechargeables included"
]


// MARK: - Form Handling

app.get("/form") { _, res, _ in
  res.render("form")
}
app.post("/form") { req, res, _ in
  let user = req.body[string: "u"]
  print("USER IS: \(user)")
  
  let options : [ String : Any ] = [
    "user"      : user,
    "nouser"    : user.isEmpty,
    "viewCount" : req.session["viewCount"]
  ]
  res.render("form", options)
}


// MARK: - JSON & Cookies

app.get("/json") { _, res, _ in
  res.json([
    [ "firstname": "Donald",   "lastname": "Duck" ],
    [ "firstname": "Dagobert", "lastname": "Duck" ]
  ])
}

app.get("/cookies") { req, res, _ in
  // returns all cookies as JSON
  res.json(req.cookies)
}


// MARK: - Main page

app.get("/") { req, res, _ in
  let tagline = arc4random_uniform(UInt32(taglines.count))
  
  let values : [ String : Any ] = [
    "tagline"   : taglines[Int(tagline)],
    "viewCount" : req.session["viewCount"]
  ]
  res.render("index", values)
}


// MARK: - Start Server

app.listen(1337) {
  print("Server listening: \($0)")
}
