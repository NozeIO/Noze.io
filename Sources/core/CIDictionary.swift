//
//  CIDictionary.swift
//  Noze.io
//
//  Created by Helge Heß on 4/29/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

public extension Dictionary where Key : StringLiteralConvertible {
  // http://tinyurl.com/hazrvas
  
  func lookupStoredKey(forCaseInsensitiveKey key: Key) -> Key? {
    let searchKey = String(key).lowercased()
    for k in self.keys {
      let lowerK = String(k).lowercased()
      if searchKey == lowerK { return k }
    }
    return nil
  }

  public mutating func removeValue(forCIKey key: Key) -> Value? {
    if let realKey = self.lookupStoredKey(forCaseInsensitiveKey: key) {
      return self.removeValue(forKey: realKey)
    }
    else {
      return nil
    }
  }
  
  public subscript(ci key : Key) -> Value? {
    get {
      let realKey = self.lookupStoredKey(forCaseInsensitiveKey: key)
      return realKey != nil ? self[realKey!] : nil
    }
    set {
      if let realKey = self.lookupStoredKey(forCaseInsensitiveKey: key) {
        self[realKey] = newValue
      }
      else {
        self[key] = newValue
      }
    }
  }
}
