//
//  IncomingMessage.swift
//  Noze.io
//
//  Created by Helge Heß on 6/2/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import http

public extension IncomingMessage {
  
  // TODO: baseUrl, originalUrl, path
  // TODO: hostname, ip, ips, protocol
  
  public func accepts(s: String) -> String? {
    // TODO: allow array values
    guard let acceptHeader = (self.headers[ci: "accept"] as? String) else {
      return nil
    }
    
    // FIXME: naive and incorrect implementation :-)
    // TODO: parse quality, patterns, etc etc
    let acceptedTypes = acceptHeader.characters.split(separator: ",")
    for mimeType in acceptedTypes {
      let mimeTypeString = String(mimeType)
      if mimeTypeString.contains(s) { return mimeTypeString }
    }
    return nil
  }
 
  
  public var xhr : Bool {
    guard let h = (headers[ci: "X-Requested-With"] as? String) else {
      return false
    }
    return h.contains("XMLHttpRequest")
  }
}


#if swift(>=3.0) // #swift3-1st-kwarg
public extension IncomingMessage {
  public func accepts(_ s: String) -> String? { return accepts(s: s) }
}
#else // Swift 2.2
#endif // Swift 2.2
