//
//  String2StreamPipe.swift
//  Noze.io
//
//  Created by Helge Heß on 5/1/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if swift(>=3.0) // #swift3-discardable-result
  
/// Pipe operator for Strings into UTF-8 byte streams
///
/// Like so:
///
///     "Hello World!" | zip | encrypt | fs
///
public func |<TO: GWritableStreamType>
             (left: String, right: TO) -> TO
             where TO.WriteType == UInt8
{
  return left.utf8.pipe(right)
}

/// Pipe operator for Strings into UnicodeScalar streams
///
public func |<TO: GWritableStreamType>
             (left: String, right: TO) -> TO
             where TO.WriteType == UnicodeScalar
{
  return left.unicodeScalars.pipe(right)
}

/// Pipe operator for Strings into Character streams
///
public func |<TO: GWritableStreamType>
             (left: String, right: TO) -> TO
             where TO.WriteType == Character
{
  return left.characters.pipe(right)
}


#else // Swift 2.x
/// Pipe operator for Strings into UTF-8 byte streams
///
/// Like so:
///
///     "Hello World!" | zip | encrypt | fs
///
public func |<TO: GWritableStreamType where TO.WriteType == UInt8>
            (left: String, right: TO) -> TO
{
  return left.utf8.pipe(right)
}

/// Pipe operator for Strings into UnicodeScalar streams
///
public func |<TO: GWritableStreamType where TO.WriteType == UnicodeScalar>
            (left: String, right: TO) -> TO
{
  return left.unicodeScalars.pipe(right)
}

/// Pipe operator for Strings into Character streams
///
public func |<TO: GWritableStreamType where TO.WriteType == Character>
            (left: String, right: TO) -> TO
{
  return left.characters.pipe(right)
}

#endif // Swift 2.x
