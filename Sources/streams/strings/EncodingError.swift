//
//  EncodingError.swift
//  Noze.io
//
//  Created by Helge Heß on 01/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import core

public enum EncodingError : Error {

  case Generic
  case CouldNotDecodeCString
  case UnsupportedEncoding(String)
  
}
