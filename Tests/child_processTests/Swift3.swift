//
//  Swift3.swift
//  NozeIO
//
//  Created by Helge Heß on 5/1/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if swift(>=3.0) // #swift3-fd
#else
extension String {
  func contains(needle: String) -> Bool {
    return self.containsString(needle)
  }
}
#endif
