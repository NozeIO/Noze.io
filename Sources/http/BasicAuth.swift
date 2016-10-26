//
//  BasicAuth.swift
//  Noze.io
//
//  Created by Fabian Fett on 26/10/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import base64

public struct BasicAuthCredentials {
  public let username : String
  public let password : String
}

public enum BasicAuthError : Error {
  case MissingAuthorizationHeader
  case InvalidBasicAuthorizationHeader
}

public func auth(req: IncomingMessage) throws -> BasicAuthCredentials {
  
  guard let authorization = req.headers["Authorization"] as? String else {
    throw BasicAuthError.MissingAuthorizationHeader
  }
  
  guard let base64 = parseAuthorizationValue(matching : "Basic",
                                             value    : authorization)
   else {
    throw BasicAuthError.InvalidBasicAuthorizationHeader
  }
    
  // Split the result at the ':' (ASCII 58). Split only once.
  let split = Base64.decode(string: base64).split(separator: 58, maxSplits: 1)
  guard split.count == 2 else {
    throw BasicAuthError.InvalidBasicAuthorizationHeader
  }
  
  guard let username = String.decode(utf8: split[0]),
        let password = String.decode(utf8: split[1]) 
    else 
  {
    throw BasicAuthError.InvalidBasicAuthorizationHeader
  }
  
  return BasicAuthCredentials(username: username, password: password)
}

public func parseAuthorizationValue(matching schema : String,
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
