//
//  UnixUtils.swift
//  SwiftSockets
//
//  Created by Helge Hess on 6/10/14.
//  Copyright (c) 2014-2015 Always Right Institute. All rights reserved.
//

// MARK: - dispatch convenience

import Dispatch
import core

#if os(Linux)
#else
  // importing this from xsys doesn't seem to work
  import Foundation // this is for POSIXError : ErrorProtocol
#endif
