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
  public func isFile()         -> Bool { return (st_mode & S_IFMT) == S_IFREG  }
  public func isDirectory()    -> Bool { return (st_mode & S_IFMT) == S_IFDIR  }
  public func isBlockDevice()  -> Bool { return (st_mode & S_IFMT) == S_IFBLK  }
  public func isSymbolicLink() -> Bool { return (st_mode & S_IFMT) == S_IFLNK  }
  public func isFIFO()         -> Bool { return (st_mode & S_IFMT) == S_IFIFO  }
  public func isSocket()       -> Bool { return (st_mode & S_IFMT) == S_IFSOCK }
  
  public func isCharacterDevice() -> Bool {
    return (st_mode & S_IFMT) == S_IFCHR
  }
  
  
  public var size : Int { return Int(st_size) }
  
  
  // TODO: we need a Date object, then we can do:
  //   var atime : Date { return Date(st_atime) }
}
