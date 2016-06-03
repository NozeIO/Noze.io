//
//  MustacheRenderer.swift
//  TestMustache
//
//  Created by Helge Heß on 6/1/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

// TODO: This doesn't HTML escape yet. Easy to add ;-)

#if swift(>=3.0) // #swift3-inout
#else // Swift 2.2

public extension MustacheNode {
  
  public func render(object o: Any?) -> String {
    var s = ""
    render(intoString: &s, cursor: o)
    return s
  }
  
  public func render(inout intoString s: String, cursor: Any?) {
    
    func render(nodes nl: [MustacheNode],
                inout intoString s: String, cursor: Any?)
    {
      nl.forEach { node in node.render(intoString: &s, cursor: cursor) }
    }
    
    switch self {
      case Empty: return
      
      case Global(let nodes):
        render(nodes: nodes, intoString: &s, cursor: cursor)
      
      case Text(let text):
        s += text
          
      case Section(let tag, let nodes):
        let v = KeyValueCoding.value(forKeyPath: tag, inObject: cursor)
        guard let vv = v else { return } // nil
        
        guard isMustacheTrue(value: vv) else { return }
        
        let mirror = Mirror(reflecting: vv)
        let ds     = mirror.displayStyle
        
        if ds == nil { // e.g. Bool
          render(nodes: nodes, intoString: &s, cursor: cursor)
          return
        }
        
        switch ds! {
          case .Collection:
            for ( _, value ) in mirror.children {
              render(nodes: nodes, intoString: &s, cursor: value)
            }

          case .Class, .Dictionary: // adjust cursor
            if isFoundationBaseType(value: vv) {
              render(nodes: nodes, intoString: &s, cursor: cursor)
            }
            else {
              render(nodes: nodes, intoString: &s, cursor: vv)
            }
          
          default:
            // keep cursor for non-collections?
            render(nodes: nodes, intoString: &s, cursor: cursor)
        }
      
      case InvertedSection(let tag, let nodes):
        let v = KeyValueCoding.value(forKeyPath: tag, inObject: cursor)
        guard !isMustacheTrue(value: v) else { return }
        nodes.forEach { node in node.render(intoString: &s, cursor: cursor) }
      
      case Tag(let tag):
        if let v = KeyValueCoding.value(forKeyPath: tag, inObject: cursor) {
          // TODO: HTML escape
          s += "\(v)"
        }
      
      case UnescapedTag(let tag):
        if let v = KeyValueCoding.value(forKeyPath: tag, inObject: cursor) {
          s += "\(v)"
        }
    }
  }
  
}

#endif // Swift 2.2
