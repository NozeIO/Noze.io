//
//  LinuxString.swift
//  NozeIO
//
//  Created by Helge Hess on 05/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if os(Linux)
#if swift(>=3.0)
#else // Swift 2.2
import Glibc

public extension String {

  public func hasPrefix(s: String) -> Bool {
    if s.isEmpty    { return true  }
    if self.isEmpty { return false }

    return self.withCString { selfCS in
      return s.withCString { pCS in
        let sLen = strlen(selfCS)
        let pLen = strlen(pCS)
        if sLen < pLen { return false }
        return strncmp(selfCS, pCS, Int(pLen)) == 0
      }
    }
  }

  public func hasSuffix(s: String) -> Bool {
    if s.isEmpty    { return true }
    if self.isEmpty { return false }
    
    return self.withCString { selfCS in
      return s.withCString { pCS in
        let sLen = strlen(selfCS)
        let pLen = strlen(pCS)
        if sLen < pLen { return false }
        let p = selfCS + Int(sLen - pLen)
        return strncmp(p, pCS, Int(pLen)) == 0
      }
    }
  }

  public func containsString(other: String) -> Bool {
    if other.isEmpty { return true  }
    if isEmpty       { return false }
    
    return self.withCString { selfCS in
      return other.withCString { pCS in
        return Glibc.strstr(selfCS, pCS) != nil
      }
    }
  }
  
  public func substringToIndex(idx: Index) -> String {
    let range = self[self.startIndex..<idx]
    return String(range)
  }
}

#endif /* Swift 2.2 */
#endif /* Linux */
