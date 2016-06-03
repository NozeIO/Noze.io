//
//  PipeSourceError.swift
//  NozeIO
//
//  Created by Helge Heß on 5/8/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import core

public struct PipeSourceError : ErrorType {
  
  public let error  : ErrorType
  public let stream : ReadableStreamType
  
  init(error: ErrorType, stream: ReadableStreamType) {
    self.error  = error
    self.stream = stream
  }

}
