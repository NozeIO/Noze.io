//
//  MustacheNode.swift
//  Noze.io
//
//  Created by Helge Heß on 6/1/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

public enum MustacheNode {
  case Empty
  case Global([ MustacheNode])
  case Text(String)
  case Section(String, [ MustacheNode ])
  case InvertedSection(String, [ MustacheNode ])
  case Tag(String)
  case UnescapedTag(String)
}

