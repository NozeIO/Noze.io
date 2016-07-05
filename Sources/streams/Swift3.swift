//
//  Swift3.swift
//  NozeIO
//
//  Created by Helge Heß on 5/9/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if swift(>=3.0) // #swift3-fd
// This does not seem to carry over to other modules (deprecation warning is per
// module)
// => use the reverse!
public typealias ErrorType    = ErrorProtocol
public typealias SequenceType = Sequence
#endif
