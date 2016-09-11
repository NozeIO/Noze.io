//
//  Helpers.swift
//  Noze.io
//
//  Created by Helge Heß on 6/1/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import Foundation

public extension MustacheRenderingContext {

  func isFoundationBaseType(value vv: Any) -> Bool {
    if vv is NSNumber { return true }
    if vv is NSString { return true }
    if vv is NSValue  { return true }
    return false
  }

  func isMustacheTrue(value v: Any?) -> Bool {
    guard let vv = v else { return false }
    
    if let b = vv as? Bool     { return b }
    if let i = vv as? Int      { return i == 0 ? false : true }
    if let s = vv as? String   { return !s.isEmpty }
    if let n = vv as? NSNumber { return n.boolValue }
    
    let mirror = Mirror(reflecting: vv)
    
    // doesn't want to be displayed?
    guard let ds = mirror.displayStyle else { return false }
    
    // it is a collection, check count
    guard ds == .collection else { return true } // all objects
    return mirror.children.count > 0
  }

}
