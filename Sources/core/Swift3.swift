//
//  Swift3.swift
//  NozeIO
//
//  Created by Helge Heß on 5/9/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if swift(>=3.0) // #swift3-fd

// This does not seem to carry over to other modules (deprecation warning is per
// module)
// => use the reverse!
public typealias ErrorType    = ErrorProtocol
public typealias SequenceType = Sequence

#else // Swift 2.2

public typealias ErrorProtocol = ErrorType
public typealias Sequence      = SequenceType
public typealias OptionSet     = OptionSetType

// MARK: - Swift 3 compatibility extensions

public extension CollectionType where Generator.Element : Equatable {
  
  public func split(separator s: Self.Generator.Element,
                    omittingEmptySubsequences: Bool = false,
                    maxSplits: Int = Int.max) -> [Self.SubSequence]
  {
    return split(s, maxSplit: maxSplits,
                 allowEmptySlices: !omittingEmptySubsequences)
  }
}

public extension CollectionType {

  public func index(after idx: Self.Index) -> Index { // v3 compat
    return idx.successor()
  }
}
  
public extension CollectionType where Generator.Element : Equatable {

  public func index(of element: Self.Generator.Element) -> Self.Index? {
    return indexOf(element)
  }
}
  
public extension CollectionType where Generator.Element == String {
  // joinWithSeparator is ambiguous w/o the `where`

  public func joined(separator s: String) -> String {
    return joinWithSeparator(s)
  }

}

public extension _ArrayType {
  
  public mutating func append
    <S: SequenceType where S.Generator.Element == Self.Generator.Element>
    (contentsOf newElements: S)
  {
    appendContentsOf(newElements)
  }
  
  public mutating func remove(at idx: Index) -> Generator.Element {
    return removeAtIndex(idx)
  }
}

public extension Dictionary {

  public mutating func removeValue(forKey k: Key) -> Value? {
    return removeValueForKey(k)
  }

}

#if os(OSX) || os(iOS) || os(watchOS) || os(tvOS) // #preview1
import Foundation
#endif

public extension String {

  public mutating func append
    <S : SequenceType where S.Generator.Element == Character>
    (contentsOf newElements: S)
  {
    appendContentsOf(newElements)
  }
  
  public func contains(other: String) -> Bool { return containsString(other) }
  
  public func lowercased() -> String { return lowercaseString }
  
  public func substring(to index: Index) -> String {
    return substringToIndex(index)
  }
  
  func index(after  idx: Index) -> Index { return idx.successor()   }
  func index(before idx: Index) -> Index { return idx.predecessor() }
}

#endif // Swift 2.2
