//
//  EventListenerSet.swift
//  Noze.IO
//
//  Created by Helge Heß on 24/06/15.
//  Copyright © 2015 ZeeZide GmbH. All rights reserved.
//

import core

// TBD: support weak listeners (Note: weak var's on closures are unsupported?)

/// An array of event handlers `T` with some extra metadata.
///
public class EventListenerSet<T> {
  // TBD: Not sure whether we need all this complexity. The listeners in
  //      Readable/Writable are all Void except for onError, which is kinda
  //      single value.
  //      Also: do we really need multiple listeners? That mostly sounds useful
  //            for debugging queue state?
  // 2016-05-08: changed back to class from struct
  
  public typealias EventHandler = ( T ) -> Void
  
  var listeners      = [ ListenerEntry<T> ]()
  var queue          = [ T ]() // TBD: weak queue?
  let maxQueueLength : Int  // if 0, nothing is queued
  let coalesce       : Bool
  
  public var count   : Int  { return listeners.count   }
  public var isEmpty : Bool { return listeners.isEmpty }
  
  var hasOnce : Bool = false
  
  public init(queueLength: Int = 128, coalesce: Bool = false) {
    self.maxQueueLength = queueLength
    self.coalesce       = coalesce
  }

  public func removeAllListeners() {
    listeners.removeAll()
  }
  
  public func add(handler listener: @escaping EventHandler) {
    add(handler: listener, once: false)
  }
  public func add(handler listener: @escaping EventHandler, once: Bool) {
    listeners.append( ListenerEntry(cb: listener, once: once) )
    if once && !hasOnce { hasOnce = true }
    
    // Emit queued events. Note: this can stop, e.g. when a once listener got
    // added.
    while !queue.isEmpty && !listeners.isEmpty {
      // TODO: fixme, use a proper FIFO
      let value = queue.remove(at: 0)
      emit(value)
    }
  }
  
  func _queueValue(value v: T) {
    
    guard maxQueueLength > 0 else { return }
    
    if coalesce && !queue.isEmpty {
      if v is Void {
        return // coalesce void
      }
      
      // TODO: coalesce other values ..
    }
    
    guard queue.count < maxQueueLength else {
      debugPrint("EventQueue exceeded capacity " +
                 "(#\(queue.count) max #\(maxQueueLength)), " +
                 "dropping event: \(v) \(self)")
      assert(queue.count < maxQueueLength)
      return
    }
    
    queue.append(v)
  }
  
  public func emit(_ v: T) {
    if listeners.isEmpty {
      // have no listeners yet, queue event for later delivery
      _queueValue(value: v)
      return
    }
    
    if hasOnce {
      var listenersCopy = listeners
      
      for i in listenersCopy.indices {
        let entry = listenersCopy[i]
        
        if entry.isEmitting > 0 {
          if entry.once {
            assert(entry.isEmitting == 0,
                   "once event handler called again while emitting")
          }
          else {
            // assert(!entry.isEmitting, "recursion in event handler?")
            print("WARN: recursive event handler!")
            nextTick { entry.cb(v) }
          }
        }
        else {
          listenersCopy[i].isEmitting += 1
          entry.cb(v)
          listenersCopy[i].isEmitting -= 1
        }
        
        if entry.once {
          // TODO: Sometimes this returns idx==0, but the array is actually
          //       empty. No idea why, Swift bug? I don't think this can be
          //       due to threading and we have no async here either?!
          //       Note: sometimes hitting that on the MacBook (aka slow).
          if let idx = listeners.index(where: { $0 === entry }) {
            if idx != 0 || !listeners.isEmpty {
              // assuming a bug in Swift returning 0 for empty arrays
              listeners.remove(at: idx)
            }
            else {
              print("WARN: got idx \(idx) but listeners are empty?!" +
                    "      array: \(listeners)" +
                    "      els:   \(self)")
            }
          }
          else {
            print("WARN: listener race, already removed once-entry.")
          }
        }
      }
    }
    else {
      let listenersCopy = listeners
      for i in 0..<listenersCopy.count {
        let entry = listenersCopy[i]
        
        assert(entry.isEmitting == 0, "recursion in event handler?")
        guard entry.isEmitting == 0 else { continue }
        
        listenersCopy[i].isEmitting += 1
        entry.cb(v)
        listenersCopy[i].isEmitting -= 1
      }
    }
  }
  
  
  // TODO: cannot compare references to closures? Need a token?
  /*
  func removeListener(first: Bool = true, listener: EventHandler) {
    guard !listeners.isEmpty else { return }

    // TODO: tried listeners.indexOf() w/o success
    for i in 0..<listeners.count {
      let entry = listeners[i]
      if entry.cb === listener {
        listeners.remove(at: i)
        if first { break }
      }
    }
    return
  }
  */
}

class ListenerEntry<T> { // class to support isEmitting
  
  let cb         : ( T ) -> Void
  let once       : Bool
  var isEmitting = 0 // counter
  
  init(cb: @escaping ( T ) -> Void, once : Bool = false) {
    self.cb         = cb
    self.once       = once
  }
}


// MARK: - Description

extension EventListenerSet: CustomStringConvertible {
  
  public var description : String {
    var s = "<EventListenerSet:"
    
    let listenerCount = listeners.count
    let queueCount    = queue.count
    
    if listenerCount == 0 && queueCount == 0 {
      s += " empty"
    }
    else if listenerCount == 0 && queueCount > 0 {
      s += " queueing(#\(queueCount))"
    }
    else if listenerCount > 0 && queueCount == 0 {
      s += " listening(#\(listenerCount))"
    }
    else {
      s += " queued-events=#\(queueCount) listeners=#\(listenerCount)"
    }
    
    s += ">"
    return s
  }
  
}
