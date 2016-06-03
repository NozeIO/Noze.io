//
//  FileDescriptorStream.swift
//  Noze.io
//
//  Created by Helge Hess on 19/05/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

/// Just a protocol which can be implemented by streams that are based upon a
/// file descriptor.
///
/// This can be useful for logging, debugging, and in a few other situations.
/// E.g. to determine whether sendfile() can be used.
///
public protocol FileDescriptorStream {
  
  var fd : FileDescriptor { get }
  
}
