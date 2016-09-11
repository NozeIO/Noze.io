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
  func evalAsync<ArgT, RT>(_ f  : @escaping (ArgT) -> RT, _ arg: ArgT,
                           _ cb : @escaping ( RT ) -> Void)
  {
    core.module.retain()
    
    module.Q.async {
      
      let result = f(arg)
      
      core.Q.async {
        cb(result)
        core.module.release()
      }
    }
  }

  func evalAsync<ArgT>(_ f  : @escaping (ArgT) throws -> Void, _ arg: ArgT,
                       _ cb : @escaping ( Error? ) -> Void)
  {
    core.module.retain()
    
    module.Q.async {
      let returnError : Error?
      
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
  
  func evalAsync<ArgT, RT>(_ f   : @escaping ( ArgT ) throws -> RT,
                           _ arg : ArgT,
                           _ cb  : @escaping ( Error?, RT? ) -> Void)
  {
    core.module.retain()
    
    module.Q.async {
      let returnError : Error?
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

}
