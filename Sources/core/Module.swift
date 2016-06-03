//
//  Module.swift
//  NozeIO
//
//  Created by Helge Heß on 4/3/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

@_exported import Dispatch

public let module = NozeCore()


// MARK: - Queue

/// All of Noze depends on running on a serialized queue. This usually is the 
/// main queue, but it can be set to any arbitrary serialized queue.
#if swift(>=3.0) // #swift3-gcd
public var Q = dispatch_get_main_queue()! // can't fail, right?
#else
public var Q = dispatch_get_main_queue()
#endif


/// Enqueue the given closure for later dispatch in the Q.
public func nextTick(handler cb: () -> Void) {
  // Node says that tick() is special in that it runs before IO events. Is the
  // same true for GCD?
  module.retain() // TBD: expensive? Do in here?
  dispatch_async(Q) {
    cb()
    module.release()
  }
}

/// Execute the given closure after the amount of milliseconds given.
public func setTimeout(milliseconds: Int, _ cb: () -> Void) {
  // TBD: what is the proper place for this?
  // TODO: in JS this also allows for a set of arguments to be passed to the
  //       callback (but who uses this facility?)
  let nsecs = Int64(milliseconds) * Int64(NSEC_PER_MSEC)
  let s     = dispatch_time(DISPATCH_TIME_NOW, nsecs)
  
  module.retain() // TBD: expensive? Do in here?
  dispatch_after(s, Q) {
    cb()
    module.release()
  }
}

#if swift(>=3.0) // #swift3-1st-kwarg
public func setTimeout(_ milliseconds: Int, _ cb: () -> Void) {
  setTimeout(milliseconds: milliseconds, cb)
}
#endif
