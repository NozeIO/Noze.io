//
//  Environment.swift
//  Noze.io
//
//  Created by Helge Heß on 4/27/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if os(Linux)

import Glibc

#if swift(>=3.0) // #swift3-ptr
#else
// what a heck! ;-)
private let pEnviron  = Glibc.dlsym(nil, "environ")
private let cpEnviron =
  UnsafePointer<UnsafePointer<UnsafePointer<CChar>>>(pEnviron)
let C_ENV  =
  UnsafePointer<UnsafePointer<CChar>>(cpEnviron != nil ? cpEnviron.memory : nil)

private let defaultEnvironment : [ String : String ] = [ : ]
  // TODO: build something via getenv

public var environ : [ String : String ] {
  guard C_ENV != nil else { return defaultEnvironment }

  var env = Dictionary<String, String>()

  // TBD: can there be multi-value pairs?
  var p = C_ENV
  while p.memory != nil {
    let cp = p.memory
    guard strlen(cp) > 0 else { continue }
    
    let peq = UnsafePointer<CChar>(index(cp, 61 /* = */))
    if peq == nil {
      guard let key = String.fromCString(cp) else { p += 1; continue }
      if env[key] == nil { env[key] = "" } // put in empty string
    }
    else {
      let keylen = peq - cp
      let valp   = peq + 1
      let value  : String
      let key    : String
      
      if valp.memory == 0 {
        value = ""
      }
      else {
        let s = String.fromCString(peq + 1)
        guard s != nil else { p += 1; continue }
        value = s!
      }

      if keylen < 1 {
        key = ""
      }
      else {
        let cs = strndup(cp, keylen)
        let s  = String.fromCString(cs)
        free(cs)
        guard s != nil else { p += 1; continue }
        key = s!
      }

      env[key] = value
    }
    
    p += 1 // next pair
  }
  
  return env
}
#endif // Swift 2.2

#endif // Linux

