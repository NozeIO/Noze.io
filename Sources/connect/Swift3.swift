//
//  Swift3.swift
//  Noze.io
//
//  Created by Helge Hess on 30/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if swift(>=3.0) // #swift3-fd

import Foundation

#else // Swift 2.2

#if os(Linux)
import xsys
#else
import Foundation
#endif

extension String {
  
  func lowercased() -> String {
    return lowercaseString
  }
  
  func contains(needle: String) -> Bool {
    return self.containsString(needle)
  }

  func substring(to index: Index) -> String {
    return substringToIndex(index)
  }
}

#endif // Swift 2.2
