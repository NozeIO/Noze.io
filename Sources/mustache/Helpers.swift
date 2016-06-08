//
//  Helpers.swift
//  Noze.io
//
//  Created by Helge Heß on 6/1/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if os(Linux)
#if swift(>=3.0) // #swift3-foundation
import Foundation
#else
// No Foundation on Linux Swift 2.2
typealias NSNumber = Void // HACK
typealias NSString = Void // HACK
typealias NSValue  = Void // HACK
#endif
#else
import Foundation
#endif

public extension MustacheRenderingContext {

  func isFoundationBaseType(value vv: Any) -> Bool {
    if vv is NSNumber { return true }
    if vv is NSString { return true }
    if vv is NSValue  { return true }
    return false
  }

  func isMustacheTrue(value v: Any?) -> Bool {
    guard let vv = v else { return false }
    
    if let b = vv as? Bool   { return b }
    if let i = vv as? Int    { return i == 0 ? false : true }
    if let s = vv as? String { return !s.isEmpty }
    
    #if os(Linux)
      #if swift(>=3.0) // #swift3-foundation
        if let n = vv as? NSNumber { return n.boolValue }
      #else
        // No NSNumber on Linux Swift 2.2
      #endif
    #else
      if let n = vv as? NSNumber { return n.boolValue }
    #endif
    
    let mirror = Mirror(reflecting: vv)
    
    // doesn't want to be displayed?
    guard let ds = mirror.displayStyle else { return false }
    
    // it is a collection, check count
    #if swift(>=3.0) // #swift3-fd
      guard ds == .collection else { return true } // all objects
    #else
      guard ds == .Collection else { return true } // all objects
    #endif
    return mirror.children.count > 0
  }

}
