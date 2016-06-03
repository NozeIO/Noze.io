//
//  Swift3.swift
//  NozeIO
//
//  Created by Helge Heß on 5/9/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if swift(>=3.0) // #swift3-fd

// this does not seem to carry over to other modules
public typealias ErrorType    = ErrorProtocol
public typealias SequenceType = Sequence
  
#else // Swift 2.2

import xsys

extension _ArrayType {
  
  public mutating func append
    <S: SequenceType where S.Generator.Element == Self.Generator.Element>
    (contentsOf newElements: S)
  {
    appendContentsOf(newElements)
  }
}

extension String {
  
  func contains(other: String) -> Bool {
    return containsString(other)
  }
}

#endif
