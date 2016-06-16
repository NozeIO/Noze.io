//
//  HTTPConnection.swift
//  Noze.io
//
//  Created by Helge Hess on 20/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import xsys
import core
import streams
import net
import enum http_parser.HTTPError

class HTTPConnection {
  // TODO: this should do proper backpressure management
  
  let log       : Logger
  var stream    : DuplexByteStreamType?
  
  var cbDone    : (( HTTPConnection ) -> Void)? = nil
  var cbMessage : (( HTTPConnection, IncomingMessage ) -> Void)? = nil
  
  // FIXME: One connection can handle multiple messages. We need to re-setup
  //        those objects.
  var message   : IncomingMessage! = nil
  var parser    : IncomingMessageParser! = nil // this is per-socket
  
  init(_ stream: DuplexByteStreamType, _ log: Logger) {
    self.stream   = stream
    self.log      = log
    
    self.log.enter();
    self.log.log("socket: \(socket)")
    defer {
      self.log.log("socket: \(socket)")
      self.log.leave()
    }
    
    _ = stream.onceEnd { [unowned self] in
      self.log.enter(); defer { self.log.leave() }
      // send EOF to parser
      self.parser?.end() // Note: this can still generate events!!!
      self.parser = nil // done parsing. TBD: this looks dangerous, because ^
      // print("SOCKET DID END \(self) \(self.stream)")
      
      // If a SERVER gets EOF while receiving the request, this just means that
      // the client is done with it. Can't be kept-alive though.
      //
      // If a CLIENT gets EOF while receiving the response, it should drop the
      // whole socket.
      // TBD: well, not really. EOF is fine as long as the parser *did* end as
      //      well? The server can close the input
    }
    _ = stream.onFinish { [unowned self] in
      // In the server this is coming after the end (the request has been read)
      // In the client this is coming BEFORE the end (the request has been sent,
      // but we still wait for the response).
      self.log.enter(); defer { self.log.leave() }
      //print("SOCKET DID FINISH \(self) \(self.stream)")
      self.emitDone()
    }
    
    if let socket = stream as? Socket {
      _ = socket.onceTimeout(handler: self.onTimeout)
    }
    _ = stream.onReadable { [unowned self] in self.doRead() }
  }
  
  func emitDone() {
    parser = nil // done parsing.
    
    // TODO: don't do this with keep-alive
    stream?.closeWriteStream()
    stream?.closeReadStream()
    stream = nil
    
    // this is removing the connection in the Server imp
    cbDone?(self)
    cbDone = nil
  }
  
  
  // MARK: - Parser
  
  func parserFailed(error e: HTTPError) {
    log.enter(); defer { log.leave() }
    
    print("HTTP ERROR: \(e)")
    // TODO
    emitDone()
  }
  
  
  let buffer   = RawByteBuffer(capacity: 100)
  var lastName : String? = nil
  
  final func _setupParser() {
    log.enter(); defer { log.leave() }
    
    // Oh well, all those inline callbacks are an'bad stylz
    let p = IncomingMessageParser()
    self.parser = p
    
    _ = p.onRequest { [unowned self] m, p, v, h in
      let msg = IncomingMessage(self.stream!)
      msg.method      = m
      msg.url         = p
      msg.httpVersion = v
      msg.headers     = h
      self.message = msg
      self.cbMessage?(self, self.message)
    }
    _ = p.onResponse { [unowned self] s, v, h in
      let msg = IncomingMessage(self.stream!)
      msg.statusCode  = s
      msg.httpVersion = v
      msg.headers     = h
      self.message = msg
      self.cbMessage?(self, self.message)
    }
    _ = p.onDone { [unowned self] in // TBD: is this onFinish? or onEnd?
      self.message.push(bucket: nil) // EOF - notifies the client that the read is done
      // TODO: this should disassociate the message from the Socket and reset
      //       parsing/
      // self.emitDone()
    }
    _ = p.onData { [unowned self] data in
      self.message.push(bucket: data)
    }
  }
  
  
  // MARK: - Reading
  
  final func doRead() {
    log.enter(); defer { log.leave() }
    
    /* push to parser (and setup parser if not yet done) */
    if self.parser == nil { _setupParser() }
    
    /* read everything available on the Socket */
    guard let bucket = self.stream?.read(count: nil) else {
      // EOF (or a hard close)
      parser.end()
      return
    }
    assert(bucket.count > 0)
    
    parser.write(bucket: bucket)
  }
  
  func onTimeout(socket: Socket) {
    // TODO
    print("TIMEOUT: \(socket)")
  }
}
