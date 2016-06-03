//
//  Messages.swift
//  NozeIO
//
//  Created by Helge Heß on 4/27/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

// MARK: - Messages

public struct Warning {
  let name    : String
  let message : String
  let error   : ErrorType?
  // us have nope stack
  
  init(name: String, message: String? = nil, error: ErrorType? = nil) {
    self.name    = name
    self.error   = error
    
    if let s = message {
      self.message = s
    }
    else if let e = error {
      self.message = "\(e)"
    }
    else {
      self.message = "Unknown Error"
    }
  }
}

extension NozeProcess {
  func emit(warning w: Warning) {
    print("(noze: \(pid)): \(w.name): \(w.message)")
    self.warningListeners.emit(w)
  }
}

public func emitWarning(warning: String, name: String = "Warning") {
  module.emit(warning: Warning(name: name, message: warning))
}
public func emitWarning(warning: ErrorType, name: String = "Warning") {
  module.emit(warning: Warning(name: name, error: warning))
}

#if swift(>=3.0) // #swift3-1st-arg
public func emitWarning(_ warning: String, name: String = "Warning") {
  module.emit(warning: Warning(name: name, message: warning))
}
public func emitWarning(_ warning: ErrorType, name: String = "Warning") {
  module.emit(warning: Warning(name: name, error: warning))
}
#endif
