//
//  Extensions.swift
//  Noze.io
//
//  Created by Helge Heß on 27/06/2016.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

extension Collection where Self.Iterator.Element : Equatable {
  // Can be done on SequenceType, but w/ the current imp only by converting
  // the sequences to collections ... So the user should rather do this
  // explicitly.
  
  typealias ItemType = Self.Iterator.Element

  /// This is like SequenceType.split, except it doesn't just split on a single
  /// element, but on another sequence.
  public func split<ST: Collection where ItemType == ST.Iterator.Element,
                                         Index == ST.Index>
                (separator sep: ST,
                 omittingEmptySubsequences: Bool = false)
                -> [ [ ItemType ] ]
  {
    // TODO: make available as a core stream
    // TODO: can we avoid the Array<T>()? This doesn't work, right?:
    //         CollectionType<ItemType> ...
    let sepLen = sep.count
    guard sepLen > 0 else { return [ Array<ItemType>(self) ] }
    let m0 = sep.first!
    
    var buckets       = Array<Array<ItemType>>()
    var currentBucket = Array<ItemType>()
    
    var matchIndex : Index? = nil
    var matchPos   : Index? = nil
    var lastWasSep : Bool   = false
    
    var i = self.startIndex
    while i != self.endIndex {
      let item = self[i]
      
      lastWasSep = false
      
      if let mi = matchIndex { // matching mode
        if matchPos! == sep.endIndex { // done
          if !currentBucket.isEmpty || !omittingEmptySubsequences {
            buckets.append(currentBucket)
          }
          currentBucket.removeAll()
          lastWasSep = true
          matchPos   = nil
          matchIndex = nil
        }
        else { // more to match
          if item == sep[matchPos!] { // still matching
            matchPos = sep.index(after: matchPos!)
            // continue as usual, I guess
            i = self.index(after: i)
            continue
          }
          else { // did NOT match
            currentBucket.append(self[matchIndex!])
            i = self.index(after: mi) // restart at item following original match
            matchIndex = nil
            matchPos   = nil
            continue
          }
        }
        
      }
      
      assert(matchPos   == nil)
      assert(matchIndex == nil)
      if item == m0 { // start matching
        matchIndex = i // remember start pos
        matchPos   = sep.index(after: sep.startIndex)
      }
      else { // not matching at all
        currentBucket.append(item)
      }
      
      i = self.index(after: i)
    }
    
    if !currentBucket.isEmpty {
      // this depends a little on whether the sequence ended with a splitter
      buckets.append(currentBucket)
    }
    else if lastWasSep && !omittingEmptySubsequences {
      buckets.append([])
    }
    
    return buckets
  }
  
}
