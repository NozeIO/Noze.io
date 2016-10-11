//
//  Logger.swift
//  Noze.IO
//
//  Created by Helge Heß on 21/06/15.
//  Copyright © 2015 ZeeZide GmbH. All rights reserved.
//

// NOTE: This is bad, don't use it. We should replace it with Console somehow.x

/// Logging object used within Noze. Do not use, should be cleaned up and
/// be replaced.
/// In userland code use the `console` module.
public class Logger : LoggerType {
  
  public typealias LogCB = ( Logger ) -> Void
  
  public var enabled : Bool
  var depth   = 0
  
  public var onAfterEnter  : LogCB? = nil
  public var onBeforeLeave : LogCB? = nil
  public var onBeforeLog   : LogCB? = nil // those would recurse
  public var onAfterLog    : LogCB? = nil // those would recurse
  
  public init(enabled: Bool) {
    self.enabled = enabled
  }
  
  public func nest()   { depth += 1 }
  public func unnest() { depth -= 1 }
  
  private func indent() {
    for _ in 0..<depth {
      print("  ", terminator: "")
    }
  }
  
  public func enter(filename: String? = #file, line: Int? = #line,
                    function: String? = #function)
  {
    guard enabled else { return }

    if let f = function {
      indent()
      print("<\(f)()")
    }

    self.nest()
    
    if let cb = onAfterEnter { cb(self) }
  }
  public func leave(filename: String? = #file, line: Int? = #line,
                    function: String? = #function)
  {
    guard enabled else { return }
    
    if let cb = onBeforeLeave { cb(self) }
    
    self.unnest()
    
    if let f = function {
      indent()
      print(">\(f)()")
    }
    if depth == 0 {
      print("") // newline for top-level
    }
  }

  public func log<T>(message: @autoclosure () -> T,
                     filename: String? = #file, line: Int? = #line,
                     function: String? = #function)
  {
    guard enabled else { return }
    
    let msg = message()
      // what is more expensive, passing around closures, or calculating
      // messages even if unnecessary?

    if let cb = onBeforeLog { cb(self) }

    indent()
    print(msg)

    if let cb = onAfterLog { cb(self) }
  }
  
  public func debug<T>(message: @autoclosure () -> T,
                       filename: String? = #file, line: Int? = #line,
                       function: String? = #function)
  {
    log(message, filename: filename, line: line, function: function)
  }
}

public protocol LoggerType {
  // This is kinda useless because protocol declarations cannot take default
  // arguments, which we want.
  // TODO: but extensions can. Could use that as a workaround.

  associatedtype LogCB = ( Self ) -> Void
  
  var enabled : Bool { get set }
  
  // TODO: make them regular 'on' funcs ...
  var onAfterEnter  : LogCB?  { get set }
  var onBeforeLeave : LogCB?  { get set }
  var onBeforeLog   : LogCB?  { get set } // those would recurse
  var onAfterLog    : LogCB?  { get set } // those would recurse
  
  func enter(filename: String?, line: Int?, function: String?)
  func leave(filename: String?, line: Int?, function: String?)
  
  func log  <T>(message: @autoclosure () -> T,
                filename: String?, line: Int?, function: String?)
  func debug<T>(message: @autoclosure () -> T,
                filename: String?, line: Int?, function: String?)
}

// this is for the wildcard 1st arg
public extension LoggerType {
  
  func enter(_ filename: String? = #file, line: Int? = #line,
             function: String? = #function)
  {
    enter(filename: filename, line: line, function: function)
  }
  func leave(_ filename: String? = #file, line: Int? = #line,
             function: String? = #function)
  {
    leave(filename: filename, line: line, function: function)
  }
  
  func log  <T>(_ message: @autoclosure () -> T,
                filename: String? = #file, line: Int? = #line,
                function: String? = #function)
  {
    log(message: message, filename: filename, line: line, function: function)
  }
  func debug<T>(_ message: @autoclosure () -> T,
                filename: String? = #file, line: Int? = #line,
                function: String? = #function)
  {
    debug(message: message, filename: filename, line: line, function: function)
  }
}

public protocol LameLogObjectType : CustomStringConvertible {

  var  logStateInfo : String { get }
  
  func logState()
  var  log : Logger { get }
}

public extension LameLogObjectType {
  
  public func logState() {
    guard log.enabled else { return }
    log.debug("[\(logStateInfo)]")
  }
  
  public var description : String {
    let t = type(of: self)
    return "<\(t):\(logStateInfo)>"
  }
}
