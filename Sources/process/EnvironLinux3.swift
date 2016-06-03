//
//  Environment.swift
//  NozeIO
//
//  Created by Helge Heß on 4/27/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if os(Linux)

import Glibc

#if swift(>=3.0) // #swift3-ptr
// what a heck! ;-)
private let pEnviron  = Glibc.dlsym(nil, "environ")
private let cpEnviron =
  UnsafePointer<UnsafePointer<UnsafePointer<CChar>>>(pEnviron)
let C_ENV  =
  UnsafePointer<UnsafePointer<CChar>>(cpEnviron != nil ? cpEnviron!.pointee : nil)

private let defaultEnvironment : [ String : String ] = [ : ]
  // TODO: build something via getenv

public var environ : [ String : String ] {
  guard C_ENV != nil else { return defaultEnvironment }

  var env = Dictionary<String, String>()

  // TBD: can there be multi-value pairs?
  var p = C_ENV
  repeat {
    guard p != nil else { break }
    
    let cp = p!.pointee
    guard strlen(cp) > 0 else { continue }
    
    let peq = UnsafePointer<CChar>(index(cp, 61 /* = */))
    if peq == nil {
      let key = String(cString: cp)
      if env[key] == nil { env[key] = "" } // put in empty string
    }
    else { // peq != nil
      let keylen = peq! - cp
      let valp   = peq! + 1
      let value  : String
      let key    : String
      
      if valp.pointee == 0 {
        value = ""
      }
      else {
        value = String(cString: peq! + 1)
      }

      if keylen < 1 {
        key = ""
      }
      else {
        let cs = strndup(cp, keylen)
        key = String(cString: cs!)
        free(cs)
      }

      env[key] = value
    }
    
    p! += 1 // next pair
  }
  while true
  
  return env
}
#endif // Swift 3+

#endif // Linux

