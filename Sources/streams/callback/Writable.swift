//
//  Writable.swift
//  Noze.io
//
//  Created by Helge Heß on 5/15/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import core

/// A callback based `WritableStream`, that is, you don't need to subclass, you
/// can just use this.
///
/// Example:
///
///     let ws = Writable<UInt8>()
///     ws._write { chunk, next in
///       console.dir(chunk)
///       next()
///     }
///
///     "hello world" | ws
///
/// Reference:
///   https://github.com/substack/stream-handbook#creating-a-writable-stream
///
public class Writable<WriteType> : WritableStream<WriteType> {
  
  // MARK: - Init
  
  override public init(highWaterMark : Int? = 1,
                       queue         : DispatchQueue = core.Q,
                       enableLogger  : Bool = false)
  {
    super.init(highWaterMark: highWaterMark, queue: queue,
               enableLogger: enableLogger)
  }
  
  public convenience init(cb: @escaping ([ WriteType ],
                          @escaping ( Error? ) -> Void) -> Void)
  {
    self.init()
    self._write(cb: cb)
  }
  
  // MARK: - The Callback

  var cb : WritableWriteCB<WriteType> = .None
  
  func _write(cb: @escaping ([WriteType], @escaping (Error?) -> Void) -> Void) {
    self.cb = .ChunkAndError(cb)
  }
  
  
  // MARK: - Callback Overload
  
  #if SWIFT_SUPPORTS_REALLY_CLEVER_TYPE_LOOKUP
    // Cannot do this, will make the untyped cb ambigiuos (even though the
    // compiler could derive the type from the call).
    public convenience init(cb: @escaping ([ WriteType ],
                            @escaping ( ) -> Void) -> Void)
    {
      self.init()
      self.cb = .JustChunk(cb)
    }
  
    func _write(cb lcb: ([ WriteType ], ( ) -> Void) -> Void) {
      cb = .JustChunk(lcb)
    }
  #endif
  
  
  // MARK: - Writable Overrides
  
  override open func _primaryWriteV(buckets c: Brigade,
                                    done: @escaping ( Error?, Int ) -> Void)
  {
    log.enter(); defer { log.leave() }
    
    switch cb {
      case .None:
        done(nil, 0) // TBD: is 0 right, or should we be /dev/null?
      case .JustChunk(let cb):
        let fb = flatten(brigadge: c)
        cb(fb) {
          done(nil, fb.count)
        }
      case .ChunkAndError (let cb):
        let fb = flatten(brigadge: c)
        cb(fb) { error in
          done(error, error != nil ? 0 : fb.count)
        }
    }
  }
}

enum WritableWriteCB<WriteType> {

  case None
  case JustChunk    (([ WriteType ], @escaping ( ) -> Void) -> Void)
  case ChunkAndError(([ WriteType ], @escaping (Error?)->Void) ->Void)
}

// lame, but gets the job done for now
private func flatten<T>(brigadge b : [ [ T ] ]) -> [ T ] {
  var bucket = [ T ]()
  for chunk in b {
    bucket.append(contentsOf: chunk)
  }
  return bucket
}
