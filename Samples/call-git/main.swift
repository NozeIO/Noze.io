// Noze.io child_process example
// - to compile in Swift 3 invoke: swift build
// - to run result: .build/debug/call-git

import streams
import child_process
import process

struct GitLogEntry {
  let commit : String
  let author : String
  let email  : String
  let date   : String
}

extension String {
  func componentsSeparated(by c: Character) -> [ String ] {
    return characters.split(separator: c).map { String($0) }
  }
}


spawn("git", "log", "-5", "--pretty=format:%H|%an|<%ae>|%ad")
  | readlines
  | through2 { lines, push, end in
      let records : [ GitLogEntry ] = lines.map { line in
        let fields = line.componentsSeparated(by: "|")
        
        return GitLogEntry(
          commit: fields[0],
          author: fields[1],
          email:  fields[2],
          date:   fields[3]
        )
      }
      end(nil, records)
    }
  | concat { (records : [ GitLogEntry ]) in
      for r in records {
        print("Entry:")
        print("  Commit: \(r.commit)")
        print("      by: \(r.author) \(r.email)")
        print("      on: \(r.date)")
      }
    }
