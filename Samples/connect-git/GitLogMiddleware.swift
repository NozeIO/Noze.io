// Noze.io Simple Connect based WebServer

import core
import streams
import http
import connect
import console
import child_process

// This is a demo on how to transform stuff in a streaming
// way along the piping queue.
//
// In Swift3 2016-05-09 this looks a little more awkward than
// necessary. Bugz I guess. Including crashers.
//
// What it does:
// - we call `git log` and pipe the stdout
// - into `readlines`, which transforms the bytes into [String] lines
// - those are piped into the `linesToRecords` function, which
//   produces `GitLogEntry` structs, which are then piped into
// - the `recordsToHTML` function, which produces HTML bytes
// - which are finally piped into the response
// Lots of piping going on.

struct GitLogEntry {
  let commit : String
  let author : String
  let email  : String
  let date   : String
}

extension String { // add stuff missing in String w/o Foundation
  func componentsSeparated(by c: Character) -> [ String ] {
    return characters.split(separator: c).map { String($0) }
  }
}

func linesToRecords(chunk : [String]?,
                    push  : ( [GitLogEntry]? ) -> Void,
                    end   : ( ErrorProtocol?, [GitLogEntry]? ) -> Void)
{
  guard let lines = chunk else { end(nil,nil); return }
        
  let records : [ GitLogEntry ] = lines.map { line in
    let fields = line.componentsSeparated(by: "|")
    
    guard fields.count > 3 else {
      print("SHORT LINE: \(line) \(fields)")
      return GitLogEntry(commit:line, author:"", email:"", date:"")
    }
    
    return GitLogEntry(
      commit: fields[0],
      author: fields[1],
      email:  fields[2],
      date:   fields[3]
    )
  }
  end(nil, records)
}

func recordsToHTML(chunk : [ GitLogEntry ]?,
                   push  : ( [UInt8]? ) -> Void,
                   end   : ( ErrorProtocol?, [UInt8]? ) -> Void)
{
  guard let records = chunk else { end(nil,nil); return }
  for r in records {
    let s =
      "<tr><td>\(r.date)</td><td>\(r.author)</td><td>\(r.commit)</td></tr>"
    push(Array<UInt8>(s.utf8)) // `res` expects bytes
  }
  end(nil, nil)
}

/// This is the actual middleware function
func gitLog(req: IncomingMessage, res: ServerResponse, next: (Any...) -> Void) {
  res.write("<h3>git log</h3>")
  res.write("<table border='1'>")
  res.write("<tr><th>Date</th><th>Author</th><th>Commit</th></tr>")

  let s = spawn("git", "log", "-100", "--pretty=format:%H|%an|<%ae>|%ad")
    | readlines
    | through2(linesToRecords)
    | through2(recordsToHTML)

  // Swift3 2016-05-09 falls apart on this, maybe this is due to
  // operator ordering (| vs .)?
  _ = s.pipe(res, endOnFinish: false)
    .onError { error in
      print("Pipe error: \(error)")
    }
    .onUnpipe { _ in
      // TODO: sometimes the socket is closed before this happens?
      res.write("</table>")
      res.end()
    }
}
