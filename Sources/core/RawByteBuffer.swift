//
//  RawByteBuffer.swift
//  Noze.io
//
//  Created by Helge Heß on 6/20/14.
//  Copyright © 2014 ZeeZide GmbH. All rights reserved.
//

import xsys

public class RawByteBuffer {
  
  public var buffer   : UnsafeMutablePointer<UInt8>?
  public var capacity : Int
  public var count    : Int
  let extra = 2
  
  public init(capacity: Int) {
    count         = 0
    self.capacity = capacity
    
    if (self.capacity > 0) {
      buffer = UnsafeMutablePointer<UInt8>
                 .allocate(capacity: self.capacity + extra)
    }
    else {
      buffer = nil
    }
  }
  deinit {
    if capacity > 0 {
      #if swift(>=4.1)
        buffer?.deallocate()
      #else
        buffer?.deallocate(capacity: capacity + extra)
      #endif
    }
  }
  
  public func asByteArray() -> [UInt8] {
    guard count > 0 else { return [] }
    assert(self.buffer != nil, "size>0, but buffer is nil?")
    
    // having to assign a value is slow
    var a = [UInt8](repeating: 0, count: count)
    
#if os(Linux)
    _ = memcpy(&a, self.buffer!, self.count)
#else
    _ = memcpy(&a, self.buffer, self.count)
      // Note: In the Darwin pkg there is also:
      //   memcpy(UnsafePointer<Void>(a), buffer, UInt(self.count))
      // func memcpy(_: UnsafePointer<()>, _: ConstUnsafePointer<()>, _: UInt) -> UnsafePointer<()>
#endif
    return a
  }
  
  public func ensureCapacity(newCapacity: Int) {
    guard newCapacity > capacity else { return }
    
    let newsize = newCapacity + 1024
    let newbuf  = UnsafeMutablePointer<UInt8>
                    .allocate(capacity: newsize + extra)
    
    if (count > 0) {
      assert(self.buffer != nil, "size>0, but buffer is nil?")
#if os(Linux)
      _ = memcpy(newbuf, buffer!, count)
#else
      _ = memcpy(newbuf, buffer, count)
#endif
    }
    #if swift(>=4.1)
      buffer?.deallocate()
    #else
      buffer?.deallocate(capacity: capacity + extra)
    #endif

    buffer   = newbuf
    capacity = newsize
  }
  
  public func reset() {
    count = 0
  }
  
  public func addBytes(_ src: UnsafeRawPointer, length: Int) {
    // debugPrint("add \(length) count: \(count) capacity: \(capacity)")
    guard length > 0 else {
      // This is fine, happens for empty bodies (like in OPTION requests)
      // debugPrint("NO LENGTH?")
      return
    }
    ensureCapacity(newCapacity: count + length)
    let dest = buffer! + count
    
    _ = memcpy(UnsafeMutableRawPointer(dest), src, length)
    count += length
    // debugPrint("--- \(length) count: \(count) capacity: \(capacity)")
  }
  
  public func add(_ cs: UnsafePointer<CChar>, length: Int? = nil) {
    if let len = length {
      addBytes(cs, length: len)
    }
    else {
      addBytes(cs, length: Int(xsys.strlen(cs)))
    }
  }
  
  public func asString() -> String? {
    guard buffer != nil else { return nil }
    
    guard let buffer = buffer else { return nil }
    buffer[count] = 0 // null terminate, buffer is always bigger than it claims
    return String(cString: buffer)
  }
}
