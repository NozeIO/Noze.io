//
//  ListBufferStream.swift
//  Noze.IO
//
//  Created by Helge Hess on 01/07/15.
//  Copyright © 2015 ZeeZide GmbH. All rights reserved.
//

/// TBD: document
/// used by WritableStream<T>
public class ListBuffer<T> {

  typealias DoneCB  = ( ) -> Void
  typealias Bucket  = [ T ]
  typealias Brigade = [ Bucket ]
  
  var highWaterMark : Int
  
  var firstBuffer   : BufferNode<T>? = nil
  var totalCount    = 0

  var isEmpty       : Bool { return totalCount == 0 }
  
  var bufferCount   : Int {
    var count   = 0
    var nodePtr = firstBuffer
    while let node = nodePtr {
      nodePtr = node.next
      count += 1
    }
    return count
  }
  
  var lastBuffer : BufferNode<T>? { // TBD: rather maintain a ptr?
    var nodePtr = firstBuffer
    while let node = nodePtr {
      if node.next == nil { // found last
        return node
      }
      nodePtr = node.next
    }
    return nil
  }
  
  
  // MARK: - Init
  
  init(highWaterMark: Int?) {
    self.highWaterMark = highWaterMark ?? 1
  }
  
  
  // MARK: - Buffer
  
  func enqueue(_ brigade: Brigade, front: Bool = false, done: DoneCB? = nil) {
    if front {
      firstBuffer = BufferNode(chunks: brigade, done: done, next: firstBuffer)
      totalCount += firstBuffer!.totalCount
    }
    else {
      let b = BufferNode(chunks: brigade, done: done)
      if let last = lastBuffer {
        assert(last.next == nil)
        last.next = b
      }
      else {
        assert(firstBuffer == nil)
        firstBuffer = b
      }
      totalCount += b.totalCount
    }
  }
  
  func dequeue() -> ( Brigade, DoneCB? )? {
    guard let buffer = firstBuffer else { return nil }
    firstBuffer = buffer.next
    totalCount -= buffer.totalCount
    return ( buffer.chunks, buffer.done )
  }
  
  var availableBufferSpace : Int {
    if totalCount >= highWaterMark {
      return 0
    }
    return highWaterMark - totalCount
  }
  
  func dequeueAll(cb: ( Brigade, DoneCB? ) -> Void) {
    var head = firstBuffer
    firstBuffer = nil
    totalCount  = 0
    
    while let h = head {
      cb(h.chunks, h.done)
      head = h.next
    }
  }
  
  // MARK: - Logging
  
  var logStateInfo : String {
    return "#\(bufferCount)/#\(totalCount) hwm=\(highWaterMark)"
  }
}


class BufferNode<T> {
  // TODO: not sure whether we should store arrays of arrays. API wise it is
  //       good to have for writev
  
  typealias Bucket = [ T ]
  typealias DoneCB = ( ) -> Void
  
  var next       : BufferNode<T>?
  let chunks     : [ Bucket ]
  let done       : DoneCB?
  let totalCount : Int
  
  init(chunks: [ Bucket ], done: DoneCB? = nil, next: BufferNode<T>? = nil) {
    self.chunks = chunks
    self.done   = done
    self.next   = next
    
    self.totalCount = countBrigade(chunks)
  }
}


// Brigade helpers

func countBrigade<T>(_ brigade: [[ T ]]) -> Int { // cannot be private
  return brigade.reduce(0) { $0 + $1.count }
}

func consumeFromBrigade<T>(_ brigade: [[ T ]], consumed: Int) -> [[ T ]] {
  // TODO: improve me. Oh man. :-) A brigade should be a (the?) list.
  typealias Bucket = [ T ]
  var newBrigade : [ Bucket ] = []
  
  var pending = consumed
  for chunk in brigade {
    if pending < 1 { // append all remaining
      newBrigade.append(chunk)
      continue
    }
    
    let chunkLen = chunk.count
    
    if chunkLen <= pending { // consume whole chunk
      pending -= chunkLen
      continue
    }
    
    // only consume parts of the chunk
    let slice = chunk[pending..<chunkLen]
    newBrigade.append(Bucket(slice)) // grmpf
    pending = 0
  }
  
  return newBrigade
}
