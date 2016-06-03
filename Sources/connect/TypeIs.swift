//
//  TypeIs.swift
//  Noze.io
//
//  Created by Helge Hess on 30/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import xsys
import http

#if swift(>=3.0) // #swift3-fd
import Foundation
#endif


// TODO: the API is both crap nor really the same like Node

public func typeIs(message: IncomingMessage, _ types: [ String ]) -> String? {
  let ctypeO = message.headers[ci: "Content-Type"] as? String
  guard let ctype = ctypeO else { return nil }
  return typeIs(ctype, types)
}

public func typeIs(type: String, _ types: [ String ]) -> String? {
  let lcType = type.lowercased()
  
  for matchType in types {
    if does(type: lcType, match: matchType) {
      return matchType
    }
  }
  
  return nil
}

private func does(type lcType: String, match matchType: String) -> Bool {
  let lcMatch = matchType.lowercased()
  
  if lcType == lcMatch { return true }
  
  // FIXME: completely naive implementation :->
  
  if lcMatch.hasSuffix("*") {
#if swift(>=3.0) // #swift3-fd
    let idx = lcMatch.index(before: lcMatch.endIndex)
#else
    let idx = lcMatch.endIndex.predecessor()
#endif
    let lcPatMatch = lcMatch.substring(to: idx)
    return lcType.hasPrefix(lcPatMatch)
  }
  
  if lcType.contains(lcMatch) {
    return true
  }
  
  return false
}


#if swift(>=3.0) // #swift3-fd
public func typeIs(_ message: IncomingMessage, _ types: [ String ]) -> String? {
  return typeIs(message: message, types)
}
public func typeIs(_ type: String, _ types: [ String ]) -> String? {
  return typeIs(type: type, types)
}
#endif
