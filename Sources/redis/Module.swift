//
//  Module.swift
//  Noze.io
//
//  Created by Helge Hess on 28/06/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import core
import net
import console

public class NozeRedis : NozeModule {
}
public var module = NozeRedis()


public let DefaultRedisPort = 6379

public func connect(port p: Int = DefaultRedisPort,
                    cb: ( RedisConnection ) -> Void)
{
  _ = net.connect(p) { socket in
    
    // console.log("got socket", socket)
    _ = socket.onEnd {
      // console.log("### done with socket: \(socket)")
    }
    
    let con = RedisConnection(socket: socket)
    
    _ = con.onError { error in
      console.log("Catched error: \(error)")
    }
    
    cb(con)
  }
  .onError { err in
    console.error("socket error: \(err)")
  }
  
}
