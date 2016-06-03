//
//  StdOutTarget.swift
//  Noze.IO
//
//  Created by Helge Heß on 01/07/15.
//  Copyright © 2015 ZeeZide GmbH. All rights reserved.
//

import streams

// TODO: detect whether stdout is interactive or a file. Might need to change
//       between KQueue and threaded source.
// TODO: this should just be done in the module constructor function in a
//       generic way. There should be no StdOutTarget 'class' (nor Stdin)
public class StdOutTarget : GCDChannelBase, GWritableTargetType {
  
  public var canEnd : Bool { return self.fd.isTTY ? false : true }
  
}
