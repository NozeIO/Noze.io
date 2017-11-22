// Noze.io cows2code example
// - to compile in Swift 3 invoke: swift build
// - to run result: .build/debug/cows2code cows.txt cows.swift

import xsys
import core
import console
import streams
import fs
import process

var formatOutput = false
  // this looks better, but kills Swift 3

if CommandLine.argc < 2 {
  print("usage: \(CommandLine.arguments[0]) cows.txt")
  xsys.exit(42)
}

let cowsTextFile  = CommandLine.arguments[1]

func escape(cString cs: String) -> String {
  var s = ""
  s.reserveCapacity(cs.characters.count)
  #if swift(>=3.2)
    let characters = cs
  #else
    let characters = cs.characters
  #endif
  for c in cs.characters {
    switch c {
      case "\\": s += "\\\\"
      case "\"": s += "\\\""
      case "\n": s += "\\n"
      default:   s += String(c) // hm
    }
  }
  return s
}

fs.access(cowsTextFile) { err in
  guard err == nil else {
    console.error("input file does not exist: \(cowsTextFile)")
    return
  }
  
  let textFile = fs.createReadStream(cowsTextFile)
  
  // TODO: there should be a split stream so that we don't have to do `concat`
  textFile | readlines | concat { allLines in
    let splitLines = allLines.split(separator: ["", ""])
    
    let now  = xsys.time(nil).componentsInLocalTime
    let nows = now.format("%a, %d %b %Y %H:%M:%S %Z")
    print("// Generated on \(nows)")
    print("let allCows : [ String ] = [")
    
    var isFirstCow = true
    for cow in splitLines {
      
      if formatOutput { // this output style kills swiftc3
        if isFirstCow { isFirstCow = false }
        else { print("  ,") }
        
        var isFirstCowLine = true
        for cowline in cow {
          let prefix = isFirstCowLine ? "      " : "  + "
          let nl     = isFirstCowLine ? "" : "\\n"
          
          print("\(prefix)\"\(nl)\(escape(cString: cowline))\"")
          isFirstCowLine = false
        }
      }
      else {
        if isFirstCow { isFirstCow = false }
        else { print(",") }
        let s = cow.joined(separator: "\n")
        print("  \"\(escape(cString: s))\"")
      }
    }
    
    print("]")
  }
}
