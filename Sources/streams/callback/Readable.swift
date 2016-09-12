//
//  Readable.swift
//  Noze.io
//
//  Created by Helge Heß on 5/15/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import core

/// A callback based `ReadableStream`, that is, you don't need to subclass, you
/// can just use this.
///
/// A `Readable` doesn't even have to have a `_read` callback. You can
/// instantiate it and just `push` to it, like so:
///
///    let rs = Readable<UInt8>()
///    rs.push("beep ")
///    rs.push("boop\n")
///    rs.push(nil) // EOF
///    rs | process.stdout
///
/// Note that all pushes are put into the buffer and will be written even though
/// an EOF got pushed.
///
/// But quite often you don't want to buffer stuff but rather behave like a
/// generator (only produce output if someone is actually reading).
/// If you already have a `Generator` (or `Iterator`) you can use the
/// `GeneratorSource` in Noze. Like so:
///
///    myGenerator.readableSource()
///
/// If you don't, you can use this stream with a callback, like so:
///
///    let rs = Readable<UInt8>()
///
///    var c : UInt8 = 97
///    rs._read = {
///      rs.push([c])
///      c += 1
///      if c > 122 /* 'z' */ { rs.push(nil) }
///    }
///    rs | process.stdout
///
/// This will only generate items when `stdout` has buffer space to consume
/// them (that is, on-demand).
///
/// Reference:
///   https://github.com/substack/stream-handbook#user-content-creating-a-readable-stream
///
public class Readable<ReadType> : ReadableStream<ReadType> {
  
  // MARK: - Init
  
  override public init(highWaterMark : Int? = 1,
                       queue         : DispatchQueue = core.Q,
                       enableLogger  : Bool = false)
  {
    super.init(highWaterMark: highWaterMark, queue: queue,
               enableLogger: enableLogger)
  }
  public convenience init(cb: @escaping ( Void ) -> Void) {
    self.init()
    self._read(cb: cb)
  }

  
  // MARK: - The Callback

  var cb = ReadableReadCB.None
  
  /// A `read` callback producing values. It is called if a consumer desires
  /// values.
  /// This has a leading underscore just for Node compat.
  func _read(cb lcb: @escaping ( Void ) -> Void) {
    cb = ReadableReadCB.NoArgs(lcb)
  }
  
  /// A `read` callback producing values. It is called if a consumer desires
  /// values.
  /// This has a leading underscore just for Node compat.
  func _read(cb lcb: @escaping ( Int  ) -> Void) {
    cb = ReadableReadCB.Amount(lcb)
  }
  
  
  // MARK: - Readable Overrides
  
  override public func _primaryRead(count howMuchToRead: Int) {
    assert(!hitEOF)
    
    switch cb {
      case .None:
        if !hitEOF {
          push(nil) // right?
        }
        break
      
      case .NoArgs(let cb): cb()
      case .Amount(let cb): cb(howMuchToRead)
    }
    
    if hitEOF { // release the closure
      cb = .None
    }
  }
}

enum ReadableReadCB {
  case None
  case NoArgs(( Void ) -> Void)
  case Amount(( Int  ) -> Void)
}
