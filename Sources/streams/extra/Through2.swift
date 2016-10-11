//
//  Through2.swift
//  Noze.io
//
//  Created by Helge Heß on 5/25/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

/// This creates a Transform stream where the transformation is done by the
/// provided closure.
///
/// Note: The closure MUST call done eventually.
public func through2<TWriteItem, TReadItem>
              (_ transform: @escaping
                            ( _ bucket: [ TWriteItem ],
                              _ push:   ( [ TReadItem ]? ) -> Void,
                              _ done:   ( Error?, [ TReadItem ]? ) -> Void )
                                 -> Void )
            -> Transform<TWriteItem, TReadItem>
{
  return Transform(transform: transform)
}

/// This creates a Transform stream where the transformation is done by the
/// provided closure.
///
/// Note: The closure MUST call done eventually.
public func through2<T>(_ transform: @escaping
                                     ( _ bucket: [ T ],
                                       _ push:   ( [ T ]? ) -> Void,
                                       _ done:   ( Error?, [ T ]? ) -> Void )
                                       -> Void )
              -> Transform<T, T>
{
  return Transform(transform: transform)
}
