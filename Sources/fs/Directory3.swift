//
//  Directory.swift
//  NozeIO
//
//  Created by Helge Hess on 04/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//
#if swift(>=3.0)
import Dispatch
import xsys
import core

public func readdir(_ path: String, cb: ( [ String ]? ) -> Void) {
  module.Q.evalAsync(readdirSync, path, cb)
}

// TBD: should that be a stream? Maybe, but it may not be worth it
public func readdirSync(_ path: String) -> [ String ]? {
#if os(Linux)
  let lDir = xsys.opendir(path)
  guard let dir = lDir else { return nil }
#else
  let dir = xsys.opendir(path)
  guard dir != nil else { return nil }
#endif
  defer { _ = xsys.closedir(dir) }
  
  var entries = [ String ]()
  repeat {
    var lEntry = UnsafeMutablePointer<xsys.dirent>(nil)
    var buffer = xsys.dirent()
    let rc     = xsys.readdir_r(dir, &buffer, &lEntry)
    
    guard rc == 0 else {
      // TODO: error handling. Hm. Do we care? Do we really want try abc?
      return nil
    }
    
    guard let entry = lEntry else { break }  // done
    
    var s : String? = nil
    if entry.pointee.d_name.0 == 46 /* . */ {
      guard entry.pointee.d_name.1 != 0 else { continue }
      if entry.pointee.d_name.1 == 46 /* .. */ {
        guard entry.pointee.d_name.2 != 0 else { continue }
      }
    }    
    withUnsafePointer(&entry.pointee.d_name) { p in
      let cs = UnsafePointer<CChar>(p) // cast
      s = String(cString: cs) // TBD: rather validatingUTF8?
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
#endif // Swift >= 3

