//
//  SimpleKVS.swift
//  TestMustache
//
//  Created by Helge Heß on 6/1/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import class Foundation.NSObject
#if os(Linux)
let lx30hack = true
#endif

public protocol KeyValueCodingType {
  
  func value(forKey k: String) -> Any?
  
}

public extension KeyValueCodingType {
  
  func value(forKey k: String) -> Any? {
    return KeyValueCoding.defaultValue(forKey: k, inObject: self)
  }
  
}


public struct KeyValueCoding {
  
  public static func value(forKeyPath p: String, inObject o: Any?) -> Any? {
    let path = p.characters.split(separator: ".").map { String($0) }
    var cursor = o
    for key in path {
      cursor = value(forKey: key, inObject: cursor)
      if cursor == nil { break }
    }
    return cursor
  }

  public static func value(forKey k: String, inObject o: Any?) -> Any? {
    if let kvc = o as? KeyValueCodingType {
      return kvc.value(forKey: k)
    }
    return defaultValue(forKey: k, inObject: o)
  }
  
  public static func defaultValue(forKey k: String, inObject o: Any?) -> Any? {
    // Presumably this is really inefficient, but well :-)
    guard let object = o else { return nil }
    
    let mirror = Mirror(reflecting: object)
    
    // extra guard against Optionals
    let isOpt  = mirror.displayStyle == .optional
    let isDict = mirror.displayStyle == .dictionary
    if isOpt {
      guard mirror.children.count > 0 else { return nil }
      let (_, some) = mirror.children.first!
      return value(forKey: k, inObject: some)
    }
    
    // support dictionary
    if isDict {
      return defaultValue(forKey: k, inDictionary: object, mirror: mirror)
    }
    
    // regular object, scan
    for ( label, value ) in mirror.children {
      guard let okey = label else { continue }
      guard okey == k        else { continue }
      
      let valueMirror = Mirror(reflecting: value)
      if valueMirror.displayStyle != .optional { return value }
      
      guard valueMirror.children.count > 0 else { return nil }
      
      let (_, some) = valueMirror.children.first!
      
      return some
    }
    return nil
  }
  
}

public extension KeyValueCoding {
  
  public static func defaultValue(forKey k: String, inDictionary o: Any,
                                  mirror: Mirror) -> Any?
  {
    for ( _, pair ) in mirror.children {
      let pairMirror = Mirror(reflecting: pair)
        // mirror on the (Key,Value) tuple of the Dictionary
        //   children[0] = ( Optional(".0"), String )
        //   children[1] = ( Optional(".1"), Any )
      
      // extract key
      let keyIdx        = pairMirror.children.startIndex
      let ( _, anyKey ) = pairMirror.children[keyIdx]
      let key           = (anyKey as? String) ?? "\(anyKey)"
      guard key == k else { continue } // break if key is not matching
      
      // extract value
      let valueIdx      = pairMirror.children.index(after: keyIdx)
      let ( _, value )  = pairMirror.children[valueIdx]
      
      // print("  \(key) = \(value)")
      
      let valueMirror = Mirror(reflecting: value)
      if valueMirror.displayStyle != .optional { return value }
      
      guard valueMirror.children.count > 0 else { return nil }
      
      let (_, some) = valueMirror.children.first!
        
      return some
    }
    return nil
  }
  
}
