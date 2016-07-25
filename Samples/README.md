Noze.io Examples
================

NOTE: It is intentional that those are full standalone SPM packages which clone 
      Noze.io, instead of being part of a big package with multiple targets.

Examples:

- [echod](echod/main.swift)
    (plain echod, just pipes the socket into itself)
- [echozd](echozd/main.swift)
    (way better echod, tweakz the input a little)
- [miniirc](miniirc/)
    (a tiny IRC server, less than perfect but working)
- [call-git](call-git/main.swift)
    (invoke `git log` and process the output)
- [sleep](sleep/main.swift)
    (just sleep n seconds)
- [httpd-helloworld](httpd-helloworld/main.swift) 
    (very simple HTTP server)
- [httpd-static](httpd-static/main.swift)
    (serve an HTML file and an image using just `http`)
- [httpd-cookies](httpd-cookies/main.swift)
    (small server to test cookies using just `http`)
- [connect-static](connect-static/main.swift)
    (serve an HTML file and an image using just `serveStatic`)
- [connect-git](connect-git/main.swift)
    (simple Connect based HTTP server)
- [express-simple](express-simple/)
    (Mustache templates, forms, some JSON, cookies, session)
- [todo-mvc](todo-mvc/)
    (A simple in-memory Todolist application backend aka TodoMVC)
- [todo-mvc-reids](todo-mvc-redis/)
    (A simple Todolist application backend aka TodoMVC which stores the data
     into Redis)

### building

Just enter the directory and type `swift build` or `make`, like so:

    cd echozd
    swift build

And on Linux you need GCD:

    swift build -Xcc -fblocks -Xlinker -ldispatch

### Running

Build results are put into `.build/debug/$TOOL`, run them straight from there,
like so:

    .build/debug/echozd
