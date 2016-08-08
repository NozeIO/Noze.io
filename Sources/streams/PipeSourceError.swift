//
//  PipeSourceError.swift
//  Noze.io
//
//  Created by Helge Heß on 5/8/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import core

public struct PipeSourceError : Error {
  
  public let error  : Error
  public let stream : ReadableStreamType
  
  init(error: Error, stream: ReadableStreamType) {
    self.error  = error
    self.stream = stream
  }

}
