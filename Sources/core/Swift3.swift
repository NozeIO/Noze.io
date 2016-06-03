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
  
// MARK: - Swift 3 compatibility extensions

public extension CollectionType where Generator.Element : Equatable {
  
  public func split(separator s: Self.Generator.Element,
                    omittingEmptySubsequences: Bool = false,
                    maxSplits: Int = Int.max) -> [Self.SubSequence]
  {
    return split(s, maxSplit: maxSplits,
                 allowEmptySlices: !omittingEmptySubsequences)
  }

  public func index(after idx: Self.Index) -> Index { // v3 compat
    return idx.successor()
  }

  public func index(of element: Self.Generator.Element) -> Self.Index? {
    return indexOf(element)
  }
}
  
public extension CollectionType where Generator.Element == String {

  public func joined(separator s: String) -> String {
    return joinWithSeparator(s)
  }

}

extension Dictionary {

  mutating func removeValue(forKey k: Key) -> Value? {
    return removeValueForKey(k)
  }

}

extension String {
  public mutating func append
    <S : SequenceType where S.Generator.Element == Character>
    (contentsOf newElements: S)
  {
    appendContentsOf(newElements)
  }
}

#endif // Swift 2.2
