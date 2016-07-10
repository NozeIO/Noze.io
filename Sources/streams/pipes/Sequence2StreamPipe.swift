//
//  Sequence2StreamPipe.swift
//  Noze.io
//
//  Created by Helge Heß on 5/1/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if swift(>=3.0) // #swift3-fd #swift3-1st-arg
#else
import xsys
import core

/// Pipe operator for streams, neat :-)
///
/// Like so:
///
///   [ 'a', 'a', 'a' ] | zip | encrypt | fs
///
public func |<TI: SequenceType, TO: GWritableStreamType
              where TI.Generator.Element == TO.WriteType>
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
public extension SequenceType {
  // TODO: We could support an async mode for blocking Sequences similar to
  //       the GeneratorSource.
  
  public func pipe<TO: GWritableStreamType
                   where Self.Generator.Element == TO.WriteType>
                  (outStream: TO, batchSize: Int = 10, endOnFinish: Bool = true)
              -> TO
  {
    let state = SequencePipeState(self, outStream,
                                  batchSize   : batchSize,
                                  endOnFinish : endOnFinish)
    
    outStream.onError  { error in state.onTargetError(error) }
    outStream.onFinish { state.onFinish() }
    
    // we are immediately readable ;-) Named like that for consistency
    state.onPipeSourceReadable()
    
    return outStream
  }
}

private class SequencePipeState<TI: SequenceType, TO: GWritableStreamType
                                where TI.Generator.Element == TO.WriteType>
{
  // TBD: should TI be bound to just a generator?
  
  let batchSize       : Int
    // TODO: this is a little stupid, we need a protocol to figure out how
    //       space is available in the WriteableStream
  
  var src             : TI.Generator
  let dest            : TO
  var hitEOF          = false
  var didStreamFinish = false
  let endOnFinish     : Bool
  
  init(_ src: TI, _ dest: TO, batchSize: Int, endOnFinish: Bool) {
    self.batchSize   = batchSize
    self.endOnFinish = endOnFinish
    self.src         = src.generate()
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
          
          dest.onceDrain {
            nextTick { // TBD
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
  
  final func generateBucket() -> [ TI.Generator.Element ] {
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

#endif // Swift 2.2
