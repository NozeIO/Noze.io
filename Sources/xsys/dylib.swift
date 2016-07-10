//
//  dylib.swift
//  Noze.io
//
//  Created by Helge Hess on 11/04/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if os(Linux)
  import Glibc

  public let dlsym  = Glibc.dlsym
  public let dlopen = Glibc.dlopen
  
#else
  import Darwin
  
  public let dlsym  = Darwin.dlsym
  public let dlopen = Darwin.dlopen
#endif
