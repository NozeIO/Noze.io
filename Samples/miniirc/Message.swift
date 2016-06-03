// Noze.io: miniirc

enum Command {
  
  case NICK(String)
  case USER(UserInfo)
  
  case ISON([String])
  
  case QUIT(String?)
  case PING(String)
  case PONG(String)
  
  case JOIN([String], [String]?)
  case PART([String], String?)
  case LIST([String]?, [String]?)
  
  case PRIVMSG(String, String)
  
  // errors
  case Invalid           (String)
  case Unsupported       (String, [String])
  case UnsupportedNumeric(Int,    [String])
  case InvalidArgs       (String, [String])
  
  var isError : Bool {
    switch self {
      case .Invalid, .Unsupported, .UnsupportedNumeric, .InvalidArgs:
        return true
      default: return false
    }
  }
}

struct Message {
  let source    : String?
  let command   : Command
}

