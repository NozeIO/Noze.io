//
//  ReadableStream.swift
//  Noze.IO
//
//  Created by Helge Hess on 30/06/15.
//  Copyright © 2015 ZeeZide GmbH. All rights reserved.
//

// those need to be global so that we can also use them in GReadableStreamType
public typealias ReadableCB = () -> Void
public typealias EndCB      = () -> Void

/// Primarily a marker interface which can be used as a *type* (which
/// GReadableStreamType cannot (generic)).
///
/// It isn't that useful since the primary method - read() - is a generic ...
///
public protocol ReadableStreamType : class, StreamType {
  // TODO: This should probably just go away. We have it because
  //       GReadableStreamType can't be used as a standalone type.
  //       Right now this is being used in onNewReadable events.
  
  /// Pause the stream (it won't emit events, and won't continue reading)
  func pause()
  func resume()
  
  /// This is emitted if a batch of `ReadType` items is available for reading,
  /// or - if EOF has been hit.
  @discardableResult func onReadable  (handler cb: @escaping ReadableCB) -> Self
  @discardableResult func onceReadable(handler cb: @escaping ReadableCB) -> Self
  
  /// This is emitted on EOF.
  func onEnd       (handler cb: @escaping EndCB)      -> Self
  func onceEnd     (handler cb: @escaping EndCB)      -> Self
  
  /// Did the stream hit EOF? Useful to check when calling `read` with a size.
  /// Careful: That EOF has been hit, doesn't imply that the whole buffer has
  ///          been read!
  var hitEOF : Bool { get }
  
  func closeReadStream()
  
  var highWaterMark : Int { get set }
    // TBD: should remove, doesn't belong here. It depends on a concrete
    //      implementation
}


/// GReadableStreamType
///
/// The key type all higher level code should work with.
///
///
/// ## Events
///
/// ### Readable
///
/// The stream has more data available, it can be read with read() :-)
///
/// ### End
///
/// I.e. the stream read an EOF. No more data can be read, its done. Really,
/// don't try.
/// NOTE: This is not usually sent on its own! And onReadable will be triggered,
///       which then makes the consumer call read(), and only then the EOF
///       condition will be evaluated.
///
public protocol GReadableStreamType : class, ReadableStreamType {
  
  associatedtype ReadType
  
  /// `read(count:)` returns up to `count` items of the `ReadType`, or `nil` if
  /// EOF has been hit.
  ///
  /// Note: There is an extension method `read` which calls `read(count:nil)`.
  ///
  /// Usually you would call `read()` in response to a `readable` event. When
  /// that event emits, either EOF has been hit, in which case `read` will
  /// return `nil`. Or the internal stream buffer has data waiting. If `nil` has
  /// been passed in as the `count`, `read` will return the whole buffer.
  /// If `count` is bigger than the internal buffer, the internal buffer will
  /// be returned.
  /// If `count` was smaller than the internal buffer, just `count` bytes are
  /// returned. But careful, in this case the caller is responsible for
  /// consuming the internal buffer! No extra `readable` event will be fired!
  ///
  func read(count c: Int?) -> [ ReadType ]?
  
  /// Push data (or EOF) to the stream buffer, this will result in an onReadable
  /// event eventually.
  func push(_ b: [ ReadType ]?)
  
  /// Like `push`, but this put the data into the front of the buffer. It is
  /// useful if a consuming stream could not handle all data, and wants to wait
  /// for more.
  func unshift(_ b: [ ReadType ])
}

public extension GReadableStreamType {
  
  /// Calls `read(count:)` with a `count` set to `nil` aka, this requests all
  /// data that is available.
  ///
  /// Usually you would call `read()` in response to a `readable` event. When
  /// that event emits, either EOF has been hit, in which case `read` will
  /// return `nil`. Or the internal stream buffer has data waiting. This method
  /// consumes the whole buffer and returns it to the caller.
  ///
  /// Note: Subclasses are supposed to override `read(count:)`, NOT this method.
  ///
  func read() -> [ ReadType ]? { // workaround for no default-args in protocols
    return self.read(count: nil)
  }

}
