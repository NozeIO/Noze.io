//
//  Through2.swift
//  Noze.io
//
//  Created by Helge Heß on 5/25/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

#if swift(>=3.0) // #swift3-1st-kwarg

/// This creates a Transform stream where the transformation is done by the
/// provided closure.
///
/// Note: The closure MUST call done eventually.
public func through2<TWriteItem, TReadItem>
              (_ transform: ( bucket: [ TWriteItem ],
                              push:   ( [ TReadItem ]? ) -> Void,
                              done:   ( ErrorProtocol?, [ TReadItem ]? ) -> Void )
                                 -> Void )
            -> Transform<TWriteItem, TReadItem>
{
  return Transform(transform: transform)
}

/// This creates a Transform stream where the transformation is done by the
/// provided closure.
///
/// Note: The closure MUST call done eventually.
public func through2<T>(_ transform: ( bucket: [ T ],
                                       push:   ( [ T ]? ) -> Void,
                                       done:   ( ErrorProtocol?, [ T ]? ) -> Void )
                                       -> Void )
              -> Transform<T, T>
{
  return Transform(transform: transform)
}

#else
  
/// This creates a Transform stream where the transformation is done by the
/// provided closure.
///
/// Note: The closure MUST call done eventually.
public func through2<TWriteItem, TReadItem>
              (transform: ( bucket: [ TWriteItem ],
                            push:   ( [ TReadItem ]? ) -> Void,
                            done:   ( ErrorType?, [ TReadItem ]? ) -> Void )
                               -> Void )
            -> Transform<TWriteItem, TReadItem>
{
  return Transform(transform: transform)
}

/// This creates a Transform stream where the transformation is done by the
/// provided closure.
///
/// Note: The closure MUST call done eventually.
public func through2<T>(transform: ( bucket: [ T ],
                                     push:   ( [ T ]? ) -> Void,
                                     done:   ( ErrorType?, [ T ]? ) -> Void )
                                     -> Void )
            -> Transform<T, T>
{
  return Transform(transform: transform)
}

#endif
