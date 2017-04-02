//
//  IncomingMessage.swift
//  Noze.io
//
//  Created by Helge Heß on 6/2/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

public extension IncomingMessage {
  
  // TODO: baseUrl, originalUrl, path
  // TODO: hostname, ip, ips, protocol
  
  public func accepts(_ s: String) -> String? {
    // TODO: allow array values
    guard let acceptHeader = (self.getHeader("accept") as? String) else {
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
    guard let h = (getHeader("X-Requested-With") as? String) else {
      return false
    }
    return h.contains("XMLHttpRequest")
  }
}
