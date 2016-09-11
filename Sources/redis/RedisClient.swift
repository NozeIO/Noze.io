//
//  RedisClient.swift
//  Noze.io
//
//  Created by Helge Hess on 29/06/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import core
import events
import console
import net

public typealias RedisReplyCB      = ( Error?, RedisValue?   ) -> Void
public typealias RedisIntReplyCB   = ( Error?, Int?          ) -> Void
public typealias RedisArrayReplyCB = ( Error?, [RedisValue]? ) -> Void
public typealias RedisHashReplyCB  = ( Error?, [String:String ]? )->Void
public typealias RedisOHashReplyCB = ( Error?, [String:String?]? )->Void

public typealias SubscribeCB = ( String, Int        ) -> Void
public typealias MessageCB   = ( String, RedisValue ) -> Void


/// Create a Redis client object
public func createClient(port     : Int    = DefaultRedisPort,
                         host     : String = "127.0.0.1",
                         password : String? = nil,
                         db       : Int?   = nil)
            -> RedisClient
{
  let options = RedisClientOptions(port: port, host: host,
                                   password: password, database: db)
  return RedisClient(options: options)
}


/// Configuration options for the Redis client object
public class RedisClientOptions : net.ConnectOptions {
  
  var password      : String?
  var database      : Int?
  var retryStrategy : RedisRetryStrategyCB?

  public init(port     : Int    = DefaultRedisPort,
              host     : String = "127.0.0.1",
              password : String? = nil,
              database : Int?   = nil)
  {
    self.password      = password
    self.database      = database
    self.retryStrategy = nil
    
    super.init()
    
    self.port          = port
    self.hostname      = host
  }
}


/// A connection to a Redis server.
///
/// Example:
///
///     import redis
///
///     let client = redis.createClient()
///     client.set("hello", "world")
///     client.get("hello") { err, reply in
///       console.log("reply: \(reply)")
///     }
///
public class RedisClient : ErrorEmitter, RedisCommandTarget {
  
  enum State {
    case Disconnected
    case Connecting
    case Connected
    case RequestedQuit
    case DidQuit
    case DidStop
    
    var canRequestQuit : Bool {
      return self == .Connected || self == .Connecting || self == .Disconnected
    }
    var canEnqueueCommands : Bool {
      return self == .Connected || self == .Connecting || self == .Disconnected
    }
  }
  
  let options    : RedisClientOptions
  var state      = State.Disconnected
  var didRetainQ = false
  
  public var stream : Socket? = nil
  
  init(options: RedisClientOptions) {
    self.options = options
    super.init()
    
    core.module.retain()
    didRetainQ = true
    
    // connect to server
    connect()
  }
  
  
  // MARK: - Connection
  
  var retryInfo = RedisRetryInfo()
  
  func connect() {
    guard state == .Disconnected else {
      console.info("socket is not disconnected", self)
      return
    }
    assert(stream == nil)
    guard stream == nil else {
      console.info("already connected", self)
      return
    }
    
    state = .Connecting
    
    retryInfo.attempt += 1
    
    stream = net.connect(options: options) { err in
      self.retryInfo.registerSuccessfulConnect()
      self.state = .Connected
      
      console.info("Connected to Redis", self)
      
      // Note: The socket is paused initially. It'll get resume'd once the first
      //       listener is added (the parser pipe is hooked up).
      
      self._didConnect()
    }
    
    assert(stream != nil)
    _ = stream!.onError(handler: self.handleSocketError)
  }
  
  func handleSocketError(err: Error) {
    console.error("socket error", err)
    
    retryInfo.lastSocketError = err
    state = .Disconnected
    
    if let socket = stream {
      socket.end()
      socket.closeReadStream()
      self.stream = nil
    }
    
    // Hm, what should we do with commands we sent?
    
    retryConnectAfterFailure()
  }
  
  func stopAll(error err: Error) {
    let oldPending = pendingCommands
    let oldSent    = sentCommands
    pendingCommands.removeAll()
    sentCommands.removeAll()
    
    for cmd in oldPending { cmd.callback?(err, nil) }
    for cmd in oldSent    { cmd.callback?(err, nil) }
  }
  
  func stop(error e: Error?) {
    state = .DidStop
    
    if let socket = stream {
      socket.closeReadStream()
      socket.closeWriteStream()
      stream = nil
    }
    
    stopAll(error: e ?? RedisClientError.ConnectionQuit)
    
    // break cycles
    subscribeListeners.removeAllListeners()
    messageListeners.removeAllListeners()
    errorListeners.removeAllListeners()
  }
  
  func retryConnectAfterFailure() {
    let retryHow : RedisRetryResult
    
    if let cb = options.retryStrategy {
      retryHow = cb(retryInfo)
    }
    else {
      if retryInfo.attempt < 10 {
        retryHow = .RetryAfter(milliseconds: retryInfo.attempt * 200)
      }
      else {
        retryHow = .Stop
      }
    }
    
    switch retryHow {
      case .RetryAfter(let timeoutInMS):
        // TBD: special Retry status?
        if state != .Connecting {
          state = .Connecting
          setTimeout(timeoutInMS) {
            self.state = .Disconnected
            self.connect()
          }
        }
      
      case .Error(let error):
        stop(error: error)
      
      case .Stop:
        stop(error: RedisClientError.ConnectionQuit)
    }
  }
  
  func handleSubscription(replies r: [RedisValue]) {
    assert(didSubscribe)
    
    for reply in r {
      switch reply {
        case .Array(let values):
          guard let values = values else {
            errorListeners.emit(RedisClientError.UnexpectedReplyType(reply))
            continue
          }
          guard values.count == 3 else {
            errorListeners.emit(RedisClientError.UnexpectedReplyType(reply))
            continue
          }
          guard let channel = values[1].stringValue,
                let type    = values[0].stringValue
          else {
            errorListeners.emit(RedisClientError.UnexpectedReplyType(reply))
            continue
          }
    
          switch type {
            case "message":
              let payload = values[2]
              messageListeners.emit(channel, payload)
            
            case "subscribe":
              // TBD: should be coalesce such?
              let channelCount = values[2].intValue ?? subscribedChannels.count
              subscribeListeners.emit(channel, channelCount)
            
            case "unsubscribe":
              if let channelCount = values[2].intValue {
                if channelCount == 0 {
                  console.info("exiting subscription mode", self)
                  didSubscribe = false
                }
                unsubscribeListeners.emit(channel, channelCount)
              }
              else {
                errorListeners.emit(RedisClientError.UnexpectedReplyType(reply))
              }
            
            default:
              errorListeners.emit(
                RedisClientError.UnexpectedPublishReplyType(type, values))
          }
        
        case .Error(let error):
          errorListeners.emit(error)
        default:
          errorListeners.emit(RedisClientError.UnexpectedReplyType(reply))
      }
    }
  }
  
  func handleCommand(replies r: [RedisValue]) {
    assert(!didSubscribe)
    
    for value in r {
      guard !self.sentCommands.isEmpty else {
        //assert(!self.sentCommands.isEmpty)
        continue
      }
      
      let cmd = self.sentCommands.removeFirst()
      
      // console.info("  finish cmd", cmd)
      
      if let cb = cmd.callback {
        switch value {
          case .Error(let error): cb(error, nil)
          default: cb(nil, value)
        }
      }
    }
  }
  
  func handle(replies values: [RedisValue]) {
    // console.info("got values: #\(values.count)", values)
    
    if didSubscribe {
      handleSubscription(replies: values)
    }
    else {
      handleCommand(replies: values)
    }
    
  }
  
  func _didConnect() {
    assert(state == .Connected)
    assert(stream != nil)
    
    
    // Hook up parser.
    
    let parser = RedisParser()
    
    stream! | parser | Writable { [weak self] values, done in
      guard let me = self else {
        console.warn("Redis client connection got deallocated, " +
                     "but parser is still streaming?!")
        done(nil)
        return
      }
      me.handle(replies: values)
      done(nil)
    }
    

    // TODO: auth
    
    
    // Re-subscribe to channels
    
    if !subscribedChannels.isEmpty {
      _subscribe(channels: Array<String>(subscribedChannels))
    }
    
    
    // => generate commands, but put them into the front of the queue!
    //    TBD: do not dupe them! (in case the connection fails over and over
    //         again)
    
    startWriting()
  }
  
  /// Forcibly end connection. You may want to use quit() instead.
  public func end() {
    state = .Disconnected
    if let stream = stream {
      stream.end() // this only closes the write end
      stream.closeReadStream() // also close the input stream
      self.stream = nil
    }
    
    if didRetainQ {
      core.module.release()
      didRetainQ = false
    }
  }
  
  /// Send the QUIT command to the Redis server, wait for the reply and then
  /// terminate the connection.
  public func quit(callback cb: (() -> Void)? = nil) {
    guard state.canRequestQuit else { return }
    
    // Unsubscribe, so that we can send the QUIT :-)
    if didSubscribe {
      _unsubscribe(channels: [])
    }
    
    let cmd = RedisCommand(command: [ RedisValue(bulkString: "QUIT") ]) {
      err, value in
      console.info("did quit", err, value, self)
      self.end()
      
      if let cb = cb {
        cb()
      }
    }
    enqueue(command: cmd)
    
    state = .RequestedQuit
  }
  
  
  // MARK: - Enqueue Commands
  
  var pendingCommands : [ RedisCommand ] = []
    // TODO: should be a linked list
  
  public func enqueue(command cmd: RedisCommand) {
    guard state.canEnqueueCommands else {
      if let cb = cmd.callback { cb(RedisClientError.ConnectionQuit, nil) }
      return
    }
    
    pendingCommands.append(cmd)
    
    if state == .Connected {
      startWriting()
    }
  }
  
  var sentCommands : [ RedisCommand ] = []
    // TODO: should be a linked list
  
  func startWriting() {
    guard let stream = self.stream else { return }
    guard !pendingCommands.isEmpty else { return }
    
    console.trace("start writing #\(pendingCommands.count) ...")
    //self.dumpPendingCommands()
    
    while !pendingCommands.isEmpty {
      let cmd = pendingCommands.removeFirst()
      
      // TODO: *need* done callback to move it to the sentCommands queue
      
      sentCommands.append(cmd)
      stream.write(redisValue: cmd.command)
    }
  }
  
  func dumpPendingCommands() {
    console.log("Pending: #\(pendingCommands.count)")
    for cmd in pendingCommands {
      console.log("  \(cmd)")
    }
    console.log("---")
  }
  
  
  // MARK: - PubSub
  
  var didSubscribe = false
  var subscribedChannels = Set<String>()
  
  public func subscribe(channels: String...) {
    guard !channels.isEmpty else { return }
    
    if state == .Connected {
      _subscribe(channels: channels)
    }
    
    subscribedChannels.formUnion(Set(channels))
    didSubscribe = !subscribedChannels.isEmpty
  }
  public func unsubscribe(channels: String...) {
    if channels.isEmpty {
      subscribedChannels.removeAll()
    }
    else {
      // TBD: should those get handled in the respective reply?
      subscribedChannels.subtract(Set(channels))
    }
    // This is done when the unsubscribe reply is received
    //   didSubscribe = !subscribedChannels.isEmpty
    
    if state == .Connected {
      _unsubscribe(channels: channels)
    }
  }
  
  public func _subscribe(channels ch: [String]) {
    guard !ch.isEmpty else { return } // nothing to subscribe
    guard let stream = self.stream else { return }
    
    var values : [ RedisValue ] = []
    values.append(RedisValue(bulkString: "SUBSCRIBE"))
    for channel in ch {
      values.append(RedisValue(bulkString: channel))
    }
    
    // TODO: callback?
    let cmd = RedisCommand(command: values) { err, value in
      if let err = err {
        console.error("could not subscribe", ch, err)
      }
    }
    stream.write(redisValue: cmd.command)
  }
  
  public func _unsubscribe(channels ch: [String]) {
    guard let stream = self.stream else { return }
    
    // No channels means unsubscribe from all
    var values : [ RedisValue ] = []
    values.append(RedisValue(bulkString: "UNSUBSCRIBE"))
    for channel in ch {
      values.append(RedisValue(bulkString: channel))
    }
    
    // TODO: callback?
    let cmd = RedisCommand(command: values) { err, value in
      if let err = err {
        console.error("could not unsubscribe", ch, err)
      }
    }
    stream.write(redisValue: cmd.command)
  }
  
  
  public var subscribeListeners   = EventListenerSet<(String, Int)>()
  public var unsubscribeListeners = EventListenerSet<(String, Int)>()
  public var messageListeners     = EventListenerSet<(String, RedisValue)>()
  
  @discardableResult
  public func onSubscribe(handler cb: @escaping SubscribeCB) -> Self {
    subscribeListeners.add(handler: cb)
    return self
  }
  @discardableResult
  public func onUnsubscribe(handler cb: @escaping SubscribeCB) -> Self {
    unsubscribeListeners.add(handler: cb)
    return self
  }
  @discardableResult
  public func onMessage(handler cb: @escaping MessageCB) -> Self {
    messageListeners.add(handler: cb)
    return self
  }
}

extension RedisClient : CustomStringConvertible {
  
  public var description : String {
    var s = "<RedisClient:"
    
    s += " \(state)"
    if let stream = stream {
      s += " \(stream.fd.fd)"
    }
    
    if !sentCommands.isEmpty {
      s += " sent=#\(sentCommands.count)"
    }
    if !pendingCommands.isEmpty {
      s += " pending=#\(pendingCommands.count)"
    }
    if sentCommands.isEmpty && pendingCommands.isEmpty {
      s += " idle"
    }
    
    s += ">"
    return s
  }
  
}


// MARK: - Errors

public enum RedisClientError : Error {
  case UnexpectedPublishReplyType(String, [RedisValue])
  case UnexpectedReplyType(RedisValue)
  case ConnectionQuit
}


// MARK: - Command object

/// Encapsulate a Redis command and the callback which should be invoked when
/// the command has been executed.
public class RedisCommand {
  // This is a class because we need reference semantics to locate a command in
  // the various queues.
  
  let command  : [ RedisValue ]
  let callback : RedisReplyCB?
  
  init(command: [ RedisValue ], callback: @escaping RedisReplyCB) {
    self.command  = command
    self.callback = callback
  }
  
  init(command: String, _ argument: RedisValue,
       callback: @escaping RedisReplyCB)
  {
    self.command  = [ RedisValue(bulkString: command), argument ]
    self.callback = callback
  }
  
  init(command: String, _ arg0: RedisValue, _ arg1: RedisValue,
       callback: @escaping RedisReplyCB)
  {
    self.command  = [ RedisValue(bulkString: command), arg0, arg1 ]
    self.callback = callback
  }

  init(command: String,
       _ arg0: RedisValue, _ arg1: RedisValue, _ arg2 : RedisValue,
       callback: @escaping RedisReplyCB)
  {
    self.command  = [ RedisValue(bulkString: command), arg0, arg1, arg2 ]
    self.callback = callback
  }
}

extension RedisCommand : CustomStringConvertible {
  
  public var description : String {
    var s = "<RedisCmd: \(command)"
    
    if callback != nil {
      s += " cb"
    }
    else {
      s += " NO-cb"
    }
    
    s += ">"
    return s
  }
  
}
