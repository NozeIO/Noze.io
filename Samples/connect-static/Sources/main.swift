// Noze.io Hello World Web Server
// - to compile in Swift 3 invoke: swift build
// - to run result: .build/debug/connect-static

import console
import http
import process
import connect

let __dirname = process.cwd() // our modules have no __dirname
print("DIR: \(__dirname)")


let app = connect()


// Middleware: logs the request
app.use(logger("dev"))


// Grmpf, cannot use connect.serveStatic, because `connect` is ambiguous,
// it is both the module and the function.
// TBD
app.use(serveStatic(__dirname + "/public"))


// and run the server
app.listen(1337) {
  print("Server listening: \($0)")
}
