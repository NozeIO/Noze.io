// Noze.io: miniirc

import leftpad // need the most important module!
import net

/// This mapping is not quite right, given a user could be connected with
/// multiple clients. But it'll do for the demo ;-)
var nickToSession : [ String : Session ] = [:]

var sessionCounter = 0

/// One TCP/IP connection to some user.
///
class Session {

  var sessionID : Int
  var state     = SessionState.Initial
  let socket    : Socket
  
  let serverID  : String?   = "noze.io"
  
  var channelsJoined = [ Channel ]()
  
  var nick      : String? {
    switch state {
      case .Initial:                   return nil
      case .NickAssigned(let nick):    return nick
      case .UserSet     (let nick, _): return nick
    }
  }
  var userInfo : UserInfo? {
    switch state {
      case .Initial, .NickAssigned: return nil
      case .UserSet(_, let info):   return info
    }
  }
  
  init(socket: Socket) {
    sessionCounter += 1
    sessionID = sessionCounter
    print("setup session #\(sessionID)")
    
    self.socket = socket
    
    _ = socket
      .onFinish { self.unregisterSession() }
      .onEnd    { self.unregisterSession() }
    
    socket | readlines | line2msg | Writable { messages, done in
      //print("handle in session #\(self.sessionID)")
      for msg in messages {
        _ = self.handle(message: msg)
      }
      done(nil)
    }
 
    sendWelcome()
  }
  
  
  // MARK: - Message Handler
  
  func handle(message m: Message) {
    // print("HANDLE: \(m)")
    
    switch m.command {
      
      case .NICK(let name):
        guard name != nick else { return }
        
        guard nickToSession[name] == nil else {
          send(source: serverID, command: 433, "*", name,
               "Nickname is already in use.")
          return
        }
        nickToSession[name] = self
        if let nick = nick { nickToSession.removeValue(forKey: nick) }
        
        state = .NickAssigned(name)
      
      case .USER(let info):
        state = .UserSet(nick ?? "<unknown>", info)
        sendIntro()
      
      case .PING(let who):
        send(command: "PONG", who)
      
      case .PRIVMSG(let target, let message):
        let nick = self.nick ?? "<unknown>"
        if let otherUser = nickToSession[target] {
          _ = otherUser.send(source: nick, command: "PRIVMSG", target, message)
        }
        else if let channel = nameToChannel[target] {
          channel.sendMessage(source: nick, message: message)
        }
        else {
          send(source: serverID, command: 401, nick ?? "<unknown>", target,
               "No such nick/channel")
        }
      
      case .ISON(let nicknames):
        var on = [String]()
        for nick in nicknames {
          guard let _ = nickToSession[nick] else { continue }
          on.append(nick)
        }
        send(source: serverID, command: 303, nick ?? "<unknown>",
             on.joined(separator: " "))
      
      case .JOIN(let channels, _):
        for channel in channels {
          joinChannel(name: channel)
        }
      case .PART(let channels, _):
        for channelName in channels {
          if let channel = nameToChannel[channelName] {
            channel.part(session: self)
#if swift(>=3.0) // #swift3-fd
            if let idx = channelsJoined.index(where: { $0 === channel }) {
              channelsJoined.remove(at: idx)
            }
#else
            if let idx = channelsJoined.indexOf({ $0 === channel }) {
              channelsJoined.removeAtIndex(idx)
            }
#endif
          }
        }
      
      case .LIST(_, _):
        let nick = self.nick ?? "<unknown>"
        send(source: serverID, command: 321, nick, "Channel", "Users  Name")
        for ( _, channel ) in nameToChannel {
          send(source: serverID, command: 322, nick, channel.name,
               channel.memberNicks.joined(separator: " "))
        }
        send(source: serverID, command: 323, "End of /LIST")
      
      case .QUIT:
        unregisterSession()
      
      case .Unsupported(let cmd, _):
        send(source: serverID, command: 421, cmd, "Unknown command")
      
      default:
        print("Not handling: \(m)")
    }
  }
  
  
  // MARK: - Channels
  
  func joinChannel(name n: String) {
    let channel : Channel
    
    if nameToChannel[n] == nil {
      // auto-create channel if missing
      channel = Channel(name: n)
      if let nick = nick {
        channel.operators.append(nick)
      }
      nameToChannel[n] = channel
    }
    else {
      channel = nameToChannel[n]!
    }
    
    channel.join(session: self)
    channelsJoined.append(channel)
  }
  
  
  // MARK: - Sending
  
  func send(source s: String? = nil, command: Int, _ args: String...) {
    let cmd = "\(command)".leftpad(3, c: "0")
    send(source: s, command: cmd, args: args)
  }
  func send(source s: String? = nil, command: String, _ args: String...) {
    send(source: s, command: "\(command)", args: args)
  }
  
  func send(source s: String? = nil, command: String, args: [String]) {
    let prefix = s != nil ? ":\(s!) " : ""
    let suffix : String
    
    if args.isEmpty {
      suffix = ""
    }
    else if args.count == 1 {
      suffix = " :" + args[0]
    }
    else {
      let regular = args[0..<(args.count - 1)].reduce("") { $0 + " \($1)" }
      suffix = "\(regular) :\(args[args.count - 1])"
    }
    
    let message = "\(prefix)\(command)\(suffix)\r\n"
    //print("S: \(message)")
    _ = socket.write(message)
  }
  
  
  // MARK: - Welcome
  
  func sendWelcome() {
    send(command: "NOTICE", "*", "*** Welcome to Noze.io!")
  }
  
  func sendIntro() {
    let nick = self.nick ?? "<unknown>"
    send(source: serverID, command: 001, nick,
         "Welcome to the Noze.io Internet Relay Chat Network \(nick)")
    send(source: serverID, command: 251, nick,
         "There are \(nickToSession.count) users on 1 server")
    send(source: serverID, command: 376, nick,
         "End of /MOTD command.")
  }
  
  
  // MARK: - End Handlers
  
  func unregisterSession() {
    // print("finishing session: \(self.socket)")
    
    for channel in channelsJoined {
      channel.part(session: self)
    }
    channelsJoined.removeAll()
    
    if let nick = self.nick {
#if swift(>=3.0) // #swift3-fd
      nickToSession.removeValue(forKey: nick)
#else
      nickToSession.removeValueForKey(nick)
#endif
    }
    
    // TODO: socket.close()
  }
}

struct UserInfo {
  let username : String
  let usermask : UInt32
  let realname : String
}

enum SessionState {
  
  case Initial
  case NickAssigned(String)
  case UserSet(String, UserInfo)
  
}
