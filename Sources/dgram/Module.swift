//
//  Module.swift
//  Noze.io
//
//  Created by Helge Heß on 4/10/16.
//  Changed by https://github.com/lichtblau
//  Copyright © 2016 ZeeZide GmbH and Contributors. All rights reserved.
//

@_exported import core
import xsys

public class NozeDgram : NozeModule {
}
public let module = NozeDgram()


open class CreateOptions {
  /// Version of IP stack (IPv4)
  public var family : sa_family_t = sa_family_t(xsys.AF_INET)

  public init() {}
}

/// Creates a new `dgram.Socket` object.
///
/// Optional onMessage block.
///
/// Sample:
///
///     let server = dgram.createSocket { sock in
///       print("connected")
///     }
///     .onError { error in
///       print("error: \(error)")
///     }
///     .bind(...) {
///       print("Server is listening on \($0.address)")
///     }
///
@discardableResult
public func createSocket(options   : CreateOptions = CreateOptions(),
                         onMessage : MessageCB? = nil) -> Socket
{
  // TODO: support options
  let sock = Socket()
  if let cb = onMessage { _ = sock.onMessage(handler: cb) }
  return sock
}
