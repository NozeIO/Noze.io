//
//  PipeSourceTarget.swift
//  NozeIO
//
//  Created by Helge Heß on 5/1/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import streams
import fs

public class PipeSource : GCDChannelBase, GReadableSourceType {
  public static var defaultHighWaterMark : Int { return 1024 } // TODO
}
public class PipeTarget : GCDChannelBase, GWritableTargetType {
}
