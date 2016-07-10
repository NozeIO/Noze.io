//
//  Sequence2StreamPipe.swift
//  Noze.io
//
//  Created by Helge Heß on 5/1/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if swift(>=3.0) // #swift3-fd #swift3-1st-arg
import xsys
import core

/// Pipe operator for streams, neat :-)
///
/// Like so:
///
///   [ 'a', 'a', 'a' ] | zip | encrypt | fs
///
public func |<TI: Sequence, TO: GWritableStreamType
              where TI.Iterator.Element == TO.WriteType>
            (left: TI, right: TO) -> TO
{
  return left.pipe(right)
}


/// Allows you to pipe any sequence into a GWritableStreamType. Note that we
/// assume that a SequenceType doesn't block.
///
/// This isn't just a foreach item target.write(item), but it properly notes
/// when the stream is full and waits for onDrain.
///
/// Note: The same could be accomplished with the `GeneratorSource` like so:
///
///         [ 'a', 'a', 'a' ].readableSource().readable() | zip | encrypt | fs
///
///       But this one is a little more efficient.
///
public extension Sequence {
  // TODO: We could support an async mode for blocking Sequences similar to
  //       the GeneratorSource.
  
  public func pipe<TO: GWritableStreamType
                   where Self.Iterator.Element == TO.WriteType>
                  (_ outStream: TO, batchSize: Int = 10, endOnFinish: Bool = true)
              -> TO
  {
    let state = SequencePipeState(self, outStream,
                                  batchSize   : batchSize,
                                  endOnFinish : endOnFinish)
    
    _ = outStream.onError  { error in state.onTargetError(error: error) }
    _ = outStream.onFinish { state.onFinish() }
    
    // we are immediately readable ;-) Named like that for consistency
    state.onPipeSourceReadable()
    
    return outStream
  }
}

private class SequencePipeState<TI: Sequence, TO: GWritableStreamType
                                where TI.Iterator.Element == TO.WriteType>
{
  // TBD: should TI be bound to just a generator?
  
  let batchSize       : Int
    // TODO: this is a little stupid, we need a protocol to figure out how
    //       space is available in the WriteableStream
  
  var src             : TI.Iterator
  let dest            : TO
  var hitEOF          = false
  var didStreamFinish = false
  let endOnFinish     : Bool
  
  init(_ src: TI, _ dest: TO, batchSize: Int, endOnFinish: Bool) {
    self.batchSize   = batchSize
    self.endOnFinish = endOnFinish
    self.src         = src.makeIterator()
    self.dest        = dest
  }
  
  
  // MARK: - Piping
  
  final func onPipeSourceReadable() {
    while !hitEOF && !didStreamFinish {
      let bucket = generateBucket()
      
      if bucket.count > 0 {
        let couldWriteEverything = dest.writev(buckets: [ bucket ], done: nil)
        
        if !couldWriteEverything && !hitEOF {
          // install drain handler
          
          _ = dest.onceDrain {
            nextTick { // avoids nested emits. TBD
              self.onPipeSourceReadable()
            }
          }
          break // wait for drain
        }
      }
      
      if hitEOF {
        if endOnFinish { dest.end() }
        break // DONE
      }
    }
  }
  
  final func generateBucket() -> [ TI.Iterator.Element ] {
    if hitEOF { return [] }
    
    var bucket = Array<TO.WriteType>()
    bucket.reserveCapacity(batchSize)
    
    for _ in 0..<batchSize {
      if let element = src.next() {
        bucket.append(element)
      }
      else {
        hitEOF = true
      }
    }
    return bucket
  }
  
  
  // MARK: - Error handling and such
  
  final func onTargetError(error: ErrorProtocol) {
    print("C: ERROR: \(error)")  // TODO
    xsys.exit(42)
    // TODO: self.exitIfDone()
  }
  
  final func onFinish() {
    // print("\nC hit ********** FINISHED ***********.")
    // TODO: we are done, what now?
    hitEOF          = true
    didStreamFinish = true
  }
}

#endif // Swift3
