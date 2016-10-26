//
//  BasicAuth.swift
//  Noze.io
//
//  Created by Fabian Fett on 26/10/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import base64

public let basicAuth = BasicAuth.self

public class BasicAuth : NozeModule {

  public struct BasicAuthCredentials {
    public let username : String
    public let password : String
  }

  public enum Error : Swift.Error {
    case MissingAuthorizationHeader
    case InvalidBasicAuthorizationHeader
  }

  public static func auth(req: IncomingMessage) throws -> BasicAuthCredentials {
    
    guard let authorization = req.headers[ci: "Authorization"] as? String else {
      throw Error.MissingAuthorizationHeader
    }
    
    guard let base64 = parseAuthorizationValue(matching : "Basic",
                                               value    : authorization)
     else {
      throw Error.InvalidBasicAuthorizationHeader
    }
      
    // Split the result at the ':' (ASCII 58). Split only once.
    let split = Base64.decode(string: base64).split(separator: 58, maxSplits: 1)
    guard split.count == 2 else {
      throw Error.InvalidBasicAuthorizationHeader
    }
    
    guard let username = String.decode(utf8: split[0]),
          let password = String.decode(utf8: split[1]) 
      else 
    {
      throw Error.InvalidBasicAuthorizationHeader
    }
    
    return BasicAuthCredentials(username: username, password: password)
  }
  
  public static func parseAuthorizationValue(matching schema : String,
                                             ignoringCase    : Bool = true,
                                             value           : String)
                -> String?
  {
    let parts = value
      .utf8
      .split(omittingEmptySubsequences: true) { $0 == 32 || $0 == 9 }
      .map { String.init($0)! }
    
    guard parts.count == 2 else { return nil }
    
    if ignoringCase {
      guard schema.lowercased() == parts[0].lowercased() else { return nil }
    }
    else {
      guard schema == parts[0] else { return nil }
    }
    
    return parts[1]
  }

}
