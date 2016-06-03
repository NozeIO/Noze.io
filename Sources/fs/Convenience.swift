//
//  Convenience.swift
//  NozeIO
//
//  Created by Helge Heß on 5/8/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import streams

// MARK: - Convenience Read * Write Methods

/// Asynchronously reads the entire contents of a file.
public func readFile(path: String, cb: DataCB) {
  // TODO: support open-flags (r+, a, etc)
  let s = createReadStream(path) | concat { bucket in
    cb(bucket, nil)
  }
  // TODO: directly attaching onError crashes swiftc (2016-05-06)
  _ = s.onError { error in cb(nil, error) }
}

/// Asynchronously reads the entire contents of a file into a string.
public func readFile(path: String, _ encoding: String, cb: StringCB) {
  // Note: The encoding does not default to utf-8 because otherwise we need to 
  //       explicitly type the closure on the caller site - which happens to be
  //       inconvenient, which is something we do not appreciated.
  //       (otherwise there is ambiguity between readFile ByteBucket and String.
  // TODO: support open-flags (r+, a, etc)
#if swift(>=3.0) // #swift3-fd
  let enc = encoding.lowercased()
#else
  let enc = encoding.lowercaseString
#endif
  guard enc == "utf8" else {
    cb(nil, EncodingError.UnsupportedEncoding(encoding))
    return
  }
  
  let s = createReadStream(path) | utf8 | concat { characters in
    let string = String(characters)
    cb(string, nil)
  }
  // TODO: directly attaching onError crashes swiftc (2016-05-06)
  _ = s.onError { error in cb(nil, error) }
}


/// Asynchronously writes data to a file, replacing the file if it already
/// exists.
///
/// NOTE: The creator of Noze begs you not to use this method. Please stream
///       your write.
public func writeFile(path: String, _ data: [ UInt8 ], cb: ErrorCB) {
  // TODO: support open-flags (r+, a, etc)
  _ = data | createWriteStream(path, hwm: data.count)
             .onFinish { cb(nil) }
             .onError  { error in cb(error) }
}

/// Asynchronously writes string to a file, replacing the file if it already
/// exists.
///
/// NOTE: The creator of Noze begs you not to use this method. Please stream
///       your write.
public func writeFile(path: String, _ string: String, cb: ErrorCB) {
  // TODO: support open-flags (r+, a, etc)
  _ = string.utf8 | createWriteStream(path)
                    .onFinish { cb(nil) }
                    .onError  { error in cb(error) }
}


#if swift(>=3.0) // #swift3-1st-kwarg
public func readFile(_ path: String, cb: DataCB) {
  readFile(path: path, cb: cb)
}
public func readFile(_ path: String, _ encoding: String, cb: StringCB) {
  readFile(path: path, encoding, cb: cb)
}
public func writeFile(_ path: String, _ data: [ UInt8 ], cb: ErrorCB) {
  writeFile(path: path, data, cb: cb)
}
public func writeFile(_ path: String, _ string: String, cb: ErrorCB) {
  writeFile(path: path, string, cb: cb)
}
#endif
