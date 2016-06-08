//
//  MustachParser.swift
//  TestMustache
//
//  Created by Helge Heß on 6/1/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if swift(>=3.0) // #swift3-ptr
#else // Swift 2.2

public class MustacheParser {
  
  public init() {}
  
  enum MustacheToken {
    case Text(String)
    case Tag(String)
    case UnescapedTag(String)
    case SectionStart(String)
    case InvertedSectionStart(String)
    case SectionEnd(String)
    case Partial(String)
  }
  
  var start   : UnsafePointer<CChar> = nil
  var p       : UnsafePointer<CChar> = nil
  var cStart  : CChar = 123 // {
  var cEnd    : CChar = 125 // }
  var sStart  : CChar =  35 // #
  var isStart : CChar =  94 // ^
  var sEnd    : CChar =  47 // /
  var ueStart : CChar =  38 // &
  var pStart  : CChar =  62 // >
  
  public var openCharacter : Character {
    set {
      let s = String(newValue).unicodeScalars
      cStart = CChar(s[s.startIndex].value)
    }
    get { return Character(UnicodeScalar(UInt32(cStart))) }
  }
  public var closeCharacter : Character {
    set {
      let s = String(newValue).unicodeScalars
      cEnd = CChar(s[s.startIndex].value)
    }
    get { return Character(UnicodeScalar(UInt32(cEnd))) }
  }
  
  
  // MARK: - Client Funcs
  
  public func parse(string s: String) -> MustacheNode {
    return s.withCString { cs in
      parse(cstr: cs)
    }
  }
  
  var root : MustacheNode! = nil
  
  public func parse(cstr cs: UnsafePointer<CChar>) -> MustacheNode {
    if cs.memory == 0 { return .Empty }
    
    start = cs
    p     = start
    
    guard let nodes = parseNodes() else { return .Empty }
    return .Global(nodes)
  }
  
  
  // MARK: - Parsing
  
  func parseNodes(section s: String? = nil) -> [ MustacheNode ]? {
    if p.memory == 0 { return nil }
    
    var nodes = [ MustacheNode ]()
    
    while let node = parseNode(sectionEnd: s) {
      switch node {
        case .Empty: continue
        default: break
      }
      
      nodes.append(node)
    }
    
    return nodes
  }
  
  func parseNode(sectionEnd se: String? = nil) -> MustacheNode? {
    guard let token = parseTagOrText() else { return nil }
    //print("PARSED: \(token)")
    
    switch token {
      case .Text        (let s): return .Text(s)
      case .Tag         (let s): return .Tag(s)
      case .UnescapedTag(let s): return .UnescapedTag(s)
      case .Partial     (let s): return .Partial(s)
  
      case .SectionStart(let s):
        guard let children = parseNodes(section: s) else { return .Empty }
        return .Section(s, children)
      
      case .InvertedSectionStart(let s):
        guard let children = parseNodes(section: s) else { return .Empty }
        return .InvertedSection(s, children)
      
      case .SectionEnd(let s):
        if !s.isEmpty && s != se {
          print("section tags not balanced: \(s) expected \(se)")
        }
        return nil
    }
  }
  
  
  // MARK: - Lexing
  
  func parseTagOrText() -> MustacheToken? {
    if p.memory == 0 { return nil }
    
    if p.memory == cStart && la1 == cStart {
      return parseTag()
    }
    else {
      return .Text(parseText())
    }
  }
  
  func parseTag() -> MustacheToken {
    guard p.memory == cStart && la1 == cStart else { return .Text("") }
    
    let isUnescaped = la2 == cStart
    
    let start  = p
    p += isUnescaped ? 3 : 2 // skip {{
    let marker = p
    
    while p.memory != 0 {
      if p.memory == cEnd && la1 == cEnd && (!isUnescaped || la2 == cEnd) {
        // found end
        let len = p - marker
        
        if isUnescaped {
          p += 3 // skip }}}
          let s = String.fromCString(marker, length: len)!
          return .UnescapedTag(s)
        }
        
        p += 2 // skip }}
        
        let typec = marker.memory
        switch typec {
          
          case sStart: // #
            let s = String.fromCString(marker + 1, length: len - 1)!
            return .SectionStart(s)
          
          case isStart: // ^
            let s = String.fromCString(marker + 1, length: len - 1)!
            return .InvertedSectionStart(s)
          
          case sEnd: // /
            let s = String.fromCString(marker + 1, length: len - 1)!
            return .SectionEnd(s)
          
          case pStart: // >
            var n = marker + 1 // skip >
            while n.memory == 32 { n += 1 } // skip spaces
            let len = p - n - 2
            let s = String.fromCString(n, length: len)!
            return .Partial(s)
          
          case ueStart /* & */:
            if (marker + 1).memory == 32 {
              let s = String.fromCString(marker + 2, length: len - 2)!
              return .UnescapedTag(s)
            }
            fallthrough
          
          default:
            let s = String.fromCString(marker, length: len)!
            return .Tag(s)
        }
      }
      
      p += 1
    }
    
    return .Text(String.fromCString(start)!)
  }
  
  func parseText() -> String {
    let start = p

    while p.memory != 0 {
      if p.memory == cStart && la1 == cStart {
        return String.fromCString(start, length: p - start)!
      }
      
      p += 1
    }
    
    return String.fromCString(start)!
  }
  
  var la0 : CChar { return p != nil ? p.memory : 0 }
  var la1 : CChar { return la0 != 0 ? (p + 1).memory : 0 }
  var la2 : CChar { return la1 != 0 ? (p + 2).memory : 0 }
}

#if os(Linux)
import func Glibc.memcpy
#else
import func Darwin.memcpy
#endif

extension String {
  
  static func fromCString(cs: UnsafePointer<CChar>, length olength: Int?) -> String? {
    guard let length = olength else { // no length given, use \0 std imp
      return String.fromCString(cs)
    }
    
    let buflen = length + 1
    let buf    = UnsafeMutablePointer<CChar>.alloc(buflen)
    memcpy(buf, cs, length)
    buf[length] = 0 // zero terminate

    let s = String.fromCString(buf)
    buf.dealloc(buflen)
    return s
  }
}

#endif // Swift 2.2
