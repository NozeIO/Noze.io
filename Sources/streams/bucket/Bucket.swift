//
//  Bucket.swift
//  NozeIO
//
//  Created by Helge Hess on 14/04/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

// TODO: Potential workaround solution: Make Bucket a class<T>. Or an enum with
//       the different posibilities hardcoded. Class is probably better (should
//       be a value type, but struct can't be subclassed :-)

// TODO:
// An attempt to allow for arbitrary BucketType's to be used in streams. It's
// not quite there yet: next step would be to make ReadableStream work with
// generic buckets.
public protocol BucketType {
  
  associatedtype BucketElement
  
  var count   : Int  { get }
  var isEmpty : Bool { get }
  
  subscript (index: Int) -> BucketElement { get set }
}

// This doesn't fly: makes Array stuff ambiguous
//   public extension Bucket {
//     var isEmpty : Bool { return count < 1 }
//   }


/// all arrays are buckets
extension Array : BucketType {
}
