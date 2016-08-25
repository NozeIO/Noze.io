//
//  Swift3.swift
//  Noze.io
//
//  Created by Helge Heß on 5/25/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if swift(>=3.0) // #swift3-fd
public typealias SwiftError    = Error
#else
public typealias SwiftError    = ErrorType
public typealias Error         = ErrorType
public typealias Collection    = CollectionType
public typealias Sequence      = SequenceType
public typealias OptionSet     = OptionSetType
#endif
