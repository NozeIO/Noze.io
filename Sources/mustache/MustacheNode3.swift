//
//  MustacheRenderer3.swift
//  Noze.io
//
//  Created by Helge Heß on 6/1/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

// TODO: This doesn't HTML escape yet. Easy to add ;-)

#if swift(>=3.0) // #swift3-inout #swift3-mirror
  
public extension MustacheNode {
  
  public func render(section tag: String, nodes : [ MustacheNode ],
                     inContext ctx: MustacheRenderingContext)
  {
    let v = ctx.value(forTag: tag)
    guard let vv = v else { return } // nil
    
    // Is it a rendering function?

    if let cb = v as? MustacheRenderingFunction {
      render(lambda: cb, nodes: nodes, inContext: ctx)
      return
    }
    else if let cb = vv as? MustacheSimpleRenderingFunction {
      render(lambda: { text, _ in return cb(text) },
             nodes: nodes, inContext: ctx)
    }
  
    // Is it a plain false?
    
    guard ctx.isMustacheTrue(value: vv) else { return }
    
    // Reflect on section value
    
    let mirror = Mirror(reflecting: vv)
    let ds     = mirror.displayStyle
    
    if ds == nil { // e.g. Bool in Swift 3
      render(nodes: nodes, inContext: ctx)
      return
    }
    
    switch ds! {
      case .collection:
        for ( _, value ) in mirror.children {
          ctx.enter(scope: value)
          render(nodes: nodes, inContext: ctx)
          ctx.leave()
        }

      case .class, .dictionary: // adjust cursor
        if ctx.isFoundationBaseType(value: vv) {
          render(nodes: nodes, inContext: ctx)
        }
        else {
          ctx.enter(scope: vv)
          render(nodes: nodes, inContext: ctx)
          ctx.leave()
        }
      
      default:
        // keep cursor for non-collections?
        render(nodes: nodes, inContext: ctx)
    }
  }
  
}


// MARK: - Convert parsed nodes back to a String template

public extension MustacheNode {
  
  public func append(toString s : inout String) {
    switch self {
      case .Empty: return
      
      case .Text(let text):
        s += text
      
      case .Global(let nodes):
        nodes.forEach { $0.append(toString: &s) }
      
      case .Section(let key, let nodes):
        s += "{{#\(key)}}"
        nodes.forEach { $0.append(toString: &s) }
        s += "{{/\(key)}}"
      
      case .InvertedSection(let key, let nodes):
        s += "{{^\(key)}}"
        nodes.forEach { $0.append(toString: &s) }
        s += "{{/\(key)}}"
      
      case .Tag(let key):
        s += "{{\(key)}}"
      
      case .UnescapedTag(let key):
        s += "{{{\(key)}}}"
      
      case .Partial(let key):
        s += "{{> \(key)}}"
    }
  }

}


public extension Sequence where Iterator.Element == MustacheNode {

  public var asMustacheString : String {
    var s = String()
    forEach { $0.append(toString: &s) }
    return s
  }
  
}

#endif // Swift3
