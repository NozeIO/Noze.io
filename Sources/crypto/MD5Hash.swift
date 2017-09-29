//
//  MD5Stream.swift
//  NozeSandbox
//
//  Created by Helge Heß on 9/15/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import core
import streams
import CryptoSwift

class MD5Hash: Hash {
  
  override public init(readHWM      : Int? = nil,
                       writeHWM     : Int? = nil,
                       queue        : DispatchQueue = core.Q,
                       enableLogger : Bool = false)
  {
    // Note: Yes, this doesn't do anything, but w/o it swiftc 0.3.0 crashes :-)
    super.init(readHWM: readHWM, writeHWM: writeHWM, queue: queue,
               enableLogger: enableLogger)
  }
  
  var hasher : MD5? = MD5()
  
  
  // MARK: - Update Mode
  
  override public func update(_ chunk: [ UInt8 ]) {
    do {
      _ = try hasher?.update(withBytes: chunk)
    }
    catch {
      fatalError("MD5 cannot fail?!")
    }
  }
  
  override public func digest(_ digest: String) -> String? {
    guard digest == "hex"     else { return nil }
    guard let hasher = hasher else { return nil }
    
    do {
      let result = try hasher.update(withBytes: [], isLast: true)
      return result.hexString
    }
    catch {
      fatalError("MD5 cannot fail?!")
    }
  }
  
  
  // MARK: - Transform Stream
  
  override public func _transform(bucket: [ UInt8 ],
                                  done: @escaping
                                        ( Error?, [ [ UInt8 ] ]? ) -> Void)
  {
    guard let hasher = hasher else {
      // TODO: throw error
      done(nil /* error */, nil)
      return
    }
    
    do {
      #if swift(>=4.0)
        _ = try hasher.update(withBytes:
                                bucket[bucket.startIndex..<bucket.endIndex])
      #else
        _ = try hasher.update(withBytes: bucket)
      #endif
      done(nil, nil) // we do not produce anything, only on end
    }
    catch let error {
      done(error, nil)
      return
    }
  }
  
  override public func _flush(done: @escaping
                                    ( Error?, [ [ UInt8 ] ]? ) -> Void)
  {
    guard let hasher = hasher else {
      // TODO: throw error
      done(nil /* error */, nil)
      return
    }
    
    do {
      let result = try hasher.update(withBytes: [], isLast: true)
      done(nil, [result])
    }
    catch let error {
      done(error, nil)
    }
    self.hasher = nil
  }
}
