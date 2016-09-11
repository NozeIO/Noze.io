//
//  RequestOptions.swift
//  Noze.io
//
//  Created by Helge Heß on 5/20/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import streams
import net

open class RequestOptions : ConnectOptions {
  // In a 'regular' framework this would be called 'Request' ... In Node the
  // request is the thing which is already queued on the socket.
  
  // TODO: family, localAddress, socketPath
  var scheme   : String     = "http" // 'protocol' in Node
  var method   : HTTPMethod = .GET
  var path     : String     = "/"
  
  var headers  : [ String : CustomStringConvertible ] = [:]
  var auth     : String?    = nil // Basic auth

  public enum AgentConfig {
    case Global
    case CustomAgent(Agent)
    case NoPooling
  }
  var agent : AgentConfig = .Global
  
  var createConnection : (( ConnectOptions ) -> DuplexByteStreamType)? = nil
    // This is a little different to Node where options is just a generic
    // dictionary which is passed around
  
  public override init() {
    super.init()
  }
}

public extension RequestOptions {
  
  func getAgent() -> Agent {
    switch agent {
      case .Global:    return globalAgent
      case .NoPooling: return Agent()
      case .CustomAgent(let a): return a
    }
  }
  
}

