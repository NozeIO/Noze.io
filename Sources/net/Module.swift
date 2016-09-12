//
//  Module.swift
//  Noze.io
//
//  Created by Helge Heß on 4/10/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

@_exported import core
@_exported import streams
import xsys

public class NozeNet : NozeModule {
}
public let module = NozeNet()


// TODO: What is the difference between connect() and createConnection?


/// Create a `Socket` object and automatically connect it to the given 
/// host/port, where `host` defaults to 'localhost'.
///
/// Optional onConnect block.
///
/// Sample:
///
///     let sock = net.connect(80, "zeezide.de") { sock in
///       sock.write("GET / HTTP/1.0\r\n")
///       sock.write("Content-Length: 0\r\n")
///       sock.write("Host: zeezide.de\r\n")
///       sock.end  ("\r\n")
///     }
///
@discardableResult
public func connect(_ port: Int, _ host: String = "localhost",
                    onConnect: ConnectCB? = nil)
            -> Socket
{
  return Socket().connect(port: port, host: host, onConnect: onConnect)
}

open class ConnectOptions : CustomStringConvertible {
  public var hostname : String?     = "localhost"
  public var port     : Int         = 80

  /// Version of IP stack (IPv4) 
  public var family   : sa_family_t = sa_family_t(xsys.AF_INET)
  
  public init() {}
  
  public var description: String {
    var ms = "<\(type(of: self)):"
    appendToDescription(&ms)
    ms += ">"
    return ms
  }
  
  open func appendToDescription(_ ms: inout String) {
    if let hostname = hostname {
      ms += " \(hostname):\(port)"
    }
    else {
      ms += " \(port)"
    }
  }
  
}

@discardableResult
public func connect(options o: ConnectOptions = ConnectOptions(),
                    onConnect cb: ConnectCB? = nil)
  -> Socket
{
  return Socket().connect(options: o, onConnect: cb)
}


/// Creates a new `net.Server` object.
///
/// Optional onConnection block.
///
/// Sample:
///
///     let server = net.createServer { sock in
///       print("connected")
///     }
///     .onError { error in
///       print("error: \(error)")
///     }
///     .listen {
///       print("Server is listening on \($0.address)")
///     }
///
@discardableResult
public func createServer(allowHalfOpen  : Bool = false,
                         pauseOnConnect : Bool = false,
                         onConnection   : ConnectCB? = nil) -> Server
{
  let srv = Server(allowHalfOpen:  allowHalfOpen,
                   pauseOnConnect: pauseOnConnect)
  if let cb = onConnection { _ = srv.onConnection(handler: cb) }
  return srv
}


#if os(Linux)
#else
  // importing this from xsys doesn't seem to work
  import Foundation // this is for POSIXError : Error
#endif
