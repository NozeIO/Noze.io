// Noze.io: miniirc

class Channel {
  
  let serverID  = "noze.io"
  let name      : String
  var welcome   : String
  var operators = [ String ]()
  var sessions  = [ Session ]()
  
  var memberNicks : [ String ] {
    return sessions.filter { $0.nick != nil }.map { $0.nick! }
  }
  
  init(name: String, welcome: String? = nil) {
    self.name    = name
    self.welcome = welcome ?? "Welcome to \(name)!"
  }
  
  
  // MARK: - Sending Messages
  
  func sendMessage(source s: String, message: String) {
    send(source: s, command: "PRIVMSG", name, message)
  }
  
  func send(source s: String, command: String, _ args: String...) {
    for otherUser in sessions {
      guard otherUser.nick! != s else { continue }
      _ = otherUser.send(source: s, command: command, args: args)
    }
  }
  
  
  // MARK: - Joining & Leaving
  
  func join(session s: Session) {
    let joinedAlready = sessions.contains { $0 === s }
    guard !joinedAlready else {
      print("joined already?!: \(s)")
      return
    }
    
    sessions.append(s)
    sendWelcome(session: s)
    
    send(source: s.nick!, command: "JOIN", name)
  }
  
  func part(session s: Session) {
#if swift(>=3.0) // #swift3-fd
    let idxO = sessions.index(where: { $0 === s })
#else // Swift 2.2
    let idxO = sessions.indexOf({ $0 === s })
#endif
    if let idx = idxO {
      print("leaving channel \(name): \(s)")
      sessions.remove(at: idx)
      send(source: s.nick!, command: "PART", name)
    }
  }

  
  // MARK: - Welcome

  func sendWelcome(session s: Session) {
    let nick = s.nick ?? "<unknown>"
    
    let ms = memberNicks.joined(separator: " ")
    
    s.send(source: serverID, command: 332, nick, name, welcome)
    s.send(source: serverID, command: 353, nick, "=", name, ms)
    s.send(source: serverID, command: 366, nick, name,"End of /NAMES list.")
  }
}

var nameToChannel : [ String : Channel ] = [
  "#noze": Channel(name: "#noze")
]
