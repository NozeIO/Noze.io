//
//  RedisConnection.swift
//  Noze.io
//
//  Created by Helge Heß on 6/25/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import core
import events
import net

public class RedisConnection: ErrorEmitter {

  public let socket : Socket
  
  // MARK: - Init
  
  public init(socket: Socket) {
    self.socket = socket
    
    super.init()
    
    configureParser()
  }
  
  
  // MARK: - Sending Commands
  
  public func send(command: String, _ args : RedisValue...) {
    // TODO: response callback
    var cmdArray : [ RedisValue ] = []
    cmdArray.reserveCapacity(args.count + 2)
    cmdArray.append(RedisValue(bulkString: command))
    cmdArray.append(contentsOf: args)
    socket.write(redisValue: cmdArray)
  }

  
  // MARK: - Parser
  
  let valueDebug = true
  
  func configureParser() {
    let parser = RedisParser()
    
    let valueDebug = self.valueDebug
    
    // TODO: figure out retain cycles
    socket | parser | Writable { values, done in
      if valueDebug {
        print("got values: #\(values.count): \(values)")
      }
      done(nil)
    }
  }
}
