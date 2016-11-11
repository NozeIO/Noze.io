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
  // Note: An important thing to remember is that the messages AND THE STREAMs
  //       of the messages are decoupled from the socket.
  //       When an IncomingMessage ends or a ServerResponse finishes, that
  //       doesn't have to affect the lifetime of the TCP connection. It can and
  //       usually is persistent after all.
  
  let log       : Logger
  var stream    : DuplexByteStreamType?
  
  // TBD: should those be a delegate? Probably.
  var cbDone    : (( HTTPConnection ) -> Void)? = nil
  var cbMessage : (( HTTPConnection, IncomingMessage ) -> Void)? = nil
    // Invoked when a message has been parsed. This is sent to the Server 
    // object which then creates a `ServerResponse` object and emits the
    // `onRequest` event.
  
  // FIXME: One connection can handle multiple messages. We need to re-setup
  //        those objects.
  var message   : IncomingMessage? = nil
  var parser    : IncomingMessageParser! = nil // this is per-socket
  
  init(_ stream: DuplexByteStreamType, _ log: Logger) {
    self.stream   = stream
    self.log      = log

    #if false
      log.enter(); log.log("socket: \(socket)")
      defer { log.log("socket: \(socket)"); log.leave() }
    #endif

    // TODO: Those are weak, but I think we should rather get the flow right.
    
    _ = stream.onceFinish { [weak self] in
      log.enter(); defer { log.leave() }
      
      // we are done writing to the socket
      self?.emitDone()
    }
    _ = stream.onceEnd { [weak self] in
      log.enter(); defer { log.leave() }
      
      // The stream did end - aka the Socket read end got closed. Aka EOF.
      // On the server this can arrive at various times. E.g. a client can close
      // its write end of the connection before the server delivered the
      // response. In this case the end comes in before finsh. However, HTTP/1.1
      // uses persistent connections by default, so the client wouldn't usually
      // close it yet in case another request is going to be sent on the same
      // connection.
      
      // Since we use the connection for both sides, we can only be sure at the
      // end to release the parser (End of readstream).
      
      // send EOF to parser
      if let parser = self?.parser {
        parser.end()
          // Note: this can still generate events!!!
          // we are NOT resetting 'self.parser' here. The parser is reused for
          // the whole lifetime of the socket connection.
      }
      else {
        // got an EOF w/o a parser?
        self?.emitDone()
      }
      
      // If a SERVER gets EOF while receiving the request, this just means that
      // the client is done with it. Can't be kept-alive though.
      //
      // If a CLIENT gets EOF while receiving the response, it should drop the
      // whole socket.
      // TBD: well, not really. EOF is fine as long as the parser *did* end as
      //      well? The server can close the input
    }
    
    if let socket = stream as? Socket {
      _ = socket.onceTimeout { [weak self] in self?.onTimeout(socket: $0) }
    }
    _ = stream.onReadable { [weak self] in self?.doRead() }
  }
  deinit {
    if let s = stream { // seems to happen, TODO: debug
      s.closeReadStream()
      s.closeWriteStream()
      self.stream = nil
    }
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
  
  var lastMessage = true // we don't do persistent yet, always set to true
  
  final func _setupParser() {
    log.enter(); defer { log.leave() }
    
    // TODO: Oh well, all those inline callbacks are an'bad stylz
    let p = IncomingMessageParser()
    self.parser = p
        
    _ = p.onRequest { [unowned self] m, p, v, h in
      let msg = IncomingMessage(self.stream!)
      msg.method      = m
      msg.url         = p
      msg.httpVersion = v
      msg.headers     = h
      self.message = msg
      self.cbMessage?(self, msg)
    }
    _ = p.onResponse { [unowned self] s, v, h in
      let msg = IncomingMessage(self.stream!)
      msg.statusCode  = s
      msg.httpVersion = v
      msg.headers     = h
      self.message = msg
      self.cbMessage?(self, msg)
    }
    
    _ = p.onDone { [unowned self] keepAlive in
      // onDone is invoked if a full HTTP message, header AND body have been
      // processed/read.
      // NOTE: The connection can still receive additional messages!!!
      let doneMessage = self.message
      self.message = nil // this message is DONE. More can arrive
      
      doneMessage?.push(nil) // EOF - notifies the client that the read is done
      
      // Continue reading the next, or not. This depends on the 'Keep-Alive'
      // headers etc and is determined by the parser!
      if !keepAlive {
        self.lastMessage = true
      }
    }
    _ = p.onData { [unowned self] data in
      assert(self.message != nil, "data callback but no message available?")
      self.message?.push(data)
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
  
  func onTimeout(socket: Socket) { // read OR write!
    log.log(message: "socket did timeout \(socket)")
    emitDone() // what else? Do we have such on IncomingMessage/ServerResponse?
  }
}
