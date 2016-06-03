//
//  EventEmitter.swift
//  Noze.IO
//
//  Created by Helge Hess on 25/06/15.
//  Copyright © 2015 ZeeZide GmbH. All rights reserved.
//

/// Marker interface for objects which emit events.
///
/// Note that in Noze.io events are static, that is, instead of:
///
///      stream.on("readable") { ... }
///
/// This is done:
///
///      stream.onReadable { ... }
///
public protocol EventEmitterType {
        
  // TODO/TBD:
  // - use reflection to scan the class for `on` methods and provide reflection
  //   in return, i.e. var supportedEvents : [ String ]
  // - do we want a generic/dynamic `func on<T>(event: String)`?
  // - another options would be to reverse the event handlers, like so:
  //     var pipe = EventListenerSet<ReadableStream>()
  //     pipe.on { ... }
  //     pipe.once { ... }
  //   TBD. This would reduce the code a lot.
}
