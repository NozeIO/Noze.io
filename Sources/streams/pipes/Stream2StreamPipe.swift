//
//  pipe.swift
//  Noze.io
//
//  Created by Helge Hess on 31/03/16.
//  Copyright © 2016 ZeeZide GmbH. All rights reserved.
//

import Dispatch
import xsys
import core
import events

// TODO: this has quite a few open ends aside from the happy path

private let tickPipe       = true
private let enableHeavyLog = false

/// Pipe operator for streams, neat :-)
///
/// Like so:
///
///   request | zip | encrypt | fs
///
@discardableResult
public func |<ReadStream: GReadableStreamType, WriteStream: GWritableStreamType>
             (left: ReadStream, right: WriteStream) -> WriteStream
             where ReadStream.ReadType == WriteStream.WriteType
{
  return left.pipe(right)
}

@discardableResult
public func |<ReadStream: GReadableStreamType, WriteStream: GWritableStreamType>
             (left: ReadStream?, right: WriteStream) -> WriteStream
             where ReadStream.ReadType == WriteStream.WriteType
{
  guard left != nil else {
    // left side has nothing to pipe, immediately end target stream.
    // TBD: good idea? :-) Added this to support: spawn("ls").stdout | ...
    right.end()
    return right
  }
  
  return left!.pipe(right)
}

public extension GReadableStreamType {

  /// pipe(in: GReadableStreamType, out: GWritableStreamType)
  ///
  /// pipe() simply connects an input stream with an output stream, but in an
  /// asynchronous way. 
  /// - as input becomes available on the input stream, it is pushed into the 
  ///   output stream
  /// - if the output stream is busy/full, the input stream is suspended
  ///
  @discardableResult
  func pipe<TO: GWritableStreamType>
                (_ outStream: TO,
                 endOnFinish: Bool = true, passErrors: Bool = true)
              -> TO
              where Self.ReadType == TO.WriteType
  {
    // Node.JS notes:
    // - onPipe is sent by writable stream (and onUnpipe)
    // - though the current code doesn't seem to be pull-stream based?
    
    // to test drain:
    //   self.highWaterMark = 1 // with 0 it stalls
    
    let state = StreamPipeState(self, outStream,
                                endOnFinish : endOnFinish,
                                passErrors  : passErrors)
    
    // TODO: Node.JS tracks the pipes in the source streams. I don't think this
    //       is necessary, but might be useful for debugging.
    
    if let emitTarget = outStream as? PipeEmitTarget {
      emitTarget.emit(pipe: self)
    }
    
    // This creates a reference cycle between the pipe (StreamPipeState) and
    // the input and output streams.
    //
    //   THIS IS INTENTIONAL. (I think :-)
    //
    // It allows you to setup a pipe which is decoupled from everything else,
    // say:
    //
    //   fs.createReadStream("from.txt") | fs.createWriteStream("to.txt")
    //
    // no reference is taken, the read and write objects are solely connected
    // and kept alive by the pipe.
    //
    // So when is the cycle broken? This is supposed to happen when the streams
    // finish (either regularily via end/finish or due to an error).
    _ = self.onError       { error in state.onSourceError(error) }
    _ = outStream.onError  { error in state.onTargetError(error) }
    _ = self.onEnd         { state.onEnd()    }
    _ = outStream.onFinish { state.onFinish() }
    
    
    // start the piping
    
    heavyLog("install initial read handler ...")
    let log : Logger?
    if let ll = self as? LameLogObjectType { log = ll.log }
    else { log = nil }
    
    _ = self.onceReadable {
      log?.enter(function: "onReadable")
      defer { log?.leave(function: "onReadable") }
      
      heavyLog("  initial pipe call")
      state.onPipeSourceReadable()
    }
    
    return outStream
  }
  
  // TODO: unpipe() function? not really necessary though ...
}

private class StreamPipeState<TI: GReadableStreamType, TO: GWritableStreamType>
              where TI.ReadType == TO.WriteType
{
  var src         : TI?
  var dest        : TO?
  let endOnFinish : Bool // call outStream 'end' on EOF?
  let passErrors  : Bool
  
  init(_ src: TI, _ dest: TO, endOnFinish: Bool, passErrors: Bool) {
    self.endOnFinish = endOnFinish
    self.passErrors  = passErrors
    self.src  = src
    self.dest = dest
  }
  
  private final func heavyPipeLog(_ s : String) {
    heavyLog("  <<[DO pipe: \(s)]>>  ")
  }

  
  // MARK: - onReadable
  
  final func handleSourceEnd() {
    if let emitTarget = dest as? PipeEmitTarget, let src = src {
      // TBD: tick this?
      emitTarget.emit(unpipe: src)
    }
    
    if endOnFinish {
      if let outStream = dest {
        heavyPipeLog("closing out")
        outStream.end()
      }
    }
    else {
      heavyLog("Keeping open \(dest as Optional)")
    }
    
    // Important: this resets all closures in the inStream which may be
    //            retaining our pipe.
    src = nil // we finished reading
    
    // OK, this is a little tricky and error prone. When the read-end has
    // finished, the pipe is essentially 'done'.
    //
    // BUT: The write-end may not have finished writing yet! Yet the pipe itself
    //      may be the only object retaining the target-stream.
    // Summary: it is important that the output streams keeps itself alive while
    //          it is writing! (this should be automagic by Target based streams
    //          as the write-closure is going to hold a reference).
    dest = nil // we are done piping
  }
  
  
  final func onPipeEOF() {
    heavyPipeLog("\nCCC hit ********** EOF ***********. \(src as Optional)")
    // FIXME: hitEOF apparently not set on sockets?
    //assert(inStream.hitEOF)

    handleSourceEnd()
  }
  
  final func onSigPipe() { // target stream is gone
    // TBD: Should we issue a SIGPIPE error on the error-handler of the
    //      input stream? Or only if requested?
    assert(dest == nil, "sigpipe but there is a target stream??")
    src = nil
  }
  
  final func onPipeSourceReadable() {
    guard let inStream  = src else {
      // readable event but no inStream? (can happen after SIGPIPE)
      if dest != nil { // this should not happen?
        onPipeEOF() // treat like EOF (which detaches dest)
      }
      return
    }
    
    /* issue read call, may hit EOF */
    guard let bucket = inStream.read() else { return onPipeEOF() }
    
    /* grab target stream */
    guard let outStream = dest else { return onSigPipe() }
    
    /* write data to target */
    
    // NOTE: Even if this returns false, the outStream still caches the
    //       buckets. It is a hint that the outStream buffer is full and the
    //       inStream should pause.
    let couldWriteEverything = outStream.write(bucket)
    
    if couldWriteEverything {
      // re-register for next readable event.
      // Note: You may think that the source gets filled in between. But no,
      //       this can't really happen as we run in a single thread. Async-IO
      //       handlers will only run in the next tick.
      //  BUT: Of course a side-effect of the `outStream.write` could push data
      //       into in-stream. TBD: not sure whether this is an actual issue.
      // TODO: not quite sure why the `tick` is necessary except to avoid greedy
      //       pipe processing (not giving other handlers a chance).
      _ = inStream.onceReadable {
        if tickPipe {
          nextTick { self.onPipeSourceReadable() }
        }
        else {
          self.onPipeSourceReadable() // recurse
        }
      }
    }
    else {
      inStream.pause()
      
      _ = outStream.onceDrain {
        _ = inStream.onceReadable {
          if tickPipe {
            nextTick { self.onPipeSourceReadable() }
              // recurse // this makes us hit EOF
          }
          else {
            self.onPipeSourceReadable() // recurse
          }
        }
        
        inStream.resume()
      }
    }
  }
  
  
  // MARK: - Errors
  
  var ignoreTargetErrors = false // in case we are the ones emitting them ;-)
  
  final func onSourceError(_ error: Error) {
    //efprint("CCC GOT ERROR: \(error)") // TODO
    
    //if let perr = error as? POSIXErrorCode {
    //  efprint("  Posix: \(perr.rawValue)")
    //}
    
    // TODO: what should we do here?
    // - forward error to target and unpipe?
    //
    // Well:
    // - http://grokbase.com/t/gg/nodejs/12bwd4zm4x/should-stream-pipe-forward-errors
    // - http://stackoverflow.com/questions/21771220/error-handling-with-node-js-streams
    // "According to this thread .pipe() is not built to forward errors":
    //   createStream()
    //     .onError { e in handleError(e) }
    //   .pipe(b)
    //     .onError { e in handleError(e) }
    //   .pipe(c)
    //     .onError { e in handleError(e) }
    
    // We do pass along errors by default. Because, I think, it just makes
    // sense ... We do, however, wrap the error.
    if passErrors {
      // TBD: Only forward if the source has no error handler besides the
      //      pipe itself? Would be nice.
      if let errDest = dest as? ErrorEmitTarget {
        let pipeError : PipeSourceError
        if let oldPipeError = error as? PipeSourceError {
          // TBD: should we add this stream as a pass-through to the error?
          pipeError = oldPipeError
        }
        else {
          pipeError = PipeSourceError(error: error, stream: src)
        }
        
        ignoreTargetErrors = true // we are done
        errDest.emit(error: pipeError)
      }
    }
    
    // an error ends the target
    handleSourceEnd()
  }
  
  final func onTargetError(_ error: Error) {
    // TODO: do we actually care about target errors?
    
    // Note: The OutStream can be a Duplex! I.e. the error might also be an
    //       error of the in-side of the Duplex
    efprint("Pipe TargetError: ERROR: \(error)")
    
    if ignoreTargetErrors {
      return
    }
    
    // TODO: what should we do here?
    
    //xsys.exit(42)
  }
  
  final func onEnd() {
    // This probably doesn't have to do anything. Quite likely we already
    // processed the EOF and closed the pipe from there.
    handleSourceEnd()
  }
  
  final func onFinish() {
    heavyLog("\nC hit ********** FINISHED ***********.")
    // TODO: need to do anything on self, like pause the source?
  }
  
}


// TEMPORARY, for hacking

#if os(Linux)
import Glibc
#endif

private var nzStdErr = StdErrStream()

private struct StdErrStream : TextOutputStream {
  mutating func write(_ string: String) { fputs(string, stderr) }
}

private func efprint<T>(_ value: T) {
  fflush(stderr)
  print(value, nzStdErr)
  fflush(stderr)
}
private func heavyLog<T>(_ value: T) {
  if enableHeavyLog { efprint(value) }
}
