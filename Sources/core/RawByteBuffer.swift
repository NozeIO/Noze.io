//
//  RawByteBuffer.swift
//  Noze.io
//
//  Created by Helge Heß on 6/20/14.
//  Copyright © 2014 ZeeZide GmbH. All rights reserved.
//

import xsys

public class RawByteBuffer {
  
#if swift(>=3.0) // #swift3-ptr
  public var buffer   : UnsafeMutablePointer<UInt8>?
#else
  public var buffer   : UnsafeMutablePointer<UInt8>
#endif
  public var capacity : Int
  public var count    : Int
  let extra = 2
  
  public init(capacity: Int) {
    count         = 0
    self.capacity = capacity
    
    if (self.capacity > 0) {
#if swift(>=3.0) // #swift3-ptr
      buffer = UnsafeMutablePointer<UInt8>(
                 allocatingCapacity: self.capacity + extra)
#else
      buffer = UnsafeMutablePointer<UInt8>.alloc(self.capacity + extra)
#endif
    }
    else {
      buffer = nil
    }
  }
  deinit {
    if capacity > 0 {
#if swift(>=3.0) // #swift3-ptr
      buffer?.deallocateCapacity(capacity + extra)
#else
      buffer.dealloc(capacity + extra)
#endif
    }
  }
  
  public func asByteArray() -> [UInt8] {
    guard count > 0 else { return [] }
    assert(self.buffer != nil, "size>0, but buffer is nil?")
    
    // having to assign a value is slow
#if swift(>=3.0) // #swift3-fd
    var a = [UInt8](repeating: 0, count: count)
#else
    var a = [UInt8](count: count, repeatedValue: 0)
#endif
    
#if os(Linux)
#if swift(>=3.0) // #swift3-ptr
    _ = memcpy(&a, self.buffer!, self.count)
#else
    memcpy(&a, self.buffer, self.count)
#endif
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
#if swift(>=3.0) // #swift3-ptr
    let newbuf  = UnsafeMutablePointer<UInt8>(
                    allocatingCapacity: newsize + extra)
    
    if (count > 0) {
      assert(self.buffer != nil, "size>0, but buffer is nil?")
#if os(Linux)
      _ = memcpy(newbuf, buffer!, count)
#else
      _ = memcpy(newbuf, buffer, count)
#endif
    }
    buffer?.deallocateCapacity(capacity + extra)
#else
    let newbuf  = UnsafeMutablePointer<UInt8>.alloc(newsize + extra)
    
    if (count > 0) {
      memcpy(newbuf, buffer, count)
    }
    buffer.dealloc(capacity + extra)
#endif

    buffer   = newbuf
    capacity = newsize
  }
  
  public func reset() {
    count = 0
  }
  
  public func addBytes(src: UnsafePointer<Void>, length: Int) {
    // debugPrint("add \(length) count: \(count) capacity: \(capacity)")
    guard length > 0 else {
      // This is fine, happens for empty bodies (like in OPTION requests)
      // debugPrint("NO LENGTH?")
      return
    }
#if swift(>=3.0) // #swift3-1st-arg #swift3-ptr
    ensureCapacity(newCapacity: count + length)
    let dest = buffer! + count
#else
    ensureCapacity(count + length)
    let dest = buffer + count
#endif
    
    _ = memcpy(UnsafeMutablePointer<Void>(dest), src, length)
    count += length
    // debugPrint("--- \(length) count: \(count) capacity: \(capacity)")
  }
  
  public func add(cs: UnsafePointer<CChar>, length: Int? = nil) {
    if let len = length {
      addBytes(cs, length: len)
    }
    else {
      addBytes(cs, length: Int(xsys.strlen(cs)))
    }
  }
  
  public func asString() -> String? {
    guard buffer != nil else { return nil }
    
#if swift(>=3.0) // #swift3-ptr #swift3-cstr
    let cptr = UnsafeMutablePointer<CChar>(buffer!)
    cptr[count] = 0 // null terminate, buffer is always bigger than it claims
    return String(cString: cptr)
#else
    let cptr = UnsafeMutablePointer<CChar>(buffer)
    cptr[count] = 0 // null terminate, buffer is always bigger than it claims
    return String.fromCString(cptr)
#endif
  }
}

#if swift(>=3.0) // #swift3-1st-arg

extension RawByteBuffer {
  public final func addBytes(_ src: UnsafePointer<Void>?, length: Int) {
    guard let nsrc = src else {
      assert(length == 0, "nil ptr, but length \(length)")
      return
    }
    addBytes(src: nsrc, length: length)
  }
  public final func add(_ cs: UnsafePointer<CChar>, length: Int? = nil) {
    add(cs: cs, length: length)
  }
}

#endif // Swift3
