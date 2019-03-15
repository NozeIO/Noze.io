//
//  IncomingMessage.swift
//  Noze.io
//
//  Created by Helge Heß on 6/2/16.
//  Copyright © 2016-2017 ZeeZide GmbH. All rights reserved.
//

import http

public extension IncomingMessage {
  
  // TODO: baseUrl, originalUrl, path
  // TODO: hostname, ip, ips, protocol
  
  func accepts(_ s: String) -> String? {
    // TODO: allow array values
    guard let acceptHeader = (self.headers[ci: "accept"] as? String) else {
      return nil
    }
    
    // FIXME: naive and incorrect implementation :-)
    // TODO: parse quality, patterns, etc etc
    #if swift(>=3.2)
      let acceptedTypes = acceptHeader.split(separator: ",")
    #else
      let acceptedTypes = acceptHeader.characters.split(separator: ",")
    #endif
    for mimeType in acceptedTypes {
      let mimeTypeString = String(mimeType)
      if mimeTypeString.contains(s) { return mimeTypeString }
    }
    return nil
  }
 
  
  var xhr : Bool {
    guard let h = (headers[ci: "X-Requested-With"] as? String) else {
      return false
    }
    return h.contains("XMLHttpRequest")
  }
}
