//
//  String2StreamPipe.swift
//  Noze.io
//
//  Created by Helge Heß on 5/1/16.
//  Copyright © 2016-2017 ZeeZide GmbH. All rights reserved.
//

/// Pipe operator for Strings into UTF-8 byte streams
///
/// Like so:
///
///     "Hello World!" | zip | encrypt | fs
///
@discardableResult
public func |<TO: GWritableStreamType>
             (left: String, right: TO) -> TO
             where TO.WriteType == UInt8
{
  return left.utf8.pipe(right)
}

/// Pipe operator for Strings into UnicodeScalar streams
///
@discardableResult
public func |<TO: GWritableStreamType>
             (left: String, right: TO) -> TO
             where TO.WriteType == UnicodeScalar
{
  return left.unicodeScalars.pipe(right)
}

#if swift(>=3.2) // on Swift 4 the String itself is the char array
#else
/// Pipe operator for Strings into Character streams
///
@discardableResult
public func |<TO: GWritableStreamType>
             (left: String, right: TO) -> TO
             where TO.WriteType == Character
{
  return left.characters.pipe(right)
}
#endif
