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
// - this doesn't (always?) fly?:
//       #if !swift(>=3.0) || !(os(OSX) || os(iOS) || os(watchOS) || os(tvOS))
//   - hence: dupe everything :-/
// - everything with init() doesn't work well in extensions.
//   - hence: use old-style methods for construction

import Dispatch
#if os(Linux)
import func Glibc.memcmp
import struct Glibc.off_t
#endif

#if swift(>=3.0)
#if (os(OSX) || os(iOS) || os(watchOS) || os(tvOS)) // #swift3-new-gcd
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

#else // Swift 3 w/o ObjGCD
// ==================== this is the old-version API COPY 1 ====================
public typealias DispatchQueueType       = dispatch_queue_t
public typealias DispatchQueueAttributes = dispatch_queue_attr_t
public typealias DispatchTimeType        = dispatch_time_t
public typealias DispatchSourceType      = dispatch_source_t
public typealias DispatchIOType          = dispatch_io_t
public typealias DispatchDataType        = dispatch_data_t
#if os(Linux)
// the version we use doesn't have this.
#else
public typealias DispatchQoS             = dispatch_qos_class_t
#endif
public let       xsys_dispatch_time      = dispatch_time

public let       xsys_DISPATCH_IO_STREAM = DISPATCH_IO_STREAM
public let       xsys_DISPATCH_IO_RANDOM = DISPATCH_IO_RANDOM

public func dispatchMain() {
  dispatch_main()
}

public extension DispatchQueueType {
  
  public func async(execute block: dispatch_block_t) {
    dispatch_async(self, block)
  }
  
  public func after(when t: DispatchTimeType, execute block: dispatch_block_t) {
    dispatch_after(t, self, block)
  }
}

public extension DispatchQueueAttributes {
  
  public static var concurrent : DispatchQueueAttributes {
    return DISPATCH_QUEUE_CONCURRENT
  }
  public static var serial     : DispatchQueueAttributes {
    return DISPATCH_QUEUE_SERIAL
  }

}
  
public extension DispatchTimeType {
  
  public static func now() -> DispatchTimeType {
    return DISPATCH_TIME_NOW
  }
  
}

public func xsys_get_default_global_queue() -> DispatchQueueType {
#if os(Linux)
  return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
#else
  return dispatch_get_global_queue(
                       QOS_CLASS_DEFAULT, UInt(DISPATCH_QUEUE_PRIORITY_DEFAULT))
#endif
}
  
public extension DispatchSourceType {
  
  public var data : UInt { return dispatch_source_get_data(self) }
  
  public func setEventHandler(handler: () -> Void) {
    dispatch_source_set_event_handler(self, handler)
  }
  public func setCancelHandler(handler: () -> Void) {
    dispatch_source_set_cancel_handler(self, handler)
  }

  public func resume() {
#if os(Linux)
      dispatch_resume(unsafeBitCast(self, to: dispatch_object_t.self))
#else
      dispatch_resume(self!)
#endif
  }
  public func suspend() {
#if os(Linux)
      dispatch_suspend(unsafeBitCast(self, to: dispatch_object_t.self))
#else
      dispatch_suspend(self!)
#endif
  }
  public func cancel() {
    dispatch_source_cancel(self)
  }
}

public struct XSysDispatchIOCloseFlags: OptionSet, RawRepresentable {
  public let rawValue: UInt
  public init(rawValue: UInt) { self.rawValue = rawValue }
  public static let stop = XSysDispatchIOCloseFlags(rawValue: DISPATCH_IO_STOP)
}

public extension DispatchIOType {
  
  public var fileDescriptor : Int32 {
    return dispatch_io_get_descriptor(self)
  }

  public func setLimit(lowWater value: Int) {
    dispatch_io_set_low_water(self, value)
  }
  
  public func setLimit(highWater value: Int) {
    dispatch_io_set_high_water(self, value)
  }
  
  public func close(flags f: XSysDispatchIOCloseFlags = .stop) {
    dispatch_io_close(self, f.rawValue)
  }
  
  public func read(offset off: off_t, length: Int,
                   queue: DispatchQueueType,
                   ioHandler: (_ done: Bool, _ data: DispatchDataType?,
                               _ error: Int32) -> Void)
  {
    dispatch_io_read(self, off, length, queue, ioHandler)
  }
  public func write(offset off: off_t, data: DispatchDataType,
                    queue: DispatchQueueType,
                    ioHandler: (_ done: Bool, _ data: DispatchDataType?,
                                _ error: Int32) -> Void)
  {
    dispatch_io_write(self, off, data, queue, ioHandler)
  }
}

public let DISPATCH_DATA_DESTRUCTOR_DEFAULT : dispatch_block_t! = nil

extension DispatchDataType {
  
  public var count: Int {
    return dispatch_data_get_size(self)
  }
  
  public var isEmpty: Bool {
#if os(Linux)
    // not strideof in this case, right?
    var mdata1 = self, mdata2 = dispatch_data_empty
    // TBD: just cast to a pointer?
    return memcmp(&mdata1, &mdata2, sizeof(dispatch_data_t.self)) == 0
#else // MacOS
    return self === dispatch_data_empty || self.count == 0
#endif
  }
  
  
  public func enumerateBytes(block b: (_ buffer    : UnsafeBufferPointer<UInt8>,
                                       _ byteIndex : Int,
                                       _ stop      : inout Bool) -> Void)
  {
    //public typealias dispatch_data_applier_t = (dispatch_data_t, Int, UnsafePointer<Void>, Int) -> Bool
    _ = dispatch_data_apply(self) { subdata, offset, ptr, len in
      let tptr = UnsafePointer<UInt8>(ptr) // cast
      let bptr = UnsafeBufferPointer<UInt8>(start: tptr, count: len)
      
      var shouldStop = false
      
      b(buffer: bptr, byteIndex: offset, stop: &shouldStop)
      
      return !shouldStop
    }
  }
}

#endif
#else // #swift3-new-gcd (Swift 2.2 section)
// ==================== this is the old-version API COPY 2 ====================
public typealias DispatchQueueType       = dispatch_queue_t
public typealias DispatchQueueAttributes = dispatch_queue_attr_t
public typealias DispatchTimeType        = dispatch_time_t
public typealias DispatchSourceType      = dispatch_source_t
public typealias DispatchIOType          = dispatch_io_t
public typealias DispatchDataType        = dispatch_data_t
public typealias DispatchQoS             = dispatch_qos_class_t
public let       xsys_dispatch_time      = dispatch_time

public let       xsys_DISPATCH_IO_STREAM = DISPATCH_IO_STREAM
public let       xsys_DISPATCH_IO_RANDOM = DISPATCH_IO_RANDOM

public func dispatchMain() {
  dispatch_main()
}

public extension DispatchQueueType {
  
  public func async(execute block: dispatch_block_t) {
    dispatch_async(self, block)
  }
  
  public func after(when t: DispatchTimeType, execute block: dispatch_block_t) {
    dispatch_after(t, self, block)
  }
}

public extension DispatchQueueAttributes {
  
  public static var concurrent : DispatchQueueAttributes {
    return DISPATCH_QUEUE_CONCURRENT
  }
  public static var serial     : DispatchQueueAttributes {
    return DISPATCH_QUEUE_SERIAL
  }

}
  
public extension DispatchTimeType {
  
  public static func now() -> DispatchTimeType {
    return DISPATCH_TIME_NOW
  }
  
}

public func xsys_get_default_global_queue() -> DispatchQueueType {
#if os(Linux)
  return dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)
#else
  return dispatch_get_global_queue(
                       QOS_CLASS_DEFAULT, UInt(DISPATCH_QUEUE_PRIORITY_DEFAULT))
#endif
}
  
public extension DispatchSourceType {
  
  public var data : UInt { return dispatch_source_get_data(self) }

  public func setEventHandler(handler: () -> Void) {
    dispatch_source_set_event_handler(self, handler)
  }
  public func setCancelHandler(handler: () -> Void) {
    dispatch_source_set_cancel_handler(self, handler)
  }

  public func resume() {
#if os(Linux)
      dispatch_resume(unsafeBitCast(self, dispatch_object_t.self))
#else
      dispatch_resume(self)
#endif
  }
  public func suspend() {
#if os(Linux)
      dispatch_suspend(unsafeBitCast(self, dispatch_object_t.self))
#else
      dispatch_suspend(self)
#endif
  }
  public func cancel() {
    dispatch_source_cancel(self)
  }
}

public struct XSysDispatchIOCloseFlags: OptionSet, RawRepresentable {
  public let rawValue: UInt
  public init(rawValue: UInt) { self.rawValue = rawValue }
  public static let stop = XSysDispatchIOCloseFlags(rawValue: DISPATCH_IO_STOP)
}

public extension DispatchIOType {
  
  public var fileDescriptor : Int32 {
    return dispatch_io_get_descriptor(self)
  }

  public func setLimit(lowWater value: Int) {
    dispatch_io_set_low_water(self, value)
  }
  
  public func setLimit(highWater value: Int) {
    dispatch_io_set_high_water(self, value)
  }

  public func close(flags f: XSysDispatchIOCloseFlags = .stop) {
    dispatch_io_close(self, f.rawValue)
  }
  
  public func read(offset off: off_t, length: Int,
                   queue: DispatchQueueType,
                   ioHandler: (done: Bool, data: DispatchDataType?, error: Int32) -> Void)
  {
    dispatch_io_read(self, off, length, queue, ioHandler)
  }
  public func write(offset off: off_t, data: DispatchDataType,
                    queue: DispatchQueueType,
                    ioHandler: (done: Bool, data: DispatchDataType?, error: Int32) -> Void)
  {
    dispatch_io_write(self, off, data, queue, ioHandler)
  }
}

public let DISPATCH_DATA_DESTRUCTOR_DEFAULT : dispatch_block_t! = nil

extension DispatchDataType {
  
  public var count: Int {
#if os(Linux)
    return self != nil ? dispatch_data_get_size(self) : 0
#else
    return dispatch_data_get_size(self)
#endif
  }
  
  public var isEmpty: Bool {
#if os(Linux)
    guard self != nil else { return true }
#endif
#if os(Linux)
    // not strideof in this case, right?
    var mdata1 = data, mdata2 = dispatch_data_empty
    // TBD: just cast to a pointer?
    return memcmp(&mdata1, &mdata2, sizeof(dispatch_data_t.self)) == 0
#else // MacOS
    return self === dispatch_data_empty || self.count == 0
#endif
  }
  
  public func enumerateBytes(block b: (buffer    : UnsafeBufferPointer<UInt8>,
                                       byteIndex : Int,
                                       stop      : inout Bool) -> Void)
  {
    //public typealias dispatch_data_applier_t = (dispatch_data_t, Int, UnsafePointer<Void>, Int) -> Bool
    dispatch_data_apply(self) { subdata, offset, ptr, len in
      let tptr = UnsafePointer<UInt8>(ptr) // cast
      let bptr = UnsafeBufferPointer<UInt8>(start: tptr, count: len)
      
      var shouldStop = false
      
      b(buffer: bptr, byteIndex: offset, stop: &shouldStop)
      
      return !shouldStop
    }
  }
}

#endif // #swift3-new-gcd
