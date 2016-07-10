//
//  StdioAction.swift
//  Noze.io
//
//  Created by Helge Heß on 5/1/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import fs

public enum StdioAction {
  
  case Pipe
    // create and bind a pipe
  
  case Ignore
    // send to /dev/null
  
  case Inherit
    // keep the descriptor as in the parent process
  
  case Fd(fd: FileDescriptor)
    // dup2 the descriptor
  
  // TODO: case: .Stream:FileDescriptorStream
  
  
  // MARK: - Convenience Init
  
  public init(_ fd: FileDescriptor) {
    self = .Fd(fd: fd)
  }
  
  // TBD: we could have a string mapping one for Node.js compat, like:
  //        "pipe" => .Pipe
  //      but I guess it isn't worth it given the fail-case.
}

extension StdioAction : IntegerLiteralConvertible {
  
  public init(integerLiteral value: Int32) {
    let fd = FileDescriptor(value)
    self = .Fd(fd: fd)
  }

}
