// Noze.io: miniirc

import core
import streams

// MARK: - Message Parser (a through stream)

// Samples:
//   NICK noze
//   USER noze 0 * :Noze io
//   :noze JOIN :#nozechannel
//
// Basic syntax:
//   [':' SOURCE]? ' ' COMMAND [' ' ARGS]? [' :' LAST-ARG]?

var line2msg : Transform<String, Message> {
  return through2 {
    ( lines : [ String ], _, done: ( ErrorProtocol?, [Message]? ) -> Void ) in
    
    /// split the line into the source, command and argument parts
    func splitIRCLine(line l: String) -> ( String?, String?, [ String ]?) {
      // there is probably a better way to do this ...
      
      let chars  = l.characters
      var idx    = chars.startIndex
      
      var source        : String?     = nil
      var commandString : String?     = nil
      var arguments     : [ String ]? = nil
      
      // parse source
      if chars[chars.startIndex] == ":" { // has a source
        idx = chars.index(after: idx) // skip colon
        
        let from : String.CharacterView.Index
        let to   : String.CharacterView.Index
        
        if let spaceIdx = chars.index(of: " ", from: idx) {
          from = idx
          to   = spaceIdx
          idx  = chars.index(after: spaceIdx) // skip space
        }
        else {
          from = idx
          to   = chars.endIndex
          idx  = chars.endIndex // done
        }
        
        if from != to && chars.index(after: from) != to {
          source = String(chars[from..<to])
          assert(!source!.isEmpty)
        }
      }
      
      // parse command (numeric or string)
      if idx != chars.endIndex {
        var lastArg  : String? = nil
        let colonIdx = chars.index(of: ":", from: idx);
        
        if colonIdx != nil {
          lastArg = String(chars[chars.index(after: colonIdx!)..<chars.endIndex])
        }
        
        let allButLast = chars[idx ..< (colonIdx ?? chars.endIndex)]
                           .split(separator: " ",
                                  omittingEmptySubsequences: true)
                           .map { return String($0) }
        if !allButLast.isEmpty {
          commandString = allButLast.first
          arguments = []
          let from = allButLast.index(after: allButLast.startIndex)
#if swift(>=3.0) // #swift3-fd
          arguments!.append(contentsOf: allButLast[from..<allButLast.endIndex])
#else
          arguments!.appendContentsOf(allButLast[from..<allButLast.endIndex])
#endif
          if let s = lastArg {
            arguments!.append(s)
          }
        }
        if arguments == nil { arguments = [] }
      }
      
      return ( source, commandString, arguments )
    }
    
    
    // convert lines to messages
    
    let messages : [ Message ]? = lines.filter { !$0.isEmpty }.map { line in
      
      let ( source, commandString, arguments ) = splitIRCLine(line: line)
      
      guard let cs = commandString, args = arguments else {
        return Message(source: source, command: .Invalid(line))
      }
      
      let command : Command
      
      // FIXME: this is wrong, too much dupe code
      switch cs { // TBD: could also match on (cs, argc)
        // Textual also sends: CAP[LS,302], PASS[pwd] if there was a pwd
        
        case "NICK":
          command = args.count == 1 ? .NICK(args[0]) : .InvalidArgs(cs, args)
        
        case "USER":
          let mask = args.count > 1 ? Int(args[1]) : 0
          if args.count == 4 && mask != nil {
            let user = UserInfo(username: args[0], usermask: UInt32(mask!),
                                realname: args[3])
            command = .USER(user)
          }
          else { command = .InvalidArgs(cs, args) }
        
        case "QUIT":
          if args.count < 2  { command = .QUIT(args.first) }
          else               { command = .InvalidArgs(cs, args) }
        
        case "PING":
          if args.count == 1 { command = .PING(args[0]) }
          else               { command = .InvalidArgs(cs, args) }
        
        case "PONG":
          if args.count == 1 { command = .PONG(args[0]) }
          else               { command = .InvalidArgs(cs, args) }
        
        case "JOIN":
          if args.count == 1 { command = .JOIN(args[0].split(","), nil) }
          else if args.count == 2 {
            command = .JOIN(args[0].split(","), args[1].split(","))
          }
          else               { command = .InvalidArgs(cs, args) }
        case "PART":
          switch args.count {
            case 1:  command = .PART(args[0].split(","), nil)
            case 2:  command = .PART(args[0].split(","), args[1])
            default: command = .InvalidArgs(cs, args)
          }
        
        case "ISON":
          command = .ISON(args)
        
        case "LIST":
          switch args.count {
            case 0:  command = .LIST(nil, nil)
            case 1:  command = .LIST(args[0].split(","), nil)
            case 2:  command = .LIST(args[0].split(","), args[1].split(","))
            default: command = .InvalidArgs(cs, args)
          }
        
        case "PRIVMSG":
          command = args.count == 2
            ? .PRIVMSG(args[0], args[1])
            : .InvalidArgs(cs, args)
        
        default:
          if let n = Int(cs)   { command = .UnsupportedNumeric(n, args) }
          else                 { command = .Unsupported(cs, args) }
      }
      
      return Message(source: source, command: command)
    }
    
    done(nil, messages)
  }
}
