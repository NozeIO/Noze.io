//
//  EncodingError.swift
//  NozeIO
//
//  Created by Helge Heß on 01/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

public enum EncodingError : ErrorType {

  case Generic
  case CouldNotDecodeCString
  case UnsupportedEncoding(String)
  
}
