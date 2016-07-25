//
//  Duplex.swift
//  Noze.io
//
//  Created by Helge Hess on 11/04/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import core

/// A DuplexStream which derives its actual implementation from a
/// 'source' and a 'target' aka a `GReadableSourceType` and
/// `GWritableTargetType`.
///
public class Duplex<TSource: GReadableSourceType, TTarget: GWritableTargetType>
             : DuplexStream<TSource.SourceElement, TTarget.TargetElement>
{
  typealias ReadType  = TSource.SourceElement
  typealias WriteType = TTarget.TargetElement
  public var source : TSource
  public var target : TTarget

  // MARK: - Init
  
  public init(source        : TSource,
              target        : TTarget,
              queue         : DispatchQueueType = core.Q,
              enableLogger  : Bool = false)
  {
    self.source = source
    self.target = target
    
    // TODO: different HWMs
    super.init(readHWM  : TSource.defaultHighWaterMark,
               writeHWM : TTarget.defaultHighWaterMark,
               queue    : queue, enableLogger: enableLogger)
  }


  // MARK: - extension points for subclass
  // TODO: those are lame copies from Readable/Writable
  
  public override func _primaryRead(count howMuchToRead: Int) {
    let log = self.log // avoid capturing self for log
    log.enter(); defer { log.leave() }
    
    source.next(queue: Q, count: howMuchToRead) { error, bucket in
      log.enter("\(#function) - generator CB"); defer { log.leave() }
      if log.enabled {
        if let bucket = bucket { log.debug("got bucket: \(bucket)") }
        else { log.debug("got EOF.") }
      }
      
      if let error = error {
        self.catched(error: error)
        return
      }
      
      // Push the bucket (or EOF) we got from the source into our interal
      // buffer. This will trigger a Readable event.
      self.push(bucket: bucket)
      
      // TBD: in here or in read? or in both?
      self.nextTick {
        self.maybeGenerateMore()
      }
    }
  }
  
  public override func _primaryPause() {
    source.pause()
  }

  public override func _primaryWriteV(buckets c : [ [ WriteType ] ],
                                      done      : ( ErrorProtocol?, Int ) -> Void)
  {
    log.enter(); defer { log.leave() }
    target.writev(queue: Q, chunks: c, yield: done)
  }

  public override var _primaryCanEnd : Bool { return target.canEnd }


  // MARK: - Closing
  
  override public func closeReadStream() {
    source.closeSource()
    super.closeReadStream()
  }
  override public func closeWriteStream() {
    target.closeTarget()
    super.closeWriteStream()
  }
}
