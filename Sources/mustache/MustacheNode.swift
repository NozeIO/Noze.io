//
//  MustacheNode.swift
//  Noze.io
//
//  Created by Helge Heß on 6/1/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

/// One node of the Mustache template. A template is parsed into a tree of the
/// various nodes.
public enum MustacheNode {
  
  case Empty
  
  /// Represents the top-level node of a Mustache template, contains the list
  /// of nodes.
  case Global([ MustacheNode])
  
  /// Regular CDATA in the template
  case Text(String)
  
  /// A section, can be either a repetition (if the value evaluates to a 
  /// Sequence) or a conditional (if the value resolves to true/false).
  /// If the value is false or an empty list, the contained nodes won't be
  /// rendered.
  /// If the value is a Sequence, the contained items will be rendered n-times,
  /// once for each member. The rendering context is changed to the item before
  /// rendering.
  /// If the value is not a Sequence, but considered 'true', the contained nodes
  /// will get rendered once.
  ///
  /// A Mustache section is introduced with a "{{#" tag and ends with a "{{/"
  /// tag.
  /// Example:
  ///
  ///     {{#addresses}}
  ///       Has address in: {{city}}
  ///     {{/addresses}}
  ///
  case Section(String, [ MustacheNode ])
  
  /// An inverted section either displays its contents or not, it never repeats.
  ///
  /// If the value is 'false' or an empty list, the contained nodes will get
  /// rendered.
  /// If it is 'true' or a non-empty list, it won't get rendered.
  ///
  /// An inverted section is introduced with a "{{^" tag and ends with a "{{/"
  /// tag.
  /// Example:
  ///
  ///     {{^addresses}}
  ///       The person has no addresses assigned.
  ///     {{/addresses}}
  ///
  case InvertedSection(String, [ MustacheNode ])
  
  /// A Mustache Variable. Will try to lookup the given string as a name in the
  /// current context. If the current context doesn't have the name, the lookup
  /// is supposed to continue at the parent contexts.
  ///
  /// The resulting value will be HTML escaped.
  ///
  /// Example:
  ///
  ///     {{city}}
  ///
  case Tag(String)
  
  /// This is the same like Tag, but the value won't be HTML escaped.
  ///
  /// Use triple braces for unescaped variables:
  ///
  ///     {{{htmlToEmbed}}}
  ///
  /// Or use an ampersand, like so:
  ///
  ///     {{^ htmlToEmbed}}
  ///
  case UnescapedTag(String)
  
  /// A partial. How this is looked up depends on the rendering context
  /// implementation.
  ///
  /// Partials are included via "{{>", like so:
  ///
  ///     {{#names}}
  ///       {{> user}}
  ///     {{/names}}
  ///
  case Partial(String)
}


// MARK: - Rendering

public extension MustacheNode {
  
  public func render(object o: Any?, cb: ( String ) -> Void) {
    let ctx = MustacheDefaultRenderingContext(o)
    render(inContext: ctx, cb: cb)
  }
  
  public func render(object o: Any?) -> String {
    let ctx = MustacheDefaultRenderingContext(o)
    render(inContext: ctx)
    return ctx.string
  }
  
  func render(nodes     nl  : [MustacheNode],
              inContext ctx : MustacheRenderingContext)
  {
    nl.forEach { node in node.render(inContext: ctx) }
  }
  
  public func render(inContext ctx: MustacheRenderingContext,
                     cb: ( String ) -> Void)
  {
    render(inContext: ctx) // TODO: make async for partials
    cb(ctx.string)
  }
  
  public func render(inContext ctx: MustacheRenderingContext) {
    
    switch self {
      case Empty: return
      
      case Global(let nodes):
        render(nodes: nodes, inContext: ctx)
      
      case Text(let text):
        ctx.append(string: text)
          
      case Section(let tag, let nodes):
        render(section: tag, nodes: nodes, inContext: ctx)
      
      case InvertedSection(let tag, let nodes):
        let v = ctx.value(forTag: tag)
        guard !ctx.isMustacheTrue(value: v) else { return }
        render(nodes: nodes, inContext: ctx)
      
      case Tag(let tag):
        if let v = ctx.value(forTag: tag) {
          if let s = v as? String {
            ctx.append(string: ctx.escape(string: s))
          }
          else {
            ctx.append(string: ctx.escape(string: "\(v)"))
          }
        }
      
      case UnescapedTag(let tag):
        if let v = ctx.value(forTag: tag) {
          if let s = v as? String {
            ctx.append(string: s)
          }
          else {
            ctx.append(string: "\(v)")
          }
        }
      
      case Partial(let name):
        guard let partial = ctx.retrievePartial(name: name) else { return }
        partial.render(inContext: ctx)
    }
  }
  
  public func render(lambda    cb  : MustacheRenderingFunction,
                     nodes     nl  : [ MustacheNode ],
                     inContext ctx : MustacheRenderingContext)
  {
    let mustache = nl.asMustacheString
    let result = cb(mustache) { mustacheToRender in
      
      let tree : MustacheNode
      if mustache == mustacheToRender { // slow, lame
        tree = MustacheNode.Global(nl)
      }
      else { // got a new sub-template to render by the callback
        let parser = MustacheParser()
        tree = parser.parse(string: mustache)
      }
      
      let lambdaCtx = ctx.newLambdaContext()
      
      tree.render(inContext: lambdaCtx)
      
      return lambdaCtx.string
    }
    ctx.append(string: result)
  }
}


// MARK: - Convert parsed nodes back to a String template

public extension MustacheNode {
  
  public var asMustacheString : String {
    var s = String()
    self.append(toString: &s)
    return s
  }
}
