//
//  Promise.swift
//  NozeIO
//
//  Created by Helge Heß on 5/3/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

// http://www.comedix.de/lexikon/db/haus_das_verrueckte_macht.php
public class Promise<T> : LiarType {
  
  var state         : PromiseState<T>
  var stateListeners = Array<Handler>()
  
  public typealias Resolver = ( ( T ) -> Void, ( ErrorType ) -> Void ) -> Void
  typealias Handler = ( PromiseState<T> ) -> Void

  public init() {
    state = .Initial
  }
  
  public init(resolver: Resolver) {
    state = .Initial
    
    // run resolver
    resolver(
      { value in
        self.state = .Fulfilled(value)
        self.stateChanged()
      },
      { error in
        self.state = .Rejected(error)
        self.stateChanged()
      }
    )
  }
  
  public init(value: T) {
    state = .Fulfilled(value)
  }
  public init(error: ErrorType) {
    state = .Rejected(error)
  }
  
  
  // MARK: - Change State
  
  func stateChanged() {
    stateListeners.forEach {
      cb in cb(state)
    }
    stateListeners.removeAll()
  }
  
  func onStateChange(cb: Handler) {
    stateListeners.append(cb)
  }
  
  
  // MARK: - Event Handlers
  
  public var promise : Promise<T> { return self }
  
  public func then<U>(run cb: ( T ) -> Promise<U>) -> Promise<U> {
    // Essentially an AND between the gateway Promise to the success of `self`
    // and the new Promise returned by the callback.
    switch state {
      case .Fulfilled(let v):
        return cb(v) // immediately execute, return new Promise from block
      
      case .Rejected (let e):
        return Promise<U>(error: e) // already rejected, return error promise
      
      case .Initial:
        // Note: we capture `cb` and the returned promise
        let p = Promise<U> { ok, fail in
          // this is the gate to the source Promise. It calls the callback which
          // then returns a new promise.
          
          self.onStateChange { state in
            switch state {
              case .Fulfilled(let v): // means `self` got resolved, NOT the p
                let nestedPromise = cb(v)
                // TBD: not sure this is right
                nestedPromise.onStateChange { state in
                  switch state {
                    case .Fulfilled(let v): // the returned close also resolved
                      ok(v)
                    case .Rejected (let e):
                      fail(e)
                    default: assert(false, "cannot change to this state ...")
                  }
                }
              
              case .Rejected (let e):
                fail(e)
              default: assert(false, "cannot change to this state ...")
            }
          }
        }
        return p
    }
  }
  public func then<U>(run cb: ( T ) -> U) -> Promise<U> {
    switch state {
      case .Fulfilled(let v):
        let value = cb(v)               // immediately execute
        return Promise<U>(value: value) // return already resolved promise
      
      case .Rejected (let e):
        return Promise<U>(error: e)
      
      case .Initial:
        // Note: we capture `cb` and the returned promise
        let p = Promise<U> { ok, fail in
          self.onStateChange { state in
            switch state {
              case .Fulfilled(let v): ok(cb(v))
              case .Rejected (let e): fail(e)
              default: assert(false, "cannot change to this state ...")
            }
          }
        }
        return p
    }
  }
  
#if swift(>=3.0) // #swift3-func-arg-tuple
  // FIXME: Find a better way to do those. They haven't been necessary in
  //        Swift 2, but they are now. Maybe a bug in swiftc, maybe not.
  public func then(run cb: () -> Void) -> Void {
    switch state {
      case .Fulfilled:
        cb() // immediately execute
      
      case .Rejected (let e):
        print("Promise was lying: dropping error: \(e)")
      
      case .Initial:
        // Note: we capture `cb` and the returned promise
        self.onStateChange { state in
          switch state {
            case .Fulfilled: cb()
            case .Rejected (let e):
              print("Promise was lying: dropping error: \(e)")
            default: assert(false, "cannot change to this state ...")
          }
        }
    }
  }
  public func then<U>(run cb: ( T ) -> U) -> Void {
    switch state {
      case .Fulfilled(let v):
        _ = cb(v) // immediately execute
  
      case .Rejected (let e):
        print("Promise was lying: dropping error: \(e)")
  
      case .Initial:
        // Note: we capture `cb` and the returned promise
        self.onStateChange { state in
          switch state {
            case .Fulfilled(let v): _ = cb(v)
            case .Rejected (let e):
              print("Promise was lying: dropping error: \(e)")
            default: assert(false, "cannot change to this state ...")
          }
        }
    }
  }
#endif
  
  public func error(run cb: ( ErrorType ) -> Void) {
    // `catch` is used already in Swift
    switch state {
      case .Fulfilled:
        break // no error, nothing to do
      
      case .Rejected(let e): // error, execute closure
        cb(e)
      
      case .Initial:
        // Note: we capture `cb` and the returned promise
        self.onStateChange { state in
          switch state {
            case .Rejected (let e): cb(e)
            case .Fulfilled: break
            default: assert(false, "cannot change to this state ...")
          }
        }
    }
  }

}

enum PromiseState<T> {
  case Initial
  case Fulfilled(T)
  case Rejected(ErrorType)
}


// Cause I'm a liar http://tinyurl.com/psu9kqa

public protocol LiarType {
  
  associatedtype T
  
  var promise : Promise<T> { get }
  
  func then<U>(run cb: ( T ) -> Promise<U>) -> Promise<U>
  func then<U>(run cb: ( T ) -> U)          -> Promise<U>
  func error  (run cb: ( ErrorType ) -> Void)
  
}

/* makes it break, picked up in places which make it fail.
public extension LiarType { // default liars
  
  public func then<U>(cb: () -> U) -> Promise<U> {
    return promise.then(cb)
  }
  public func then<U>(cb: () -> Promise<U>) -> Promise<U> {
    return promise.then(cb)
  }
  public func error(cb: (ErrorType) -> Void) {
    promise.error(cb)
  }
  
}
*/
