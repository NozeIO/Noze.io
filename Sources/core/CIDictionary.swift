//
//  CIDictionary.swift
//  NozeIO
//
//  Created by Helge Heß on 4/29/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

public extension Dictionary where Key : StringLiteralConvertible {
  // http://tinyurl.com/hazrvas
  
#if swift(>=3.0) // #swift3-1st-arg #swift3-fd
  func lookupStoredKeyForCaseInsensitiveKey(_ key: Key) -> Key? {
    let searchKey = String(key).lowercased()
    for k in self.keys {
      let lowerK = String(k).lowercased()
      if searchKey == lowerK { return k }
    }
    return nil
  }
#else
  func lookupStoredKeyForCaseInsensitiveKey(key: Key) -> Key? {
    let searchKey = String(key).lowercaseString
    for k in self.keys {
      let lowerK = String(k).lowercaseString
      if searchKey == lowerK { return k }
    }
    return nil
  }
#endif

  public mutating func removeValueForKey(ci key: Key) -> Value? {
    if let realKey = self.lookupStoredKeyForCaseInsensitiveKey(key) {
#if swift(>=3.0) // #swift3-1st-arg #swift3-fd
      return self.removeValue(forKey: realKey)
#else
      return self.removeValueForKey(realKey)
#endif
    }
    else {
      return nil
    }
  }
  
  public subscript(ci key : Key) -> Value? {
    get {
      let realKey = self.lookupStoredKeyForCaseInsensitiveKey(key)
      return realKey != nil ? self[realKey!] : nil
    }
    set {
      if let realKey = self.lookupStoredKeyForCaseInsensitiveKey(key) {
        self[realKey] = newValue
      }
      else {
        self[key] = newValue
      }
    }
  }
}
