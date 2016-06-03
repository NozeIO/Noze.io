//
//  Module.swift
//  NozeIO
//
//  Created by Helge Hess on 11/04/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import core

public class NozeLeftpad : NozeModule {
}
public let module = NozeLeftpad()

public extension String {
  
  public func leftpad(length: Int, c: Character = " ") -> String {
    let oldLength = self.characters.count
    guard oldLength < length else { return self }
    
    let prefix = c._repeat(times: (length - oldLength))
    
    return prefix + self
  }
  
#if swift(>=3.0) // #swift3-fd
  public func leftpad(_ length: Int, c: Character = " ") -> String {
    return leftpad(length: length, c: c)
  }
#endif
  
}

private extension Character {
  
  func _repeat(times t: Int) -> String {
    // This likely can be done faster. Maybe using a dynamic char sequence?
    // Given that this function is so important that it b0rked half the
    // Internet, it should be as fast ass possible.
    
#if swift(>=3.0) // #swift3-fd
    let s = Array<Character>(repeating: self, count: t)
#else
    let s = Array<Character>(count: t, repeatedValue: self)
#endif
    return String(s)
  }
  
}