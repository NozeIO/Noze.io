//
//  UUID.swift
//  Noze.io
//
//  Created by Helge Hess on 23/07/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if !os(Linux)
  import Darwin

private func makeArray<T: ExpressibleByIntegerLiteral>(count c: Int) -> [ T ] {
  return Array<T>(repeating: 0, count: c)
}

/// Hm, `uuid_t` is a tuple and can't be extended. Also, you can't really work
/// with that tuple in the C API.
public struct xsys_uuid {
  
  public var arrayValue : [ UInt8 ]
  
  public var value : uuid_t {
    return uuid(fromArray: arrayValue)
  }
  
  
  // MARK: - UUID Generators

  public static func generate() -> xsys_uuid {
    var v : [UInt8] = makeArray(count: 16)
    uuid_generate(&v)
    return xsys_uuid(v)
  }
  
  public static func generateRandom() -> xsys_uuid {
    var v : [UInt8] = makeArray(count: 16)
    uuid_generate_random(&v)
    return xsys_uuid(v)
  }
  
  public static func generateTime() -> xsys_uuid {
    var v : [UInt8] = makeArray(count: 16)
    uuid_generate_time(&v)
    return xsys_uuid(v)
  }
  
  
  // MARK: - Init Structure
  
  public init!(_ uuid: [ UInt8 ]) {
    arrayValue = uuid
  }
  
  public init(_ uuid: uuid_t) {
    var v = Array<UInt8>()
    v.reserveCapacity(16)
    // This can be done with reflection, but presumable that is too expensive
    v.append(uuid.0);  v.append(uuid.1);  v.append(uuid.2);  v.append(uuid.3)
    v.append(uuid.4);  v.append(uuid.5);  v.append(uuid.6);  v.append(uuid.7)
    v.append(uuid.8);  v.append(uuid.9);  v.append(uuid.10); v.append(uuid.11)
    v.append(uuid.12); v.append(uuid.13); v.append(uuid.14); v.append(uuid.15)
    self.arrayValue = v
  }
  
  
  // MARK: - Parse UUID strings
  
  public init?(_ uuid: String) {
    var v  : [UInt8] = makeArray(count: 16)
    let rc : Int32 = uuid.withCString { cs in return uuid_parse(cs, &v) }
    guard rc == 0 else { return nil }
    arrayValue = v
  }
  
  
  // MARK: - String Representation
  
  // TODO: Parse Strings
  
  // TODO: Use Pointer directly, avoid array
  
  public func lowercased() -> String {
    var cs   : [Int8] = makeArray(count: 36 + 1)
    var uuid = arrayValue
    
    uuid_unparse_lower(&uuid, &cs)
    return String(cString: &cs)
  }
  
  public func uppercased() -> String {
    var cs   : [Int8] = makeArray(count: 36 + 1)
    var uuid = arrayValue
    
    uuid_unparse_upper(&uuid, &cs)
    return String(cString: &cs)
  }
  
  public var stringValue : String {
    var cs   : [Int8] = makeArray(count: 36 + 1)
    var uuid = arrayValue
    
    uuid_unparse(&uuid, &cs)
    return String(cString: &cs)
  }
}

extension xsys_uuid : CustomStringConvertible {
  
  public var description : String {
    return stringValue
  }
  
}


// MARK: - Equatable

extension xsys_uuid : Equatable {
}

public func ==(lhs: xsys_uuid, rhs: xsys_uuid) -> Bool {
  return lhs.arrayValue == rhs.arrayValue
}

public func ==(lhs: uuid_t, rhs: uuid_t) -> Bool {
  // Weird that this isn't automatic. Any better way to do this?
  return lhs.0 == rhs.0 && lhs.1 == rhs.1 && lhs.2 == rhs.2 && lhs.3 == rhs.3
      && lhs.4 == rhs.4 && lhs.5 == rhs.5 && lhs.6 == rhs.6 && lhs.7 == rhs.7
      && lhs.8 == rhs.8 && lhs.9 == rhs.9
      && lhs.10 == rhs.10 && lhs.11 == rhs.11
      && lhs.12 == rhs.12 && lhs.13 == rhs.13
      && lhs.14 == rhs.14 && lhs.15 == rhs.15
}


// MARK: - Tuple Helper

func uuid(fromArray v: [UInt8]) -> uuid_t {
  // This is a little stupid, but stick to the exposed Unix API
  return (
    v[0], v[1], v[ 2], v[ 3], v[ 4], v[ 5], v[ 6], v[ 7],
    v[8], v[9], v[10], v[11], v[12], v[13], v[14], v[15]
  )
}

#else
  import Glibc

  // TBD: uuid is not standard on Linux libc, one needs to link to (and install)
  //      libuuid explicitly.
#endif
