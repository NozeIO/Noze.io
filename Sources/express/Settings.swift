//
//  Settings.swift
//  Noze.io
//
//  Created by Helge Hess on 02/06/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

public protocol SettingsHolder {
  
  func set(key: String, _ value: Any?)
  func get(key: String) -> Any?
  
}

public extension SettingsHolder {
  
  public func enable(key: String) {
    set(key, true)
  }
  public func disable(key: String) {
    set(key, false)
  }
  
  public subscript(setting key : String) -> Any? {
    get { return get(key)    }
    set { set(key, newValue) }
  }

}

// MARK: - Swift 3 Helpers

#if swift(>=3.0) // #swift3-1st-arg #swift3-discardable-result
public extension SettingsHolder {
  
  public func set(_ key: String, _ value: Any?) { set(key: key, value) }
  public func get(_ key: String) -> Any?        { return get(key: key) }
  
  public func enable (_ key: String) { enable (key: key) }
  public func disable(_ key: String) { disable(key: key) }
}
#endif // Swift 3+
