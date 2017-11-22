//
//  Module.swift
//  Noze.io
//
//  Created by Helge Hess on 11/04/16.
//  Copyright © 2016-2017 ZeeZide GmbH. All rights reserved.
//

import core

public class NozeLeftpad : NozeModule {
}
public let module = NozeLeftpad()

public extension String {
  
  public func leftpad(_ length: Int, c: Character = " ") -> String {
    #if swift(>=3.2)
      let oldLength = self.count
    #else
      let oldLength = self.characters.count
    #endif
    guard oldLength < length else { return self }
    
    let prefix = c._repeat(times: (length - oldLength))
    
    return prefix + self
  }
    
}

private extension Character {
  
  func _repeat(times t: Int) -> String {
    // This likely can be done faster. Maybe using a dynamic char sequence?
    // Given that this function is so important that it b0rked half the
    // Internet, it should be as fast ass possible.
    
    let s = Array<Character>(repeating: self, count: t)
    return String(s)
  }
  
}
