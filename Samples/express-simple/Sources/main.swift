// Noze.io Simple Express based demo
// - to compile in Swift 3 invoke: swift build
// - to run result: .build/debug/express-simple

import process
import http
import connect
import express

let __dirname = process.cwd() // our modules have no __dirname
print("DIR: \(__dirname)")


let app = express()

app.use(logger("dev"))
app.use(bodyParser.urlencoded())
app.use(serveStatic(__dirname + "/public"))


// settings

app.set("view engine", "html") // really mustache, but we want to use .html
app.set("views", __dirname + "/views")


// routes

let taglines = [
  "Ours is longer!",
  "Less than Perfect.",
  "Das Haus das Verrückte macht.",
  "Rechargeables included"
]

app.get("/form") { _, res, _ in
  res.render("form")
}
app.post("/form") { req, res, _ in
  let user = req.body[string: "u"]
  print("USER IS: \(user)")
  res.render("form", [ "user": user, "nouser": user.isEmpty ])
}

app.get("/json") { _, res, _ in
  res.json([
    [ "firstname": "Donald",   "lastname": "Duck" ],
    [ "firstname": "Dagobert", "lastname": "Duck" ]
  ])
}

app.get("/") { _, res, _ in
  let tagline = rand() % Int32(taglines.count)
  res.render("index", [ "tagline": taglines[Int(tagline)] ])
}


// and run the server
app.listen(1337) {
  print("Server listening: \($0)")
}
