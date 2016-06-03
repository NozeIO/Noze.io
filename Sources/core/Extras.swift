//
//  Extras.swift
//  Noze.IO
//
//  Created by Helge Heß on 21/06/15.
//  Copyright © 2015 ZeeZide GmbH. All rights reserved.
//

public func paddedNumber(value: Int, width: Int = 1, pad: Character = " ")
            -> String
{
  var s = String(value)
  while s.characters.count < width {
    s = String(pad) + s
  }
  return s
}
