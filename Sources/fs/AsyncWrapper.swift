//
//  AsyncWrapper.swift
//  NozeIO
//
//  Created by Helge Heß on 5/8/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import core

extension DispatchQueueType {
  // Move to core? Not sure about that.
  
  /// Evaluate the given function with the given argument on the queue. Once
  /// done, return the result value using the given callback on the main Q.
  ///
  /// This is useful for wrapping synchronous file APIs. Example:
  ///
  ///    public func readdir(path: String, cb: ( [ String ]? ) -> Void) {
  ///      module.Q.evalAsync(readdirSync, path, cb)
  ///    }
  ///
  func evalAsync<ArgT, RT>(f: (ArgT) -> RT, _ arg: ArgT, _ cb: ( RT ) -> Void) {
    core.module.retain()
    
    dispatch_async(module.Q) {
      
      let result = f(arg)
      
      dispatch_async(core.Q) {
        cb(result)
        core.module.release()
      }
    }
  }

  func evalAsync<ArgT>(f: (ArgT) throws -> Void, _ arg: ArgT,
                       _ cb: ( ErrorType? ) -> Void)
  {
    core.module.retain()
    
    dispatch_async(module.Q) {
      let returnError : ErrorType?
      
      do {
        try f(arg)
        returnError = nil
      }
      catch let error {
        returnError = error
      }
      
      dispatch_async(core.Q) {
        cb(returnError)
        core.module.release()
      }
    }
  }
  
  func evalAsync<ArgT, RT>(f: (ArgT) throws -> RT,
                           _ arg: ArgT,
                           _ cb: ( ErrorType?, RT? ) -> Void)
  {
    core.module.retain()
    
    dispatch_async(module.Q) {
      let returnError : ErrorType?
      let result      : RT?
      
      do {
        result = try f(arg)
        returnError = nil
      }
      catch let error {
        returnError = error
        result      = nil
      }
      
      dispatch_async(core.Q) {
        cb(returnError, result)
        core.module.release()
      }
    }
  }

#if swift(>=3.0) // #swift3-1st-arg
  func evalAsync<ArgT, RT>(_ f: (ArgT) -> RT, _ arg: ArgT, _ cb: ( RT ) -> Void) {
    evalAsync(f: f, arg, cb)
  }
  func evalAsync<ArgT>(_ f: (ArgT) throws -> Void, _ arg: ArgT,
                       _ cb: ( ErrorType? ) -> Void)
  {
    evalAsync(f: f, arg, cb)
  }
  func evalAsync<ArgT, RT>(_ f: (ArgT) throws -> RT,
                           _ arg: ArgT,
                           _ cb: ( ErrorType?, RT? ) -> Void)
  {
    evalAsync(f: f, arg, cb)
  }
#endif
}
