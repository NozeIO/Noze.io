//
//  Swift3.swift
//  Noze.io
//
//  Created by Helge Heß on 6/3/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if swift(>=3.0) // #swift3-fd

#else // Swift 2.2

extension String {
  func contains(needle: String) -> Bool { return self.containsString(needle) }
  
  func index(after  idx: Index) -> Index { return idx.successor()   }
  func index(before idx: Index) -> Index { return idx.predecessor() }
}

extension Dictionary {
  
  mutating func removeValue(forKey k: Key) -> Value? {
    return removeValueForKey(k)
  }
  
}

#endif // Swift 2.2
