# Noze.io fs module

A filesystem module modelled after the builtin Node
[fs module](https://nodejs.org/dist/latest-v7.x/docs/api/fs.html).
In applications you probably want to use the Connect or Express module instead.

TODO: more docs

## File System Streams

Read stream:

   let in = fs.createReadStream("/etc/passwd")

Write stream:

   let out = fs.createWriteStream("/tmp/tmpfile.txt")

Copy stream by piping:

   in | out


## Convenience functions

Don't, stream! Really.

Read file as binary:

    fs.readFile("/etc/passwd") { err, data in
      guard err = nil else { console.error("file read failed: ", err) }
      console.log("got data: ", data)
    }

Read file as a string:

    fs.readFile("/etc/passwd", "utf8") { err, s in
      guard err = nil else { console.error("file read failed: ", err) }
      console.log("got data: ", s)
    }

Write file:

    fs.writeFile("/tmp/doit.txt", "Noze.io is quite OK!")

Also available: `readFileSync`


## Directories

List directory:

    fs.readdir("/tmp/") { contents in
      guard let contents = contents else { console.log("Could not read dir!") }
      for path in contents {
        console.log("subdir: \(path)")
      }
    }

Also available: `readdirSync`


## Grab File Info

    fs.access("/etc/passwd", R_OK) { err in
      if err != nil else { console.error("no read access to /etc/passwd")
      else               { console.log("can read /etc/passwd")
    }

    fs.stat("/etc/passwd") { err, finfo in
      guard let finfo = finfo else {
        console.error("could not stat /etc/passwd: ", err)
        return
      }
      console.log("info about file: \(finfo)")
    }


Also available: `lstat`, `accessSync`, `statSync`, `lstatSync`


## Temp module

Create temporary files.

    temp.open { err, finfo in
      guard let ( fd, path ) = finfo else {
        console.error("could not open a tempfile: ", err)
        return
      }

      // do something
      fd.close()
    }

Or as a stream

    let tmpfile = temp.createWriteStream()
    ...

Optional arguments to the functions:

    (prefix) ("nzf-")    // first argument, not a kwarg
    suffix   ("")
    dir      (/tmp/)
    pattern  (XXXXXXXX)


## Path module

Work with pathes:

    let filename = path.basename("/etc/passwd") // gives passwd
    let dirname  = path.dirname("/etc/passwd")  // gives /etc


## Stdin/stdout


## FSWatcher / fs.watch()

Only available on macOS.

    fs.watch("/etc/passwd") { event in
      console.log("/etc/passwd event: ", event)
    }

