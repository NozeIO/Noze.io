//
//  StatStruct.swift
//  Noze.io
//
//  Created by Helge Heß on 5/8/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import xsys
#if os(Linux)
  import Glibc
#else
  import Darwin
#endif

public extension xsys.stat_struct {
  
  // could be properties, but for consistency with Node ...
  func isFile()         -> Bool { return (st_mode & S_IFMT) == S_IFREG  }
  func isDirectory()    -> Bool { return (st_mode & S_IFMT) == S_IFDIR  }
  func isBlockDevice()  -> Bool { return (st_mode & S_IFMT) == S_IFBLK  }
  func isSymbolicLink() -> Bool { return (st_mode & S_IFMT) == S_IFLNK  }
  func isFIFO()         -> Bool { return (st_mode & S_IFMT) == S_IFIFO  }
  func isSocket()       -> Bool { return (st_mode & S_IFMT) == S_IFSOCK }
  
  func isCharacterDevice() -> Bool {
    return (st_mode & S_IFMT) == S_IFCHR
  }
  
  
  var size : Int { return Int(st_size) }
  
  
  // TODO: we need a Date object, then we can do:
  //   var atime : Date { return Date(st_atime) }
}
