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
///     ws._write { chunk, done in
///       console.dir(chunk)
///       done()
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
                       queue         : DispatchQueueType = core.Q,
                       enableLogger  : Bool = false)
  {
    super.init(highWaterMark: highWaterMark, queue: queue,
               enableLogger: enableLogger)
  }
  
#if swift(>=3.0) // #swift3-escape
  public convenience init
    (cb: @escaping ([ WriteType ], @escaping ( Error? ) -> Void) -> Void)
  {
    self.init()
    self._write(cb: cb)
  }
#else // Swift 2.x
  public convenience init(cb: ([ WriteType ], ( ErrorType? ) -> Void) -> Void) {
    self.init()
    self._write(cb: cb)
  }
#endif // Swift 2.x
  
  
  // MARK: - The Callback

  var cb : WritableWriteCB<WriteType> = .None
  
  /* cannot do this, will make the untyped cb ambigiuos
  func _write(cb lcb: ([ WriteType ], ( ) -> Void) -> Void) {
    cb = .JustChunk(lcb)
  }
  */
#if swift(>=3.0) // #swift3-escape
  func _write(cb: @escaping ([WriteType], @escaping (Error?) -> Void) -> Void) {
    self.cb = .ChunkAndError(cb)
  }
#else // Swift 2.x
  func _write(cb lcb: ([ WriteType ], ( ErrorType? ) -> Void) -> Void) {
    cb = .ChunkAndError(lcb)
  }
#endif // Swift 2.x
  
  
  // MARK: - Writable Overrides
  
  override func _primaryWriteV(buckets c: Brigade, done: PrimaryWriteDoneCB) {
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
#if swift(>=3.0) // #swift3-escape
  public typealias WritableWriteCBJustChunk =
                     @escaping ([ WriteType ], @escaping ( ) -> Void) -> Void
  public typealias WritableWriteCBChunkAndError =
                @escaping ([ WriteType ], @escaping ( Error? ) -> Void) -> Void
#else // Swift 2.x
  public typealias WritableWriteCBJustChunk =
                     ([ WriteType ], ( ) -> Void) -> Void
  public typealias WritableWriteCBChunkAndError =
                     ([ WriteType ], ( ErrorType? ) -> Void) -> Void
#endif // Swift 2.x
  
  case None
  case JustChunk    (WritableWriteCBJustChunk)
  case ChunkAndError(WritableWriteCBChunkAndError)
}

// lame, but gets the job done for now
private func flatten<T>(brigadge b : [ [ T ] ]) -> [ T ] {
  var bucket = [ T ]()
  for chunk in b {
    bucket.append(contentsOf: chunk)
  }
  return bucket
}
