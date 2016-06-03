//
//  QueryString.swift
//  Noze.io
//
//  Created by Helge Heß on 5/17/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if swift(>=3.0)
import Foundation // for String.hasPrefix/hasSuffix
#endif

import core
import console

public class QueryStringModule : NozeModule {
  // TODO: doesn't really belong here, but well.
  // TODO: stringify etc
  // TODO: this is a little funky because URL parsing really happens at a byte
  //       level (% decoding etc)
  
#if swift(>=3.0) // #swift3-1st-arg
  public func parse(_ string      : String,
                    separator     : Character = "&",
                    pairSeparator : Character = "=",
                    decodeURIComponent : (( String ) -> String) = _unescape)
              -> Dictionary<String, Any>
  {
    return _parse(string: string,
                  separator: separator, pairSeparator: pairSeparator,
                  decodeURIComponent: decodeURIComponent)
  }
#else
  public func parse(string        : String,
                    separator     : Character = "&",
                    pairSeparator : Character = "=",
                    decodeURIComponent : (( String ) -> String) = _unescape)
              -> Dictionary<String, Any>
  {
    return _parse(string: string,
                  separator: separator, pairSeparator: pairSeparator,
                  decodeURIComponent: decodeURIComponent)
  }
#endif
}
public let querystring = QueryStringModule()


// MARK: - Implementation

private func _parse(string s     : String,
                    separator     : Character = "&",
                    pairSeparator : Character = "=",
                    emptyValue    : Any       = "",
                    zopeFormats   : Bool      = true,
                    decodeURIComponent : (( String ) -> String) = _unescape)
     -> Dictionary<String, Any>
{
  guard !s.isEmpty else { return [:] }
  
  var qp = Dictionary<String, Any>()
  
  let pairs = s.characters.split(separator: separator,
                                      omittingEmptySubsequences: true)
  for pair in pairs {
    let pairParts = pair.split(separator: pairSeparator,
                               omittingEmptySubsequences: true, maxSplits: 1)
    guard !pairParts.isEmpty else { continue }
    
    // check key and whether it contains Zope style formats
    
    let keyPart = pairParts[0]
    let fmtIdx  = keyPart.index(of: ":")
    let key     : String
    let formats : String?
    
    if zopeFormats && fmtIdx != nil  {
      key     = String(keyPart[keyPart.startIndex..<fmtIdx!])
      formats =
        String(keyPart[keyPart.index(after: fmtIdx!)..<keyPart.endIndex])
    }
    else {
      key     = String(keyPart)
      formats = nil
    }
    
    // check whether there is a key but no value ...
    
    if pairParts.count == 1 {
      if qp[key] == nil {
        qp[key] = emptyValue
      }
      continue
    }
    
    // get value
    
    let rawValue = decodeURIComponent(String(pairParts[1]))
    let value : Any
    
    if let formats = formats {
      // TODO: record, list, tuple, array:
      //       e.g.: person.age:int:record
      if formats.hasPrefix("list") || formats.hasPrefix("tuple") ||
         formats.hasPrefix("array")
      {
        console.error("list parameter not yet implement: \(formats)")
        value = rawValue
      }
      else if formats.hasPrefix("record") {
        console.error("record parameter not yet implement: \(formats)")
        value = rawValue
      }
      else {
        if let zvalue = parseZQPValue(string: rawValue, format: formats) {
          value = zvalue
        }
        else {
          continue // TBD: skip
        }
      }
    }
    else {
      value = rawValue
    }
    
    if let existingValue = qp[key] {
      var a : Array<Any>
      if let aa = existingValue as? Array<Any> {
        a = aa
      }
      else {
        a = Array<Any>()
        a.append(existingValue)
      }
      a.append(value)
      qp[key] = a
    }
    else {
      qp[key] = value
    }
  }
  
  return qp
}


/// Zope like value formatter
///
/// As explained in 
/// [Passing Parameters to Scripts](http://www.faqs.org/docs/ZopeBook/ScriptingZope.html)
///
/// You can annotate form names with "filters" to convert strings being
/// passed in by browsers into objects, eg:
///
///     <input type="text" name="age:int" />
///
/// When the browser submits the form, "age:int" will initially be stored
/// as a string. This method will detect the ":int" suffix and create an
/// Integer object keyed under 'age'. That is, you will be able to do this:
///
///     let age = qp["age"] as? Int
///
/// The facility is quite powerful, eg filters can be nested.
///
public func parseZQPValue(string s: String, format: String) -> Any? {
  // TODO: date, tokens, required
  switch format {
    case "int", "long": return Int(s)
    case "float":       return Float(s)
    case "string":      return s
    
    case "text":
      return String(s.characters.filter({$0 != "\r"}))
    
    case "lines":
      let lines = s.characters.filter({$0 != "\r"}).split(separator: "\n")
      return lines.map { String($0) }
    
    case "boolean":
      switch s {
        case "1", "Y", "y", "yes", "YES", "on", "ON": return true
        default: return false
      }
    
    case "ignore_empty":
      return s.isEmpty ? nil : s
    
    case "method", "action", "default_method", "default_action":
      return s
    
    default:
      console.error("Unsupported query value format: \(format)")
      return s
  }
}

/// %-unescape a string.
private func _unescape(string: String) -> String {
  // FIXME: crappy&slow implementation, do this better.
  // Also: this should be based on bytes, not Strings
  let s = string.characters
  
  guard s.index(of: "%") != nil || s.index(of: "+") != nil else {
    return string
  }
  
  var newString = [ UInt8 ]()
  
  func append(character c: Character) {
    // yup, this is super-lame
    newString.append(contentsOf: String(c).utf8)
  }
  
  var idx = s.startIndex
  while idx != s.endIndex {
    let c0 = s[idx]

    if c0 == "+" {
      newString.append(32)
      idx = s.index(after: idx)
      continue
    }
    
    if c0 != "%" {
      append(character: c0)
      idx = s.index(after: idx)
      continue
    }
    
    let idx1 = s.index(after: idx)
    let idx2 = idx1 != s.endIndex ? s.index(after: idx1) : s.endIndex
    if idx1 == s.endIndex || idx2 == s.endIndex {
      append(character: c0)
      idx = s.index(after: idx)
      continue
    }
    
    if let value = Int(String(s[idx1...idx2]), radix: 16) {
      assert(value >= 0 && value < 256)
      newString.append(UInt8(value))
      idx = s.index(after: idx2)
    }
    else {
      append(character: c0)
      idx = s.index(after: idx)
    }
  }
  
  newString.append(0) // zero terminate
  
  return newString.withUnsafeBufferPointer { bp in
    let p = UnsafePointer<CChar>(bp.baseAddress)
#if swift(>=3.0) // #swift3-fd
    return String(cString: p!)
#else
    return String.fromCString(p)!
#endif
  }
}

