# Noze.io http module

An HTTP module modelled after the builtin Node
[http module](https://nodejs.org/dist/latest-v7.x/docs/api/http.html).
In applications you probably want to use the Connect or Express module instead.

In Noze.io the `http` module also contains a set of other 'modules':

- `url`         for parsing URLs
- `querystring` for parsing URL query strings
- `cookies`     for dealing with HTTP cookies
- `basicAuth`   for parsing HTTP Basic authentication headers

## Core http module

The Noze.io HTTP module supports both ends, it can work as an HTTP client as
well as an HTTP server.

### HTTP server

Example:

    import http

    http.createServer { req, res in 
      res.writeHead(200, [ "Content-Type": "text/html" ])
      res.end("<h1>Hello World</h1>")
    }
    .listen(1337)

### HTTP client

Example:

    let req = request("http://www.zeezide.de/") { res in
      print("Response status: \(res.statusCode)")"
      res | utf8 | concat { data in
        result = String(data) // convert characters into String
        print("Response body: \(result)")
      }
    }

## Embedded Modules

### url

This is similar to the Node
[url module](https://nodejs.org/dist/latest-v7.x/docs/api/url.html).

Usage:

    import http
    let myURL = url.parse("http://noze.io/")

Note: In Swift you have also access to the `URL` (aka `NSURL`) class as well as
      `URLComponents`. Depending on your needs that might be the preferred
      class.

### querystring

Example:

    let parsed = querystring.parse("a=5&b=3&c=Hello World&a=8")
    let aValues = parsed["a"] // [ '5', '8' ]
    let cValue  = parsed["c"] as! String // 'Hello World'

### cookies

Example:

    let cookies = Cookies(req, res)
    cookies.set("theAnswer", "42")               // set a cookie
    if let answer = cookies.get("theAnswer") {..}  // get a cookie

An example server can be found here: 
[httpd-cookies](https://github.com/NozeIO/Noze.io/blob/master/Samples/httpd-cookies/main.swift).

### basicAuth

This is a very basic module, one should rather use a middleware dealing with
authentication.

Example:

    http.createServer { req, res in
      guard let credentials = try? basicAuth.auth(req: req),
            credentials.name == "John", 
            credentials.pass == "Doe"
       else {
        res.statusCode = 401
        res.setHeader("WWW-Authenticate", 
                      "Basic realm=\"Cows Heaven\"")
        return res.end()
      }

      res.end("Welcome to the forbidden zone!")
    }

