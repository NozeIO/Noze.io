//
//  AsyncWrapper.swift
//  Noze.io
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
    
    module.Q.async {
      
      let result = f(arg)
      
      core.Q.async {
        cb(result)
        core.module.release()
      }
    }
  }

  func evalAsync<ArgT>(f: (ArgT) throws -> Void, _ arg: ArgT,
                       _ cb: ( ErrorProtocol? ) -> Void)
  {
    core.module.retain()
    
    module.Q.async {
      let returnError : ErrorProtocol?
      
      do {
        try f(arg)
        returnError = nil
      }
      catch let error {
        returnError = error
      }
      
      core.Q.async {
        cb(returnError)
        core.module.release()
      }
    }
  }
  
  func evalAsync<ArgT, RT>(f: (ArgT) throws -> RT,
                           _ arg: ArgT,
                           _ cb: ( ErrorProtocol?, RT? ) -> Void)
  {
    core.module.retain()
    
    module.Q.async {
      let returnError : ErrorProtocol?
      let result      : RT?
      
      do {
        result = try f(arg)
        returnError = nil
      }
      catch let error {
        returnError = error
        result      = nil
      }
      
      core.Q.async {
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
                       _ cb: ( ErrorProtocol? ) -> Void)
  {
    evalAsync(f: f, arg, cb)
  }
  func evalAsync<ArgT, RT>(_ f: (ArgT) throws -> RT,
                           _ arg: ArgT,
                           _ cb: ( ErrorProtocol?, RT? ) -> Void)
  {
    evalAsync(f: f, arg, cb)
  }
#endif
}
