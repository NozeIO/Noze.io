//
//  RedisParser.swift
//  Noze.io
//
//  Created by Helge Heß on 6/25/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import core
import streams

/// Parses a byte stream into Redis RESP formatted objects, that is, into
/// `RedisValue` objects.
///
/// RESP (REdis Serialization Protocol) supports those types:
///
/// - simple strings (+OK\r\n)
/// - bulk   strings ($len\r\npayload\r\n or $-1\r\n for nil)
/// - integers       (:99\r\n)
/// - errors         (-ERR unknown command abc\r\n)
/// - nested arrays  (*cnt\r\nRESP or *-1\r\n for nil)
///
class RedisParser : TransformStream<UInt8, RedisValue> {
  
  let heavyDebug = false
  
  
  // MARK: - Init
  
  override init(readHWM      : Int? = nil,
                writeHWM     : Int? = nil,
                queue        : DispatchQueueType = core.Q,
                enableLogger : Bool = false)
  {
    super.init(readHWM: readHWM, writeHWM: writeHWM, queue: queue,
               enableLogger: enableLogger)
  }
  
  
  // MARK: - Parsing
  
  typealias WriteTypeBucket = [ WriteType ]

  enum ParserError : Error {
    case UnexpectedStartByte(char: UInt8, bucket: [UInt8])
  }
  
  enum ParserState {
    case ProtocolError
    case Start
    case Error
    case Integer
    case BulkStringLen
    case BulkStringValue
    case SimpleString
    case ArrayCount
  }
  
  class ParseContext {
    let parent : ParseContext?
    var values : [ ReadType ] = []
    
    let count  : Int? // expected count, can be nil for top-level
    
    init() { // top-level context
      self.parent = nil
      self.count  = nil
    }
    init(_ parent: ParseContext, _ count: Int) { // array context
      self.parent = parent
      self.count  = count
    }
    
    var isDone   : Bool { return count == nil || count! <= values.count }
    var isNested : Bool { return parent != nil }
    
    func append(value v: ReadType) -> Bool {
      assert(!isNested || !isDone,
             "attempt to add to a context which is not TL or done")
      values.append(v)
      return isDone
    }
  }
  
  var state      : ParserState = .Start
  var skipNL     = false // some sideline extra state ...
  var hadMinus   = false
  
  // parsing buffers
  var countValue : Int    = 0
  var byteValue  = [ UInt8 ]()
  
  var context    : ParseContext?  = nil
  
  var lastError  : Error? = nil
  
  func append(value v: ReadType) {
    guard let ctx = context else {
      assert(context != nil, "attempt to append to context, but none is setup!")
      return
    }
    
    _ = ctx.append(value: v)
    
    if ctx.isNested && ctx.isDone {
      if heavyDebug { print("^^ FINISHED CONTEXT: \(ctx)") }
      self.context = ctx.parent
      _ = self.context!.append(value: RedisValue.Array(ctx.values))
    }
  }
  
  override func _transform(bucket b: [ UInt8 ],
                           done: @escaping ( Error?, [ RedisValue ]? ) -> Void)
  {
    guard !b.isEmpty else {
      assert(!b.isEmpty, "transform bucket is empty?")
      return done(nil, nil)
    }
    
    if heavyDebug { print("GOT BUCKET: \(b.debug)") }
    
    var p    = b.startIndex
    let ep   = b.endIndex
    //var mark : WriteTypeBucket.Index? = nil // doesn't work: b.Type.Index
    
    if heavyDebug {
      print("*SCAN [\(p):\(ep)]: \(state)")
    }
    
    // setup new context, or reuse the existing one.
    
    if context == nil { context = ParseContext() }
    else {
      assert(!context!.isDone, "Pending context flying around ...")
    }
    
    // Walk over each byte. This sounds expensive (and with arrays it is a
    // little), but technically, stuff peeking ahead often walks the same data
    // again and again. So it might actually be the best way to do this.
    while p != ep {
      let c  = b[p]
      let np = p + 1
      
      if skipNL {
        skipNL = false
        if c == 10 {
          p = np
          continue
        }
        // else: error? (just had CR, not CRLF)
      }
      
      var currentState : ParserState = self.state
      if heavyDebug {
        print("START \(c)[\(p):\(ep)]: \(currentState)")
      }
      
      switch currentState {
        
        case .ProtocolError: // only hit on first iteration?!
          assert(p == b.startIndex)
          done(self.lastError, nil)
          return
        
        case .Start:
          switch c {
            case 43 /* + */: currentState = .SimpleString
            case 45 /* - */: currentState = .Error
            case 58 /* : */: currentState = .Integer
            case 36 /* $ */: currentState = .BulkStringLen
            case 42 /* * */: currentState = .ArrayCount
            default: // TODO: support telnet mode?
              self.lastError =
                     ParserError.UnexpectedStartByte(char: c, bucket: b)
              self.state = ParserState.ProtocolError
              done(self.lastError, nil)
              return
          }
          countValue = 0
          byteValue.removeAll()
        
        case .ArrayCount, .BulkStringLen, .Integer:
          let c0 : UInt8 = 48, c9 : UInt8 = 57, cMinus : UInt8 = 45
          if c >= c0 && c <= c9 {
            let digit = c - c0
            countValue = (countValue * 10) + Int(digit)
          }
          else if !hadMinus && c == cMinus && countValue == 0 {
            // this allows: $0-10\r\n...
            hadMinus = true
          }
          else if c == 13 || c == 10 { // finished reading number
            let doNegate = hadMinus
            hadMinus = false
            if c == 13 { skipNL = true }
            if heavyDebug { print(":: PARSED NUMBER: \(countValue)") }
            
            switch currentState {
              
              case .ArrayCount:
                if doNegate { // -1 signals the `nil` array
                  assert(countValue == 1) // TODO: throw error
                  append(value: RedisValue.Array(nil))
                }
                else if let ctx = context {
                  if countValue > 0 {
                    context = ParseContext(ctx, countValue)
                    if heavyDebug { print("! started new context: \(context)") }
                  }
                  else {
                    // push an empty array
                    append(value: RedisValue.Array([]))
                  }
                }
                else {
                  // ERROR
                  assert(context != nil, "Cannot nest array w/o parent ctx")
                }
                currentState = .Start
              
              case .BulkStringLen:
                if doNegate {
                  currentState = .Start
                  append(value: RedisValue.BulkString(nil))
                }
                else {
                  currentState = .BulkStringValue
                  byteValue.removeAll()
                  byteValue.reserveCapacity(countValue + 1)
                    // inefficient, should use a marker
                }
              
              case .Integer:
                let value = doNegate ? -countValue : countValue
                countValue = 0 // reset
                
                append(value: RedisValue.Integer(value))
                currentState = .Start
              
              default: break
            }
          }
          else {
            self.lastError = ParserError.UnexpectedStartByte(char: c, bucket: b)
            self.state = ParserState.ProtocolError
            done(self.lastError, nil)
            return
          }
        
        case .BulkStringValue:
          // TODO: inefficient, should use a marker
          if byteValue.count < countValue {
            byteValue.append(c)
          }
          else if byteValue.count == countValue && (c == 13 || c == 10) {
            // end of bulk string
            if c == 13 { skipNL = true }
            
            let value = byteValue
            byteValue.removeAll()
            append(value: RedisValue.BulkString(value))
            if heavyDebug { print("$$ PARSED BULK: \(value.debug)") }
            currentState = .Start
          }
          else {
            self.lastError = ParserError.UnexpectedStartByte(char: c, bucket: b)
            self.state = ParserState.ProtocolError
            done(self.lastError, nil)
            return
          }
        
        case .SimpleString, .Error:
          if c == 13 || c == 10 {
            if c == 13 { skipNL = true }
            
            if currentState == .SimpleString {
              append(value: RedisValue.SimpleString(byteValue))
            }
            else {
              // TODO: make nice :-)
              let pair = byteValue.split(separator: 32, maxSplits: 1)
              let code = pair.count > 0 ? String.decode(utf8: pair[0]) ?? "" :""
              let msg  = pair.count > 1 ? String.decode(utf8: pair[1]) ?? "" :""
              let error = RedisError(code: code, message: msg)
              append(value: RedisValue.Error(error))
            }
            byteValue.removeAll()
            
            currentState = .Start
          }
          else {
            byteValue.append(c)
          }
      }
      
      // trailer
      
      if heavyDebug {
        if self.state != currentState {
          print("  END \(c)[\(p)]: " +
                "FROM state \(self.state) to \(currentState)")
        }
      }
      self.state = currentState
      p = np
    }
    
    
    // finish up.
    
    if let ctx = context {
      if ctx.isDone { // context is finished, we consume it
        let values = ctx.values
        context = nil
        if heavyDebug { print("DONE: \(values)") }
        done(nil, values)
      }
      else {
        // we leave the context around
        done(nil, [])
      }
    }
    else {
      assert(context != nil, "No context at the end of the loop?")
      done(nil, [])
    }
  }
}
