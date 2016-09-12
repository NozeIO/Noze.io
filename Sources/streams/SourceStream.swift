//
//  Readable.swift
//  Noze.IO
//
//  Created by Helge Hess on 22/06/15.
//  Copyright © 2015 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import core

/// A GCD based Readable stream. Similar but not exactly the same like a Node.JS
/// streams2 Readable object.
///
/// All the buffering logic is in `ReadableStream`, the `Readable` is solely
/// connecting a `GReadableSourceType` to the _primaryRead() implementation
/// of the ReadableStream.
/// In essence, a `GReadableSourceType` is nothing but an asynchronous
/// generator.
///
/// * How to use as a client/consumer
///
/// Sample:
///   let stream = StdinSource().readable()
///   stream.onEnd      { print("stream processing is done ...") }
///   stream.onError    { print("catched error: \($0)") }
///   stream.onReadable {
///     let bucket = stream.read() // nil on EOF
///     print("got bucket of data: \(bucket)")
///   }
///
/// Explained:
/// - the readable() function wraps a ReadableSource, in this case the
///   StdinSource, in a Readable stream
/// - the onEnd callback is called when the stream hit EOF *and* all data from
///   the internal buffers has been read
/// - the onError block is called, well, on errors :-)
/// - the onReadable is called when the Readable has data in its internal
///   buffers which the client can read from w/o blocking. Or on EOF.
///   NOTEs:
///   - there really should be only one subscriber for Readable events, or
///     at least only one party should actually read() from it
///   - setting the first onReadable callback will schedule the source for
///     reading (i.e. files will get opened, the first blocks will get read)
///
/// * Adding a new type of stream
///
/// Unlike in Node.JS there is no _read() primary function. Instead implement a
/// ReadableSource object. See the protocol's documentation for further 
/// information on how to do this.
///
///
/// * Differences to Node.JS:
/// - This Readable doesn't actually implement the underlying _read()
///   implementation, but defers that to a 'ReadableSourceType'
/// - The Readable can deal with sets of any type (not just bytes, but e.g. 
///   lines, or records as well). While Node.JS also has an 'object mode',
///   this works on a 'per item' basis.
/// - We do not support streams1 'data' events to avoid confusion what should
///   be used. Maybe we should change that, easy enough.
///
/// I originally called this BufferedReadablePullStream, but renamed that back
/// to Readable to be more in line with Node.
///
public class SourceStream<G : GReadableSourceType>
               : ReadableStream<G.SourceElement>
               , GReadableSourceType // a `Readable` itself can act as a source
{
  public var source : G
  
  // MARK: - Init
  
  init(source        : G,
       highWaterMark : Int? = nil,
       queue         : DispatchQueue = core.Q,
       enableLogger  : Bool = false)
  {
    self.source = source
    
    super.init(highWaterMark: highWaterMark ?? G.defaultHighWaterMark,
               queue: queue, enableLogger: enableLogger)
    
    module.newReadableListeners.emit(self)
  }
  
  
  // MARK: - Call Source
  
  public override func _primaryRead(count howMuchToRead: Int) {
    let log = self.log // avoid capturing self for log
    log.enter(); defer { log.leave() }
    
    // Note: The source can run this either synchronously, OR
    //       asynchronously!
    source.next(queue: Q, count: howMuchToRead) { error, bucket in
      log.enter("\(#function) - generator CB"); defer { log.leave() }
      if log.enabled {
        if let bucket = bucket { log.debug("got bucket: \(bucket)") }
        else { log.debug("got EOF.") }
      }
      
      if let error = error {
        self.catched(error: error)
        return
      }
      
      // Push the bucket (or EOF) we got from the source into our interal
      // buffer. This will trigger a Readable event.
      self.push(bucket)
      
      // In here we used to call `self.nextTick { self.maybeGenerateMore() }`,
      // but I think this is wrong. It is called in other places and if
      // anything, push should see whether/how it needs to retrigger the
      // generator.
    }
  }

  public override func _primaryPause() {
    source.pause()
  }
  
  
  // MARK: - Closing
  
  override public func closeReadStream() {
    source.closeSource()
    super.closeReadStream()
  }
  
  
  // MARK: - Readable is a ReadableSource itself
  
  public static var defaultHighWaterMark : Int {
    return G.defaultHighWaterMark
  }
}

public extension GReadableSourceType {

  public func readable(hwm: Int = Self.defaultHighWaterMark)
              -> SourceStream<Self>
  {
    return SourceStream(source: self, highWaterMark: hwm)
  }

}
