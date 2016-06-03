//
//  Swift3.swift
//  NozeIO
//
//  Created by Helge Heß on 5/1/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if swift(>=3.0) // #swift3-fd

public typealias ErrorType     = ErrorProtocol

public typealias GeneratorType = IteratorProtocol

#else // Swift 2.2
  
extension String {
  
  public func uppercased() -> String { return uppercaseString }
  
  public mutating func append
    <S : SequenceType where S.Generator.Element == Character>
    (contentsOf newElements: S)
  {
    appendContentsOf(newElements)
  }
}

/* pulled in from streams
extension _ArrayType {
  
  public mutating func append
    <S: SequenceType where S.Generator.Element == Self.Generator.Element>
    (contentsOf newElements: S)
  {
    appendContentsOf(newElements)
  }
}
*/

#endif // Swift 2.2
