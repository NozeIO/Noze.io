//
//  CIDictionary.swift
//  Noze.io
//
//  Created by Helge Heß on 4/29/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

public extension Dictionary where Key : ExpressibleByStringLiteral {
  // http://tinyurl.com/hazrvas
  
  func lookupStoredKey(forCaseInsensitiveKey key: Key) -> Key? {
    let searchKey = ((key as? String) ?? String(describing: key)).lowercased()
    for k in self.keys {
      let lowerK = ((k as? String) ?? String(describing: k)).lowercased()
      if searchKey == lowerK { return k }
    }
    return nil
  }

  mutating func removeValue(forCIKey key: Key) -> Value? {
    if let realKey = self.lookupStoredKey(forCaseInsensitiveKey: key) {
      return self.removeValue(forKey: realKey)
    }
    else {
      return nil
    }
  }
  
  subscript(ci key : Key) -> Value? {
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
