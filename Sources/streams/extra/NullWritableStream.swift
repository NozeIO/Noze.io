//
//  NullWritableStream
//  Noze.io
//
//  Created by Helge Hess on 28/04/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import core

/// Marker interface for streams which discard everything.
public protocol NullStreamType {
}

public class NullWritableStream<WriteType>
             : WritableStream<WriteType>, NullStreamType
{
  
  public init() {
    super.init(highWaterMark: 0, queue: core.Q, enableLogger: false)
  }
  
  // MARK: - extension points for subclass

  override func _primaryWriteV(buckets c: Brigade, done: PrimaryWriteDoneCB) {
    log.enter(); defer { log.leave() }
    let brigadeCount = c.reduce(0 /* start value */) { $0 + $1.count }
    done(nil, brigadeCount)
  }
}

public typealias NullByteWritableStream = NullWritableStream<UInt8>
