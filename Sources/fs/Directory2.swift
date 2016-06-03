//
//  Directory.swift
//  NozeIO
//
//  Created by Helge Hess on 04/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//
#if swift(>=3.0)
#else // Swift 2.2
import Dispatch
import xsys
import core

public func readdir(path: String, cb: ( [ String ]? ) -> Void) {
  module.Q.evalAsync(readdirSync, path, cb)
}

// TBD: should that be a stream? Maybe, but it may not be worth it
public func readdirSync(path: String) -> [ String ]? {
  let dir = xsys.opendir(path)
  guard dir != nil else { return nil }
  defer { xsys.closedir(dir) }
  
  var entries = [ String ]()
  repeat {
    var lEntry : UnsafeMutablePointer<xsys.dirent> = nil
    var buffer = xsys.dirent()
    let rc     = xsys.readdir_r(dir, &buffer, &lEntry)
    
    guard rc == 0 else {
      // TODO: error handling. Hm. Do we care? Do we really want try abc?
      return nil
    }
    
    let entry = lEntry
    guard entry != nil else { break }  // done
    
    var s : String? = nil
    if entry.memory.d_name.0 == 46 /* . */ {
      guard entry.memory.d_name.1 != 0 else { continue }
      if entry.memory.d_name.1 == 46 /* .. */ {
        guard entry.memory.d_name.2 != 0 else { continue }
      }
    }    
    withUnsafePointer(&entry.memory.d_name) { p in
      let cs = UnsafePointer<CChar>(p) // cast
      s = String.fromCString(cs)
    }

    if let s = s {
      entries.append(s)
    }
    else {
      assert(false, "could not decode directory name")
    }
  } while true
  
  return entries
}
#endif // Swift 2.2
