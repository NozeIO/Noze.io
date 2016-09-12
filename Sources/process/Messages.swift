//
//  Messages.swift
//  Noze.io
//
//  Created by Helge Heß on 4/27/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

// MARK: - Messages

public struct Warning {
  let name    : String
  let message : String
  let error   : Error?
  // us have nope stack
  
  init(name: String, message: String? = nil, error: Error? = nil) {
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

public func emitWarning(_ warning: String, name: String = "Warning") {
  module.emit(warning: Warning(name: name, message: warning))
}
public func emitWarning(_ warning: Error, name: String = "Warning") {
  module.emit(warning: Warning(name: name, error: warning))
}
