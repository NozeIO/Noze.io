//
//  StdInSource.swift
//  Noze.IO
//
//  Created by Helge Hess on 26/06/15.
//  Copyright © 2015 ZeeZide GmbH. All rights reserved.
//

import streams

public class StdInSource : GCDChannelBase, GReadableSourceType {

  public static var defaultHighWaterMark : Int { return 1024 } // TODO
  
  public init() {
    super.init(FileDescriptor.stdin)
  }
}
