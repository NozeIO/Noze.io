//
//  StreamPromise.swift
//  NozeIO
//
//  Created by Helge Heß on 5/4/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import core

// The plan was to do: GReadableStreamType: LiarType and thereby mixin then etc,
// but you can't do that with generic protocols like GReadableStreamType. Sigh.

// TODO: This is a little wasteful as we create a new for each promise call, but
//       it is all Swift's fault for not providing storage in 'categories' ;->

public extension GReadableStreamType {
  
  var promise : Promise<Void> {
    return Promise<Void> { ok, fail in
      _ = self.onceEnd   { ok() }
      _ = self.onceError { error in fail(error) }
    }
  }
  
  public func then<U>(cb: () -> U) -> Promise<U> {
    return promise.then(run: cb)
  }
  public func then<U>(cb: () -> Promise<U>) -> Promise<U> {
    return promise.then(run: cb)
  }
  public func error(cb: (ErrorType) -> Void) {
    promise.error(run: cb)
  }
  
}

public extension GWritableStreamType {
  
  var promise : Promise<Void> {
    return Promise<Void> { ok, fail in
      _ = self.onceFinish { ok() }
      _ = self.onceError  { error in fail(error) }
    }
  }
  var unpipePromise : Promise<Void> {
    return Promise<Void> { ok, fail in
      _ = self.onceUnpipe { _ in ok() }
      _ = self.onceError  { error in fail(error) }
    }
  }
  
  public func then<U>(cb: () -> U) -> Promise<U> {
    return promise.then(run: cb)
  }
  public func then<U>(cb: () -> Promise<U>) -> Promise<U> {
    return promise.then(run: cb)
  }
  public func error(cb: (ErrorType) -> Void) {
    promise.error(run: cb)
  }
  
  public func then<S: GWritableStreamType>(cb: () -> S) -> Promise<Void> {
    return promise.then { () -> Promise<Void> in
                          let stream = cb(); return stream.promise }
  }
}
