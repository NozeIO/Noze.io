//
//  Hash.swift
//  NozeSandbox
//
//  Created by Helge Heß on 9/15/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import streams

public protocol HashStreamType : class, WritableByteStreamType {
  // https://nodejs.org/api/crypto.html#crypto_class_hash
  
  // MARK: - Update Mode
  
  func update(_ chunk: [ UInt8 ])
  func digest(_ digest: String) -> String?
}

public protocol GHashStreamType: HashStreamType, GTransformStreamType {
  // This protocol cannot be used as a return type, hence below the 'Hash'
  // class ...
}

public class Hash: TransformStream<UInt8, [ UInt8 ]>, GHashStreamType {
  // Abstract class, solely required to workaround the generic protocol issue
  
  public func update(_ chunk: [ UInt8 ]) {
    fatalError("override in subclass: \(#function)")
  }
  public func digest(_ digest: String) -> String? {
    fatalError("override in subclass: \(#function)")
  }
}
