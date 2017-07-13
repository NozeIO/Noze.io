//
//  Created by Helge Hess on 07/12/17.
//  Copyright © 2017 ZeeZide GmbH. All rights reserved.
//

import process

enum colors {
  
  static func yellow(_ a: Any?...) -> String {
    return colorize(start: 33, values: a)
  }
  static func green(_ a: Any?...) -> String {
    return colorize(start: 32, values: a)
  }
  static func red(_ a: Any?...) -> String {
    return colorize(start: 31, values: a)
  }
  static func gray(_ a: Any?...) -> String {
    return colorize(start: 90, values: a)
  }
  
  static func colorize(start: Int, end: Int = 39, values: [Any?]) -> String {
    var s = process.isRunningInXCode ? "" : "\u{001b}[\(start)m"
    for v in values {
      if let v = v {
        s += "\(v)"
      }
      else {
        s += "<nil>"
      }
    }
    if !process.isRunningInXCode {
      s += "\u{001b}[\(end)m"
    }
    return s
  }
}
