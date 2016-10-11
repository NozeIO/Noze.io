//
//  MustacheRenderingContext.swift
//  Noze.io
//
//  Created by Helge Heß on 6/7/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

public typealias MustacheRenderingFunction =
                   ( String, ( String ) -> String ) -> String
public typealias MustacheSimpleRenderingFunction = ( String ) -> String

public protocol MustacheRenderingContext {
  
  // MARK: - Content Generation
  
  var string : String { get }
  func append(string s: String)

  // MARK: - Cursor
  
  var cursor : Any? { get }
  func enter(scope ctx: Any?)
  func leave()
  
  // MARK: - Value
  
  func value(forTag tag: String) -> Any?
  
  // MARK: - Lambda Context (same stack, empty String)
  
  func newLambdaContext() -> MustacheRenderingContext
  
  // MARK: - Partials
  
  func retrievePartial(name n: String) -> MustacheNode?
}

public extension MustacheRenderingContext {

  public func value(forTag tag: String) -> Any? {
    return KeyValueCoding.value(forKeyPath: tag, inObject: cursor)
  }
  
  public func retrievePartial(name n: String) -> MustacheNode? {
    return nil
  }
}

open class MustacheDefaultRenderingContext : MustacheRenderingContext {
  
  public var string : String = ""
  public var stack  = [ Any? ]() // #linux-public
  
  public init(_ root: Any?) {
    if let a = root {
      stack.append(a)
    }
  }
  public init(context: MustacheDefaultRenderingContext) {
    stack = context.stack
  }
  
  
  // MARK: - Content Generation
  
  public func append(string s: String) {
    string += s
  }
  
  
  // MARK: - Cursor

  public func enter(scope ctx: Any?) {
    stack.append(ctx)
  }
  public func leave() {
    _ = stack.removeLast()
  }
  
  public var cursor : Any? {
    guard let last = stack.last else { return nil }
    return last
  }
  
  
  // MARK: - Value
  
  open func value(forTag tag: String) -> Any? {
    let check = stack.reversed()
    for c in check {
      if let v = KeyValueCoding.value(forKeyPath: tag, inObject: c) {
        return v
      }
    }
    
    return nil
  }
  
  
  // MARK: - Lambda Context (same stack, empty String)
  
  open func newLambdaContext() -> MustacheRenderingContext {
    return MustacheDefaultRenderingContext(context: self)
  }

  
  // MARK: - Partials
  
  open func retrievePartial(name n: String) -> MustacheNode? {
    return nil
  }
}
