//
//  String2StreamPipe.swift
//  NozeIO
//
//  Created by Helge Heß on 5/1/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

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
