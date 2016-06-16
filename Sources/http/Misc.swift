//
//  Misc.swift
//  NozeIO
//
//  Created by Helge Heß on 4/29/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import xsys
import streams

// a few static chunks ...
let eolBrigade      : [ [ UInt8 ] ] = [ [ UInt8(13), UInt8(10) ] ]
let colonSepBrigade : [ [ UInt8 ] ] = [ [ UInt8(58), UInt8(32) ] ]
let commaSepBrigade : [ [ UInt8 ] ] = [ [ UInt8(44), UInt8(32) ] ]


public let HTTPDateFormat = "%a, %d %b %Y %H:%M:%S GMT" // TBD: %Z emits UTC

// Generate an HTTP date header value
func generateDateHeader(timestamp ts: time_t = xsys.time(nil)) -> String {
  return ts.componentsInUTC.format(HTTPDateFormat)
}

func writeHeaders<T: GWritableStreamType where T.WriteType == UInt8>
       (toStream out: T, _ headers: Dictionary<String, Any>)
{
  // FIXME: using write(String) is WRONG here, HTTP is ISO-Latin-1, not UTF-8
  for ( name, value ) in headers {
    // print("NAME: \(name): \(value)")
    
    // FIXME: improve this junk
    if let s = value as? String {
      _ = out.write(name)
      _ = out.writev(buckets: colonSepBrigade, done: nil)
      _ = out.write(s)
      _ = out.writev(buckets: eolBrigade, done: nil)
    }
    else if let sa = value as? Array<String> {
      // TBD: Not generating commas but multiple headers.
      for s in sa {
        _ = out.write(name)
        _ = out.writev(buckets: colonSepBrigade, done: nil)
        _ = out.write(s)
        _ = out.writev(buckets: eolBrigade, done: nil)
      }
    }
    else if let s = value as? CustomStringConvertible {
      _ = out.write(name)
      _ = out.writev(buckets: colonSepBrigade, done: nil)
      _ = out.write(s.description)
      _ = out.writev(buckets: eolBrigade, done: nil)
    }
    else {
      fatalError("unexpected header type")
    }
  }
}
