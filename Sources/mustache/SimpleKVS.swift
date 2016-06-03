//
//  SimpleKVS.swift
//  TestMustache
//
//  Created by Helge Heß on 6/1/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if os(Linux)
#if swift(>=3.0) // #swift3-foundation
import class Foundation.NSObject
let lx30hack = true
#else
// No Foundation on Linux Swift 2.2
typealias NSObject = Int // HACK
let lx22hack = true
#endif
#else // Darwin
import class Foundation.NSObject
#endif // Dawin

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
#if swift(>=3.0) // #swift3-fd
    let path = p.characters.split(separator: ".").map { String($0) }
#else
    let path = p.characters.split(".").map { String($0) }
#endif
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
#if swift(>=3.0) // #swift3-fd
    let isOpt  = mirror.displayStyle == .optional
    let isDict = mirror.displayStyle == .dictionary
#else
    let isOpt  = mirror.displayStyle == .Optional
    let isDict = mirror.displayStyle == .Dictionary
#endif
    if isOpt {
      guard mirror.children.count > 0 else { return nil }
      let (_, some) = mirror.children.first!
      return value(forKey: k, inObject: some)
    }
    
    // support dictionary
    if isDict {
      for ( idx, value ) in mirror.children {
        
        // FIXME: replace those dupes
        // FIXME: There should be some way to reflect on just the key and then
        //        continue using a regular Mirror on the Any value, but this
        //        doesn't work: case (key, _)
        // In consequence this is limited to the hardcoded set of (key,value)
        // pairs.
        
        if let t = value as? ( String, Any ) {
          guard t.0 == k else { continue }
          let value = t.1
          
          let valueMirror = Mirror(reflecting: value)
#if swift(>=3.0) // #swift3-fd
          if valueMirror.displayStyle != .optional { return value }
#else
          if valueMirror.displayStyle != .Optional { return value }
#endif
          
          guard valueMirror.children.count > 0 else { return nil }
          
          let (_, some) = valueMirror.children.first!
          
          return some
        }
        else if let t = value as? ( String, String ) {
          guard t.0 == k else { continue }
          let value = t.1
          
          let valueMirror = Mirror(reflecting: value)
#if swift(>=3.0) // #swift3-fd
          if valueMirror.displayStyle != .optional { return value }
#else
          if valueMirror.displayStyle != .Optional { return value }
#endif
          
          guard valueMirror.children.count > 0 else { return nil }
          
          let (_, some) = valueMirror.children.first!
          
          return some
        }
        else if let t = value as? ( NSObject, AnyObject ) {
#if os(Linux)
#if swift(>=3.0) // #swift3-1st-arg
          // cast from 'NSObject' to unrelated type 'String' always fails
          guard !lx30hack else { return nil }
#else
          guard !lx22hack else { return nil }
#endif
#else
          guard let okey = (t.0 as? String) else { return nil } // TODO: once
          guard okey == k                   else { continue }
#endif
          let value = t.1
          
          let valueMirror = Mirror(reflecting: value)
#if swift(>=3.0) // #swift3-fd
          if valueMirror.displayStyle != .optional { return value }
#else
          if valueMirror.displayStyle != .Optional { return value }
#endif
          
          guard valueMirror.children.count > 0 else { return nil }
          
          let (_, some) = valueMirror.children.first!
          
          return some
        }
        else {
          print("KVC: unexpected dict pair: " +
                "\(idx) \(value) \(value.dynamicType)")
          return nil
        }
      }
      return nil
    }
    
    // regular object, scan
    for ( label, value ) in mirror.children {
      guard let okey = label else { continue }
      guard okey == k        else { continue }
      
      let valueMirror = Mirror(reflecting: value)
#if swift(>=3.0) // #swift3-fd
      if valueMirror.displayStyle != .optional { return value }
#else
      if valueMirror.displayStyle != .Optional { return value }
#endif
      
      guard valueMirror.children.count > 0 else { return nil }
      
      let (_, some) = valueMirror.children.first!
      
      return some
    }
    return nil
  }
  
}
