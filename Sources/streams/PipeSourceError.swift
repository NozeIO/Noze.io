//
//  PipeSourceError.swift
//  Noze.io
//
//  Created by Helge Heß on 5/8/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import core

public struct PipeSourceError : ErrorProtocol {
  
  public let error  : ErrorProtocol
  public let stream : ReadableStreamType
  
  init(error: ErrorProtocol, stream: ReadableStreamType) {
    self.error  = error
    self.stream = stream
  }

}
