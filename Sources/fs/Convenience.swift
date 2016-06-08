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
  let enc = encoding.lowercased()
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


// MARK: - Synchronous Versions (do not use ..)

#if os(Linux)
  import func Glibc.fopen
  import func Glibc.fclose
  import func Glibc.fread
  import func Glibc.memcpy
#else
  import func Darwin.fopen
  import func Darwin.fclose
  import func Darwin.fread
  import func Darwin.memcpy
#endif

public func readFileSync(path: String) -> [ UInt8 ]? {
  #if swift(>=3.0) // #swift3-ptr
    guard let fh = fopen(path, "rb") else { return nil }
  #else
    let fh = fopen(path, "rb")
    if fh == nil { return nil }
  #endif
  defer { fclose(fh) }
  
  let bufsize = 4096
  #if swift(>=3.0) // #swift3-ptr
    let buffer  = UnsafeMutablePointer<UInt8>(allocatingCapacity: bufsize)
    defer { buffer.deallocateCapacity(bufsize) }
  #else
    let buffer  = UnsafeMutablePointer<UInt8>.alloc(bufsize)
    defer { buffer.dealloc(bufsize) }
  #endif
  
  var result = [ UInt8 ]()
  
  repeat {
    let rc = fread(buffer, 1, bufsize, fh)
    
    if rc > 0 {
      // Isn't there a better way? Define an own SequenceType which has a ptr
      // and a length? And then do a appendContentsOf:
      #if swift(>=3.0) // #swift3-fd
        var subbuf = Array<UInt8>(repeating: 0, count: rc)
        _ = subbuf.withUnsafeMutableBufferPointer { bp in
          memcpy(bp.baseAddress!, buffer, rc)
        }
      #else
        var subbuf = Array<UInt8>(count: rc, repeatedValue: 0)
        _ = subbuf.withUnsafeMutableBufferPointer { bp in
          memcpy(bp.baseAddress, buffer, rc)
        }
      #endif
      result.append(contentsOf: subbuf)
    }
    
    if rc < bufsize { // EOF or error
      break
    }
  }
  while true
  
  return result
}

public func readFileSync(path: String, _ encoding: String) -> String? {
  // Note: The encoding does not default to utf-8 because otherwise we need to
  //       explicitly type the closure on the caller site - which happens to be
  //       inconvenient, which is something we do not appreciated.
  //       (otherwise there is ambiguity between readFile ByteBucket and String.
  // TODO: support open-flags (r+, a, etc)
  let enc = encoding.lowercased()
  guard enc == "utf8" else { return nil }

  guard var bytes = readFileSync(path) else { return nil }
  
  bytes.append(0)
  #if swift(>=3.0) // #swift3-fd #swift3-cstr
    return bytes.withUnsafeBufferPointer { bp in
      let cs = UnsafePointer<CChar>(bp.baseAddress)
      return String(cString: cs!)
    }
  #else
    return bytes.withUnsafeBufferPointer { bp in
      let cs = UnsafePointer<CChar>(bp.baseAddress)
      return String.fromCString(cs)
    }
  #endif
}


// MARK: - Swift 3

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

public func readFileSync(_ path: String) -> [ UInt8 ]? {
  return readFileSync(path: path)
}
public func readFileSync(_ path: String, _ encoding: String) -> String? {
  return readFileSync(path: path, encoding)
}
#endif
