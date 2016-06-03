//
//  Console.swift
//  NozeIO
//
//  Created by Helge Hess on 28/04/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import streams

public enum LogLevel : Int8 { // cannot nest types in generics
  case Error
  case Warn
  case Log
  case Info
  case Trace
  
  var logPrefix : String {
    switch self {
      case .Error: return "ERROR: "
      case .Warn:  return "WARN:  "
      case .Info:  return "INFO: "
      case .Trace: return "Trace: "
      case .Log:   return ""
    }
  }
}

/// Writes UTF-8 to any byte stream.
public protocol ConsoleType {
  
  var logLevel : LogLevel { get }
  
#if swift(>=3.0) // #swift3-type #swift3-1st-arg
  func primaryLog(_ logLevel: LogLevel, _ msgfunc : @noescape () -> String,
                  _ values : [ CustomStringConvertible ] )
#else
  func primaryLog(logLevel: LogLevel, @noescape _ msgfunc : () -> String,
                  _ values : [ CustomStringConvertible ] )
#endif
}

public extension ConsoleType { // Actual logging funcs
  
#if swift(>=3.0) // #swift3-type
  public func error(_ msg: @autoclosure () -> String,
                    _ values : CustomStringConvertible...)
  {
    primaryLog(.Error, msg, values)
  }
  public func warn(_ msg: @autoclosure () -> String,
                   _ values : CustomStringConvertible...)
  {
    primaryLog(.Warn, msg, values)
  }
  public func log(_ msg: @autoclosure () -> String,
                  _ values : CustomStringConvertible...)
  {
    primaryLog(.Log, msg, values)
  }
  public func info(_ msg: @autoclosure () -> String,
                   _ values : CustomStringConvertible...)
  {
    primaryLog(.Info, msg, values)
  }
  public func trace(_ msg: @autoclosure () -> String,
                    _ values : CustomStringConvertible...)
  {
    primaryLog(.Trace, msg, values)
  }
  
  public func dir(_ obj: Any) {
    // TODO: implement more
    log("\(obj)")
  }
#else // Swift 2.2
  public func error(@autoclosure msg: () -> String,
                    _ values : CustomStringConvertible...)
  {
    primaryLog(.Error, msg, values)
  }
  public func warn(@autoclosure msg: () -> String,
                   _ values : CustomStringConvertible...)
  {
    primaryLog(.Warn, msg, values)
  }
  public func log(@autoclosure msg: () -> String,
                  _ values : CustomStringConvertible...)
  {
    primaryLog(.Log, msg, values)
  }
  public func info(@autoclosure msg: () -> String,
                   _ values : CustomStringConvertible...)
  {
    primaryLog(.Info, msg, values)
  }
  public func trace(@autoclosure msg: () -> String,
                    _ values : CustomStringConvertible...)
  {
    primaryLog(.Trace, msg, values)
  }
  
  public func dir(obj: Any) {
    // TODO: implement more
    log("\(obj)")
  }
#endif
}

public class ConsoleBase : ConsoleType {

  public var logLevel : LogLevel
  let stderrLogLevel  : LogLevel = .Error // directed to stderr, if available
  
  public init(_ logLevel: LogLevel = .Info) {
    self.logLevel = logLevel
  }

#if swift(>=3.0) // #swift3-type
  public func primaryLog(_ logLevel: LogLevel,
                         _ msgfunc : @noescape () -> String,
                         _ values : [ CustomStringConvertible ] )
  {
  }
#else
  public func primaryLog(logLevel: LogLevel, @noescape _ msgfunc : () -> String,
                         _ values : [ CustomStringConvertible ] )
  {
  }
#endif
}

func writeValues<T: GWritableStreamType where T.WriteType == UInt8>
  (to t: T, _ values : [ CustomStringConvertible ])
{
  for v in values {
    _ = t.writev(buckets: spaceBrigade, done: nil)
    _ = t.write(v.description)
  }
}

// The implementation of this is a little less obvious due to all the
// generics ... we could hook it up to ReadableStream which might make it a
// little cleaner. But hey! ;-)

let eolBrigade   : [ [ UInt8 ] ] = [ [ 10 ] ]
let spaceBrigade : [ [ UInt8 ] ] = [ [ 32 ] ] // best name evar

public class Console<OutStreamType: GWritableStreamType
                     where OutStreamType.WriteType == UInt8>
             : ConsoleBase
{
  
  let stdout : OutStreamType
  
  // Note: An stderr optional doesn't fly because the type of Console
  //       can't be derived w/o giving a type.
  public init(_ stdout: OutStreamType, logLevel: LogLevel = .Info) {
    self.stdout   = stdout
    super.init(logLevel)
  }
  
#if swift(>=3.0) // #swift3-type
  public override func primaryLog(_ logLevel : LogLevel,
                                  _ msgfunc  : @noescape () -> String,
                                  _ values   : [ CustomStringConvertible ] )
  {
    // Note: We just write and write and write, not waiting for the stream
    //       to actually drain the buffer.
    // TBD:  We could make this threadsafe by dispatching the write to core.Q.
    //       Not sure it's worth it.
    guard logLevel.rawValue <= self.logLevel.rawValue else { return }
    
    let s = msgfunc()
    _ = stdout.write(logLevel.logPrefix)
    _ = stdout.write(s)
    writeValues(to: stdout, values)
    _ = stdout.writev(buckets: eolBrigade, done: nil)
  }
#else
  public override func primaryLog(logLevel : LogLevel,
                                  @noescape _ msgfunc : () -> String,
                                  _ values : [ CustomStringConvertible ] )
  {
    // Note: We just write and write and write, not waiting for the stream
    //       to actually drain the buffer.
    // TBD:  We could make this threadsafe by dispatching the write to core.Q.
    //       Not sure it's worth it.
    guard logLevel.rawValue <= self.logLevel.rawValue else { return }
    
    let s = msgfunc()
    stdout.write(logLevel.logPrefix)
    stdout.write(s)
    writeValues(to: stdout, values)
    stdout.writev(buckets: eolBrigade, done: nil)
  }
#endif
}

// Unfortunately we can't name this 'Console' as I hoped. Swift complains about
// invalid redeclaration..
public class Console2<OutStreamType: GWritableStreamType,
                      ErrStreamType: GWritableStreamType
                      where OutStreamType.WriteType == UInt8,
                            ErrStreamType.WriteType == UInt8>
             : ConsoleBase
{
  
  let stdout : OutStreamType
  let stderr : ErrStreamType
  
  // Note: An stderr optional doesn't fly because the type of Console
  //       can't be derived w/o giving a type.
  public init(_ stdout: OutStreamType, _ stderr: ErrStreamType,
              logLevel: LogLevel = .Info)
  {
    self.stdout   = stdout
    self.stderr   = stderr
    super.init(logLevel)
  }
  
#if swift(>=3.0) // #swift3-type #swift3-1st-arg
  public override func primaryLog(_ logLevel : LogLevel,
                                  _ msgfunc  : @noescape () -> String,
                                  _ values   : [ CustomStringConvertible ] )
  {
    // Note: We just write and write and write, not waiting for the stream
    //       to actually drain the buffer.
    // TBD:  We could make this threadsafe by dispatching the write to core.Q.
    //       Not sure it's worth it.
    guard logLevel.rawValue <= self.logLevel.rawValue else { return }
    
    let s = msgfunc()
    
    if logLevel.rawValue <= stderrLogLevel.rawValue {
      _ = stderr.write(logLevel.logPrefix)
      _ = stderr.write(s)
      writeValues(to: stdout, values)
      _ = stderr.writev(buckets: eolBrigade, done: nil)
    }
    else {
      _ = stdout.write(logLevel.logPrefix)
      _ = stdout.write(s)
      writeValues(to: stdout, values)
      _ = stdout.writev(buckets: eolBrigade, done: nil)
    }
  }
#else // Swift 2.2
  public override func primaryLog(logLevel : LogLevel,
                                  @noescape _ msgfunc : () -> String,
                                  _ values : [ CustomStringConvertible ] )
  {
    // Note: We just write and write and write, not waiting for the stream
    //       to actually drain the buffer.
    // TBD:  We could make this threadsafe by dispatching the write to core.Q.
    //       Not sure it's worth it.
    guard logLevel.rawValue <= self.logLevel.rawValue else { return }
    
    let s = msgfunc()
    
    if logLevel.rawValue <= stderrLogLevel.rawValue {
      stderr.write(logLevel.logPrefix)
      stderr.write(s)
      writeValues(to: stdout, values)
      stderr.writev(buckets: eolBrigade, done: nil)
    }
    else {
      stdout.write(logLevel.logPrefix)
      stdout.write(s)
      writeValues(to: stdout, values)
      stdout.writev(buckets: eolBrigade, done: nil)
    }
  }
#endif // Swift 2.2
}
