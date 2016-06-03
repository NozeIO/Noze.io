//
//  ArrayBuffer.swift
//  Noze.IO
//
//  Created by Helge Hess on 01/07/15.
//  Copyright © 2015 ZeeZide GmbH. All rights reserved.
//

/// ArrayBuffer<T> - an array of arrays managing elements of type T
///
/// This is because we often get arrays of bytes in APIs (aka buckets), and it
/// seems more efficient to keeps those buckets as-is, instead of merging them
/// into a BIG, serialized array.
///
/// Note: The dequeing returns a Bucket, not a Bridgade. Hence it might need to
/// merge. TBD: is this good? or should we dequeue Brigades?
///
/// Also: I think in Apache buckets can be of different types. Eg a
/// Bucket<UInt8> could be either an in-memory array of bytes, or a file
/// descriptor! Passing around the file descriptor would be way more efficient
/// (i.e. if the sole bucket is a file, one could sendfile() a file straight to
/// a socket instead of copying the bytes).
///
/// TBD: Bad name? Better name it BrigadeArray or something? Or at least
///      NozeArrayBuffer - ArrayBuffer sounds like it is a Foundation class.
///
/// TBD: In this implementation a Bucket is fixed to be an array of UInt8, it
///      actually can't be a different type of Bucket (like a File<UInt8>).
public struct ArrayBuffer<T> {
  
  typealias Bucket  = [ T ] // TBD: do not fix this to be an array
  typealias Brigade = [ Bucket ]
  
  var brigade       = Brigade() // allocate an empty array of buckets
  var totalCount    = 0
  
  var isEmpty : Bool { return totalCount == 0 }
  
  // MARK: - Buffer

  mutating func enqueue(brigade b: Brigade, front: Bool = false) {
    for bucket in b {
      enqueue(bucket: bucket, front: front)
    }
  }
  
  mutating func enqueue(bucket b: Bucket, front: Bool = false) {
    let bucketCount = b.count
    guard bucketCount > 0 else { return }
    
    if front { // unshift
#if swift(>=3.0)
      brigade.insert(b, at: 0)
#else
      brigade.insert(b, atIndex: 0)
#endif
    }
    else { // push
      brigade.append(b)
    }
    totalCount += bucketCount
  }
  
  mutating func dequeue(count c: Int) -> Bucket {
    let count = c
    assert(totalCount > 0)
    
    var joinBucket = Bucket()
    
    while joinBucket.count < count && totalCount > 0 {
      let pending = count - joinBucket.count
      
      // TODO: replace with a linked list of buffers
#if swift(>=3.0)
      let bucket  = brigade.remove(at: 0)
#else
      let bucket  = brigade.removeAtIndex(0)
#endif
      
      if pending >= bucket.count { // consume full bucket
        totalCount -= bucket.count
        joinBucket += bucket
          // TBD: Lookup perf characteristics of this. Is it a copy?
      }
      else { // we don't need the full bucket
        joinBucket += bucket[0..<pending]
        
        // cannot insert a slice, this likely really does a copy
#if swift(>=3.0)
        brigade.insert(Bucket(bucket[pending..<bucket.count]), at: 0)
#else
        brigade.insert(Bucket(bucket[pending..<bucket.count]), atIndex: 0)
#endif
        
        totalCount -= pending
      }
      
    }
    
    assert(totalCount >= 0)
    return joinBucket
  }


#if swift(>=3.0) // #swift3-1st-arg
  mutating func enqueue(_ brigade: Brigade, front: Bool = false) {
    enqueue(brigade: brigade, front: front)
  }
  mutating func enqueue(_ bucket: Bucket, front: Bool = false) {
    enqueue(bucket: bucket, front: front)
  }
#endif
  
  // MARK: - Logging
  
  var logStateInfo : String {
    return "#\(brigade.count)/total=#\(totalCount)"
  }
}
