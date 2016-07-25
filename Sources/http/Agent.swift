//
//  Agent.swift
//  Noze.io
//
//  Created by Helge Heß on 4/27/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import streams
import net

public class Agent {

  let keepAlive      : Bool
  let keepAliveMsecs : Int
  let maxSockets     : Int
  let maxFreeSockets : Int
  
  public init(keepAlive: Bool = true, keepAliveMsecs: Int = 1000,
              maxSockets: Int = Int.max, maxFreeSockets: Int = 256)
  {
    self.keepAlive      = keepAlive
    self.keepAliveMsecs = keepAliveMsecs
    self.maxSockets     = maxSockets
    self.maxFreeSockets = maxFreeSockets
  }

  // TODO: connection pool of HTTP client sockets
  
  
  public func createConnection(options o: RequestOptions)
              -> DuplexByteStreamType
  {
    // TODO: reuse connections, pool on: (unc
    //         hostname + port
    return net.connect(options: o)
  }
  
  public func pool(connection c: DuplexByteStreamType) {
    // TODO: reuse connections
    c.closeReadStream()
    c.closeWriteStream()
  }
}
