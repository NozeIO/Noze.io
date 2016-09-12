//
//  UniqStrings.swift
//  Noze.io
//
//  Created by Helge Hess on 02/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import core

/// Consumes Strings and only emits such which haven't been emitted already.
///
/// That is the same thing like the Unix uniq command ;-)
///
/// Note: This is not a line splitter. Pipe it through `readlines` if you want
///       that.
///
/// IMPORTANT: To make this work in a useful way, you need to make sure that
///            the Readable produces full chunks of Strings! For example by
///            piping stuff through `readlines`.
///            Conceptually a GReadableType<String> can report partial lines as
///            individual streams!
///
public class UniqStrings: TransformStream<String, String> {
  // TODO: add more features like
  // -c     (count the lines)
  // -d/-u  (only report dupes vs only report uniq lines)
  // -f num (ignore first n fields)
  // -s num (ignore first n items)
  // TODO: could be made generic?
  
  let caseInsensitive = false
  let startIndex      = 0
  
  override init(readHWM      : Int? = 1,
                writeHWM     : Int? = 1,
                queue        : DispatchQueue = core.Q,
                enableLogger : Bool = false)
  {
    super.init(readHWM: readHWM, writeHWM: writeHWM, queue: queue,
               enableLogger: enableLogger)
  }
  
  // TBD: we could also store just hashes? This might grow a little big ;-)
  var seenStrings = Set<String>()
  
  public override func _transform(bucket b: [ String ],
                                  done: @escaping ( Error?, [String]? ) -> Void)
  {
    guard !b.isEmpty else {
      done(nil, nil)
      return
    }
    
    var pushBucket : [ String ]? = nil
    
    for i in b.indices {
      let line        = b[i]
      let lSearchLine = searchLine(forLine: line)
      
      if seenStrings.contains(lSearchLine) {
        if pushBucket == nil {
          pushBucket = Array(b[0..<i])
        }
      }
      else {
        seenStrings.insert(lSearchLine)
        
        if pushBucket != nil {
          pushBucket!.append(line)
        }
      }
    }
    
    done(nil, pushBucket ?? b)
  }
  
  final func searchLine(forLine lLine: String) -> String {
    let searchLine : String

    if self.startIndex > 0 {
      let startIndex = lLine.index(lLine.startIndex, offsetBy:self.startIndex)
      let shortLine  = lLine[startIndex..<lLine.endIndex]
      searchLine = caseInsensitive ? shortLine.lowercased() : shortLine
    }
    else {
      searchLine = caseInsensitive ? lLine.lowercased() : lLine
    }
    return searchLine
  }
}
