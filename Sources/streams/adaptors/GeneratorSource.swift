//
//  GeneratorSource.swift
//  Noze.IO
//
//  Created by Helge Hess on 24/06/15.
//  Copyright © 2015 ZeeZide GmbH. All rights reserved.
//

#if swift(>=3.0)
#else // Swift 2.2+

import Dispatch
import core

public extension SequenceType {
  
  func readableSource() -> SyncGeneratorSource<Self.Generator> {
    return SyncGeneratorSource(self)
  }
  
  func asyncReadableSource() -> AsyncGeneratorSource<Self.Generator> {
    return AsyncGeneratorSource(self)
  }
  
}

public extension GeneratorType {
  
  func readableSource() -> SyncGeneratorSource<Self> {
    return SyncGeneratorSource(self)
  }
  
  func asyncReadableSource() -> AsyncGeneratorSource<Self> {
    return AsyncGeneratorSource(self)
  }
  
}

/// Wraps a regular Swift Generator in a ReadableSourceType.
///
/// Note that this one is synchronous, aka, the Generator should not block on
/// I/O or be otherwise expensive. For such cases use the AsyncGeneratorSource.
public struct SyncGeneratorSource<G: GeneratorType> : GReadableSourceType {
  
  public static var defaultHighWaterMark : Int { return 5 } // TODO
  var source : G
  var isDone = false // TBD: seems like we need to track this
  
  // MARK: - Init from a GeneratorType or a SequenceType
  
  init(_ source: G) {
    self.source = source
  }
  init<S: SequenceType where S.Generator == G>(_ source: S) {
    self.init(source.generate())
  }
  
  // MARK: - queue based next() function
  
  /// Synchronously generates an item. That is, this directly yields a value
  /// back to the Readable.
  public mutating func next(queue _: DispatchQueueType, count: Int,
                            yield : ( Error?, [ G.Element ]? ) -> Void)
  {
    _next(count) { bucket in yield(nil, bucket) }
  }
  
  public mutating func _next(count: Int, yield : ( [ G.Element ]? ) -> Void) {
    // Difference to the main entry point: this `_next` has no Q and no
    //                                     Error.
    
    guard !isDone else { yield(nil); return }
    guard let first = source.next() else {
      isDone = true // TBD: remember EOF, do not invoke next() again
      yield(nil) // EOF
      return
    }
    
    // client just asked for one item, return that
    
    if count == 1 {
      yield( [ first ] )
      return
    }
    
    // more items are desired, collect all of them synchrounsly
    
    var buffer : [ G.Element ] = []
    buffer.reserveCapacity(count)
    buffer.append(first)
    
    for _ in 1..<count {
      guard let item = source.next() else { // Generator is empty, returned nil
        isDone = true
        yield(buffer)
        yield(nil)    // EOF, two yields
        return
      }
      
      buffer.append(item)
    }
    
    yield(buffer)
  }
}

/// Wraps a regular Swift Generator in a ReadableSourceType.
///
/// The AsyncGeneratorSource uses a worker queue to dispatch reading
/// asynchronously.
///
/// Note: Currently the worker queue is supposed to be a serial queue, as the
///       Readable might dispatch a set of reads and the source has no internal
///       synchronization yet.
/// TODO: support pause()?
public struct AsyncGeneratorSource<G: GeneratorType> : GReadableSourceType {
  
  public static var defaultHighWaterMark : Int { return 5 } // TODO
  var source              : G
  let workerQueue         : DispatchQueueType
  let maxCountPerDispatch : Int
  
  // MARK: - Init from a GeneratorType or a SequenceType
  
  init(_ source: G, workerQueue: DispatchQueueType = defaultWorkerQueue,
       maxCountPerDispatch: Int = 16)
  {
    self.source              = source
    self.workerQueue         = workerQueue
    self.maxCountPerDispatch = maxCountPerDispatch
  }
  init<S: SequenceType where S.Generator == G>
    (_ source: S, workerQueue: DispatchQueueType = defaultWorkerQueue)
  {
    self.init(source.generate(), workerQueue: workerQueue)
  }
  
  
  // MARK: - queue based next() function
  
  /// Asynchronously generate items.
  ///
  /// This dispatches the generator on the workerQueue of the source, but
  /// properly yields back results on the queue which is passed in.
  ///
  /// The number of generation attempts can be limited using the 
  /// maxCountPerDispatch property. I.e. that property presents an upper limit
  /// to the 'count' property which was passed in.
  public mutating func next(queue Q : DispatchQueueType, count: Int,
                            yield   : ( Error?, [ G.Element ]? )-> Void)
  {
    // Note: we do capture self for the generator ...
    let maxCount = self.maxCountPerDispatch
    
    core.module.retain()
    
    workerQueue.async {
      guard let first = self.source.next() else {
        Q.async {
          yield(nil, nil) // EOF
          core.module.release()
        }
        return
      }
      
      let actualCount = max(count, maxCount)
      
      if actualCount == 1 {
        let bucket = [ first ]
        Q.async {
          yield(nil, bucket)
          core.module.release()
        }
        return
      }
      
      // asked for more than one
      
      var buffer : [ G.Element ] = []
      buffer.reserveCapacity(actualCount)
      buffer.append(first)
      
      var hitEOF = false
      for _ in 1..<actualCount {
        guard let item = self.source.next() else {
          hitEOF = true
          break
        }
        
        buffer.append(item)
      }
      Q.async {
        yield(nil, buffer)
        if hitEOF { yield(nil, nil) } // EOF
        core.module.release()
      }
    }
  }
}
  
/* Nope: Use a serial queue, w/o internal synchronization we would generate
         yields out of order.
return dispatch_get_global_queue(QOS_CLASS_DEFAULT,
                                 UInt(DISPATCH_QUEUE_PRIORITY_DEFAULT))
*/
private var defaultWorkerQueue = // Note: alloc of the global is lazy
              dispatch_queue_create("io.noze.source.generator.async", nil)

#endif // Swift 2.2
