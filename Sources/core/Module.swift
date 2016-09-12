//
//  Module.swift
//  Noze.io
//
//  Created by Helge Heß on 4/3/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

@_exported import Dispatch

public let module = NozeCore()


// MARK: - Queue

/// All of Noze depends on running on a serialized queue. This usually is the 
/// main queue, but it can be set to any arbitrary serialized queue.
public var Q = DispatchQueue.main
  
/// Enqueue the given closure for later dispatch in the Q.
public func nextTick(handler cb: @escaping () -> Void) {
  // Node says that tick() is special in that it runs before IO events. Is the
  // same true for GCD?
  module.retain() // TBD: expensive? Do in here?
  Q.async {
    cb()
    module.release()
  }
}

/// Execute the given closure after the amount of milliseconds given.
public func setTimeout(_ milliseconds: Int, _ cb: @escaping () -> Void) {
  // TBD: what is the proper place for this?
  // TODO: in JS this also allows for a set of arguments to be passed to the
  //       callback (but who uses this facility?)
  let s = DispatchTime.now() + DispatchTimeInterval.milliseconds(milliseconds)
  
  module.retain() // TBD: expensive? Do in here?
  Q.asyncAfter(deadline: s) {
    cb()
    module.release()
  }
}
