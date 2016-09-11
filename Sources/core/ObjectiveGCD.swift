//
//  ObjectiveGCD.swift
//  Noze.io
//
//  Created by Helge Heß on 04/07/2016.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

// NOTE: 2016-07-04: This is just a temporary measure. Presumably when Swift 3
//       is released later 2016, both Linux and OSX will completely switch to
//       the objectified GCD Swift API.
//       Until then Swift 2.2/2.3 is the stable Swift release and needs to be
//       supported to avoid continious breakage due to Swift 3 changes.
//       Hence this ultimate uglyness.
//
// This is just a very simple compat layer which uses a lot of typealiases and
// wrapper funcs instead of the 'real' thing of Apple which uses
// RawRepresentable.
//
// Issues:
// - everything with init() doesn't work well in extensions.
//   - hence: use old-style methods for construction

import Dispatch
#if os(Linux)
import func Glibc.memcmp
import struct Glibc.off_t
#endif

// ==================== this is the new-version API ====================
// wrap the new-style API
  
public typealias dispatch_queue_t       = DispatchQueue
  // this is not quite right, dispatch_queue_t still exists!

public typealias DispatchQueueType      = DispatchQueue
public typealias DispatchTimeType       = DispatchTime
public typealias DispatchIOType         = DispatchIO
public typealias DispatchDataType       = DispatchData
public typealias DispatchSourceType     = DispatchSourceProtocol

public func dispatch_main() {
  dispatchMain()
}

public func dispatch_get_main_queue() -> dispatch_queue_t {
  return DispatchQueue.main
}

public func dispatch_after(_ t: DispatchTimeType, _ q: DispatchQueueType,
                           _ block: @escaping () ->())
{
  q.asyncAfter(deadline: t, execute: block)
}

public func xsys_dispatch_time(_ base : DispatchTime, _ offset : Int64)
     -> DispatchTime
{
  return base + DispatchTimeInterval.nanoseconds(Int(offset))
}

public var DISPATCH_TIME_NOW : DispatchTimeType { return DispatchTime.now() }

public let DISPATCH_QUEUE_CONCURRENT = DispatchQueue.Attributes.concurrent
public func dispatch_queue_create(_ label: String,
                                  _ attrs: DispatchQueue.Attributes)
            -> DispatchQueue
{
  return DispatchQueue(label: label, attributes: attrs)
}

public func xsys_get_default_global_queue() -> DispatchQueueType {
  return DispatchQueue.global()
}

public let  xsys_DISPATCH_IO_STREAM = DispatchIO.StreamType.stream
public let  xsys_DISPATCH_IO_RANDOM = DispatchIO.StreamType.random
public func dispatch_io_create          (_ type  : DispatchIO.StreamType,
                                         _ fileDescriptor: Int32,
                                         _ queue : DispatchQueue,
                                         _ cleanupHandler:
                                             @escaping (_ error: Int32)->Void)
            -> DispatchIO
{
  return DispatchIO(type: type, fileDescriptor: fileDescriptor, queue: queue,
                    cleanupHandler: cleanupHandler)
}                                         
public func dispatch_io_create_with_path(_ type  : DispatchIO.StreamType,
                                         _ path  : UnsafePointer<Int8>,
                                         _ oflag : Int32,
                                         _ mode  : mode_t,
                                         _ queue : DispatchQueue,
                                         _ cleanupHandler:
                                             @escaping (_ error: Int32)->Void)
            -> DispatchIO
{
  return DispatchIO(type: type, path: path, oflag: oflag, mode: mode,
                    queue: queue, cleanupHandler: cleanupHandler)
}

public let DISPATCH_DATA_DESTRUCTOR_DEFAULT : (@convention(block) () -> Void)? = nil

public func dispatch_data_create(_ buffer: UnsafeRawPointer, _ size: Int,
                                 _ queue: DispatchQueueType? = nil,
                                 _ destructor: (@convention(block) () -> Void)? = nil)
            -> DispatchDataType
{
  let tptr = buffer.assumingMemoryBound(to: UInt8.self)
  let bptr = UnsafeBufferPointer(start: tptr, count: size)
  if destructor == nil {
    return DispatchData(bytesNoCopy: bptr)
  }
  else {
    let dealloc : DispatchData.Deallocator = .custom(queue, destructor!)
    return DispatchData(bytesNoCopy: bptr, deallocator: dealloc)
  }
}
public func dispatch_data_create_concat(_ data1: DispatchDataType,
                                        _ data2: DispatchDataType)
            -> DispatchDataType
{
  var combined = data1
  combined.append(data2)
  return combined
}

