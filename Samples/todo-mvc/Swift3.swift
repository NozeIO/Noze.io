//
//  Swift3.swift
//  Noze.io
//
//  Created by Helge Heß on 5/25/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if swift(>=3.0) // #swift3-fd
  
// this does not seem to carry over to other modules
public typealias ErrorType   = ErrorProtocol
  
#else // Swift 2.2
  
extension Dictionary {
  
  mutating func removeValue(forKey k: Key) -> Value? {
    return removeValueForKey(k)
  }
  
}

#endif // Swift 2.2
