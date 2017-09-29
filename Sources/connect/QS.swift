//
//  QS.swift
//  ExExpress
//
//  Created by Helge Hess on 02.05.17.
//  Copyright © 2017 ZeeZide GmbH. All rights reserved.
//

public enum qs {
  // TODO: doesn't really belong here, but well.
  // TODO: stringify etc
  // TODO: this is a little funky because URL parsing really happens at a byte
  //       level (% decoding etc)
  
  public class Options {
    let separator      : Character = "&"
    let pairSeparator  : Character = "="
    let depth          : Int       = 5
    let parameterLimit : Int       = 1000
    let arrayLimit     : Int       = 20
    let allowsDot      : Bool      = false
  }

  class EmptyArraySlot {}
  public static let sparseArrayDefaultValue : Any = EmptyArraySlot()
  
  public static func parse(_ string       : String,
                           separator      : Character = "&",
                           pairSeparator  : Character = "=",
                           depth          : Int       = 5,
                           parameterLimit : Int       = 1000,
                           arrayLimit     : Int       = 20,
                           allowsDot      : Bool      = false,
                           decodeURIComponent dd:
                                       (( String ) -> String)? = nil)
                     -> Dictionary<String, Any>
  {
    let decodeURIComponent = dd ?? _unescape
    if allowsDot { fatalError("allowsDot unsupported") }

    let parsedQV = RefStringAnyDictionary()
    var count = 0
    let pairs = string.characters.split(separator: separator,
                                        omittingEmptySubsequences: true)
    for pair in pairs {
      guard count < parameterLimit else { break }
      count += 1
      
      let pairParts = pair.split(separator: pairSeparator,
                                 maxSplits: 1,
                                 omittingEmptySubsequences: true)
      guard !pairParts.isEmpty else { continue }
    
      let key   = decodeURIComponent(String(pairParts[0]))
      let value = pairParts.count > 1
                  ? decodeURIComponent(String(pairParts[1])) : ""
          
      let kp = parseKeyPath(key, depth: depth, allowsDot: allowsDot)
      guard kp.count > 1 else {
        parsedQV[key] = value
        continue
      }
      
      // TODO: validate kp, e.g. must begin with name
      
      // Oh my. All this code :-0 This needs a rewrite, ugly.
      // FIXME: I don't like this :-)
      
      enum CursorType {
        case Dict(RefStringAnyDictionary)
        case Array(RefAnyArray)
        case Other(Any)
      }
      
      var cursor = CursorType.Dict(parsedQV)
      
      for idx in 0..<(kp.count - 1) {
        let part = kp[idx]
        let next = kp[idx + 1]
        
        switch part {
          case .Key(let name):
            guard case .Dict(let cursorDict) = cursor else {
              assertionFailure("expected dictionary for key")
              break
            }
            
            if let currentValue = cursorDict[name] { // has a value already
              if case .Key(_) = next {
                // if the next is a key, we must have a dictionary
                if currentValue is RefStringAnyDictionary {
                  // all good
                }
                else if let array = currentValue as? RefAnyArray {
                  let newValue = RefStringAnyDictionary()
                  for i in 0..<array.count {
                    newValue["\(i)"] = array[i]
                  }
                  cursorDict[name] = newValue
                }
                else {
                  assertionFailure("unexpected object: \(currentValue)")
                  break
                }
              }
            }
            else { // no value
              switch next {
                case .Key(_):
                  cursorDict[name] = RefStringAnyDictionary()
                case .Array, .Index(_):
                  cursorDict[name] = RefAnyArray()
                case .Error(let msg):
                  assertionFailure("error: \(msg)")
                  break
              }
            }
          
            if let nextCursor = cursorDict[name] {
              if let rd = nextCursor as? RefStringAnyDictionary {
                cursor = .Dict(rd)
              }
              else if let ra = nextCursor as? RefAnyArray {
                cursor = .Array(ra)
              }
              else {
                assertionFailure("unexpected object: \(nextCursor)")
                cursor = .Other(nextCursor)
              }
            }
          
          case .Array:
            // e.g.: "a[][b]=10&a[][c]=20"
            guard case .Array(let cursorArray) = cursor else {
              assertionFailure("expected array for key")
              break
            }
            // w/ [] we always append aka create a new value
            switch next {
              case .Key(_):
                let nextValue = RefStringAnyDictionary()
                cursorArray.append(nextValue)
                cursor = .Dict(nextValue)
              case .Array, .Index(_):
                let nextValue = RefAnyArray()
                cursorArray.append(nextValue)
                cursor = .Array(nextValue)
              case .Error(let msg):
                assertionFailure("error: \(msg)")
                break
            }
          
          case .Index(let idx):
            switch cursor {
              case .Dict(let cursorDict): // mixed
                let name = "\(idx)"
                if let _ /*currentValue*/ = cursorDict[name] {
                  // TODO
                }
                else {
                  // TODO
                }
                assert(false, "mixed values, unsupported")
                break
              
              case .Array(let cursorArray):
                cursorArray.ensureSize(idx + 1,
                                       defaultValue: sparseArrayDefaultValue)
                let currentValue = cursorArray[idx]
                if !(currentValue is EmptyArraySlot) {
                  if let rd = currentValue as? RefStringAnyDictionary {
                    cursor = .Dict(rd)
                  }
                  else if let ra = currentValue as? RefAnyArray {
                    cursor = .Array(ra)
                  }
                  else {
                    assertionFailure("unexpected object: \(currentValue)")
                    cursor = .Other(currentValue)
                  }
                }
                else {
                  switch next {
                    case .Key(_):
                      let nextValue = RefStringAnyDictionary()
                      cursorArray[idx] = nextValue
                      cursor = .Dict(nextValue)
                    case .Array, .Index(_):
                      let nextValue = RefAnyArray()
                      cursorArray[idx] = nextValue
                      cursor = .Array(nextValue)
                    case .Error(let msg):
                      assertionFailure("error: \(msg)")
                      break
                  }
                }
              
              default:
                assertionFailure("unexpected object: \(cursor)")
            }
          
          default:
            assertionFailure("not implemented: non-dict part: \(part)")
            break
        }
      }
      
      let lastPart = kp[kp.count - 1]
      switch lastPart {
        case .Key(let name):
          guard case .Dict(let cursorDict) = cursor else {
            assertionFailure("expected dictionary for key")
            break
          }
          cursorDict[name] = value
        
        case .Array:
          guard case .Array(let cursorArray) = cursor else {
            assertionFailure("expected array")
            break
          }
          cursorArray.append(value)
        
        case .Index(let idx):
          switch cursor {
            case .Dict(let cursorDict):
              cursorDict["\(idx)"] = value
            case .Array(let cursorArray):
              cursorArray.ensureSize(idx + 1,
                                     defaultValue: sparseArrayDefaultValue)
              cursorArray[idx] = value
            default:
              assertionFailure("unexpected object: \(cursor)")
          }
        
        default:
          assertionFailure("not implemented: non-dict part: \(lastPart)")
          break
      }      
    }
    
    return parsedQV.flatten() as? Dictionary<String, Any> ?? [:]
  }
}


// Hm

protocol RefTypeFlatten: class {
  
  func flatten() -> Any
  
}

typealias RefAnyArray            = RefArray<Any>
typealias RefStringAnyDictionary = RefDictionary<String, Any>

class RefArray<Element>: RefTypeFlatten {
  
  var storage = Array<Element>()
  
  var isEmpty : Bool { return storage.isEmpty }
  var count   : Int  { return storage.count   }
  
  subscript(key: Int) -> Element {
    set { storage[key] = newValue }
    get { return storage[key]     }
  }

  func ensureSize(_ size: Int, defaultValue: @autoclosure () -> Element) {
    guard count < size else { return }
    
    let value = defaultValue()
    for _ in count..<size {
      append(value)
    }
  }
  
  func append(_ element: Element) {
    storage.append(element)
  }

  func flatten() -> Any {
    var fstorage = Array<Any>()
    fstorage.reserveCapacity(count)
    
    for value in storage {
      if let rd = value as? RefTypeFlatten {
        fstorage.append(rd.flatten())
      }
      else {
        fstorage.append(value)
      }
    }
    return fstorage
  }
}

class RefDictionary<Key : Hashable, Value>: RefTypeFlatten {
  
  var storage = Dictionary<Key, Value>()
  
  var isEmpty : Bool { return storage.isEmpty }
  
  subscript(key: Key) -> Value? {
    set { storage[key] = newValue }
    get { return storage[key]     }
  }
  
  func flatten() -> Any {
    var fstorage = Dictionary<Key, Any>()
    for ( key, value ) in storage {
      if let rd = value as? RefTypeFlatten {
        fstorage[key] = rd.flatten()
      }
      else {
        fstorage[key] = value
      }
    }
    return fstorage
  }
}


// 'foo[bar][baz]=foobarbaz' -> [ "foo": [ "bar": [ "baz": "foobarbaz" ] ] ]
// 'a[]=b&a[]=c')            -> [ "a": [ "b", "c" ] ]
// 'a[1]=b&a[3]=c'           -> [ "a": [ nil, "b", nil, "c" ] ]  (max: 20)
// 'a.b=c' (allowsDot)       -> [ "a": [ "b": "c" ] ]
// 'a[][b]=c'                -> [ "a": [ [ "b": "c" ] ] ]
enum QueryParameterKeyPart {
  case Key(String) // hello or [hello]
  case Index(Int)  // [1]
  case Array       // []
  case Error(String)
}

extension qs {
  
  static func parseKeyPath(_ s: String, depth: Int = 5, allowsDot: Bool)
              -> [ QueryParameterKeyPart ]
  {
    guard !s.isEmpty else { return [] }
    
    var idx      = s.startIndex
    let endIndex = s.endIndex
    
    func consume(_ count: Int = 1) {
      idx = s.index(idx, offsetBy: count)
    }
    func isDigit(_ c: Character) -> Bool {
      switch c {
        case "0", "1", "2", "3", "4", "5", "6", "7", "8", "9": return true
        default: return false
      }
    }
    
    func parseIdentifier() -> String? {
      guard idx < endIndex else { return nil }
      
      var hitDot = false
      var lidx = idx
      while lidx < endIndex {
        if allowsDot && s[lidx] == "." {
          hitDot = true
          break
        }
        if s[lidx] == "[" {
          break
        }
        
        lidx = s.index(after: lidx)
      }
      
      if hitDot {
        let r = s[idx..<lidx]
        idx = s.index(after: lidx)
        return String(r)
      }
      
      let r = s[idx..<lidx]
      idx = lidx
      return String(r)
    }
    
    func parseNumber() -> Int? {
      guard idx < endIndex else { return nil }
      
      var lidx = idx
      while lidx < endIndex {
        guard isDigit(s[lidx]) else { break }
        lidx = s.index(after: lidx)
      }
      
      let sv = s[idx..<lidx]
      idx = lidx
      
      return Int(sv)
    }
    
    func parseSubscript() -> QueryParameterKeyPart? {
      guard idx < endIndex else { return nil }
      guard s[idx] == "["  else { return nil }
      
      consume() // "["
      guard idx < endIndex else { return .Error("lbrack not closed") }
      
      if s[idx] == "]" {
        consume() // ]
        return .Array
      }
      
      if isDigit(s[idx]) {
        guard let v = parseNumber()
         else { return .Error("could not parse number") }
        guard idx < endIndex, s[idx] == "]"
         else { return .Error("lbrack not closed") }
        
        consume() // ]
        return .Index(v)
      }
      
      var lidx = idx
      while lidx < endIndex {
        if s[lidx] == "]" { break }
        lidx = s.index(after: lidx)
      }
      guard lidx < endIndex, s[lidx] == "]"
       else { return .Error("lbrack not closed") }
      
      let r = s[idx..<lidx]
      idx = s.index(after: lidx)
      
      return .Key(String(r))
    }
    
    func parseKeyPart() -> QueryParameterKeyPart? {
      guard idx < endIndex else { return nil }
      
      if s[idx] == "[" {
        return parseSubscript()
      }
      
      guard let kid = parseIdentifier() else { return nil }
      return .Key(kid)
    }
    
    var parts = [ QueryParameterKeyPart ]()
    while let part = parseKeyPart() {
      parts.append(part)
      
      // check depth limit.
      if parts.count > depth {
        if idx < endIndex {
          parts.append(.Key(String(s[idx..<endIndex])))
        }
        break
      }
    }
    return parts
  }
  
}


import Foundation

/// %-unescape a string.
private func _unescape(string: String) -> String {
  return string.replacingOccurrences(of: "+", with: " ")
               .removingPercentEncoding ?? string
}
