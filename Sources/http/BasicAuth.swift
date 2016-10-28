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

  public struct Credentials {
    public let username : String
    public let password : String
  }

  public enum Error : Swift.Error {
    case MissingAuthorizationHeader
    case InvalidBasicAuthorizationHeader
  }

  public static func auth(_ req: IncomingMessage) throws -> Credentials {
    
    guard let authorization = req.headers[ci: "Authorization"] as? String else {
      throw Error.MissingAuthorizationHeader
    }
    
    let parts = authorization
      .utf8
      .split(omittingEmptySubsequences: true) { $0 == 32 || $0 == 9 }
      .map { String.init($0)! }
    
    guard parts.count == 2 && "basic" == parts[0].lowercased() else { 
      throw Error.InvalidBasicAuthorizationHeader
    }
    
    let base64 = parts[1]
      
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
    
    return Credentials(username: username, password: password)
  }
}
