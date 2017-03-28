//
//  Directory.swift
//  Noze.io
//
//  Created by Helge Hess on 04/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//
import Dispatch
import xsys
import core

public func readdir(_ path: String,
                    cb: @escaping ( Error?, [ String ]? ) -> Void)
{
  module.Q.evalAsync(readdirSync, path, cb)
}

// TBD: should that be a stream? Maybe, but it may not be worth it
public func readdirSync(_ path: String) throws -> [ String ] {
  guard let dir = xsys.opendir(path) else {
    throw POSIXErrorCode(rawValue: xsys.errno)!
  }
  defer { _ = xsys.closedir(dir) }
  
  var entries = [ String ]()
  repeat {
    xsys.errno = 0
    guard let entry = xsys.readdir(dir) else {
      if xsys.errno == 0 {
        break
      }
      // On Linux, only EBADF is documented.  macOS lists EFAULT, which
      // is equally implausible.  But it also mentions EIO, which might
      // just be possible enough to consider it.
      throw POSIXErrorCode(rawValue: xsys.errno)!
    }
    
    var s : String? = nil
    if entry.pointee.d_name.0 == 46 /* . */ {
      guard entry.pointee.d_name.1 != 0 else { continue }
      if entry.pointee.d_name.1 == 46 /* .. */ {
        guard entry.pointee.d_name.2 != 0 else { continue }
      }
    }
   
    
    //&entry.pointee.d_name
    
    withUnsafePointer(to: &entry.pointee.d_name) { p in
      // TBD: Cast ptr to (CChar,CChar) tuple to an UnsafePointer<CChar>.
      //      Is this the right way to do it? No idea.
      //      Rather do withMemoryRebound? But what about the capacity?
      let rp  = UnsafeRawPointer(p)
      let crp = rp.assumingMemoryBound(to: CChar.self)
      s       = String(cString: crp) // TBD: rather validatingUTF8?
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

