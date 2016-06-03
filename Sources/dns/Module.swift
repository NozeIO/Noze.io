//
//  Module.swift
//  NozeIO
//
//  Created by Helge Hess on 11/04/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import core

public class NozeDNS : NozeModule {
}
public let module = NozeDNS()


#if os(Linux)
#else
  // importing this from xsys doesn't seem to work
  import Foundation // this is for POSIXError : ErrorType
#endif
