//
//  String2StreamPipe.swift
//  Noze.io
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

/// Pipe operator for Strings into Character streams
///
@discardableResult
public func |<TO: GWritableStreamType>
             (left: String, right: TO) -> TO
             where TO.WriteType == Character
{
  return left.characters.pipe(right)
}
