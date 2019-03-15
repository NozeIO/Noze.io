//
//  Console.swift
//  Noze.io
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
  
  func primaryLog(_ logLevel: LogLevel, _ msgfunc: () -> String,
                  _ values: [ Any? ] )
}

public extension ConsoleType { // Actual logging funcs
  
  func error(_ msg: @autoclosure () -> String, _ values: Any?...) {
    primaryLog(.Error, msg, values)
  }
  func warn (_ msg: @autoclosure () -> String, _ values: Any?...) {
    primaryLog(.Warn, msg, values)
  }
  func log  (_ msg: @autoclosure () -> String, _ values: Any?...) {
    primaryLog(.Log, msg, values)
  }
  func info (_ msg: @autoclosure () -> String, _ values: Any?...) {
    primaryLog(.Info, msg, values)
  }
  func trace(_ msg: @autoclosure () -> String, _ values: Any?...) {
    primaryLog(.Trace, msg, values)
  }
  
  func dir(_ obj: Any?) {
    // TODO: implement more
    log("\(obj as Optional)")
  }
}

public class ConsoleBase : ConsoleType {

  public var logLevel : LogLevel
  let stderrLogLevel  : LogLevel = .Error // directed to stderr, if available
  
  public init(_ logLevel: LogLevel = .Info) {
    self.logLevel = logLevel
  }

  public func primaryLog(_ logLevel: LogLevel,
                         _ msgfunc : () -> String,
                         _ values : [ Any? ] )
  {
  }
}

func writeValues<T: GWritableStreamType>(to t: T, _ values : [ Any? ])
                 where T.WriteType == UInt8
{
  for v in values {
    _ = t.writev(buckets: spaceBrigade, done: nil)
    
    if let v = v as? CustomStringConvertible {
      _ = t.write(v.description)
    }
    else if let v = v as? String {
      _ = t.write(v)
    }
    else {
      _ = t.write("\(v as Optional)")
    }
  }
}

// The implementation of this is a little less obvious due to all the
// generics ... we could hook it up to ReadableStream which might make it a
// little cleaner. But hey! ;-)

let eolBrigade   : [ [ UInt8 ] ] = [ [ 10 ] ]
let spaceBrigade : [ [ UInt8 ] ] = [ [ 32 ] ] // best name evar

public class Console<OutStreamType: GWritableStreamType> : ConsoleBase
                     where OutStreamType.WriteType == UInt8
{
  
  let stdout : OutStreamType
  
  // Note: An stderr optional doesn't fly because the type of Console
  //       can't be derived w/o giving a type.
  public init(_ stdout: OutStreamType, logLevel: LogLevel = .Info) {
    self.stdout   = stdout
    super.init(logLevel)
  }
  
  public override func primaryLog(_ logLevel : LogLevel,
                                  _ msgfunc  : () -> String,
                                  _ values   : [ Any? ] )
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
}

// Unfortunately we can't name this 'Console' as I hoped. Swift complains about
// invalid redeclaration..
public class Console2<OutStreamType: GWritableStreamType,
                      ErrStreamType: GWritableStreamType>
             : ConsoleBase
             where OutStreamType.WriteType == UInt8,
                   ErrStreamType.WriteType == UInt8
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
  
  public override func primaryLog(_ logLevel : LogLevel,
                                  _ msgfunc  : () -> String,
                                  _ values   : [ Any? ] )
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
}
